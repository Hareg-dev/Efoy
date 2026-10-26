import 'package:cryptography/cryptography.dart';
import 'package:efoy_licensing/efoy_licensing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/licensing/installation_identity.dart';
import 'package:efoy_retail_app/core/licensing/license_gate.dart';
import 'package:efoy_retail_app/core/licensing/license_service.dart';
import 'package:efoy_retail_app/core/licensing/license_store.dart';
import 'package:efoy_retail_app/core/licensing/secure_store.dart';

/// Deterministic clock for time-dependent license tests.
class MutableClock {
  MutableClock(this.now);

  DateTime now;

  DateTime call() => now;

  /// Epoch milliseconds of the current time.
  int get nowMs => now.millisecondsSinceEpoch;
}

/// Test-only Ed25519 signer for activation-code fixtures.
///
/// This mirrors what the operator-side issuer CLI does. It exists only in
/// the test suite (the `cryptography` package is a dev dependency of the
/// app); the distributed app contains verification only and can never sign.
class TestIssuer {
  TestIssuer._(this._keyPair, this.publicKeyBytes);

  static final Ed25519 _algorithm = Ed25519();

  final SimpleKeyPair _keyPair;

  /// Public key bytes matching the private key of this throwaway issuer.
  final List<int> publicKeyBytes;

  /// Creates a fresh throwaway keypair per fixture.
  static Future<TestIssuer> create() async {
    final keyPair = await _algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    return TestIssuer._(keyPair, publicKey.bytes);
  }

  /// Signs the canonical bytes of [payload].
  Future<List<int>> sign(LicensePayload payload) async {
    final signature = await _algorithm.sign(
      payload.canonicalBytes(),
      keyPair: _keyPair,
    );
    return signature.bytes;
  }

  /// Produces a complete activation code for [payload].
  Future<String> issueCode(LicensePayload payload) async {
    return ActivationCode.encode(payload, await sign(payload));
  }
}

/// A 30-day monthly license payload bound to [installationId].
LicensePayload monthlyPayload({
  required String installationId,
  required int issuedAtMs,
  int? expiresAtMs,
  int validityMs = 30 * 24 * 60 * 60 * 1000,
  String licenseId = 'EFY-TEST-0001',
  int version = LicensePayload.supportedVersion,
}) {
  return LicensePayload(
    version: version,
    licenseId: licenseId,
    installationId: installationId,
    plan: LicensePlan.monthly,
    issuedAtMs: issuedAtMs,
    expiresAtMs: expiresAtMs ?? issuedAtMs + validityMs,
  );
}

/// A lifetime license payload bound to [installationId].
LicensePayload lifetimePayload({
  required String installationId,
  required int issuedAtMs,
  String licenseId = 'EFY-TEST-LIFE',
}) {
  return LicensePayload(
    version: LicensePayload.supportedVersion,
    licenseId: licenseId,
    installationId: installationId,
    plan: LicensePlan.lifetime,
    issuedAtMs: issuedAtMs,
    expiresAtMs: LicensePayload.lifetimeExpirySentinelMs,
  );
}

/// Wires the real [LicenseService] to in-memory stores, a mutable clock and
/// a throwaway verifier key, so policy tests need no platform plugins.
class LicenseHarness {
  LicenseHarness._({
    required this.secureStore,
    required this.licenseStore,
    required this.clock,
    required this.issuer,
  }) : verifier = LicenseVerifier(publicKeyBytes: issuer.publicKeyBytes);

  final InMemorySecureStore secureStore;
  final InMemoryLicenseStore licenseStore;
  final MutableClock clock;
  final TestIssuer issuer;
  final LicenseVerifier verifier;

  LicenseService? _service;

  /// The current service instance, created on first use.
  LicenseService get service => _service ??= _buildService();

  LicenseService _buildService() {
    return LicenseService(
      licenseStore: licenseStore,
      secureStore: secureStore,
      verifier: verifier,
      clock: clock.call,
    );
  }

  /// Simulates an app restart: a fresh service over the same persisted
  /// state (secure storage and license store survive the restart).
  LicenseService restart() {
    _service = null;
    return service;
  }

  static Future<LicenseHarness> create({DateTime? now}) async {
    return LicenseHarness._(
      secureStore: InMemorySecureStore(),
      licenseStore: InMemoryLicenseStore(),
      clock: MutableClock(now ?? DateTime.utc(2026, 1, 10)),
      issuer: await TestIssuer.create(),
    );
  }

  /// The installation id of this harness (created on first use).
  Future<String> installationId() async {
    final identity = InstallationIdentity(secureStore: secureStore);
    return (await identity.getInstallationId())!;
  }

  /// Issues a valid monthly activation code for this installation.
  Future<String> monthlyCode({
    int? issuedAtMs,
    int validityMs = 30 * 24 * 60 * 60 * 1000,
    String licenseId = 'EFY-TEST-0001',
  }) async {
    return issuer.issueCode(
      monthlyPayload(
        installationId: await installationId(),
        issuedAtMs: issuedAtMs ?? clock.nowMs,
        validityMs: validityMs,
        licenseId: licenseId,
      ),
    );
  }

  /// Issues a valid lifetime activation code for this installation.
  Future<String> lifetimeCode({
    int? issuedAtMs,
    String licenseId = 'EFY-TEST-LIFE',
  }) async {
    return issuer.issueCode(
      lifetimePayload(
        installationId: await installationId(),
        issuedAtMs: issuedAtMs ?? clock.nowMs,
        licenseId: licenseId,
      ),
    );
  }
}

/// Expectation helper: the future completes with [LicenseRequiredException]
/// whose [LicensedOperation] is [operation].
Future<void> expectBlocked(
  Future<void> future,
  LicensedOperation operation,
) async {
  await expectLater(
    future,
    throwsA(
      isA<LicenseRequiredException>().having(
        (error) => error.operation,
        'operation',
        operation,
      ),
    ),
  );
}
