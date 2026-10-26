import 'package:efoy_licensing/efoy_licensing.dart';

import 'clock_guard.dart';
import 'installation_identity.dart';
import 'license_access_state.dart';
import 'license_gate.dart';
import 'license_store.dart';
import 'secure_store.dart';

/// Outcome of an activation (or renewal — same code path) attempt.
class ActivationResult {
  const ActivationResult.ok(this.state)
    : success = true,
      rejection = null,
      storageFailure = false;

  const ActivationResult.rejected(this.rejection)
    : success = false,
      state = null,
      storageFailure = false;

  const ActivationResult.storageUnavailable()
    : success = false,
      rejection = null,
      state = null,
      storageFailure = true;

  final bool success;

  /// Populated when a code was syntactically usable but rejected.
  final LicenseRejectionReason? rejection;

  /// Fresh access state after a successful activation.
  final LicenseAccessState? state;

  /// True when the platform keystore was unavailable and nothing could be
  /// verified or persisted.
  final bool storageFailure;
}

/// Centralized licensing policy for the whole app.
///
/// Every licensing decision flows through this single service:
/// - current access status (trial / licensed / expired / blocked),
/// - activation and offline renewal of signed licenses,
/// - paid-operation enforcement via [ServiceLicenseGate],
/// - best-effort clock-rollback detection.
///
/// Data protection guarantees: expiry never deletes or corrupts business
/// data. Expired users keep full read access plus export and backup.
class LicenseService {
  LicenseService({
    required LicenseStore licenseStore,
    required SecureStore secureStore,
    required LicenseVerifier verifier,
    DateTime Function()? clock,
  }) : _licenseStore = licenseStore, // ignore: prefer_initializing_formals
       _verifier = verifier, // ignore: prefer_initializing_formals
       _clock = clock ?? DateTime.now,
       _identity = InstallationIdentity(secureStore: secureStore),
       _clockGuard = ClockGuard(secureStore: secureStore),
       _secureStore = secureStore;

  /// Duration of the free evaluation window for new installations.
  static const Duration trialDuration = Duration(days: 3);

  static const String _trialStartKey = 'efoy_trial_started_ms';

  final LicenseStore _licenseStore;
  final LicenseVerifier _verifier;
  final DateTime Function() _clock;
  final InstallationIdentity _identity;
  final ClockGuard _clockGuard;
  final SecureStore _secureStore;

  DateTime _now() => _clock();

  /// Computes the current access state. Also maintains the clock
  /// high-water mark, so call this regularly (the UI stream does).
  Future<LicenseAccessState> currentAccess() async {
    final now = _now();
    final installationId = await _identity.getInstallationId();
    if (installationId == null) {
      return const LicenseAccessState.blocked(
        installationId: null,
        blockReason: LicenseBlockReason.storageUnavailable,
      );
    }

    final rollback = await _clockGuard.checkAndRecord(now);
    final license = await _licenseStore.latest();

    if (license != null) {
      return _licenseState(
        license: license,
        installationId: installationId,
        now: now,
        rollback: rollback,
      );
    }

    return _trialState(
      installationId: installationId,
      now: now,
      rollback: rollback,
    );
  }

  LicenseAccessState _licenseState({
    required StoredLicenseRecord license,
    required String installationId,
    required DateTime now,
    required bool rollback,
  }) {
    final isLifetime = license.plan == LicensePlan.lifetime;

    // Binding check: a license restored from another device's backup does
    // not authorize this installation.
    if (license.installationId != installationId) {
      return LicenseAccessState(
        status: LicenseAccessStatus.expired,
        installationId: installationId,
        plan: license.plan.wireName,
        licenseId: license.licenseId,
        expiresAt: license.expiresAt,
        activatedAt: license.activatedAt,
      );
    }

    if (isLifetime) {
      return LicenseAccessState(
        status: LicenseAccessStatus.licensed,
        installationId: installationId,
        plan: license.plan.wireName,
        licenseId: license.licenseId,
        expiresAt: null,
        activatedAt: license.activatedAt,
      );
    }

    if (rollback) {
      // Clock appears rolled back: time-limited licenses stay locked until
      // the device clock catches up with the recorded high-water mark.
      return LicenseAccessState(
        status: LicenseAccessStatus.expired,
        installationId: installationId,
        plan: license.plan.wireName,
        licenseId: license.licenseId,
        expiresAt: license.expiresAt,
        activatedAt: license.activatedAt,
        clockRollbackSuspected: true,
      );
    }

    if (now.isBefore(license.expiresAt)) {
      return LicenseAccessState(
        status: LicenseAccessStatus.licensed,
        installationId: installationId,
        plan: license.plan.wireName,
        licenseId: license.licenseId,
        expiresAt: license.expiresAt,
        activatedAt: license.activatedAt,
      );
    }

    return LicenseAccessState(
      status: LicenseAccessStatus.expired,
      installationId: installationId,
      plan: license.plan.wireName,
      licenseId: license.licenseId,
      expiresAt: license.expiresAt,
      activatedAt: license.activatedAt,
    );
  }

  Future<LicenseAccessState> _trialState({
    required String installationId,
    required DateTime now,
    required bool rollback,
  }) async {
    final DateTime trialEnd;
    try {
      trialEnd = await _ensureTrialEnd(now);
    } on SecureStoreUnavailableException {
      return const LicenseAccessState.blocked(
        installationId: null,
        blockReason: LicenseBlockReason.storageUnavailable,
      );
    }

    if (rollback) {
      return LicenseAccessState(
        status: LicenseAccessStatus.trialExpired,
        installationId: installationId,
        expiresAt: trialEnd,
        clockRollbackSuspected: true,
      );
    }

    if (now.isBefore(trialEnd)) {
      return LicenseAccessState(
        status: LicenseAccessStatus.trial,
        installationId: installationId,
        expiresAt: trialEnd,
      );
    }

    return LicenseAccessState(
      status: LicenseAccessStatus.trialExpired,
      installationId: installationId,
      expiresAt: trialEnd,
    );
  }

  /// Reads the recorded trial start, recording it on first use.
  Future<DateTime> _ensureTrialEnd(DateTime now) async {
    try {
      final stored = await _secureStore.read(_trialStartKey);
      final startMs = stored == null ? null : int.tryParse(stored);
      if (startMs == null) {
        final nowMs = now.millisecondsSinceEpoch;
        await _secureStore.write(_trialStartKey, nowMs.toString());
        return now.add(trialDuration);
      }
      return DateTime.fromMillisecondsSinceEpoch(startMs).add(trialDuration);
    } on SecureStoreUnavailableException {
      // Identity already succeeded, but the store broke between calls.
      // Fail closed for paid operations via the blocked status.
      rethrow;
    }
  }

  /// Activates (or renews — identical flow) a license from an offline
  /// activation code. The code is verified against the embedded public key
  /// and bound to this installation before anything is persisted.
  Future<ActivationResult> activate(String activationCode) async {
    final installationId = await _identity.getInstallationId();
    if (installationId == null) {
      return const ActivationResult.storageUnavailable();
    }

    final now = _now();
    final cleaned = activationCode.replaceAll(RegExp(r'\s'), '');
    final verification = await _verifier.verify(
      cleaned,
      installationId: installationId,
      now: now,
    );

    if (!verification.isValid) {
      return ActivationResult.rejected(verification.reason!);
    }

    final payload = verification.payload!;
    await _licenseStore.save(
      StoredLicenseRecord(
        installationId: installationId,
        activationCode: cleaned,
        licenseId: payload.licenseId,
        issuedAt: payload.issuedAtUtc,
        activatedAt: now,
        expiresAt: payload.expiresAtUtc,
        plan: payload.plan,
      ),
    );

    return ActivationResult.ok(await currentAccess());
  }

  /// Gate used by repositories: recomputes the access state on every call,
  /// so enforcement never relies on a possibly stale cached UI state.
  ServiceLicenseGate asGate() => ServiceLicenseGate(this);
}

/// [LicenseGate] backed by [LicenseService].
class ServiceLicenseGate implements LicenseGate {
  const ServiceLicenseGate(this._service);

  final LicenseService _service;

  @override
  Future<void> ensureAllowed(LicensedOperation operation) async {
    final state = await _service.currentAccess();
    if (!state.canPerformPaidOperations) {
      throw LicenseRequiredException(operation: operation, state: state);
    }
  }
}
