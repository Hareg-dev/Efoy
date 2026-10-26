/// Overall licensing status of this installation.
enum LicenseAccessStatus {
  /// Inside the free evaluation window (no license activated yet).
  trial,

  /// The evaluation window has ended and no valid license is activated.
  trialExpired,

  /// A signed license is activated and within its validity window.
  licensed,

  /// A license exists but is expired (or the device clock was rolled back).
  expired,

  /// Conservative block: installation identity or secure storage is
  /// unavailable, so licensing state cannot be trusted.
  blocked,
}

/// Why a [LicenseAccessStatus.blocked] state is active.
enum LicenseBlockReason {
  /// Platform secure storage is unavailable (corrupt keystore, OS bug).
  storageUnavailable,
}

/// Immutable snapshot of the current licensing state, produced by
/// [LicenseService] and consumed by UI and enforcement code.
class LicenseAccessState {
  const LicenseAccessState({
    required this.status,
    required this.installationId,
    this.plan,
    this.licenseId,
    this.expiresAt,
    this.activatedAt,
    this.clockRollbackSuspected = false,
    this.blockReason,
  });

  /// Conservative block state (see [LicenseAccessStatus.blocked]).
  const LicenseAccessState.blocked({
    required this.installationId,
    required this.blockReason,
  }) : status = LicenseAccessStatus.blocked,
       plan = null,
       licenseId = null,
       expiresAt = null,
       activatedAt = null,
       clockRollbackSuspected = false;

  final LicenseAccessStatus status;

  /// This installation's random identifier (null in blocked state).
  final String? installationId;

  /// Activated plan; null while on trial.
  final String? plan;

  /// Issuer-minted license id; null while on trial.
  final String? licenseId;

  /// When the current license or trial ends (null for lifetime licenses).
  final DateTime? expiresAt;

  /// When the current license was activated (null while on trial).
  final DateTime? activatedAt;

  /// Best-effort flag: the device clock appears to have been moved back.
  final bool clockRollbackSuspected;

  /// Populated only for [LicenseAccessStatus.blocked].
  final LicenseBlockReason? blockReason;

  /// True when paid operations may proceed.
  bool get canPerformPaidOperations =>
      status == LicenseAccessStatus.trial ||
      status == LicenseAccessStatus.licensed;

  /// True when a signed license is activated (active or expired).
  bool get hasLicense => plan != null;

  /// True for lifetime licenses (no expiry date to show).
  bool get isLifetime => plan == 'lifetime';

  /// Whole days remaining, rounded down; 0 when expired or unknown.
  int get daysRemaining {
    final end = expiresAt;
    if (end == null) return 0;
    final remaining = end.difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inDays;
  }

  /// Expiring within the next seven days.
  bool get isExpiringSoon {
    if (!canPerformPaidOperations) return false;
    if (isLifetime) return false;
    final days = daysRemaining;
    return days > 0 && days <= 7;
  }
}
