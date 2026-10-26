import 'license_access_state.dart';

/// Business operations that require an active (non-expired) license or an
/// active trial. Everything else — viewing history, reports, export and
/// backup — remains available after expiry by design.
enum LicensedOperation {
  recordSale('record a sale'),
  voidSale('void a sale'),
  restock('restock inventory'),
  manageProducts('add, edit or remove products'),
  manageExpenses('add, edit or remove expenses'),
  manageHeldOrders('hold or restore orders');

  const LicensedOperation(this.label);

  /// Short human-readable label used in user-facing messages.
  final String label;
}

/// Thrown by [LicenseGate] when a paid operation is attempted while the
/// license is expired, the trial has ended, or secure storage is unusable.
///
/// Carries the computed access state so the UI can explain exactly what to
/// do next (renew, activate, or fix the device). Business data is never
/// modified when this exception is thrown.
class LicenseRequiredException implements Exception {
  const LicenseRequiredException({
    required this.operation,
    required this.state,
  });

  final LicensedOperation operation;

  final LicenseAccessState state;

  @override
  String toString() =>
      'LicenseRequiredException: cannot ${operation.label} '
      '(${state.status.name})';
}

/// Single point where licensing decisions are enforced, at the business /
/// service layer rather than only in the UI.
abstract class LicenseGate {
  Future<void> ensureAllowed(LicensedOperation operation);
}

/// Gate used by tests and tooling to bypass enforcement explicitly.
class AlwaysAllowedLicenseGate implements LicenseGate {
  const AlwaysAllowedLicenseGate();

  @override
  Future<void> ensureAllowed(LicensedOperation operation) async {}
}

/// Gate used by tests to verify enforcement wiring without a real service.
class AlwaysBlockedLicenseGate implements LicenseGate {
  const AlwaysBlockedLicenseGate();

  @override
  Future<void> ensureAllowed(LicensedOperation operation) async {
    throw LicenseRequiredException(
      operation: operation,
      state: LicenseAccessState.blocked(
        installationId: null,
        blockReason: LicenseBlockReason.storageUnavailable,
      ),
    );
  }
}
