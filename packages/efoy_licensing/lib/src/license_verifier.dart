import 'package:cryptography/cryptography.dart';

import 'activation_code.dart';
import 'license_payload.dart';

/// Why an activation code was rejected.
enum LicenseRejectionReason {
  /// The code could not be decoded (format error).
  malformedCode,

  /// The payload declares a format version this app cannot understand.
  unsupportedVersion,

  /// The payload declares a plan this app does not support.
  unsupportedPlan,

  /// The payload violates schema or date invariants.
  invalidPayload,

  /// The Ed25519 signature does not match the canonical payload bytes.
  invalidSignature,

  /// The license was issued for a different installation identifier.
  installationMismatch,

  /// The license validity window has passed.
  expired,

  /// The license is not yet valid (issued in the future beyond tolerance).
  notYetValid,
}

/// Outcome of offline license verification.
class LicenseVerification {
  const LicenseVerification._({this.payload, this.reason});

  const LicenseVerification.valid(LicensePayload payload)
    : this._(payload: payload);

  const LicenseVerification.rejected(LicenseRejectionReason reason)
    : this._(reason: reason);

  final LicensePayload? payload;

  final LicenseRejectionReason? reason;

  bool get isValid => payload != null;
}

/// Offline Ed25519 verification of activation codes against the embedded
/// public key. This class contains **no signing capability**; licenses are
/// produced exclusively by the operator-side issuer tool.
class LicenseVerifier {
  LicenseVerifier({required List<int> publicKeyBytes})
    : _publicKey = SimplePublicKey(
        List<int>.unmodifiable(publicKeyBytes),
        type: KeyPairType.ed25519,
      );

  static final Ed25519 _algorithm = Ed25519();

  final SimplePublicKey _publicKey;

  /// Tolerance for minor clock skew when checking "issued in the future".
  static const Duration clockSkewTolerance = Duration(minutes: 10);

  /// Verifies an activation code end to end:
  /// decode → schema validation → signature over canonical bytes →
  /// installation binding → validity window.
  Future<LicenseVerification> verify(
    String activationCode, {
    required String installationId,
    DateTime? now,
  }) async {
    final decoded = ActivationCode.decode(activationCode);
    if (!decoded.isOk) {
      if (decoded.error == ActivationCodeFormatError.unsupportedPlan) {
        // Well-formed code, but the plan is unknown to this build (e.g. a
        // plan introduced by a newer app version).
        return const LicenseVerification.rejected(
          LicenseRejectionReason.unsupportedPlan,
        );
      }
      return const LicenseVerification.rejected(
        LicenseRejectionReason.malformedCode,
      );
    }

    final payload = decoded.payload!;

    // Version check first: a future format must not be interpreted.
    if (payload.version != LicensePayload.supportedVersion) {
      return const LicenseVerification.rejected(
        LicenseRejectionReason.unsupportedVersion,
      );
    }

    // Date and lifetime-sentinel invariants.
    try {
      payload.validate();
    } on LicensePayloadException {
      return const LicenseVerification.rejected(
        LicenseRejectionReason.invalidPayload,
      );
    }

    // Signature over the canonical byte representation.
    final signature = Signature(decoded.signature!, publicKey: _publicKey);
    final signatureOk = await _algorithm.verify(
      payload.canonicalBytes(),
      signature: signature,
    );
    if (!signatureOk) {
      return const LicenseVerification.rejected(
        LicenseRejectionReason.invalidSignature,
      );
    }

    // Installation binding.
    if (payload.installationId != installationId) {
      return const LicenseVerification.rejected(
        LicenseRejectionReason.installationMismatch,
      );
    }

    // Validity window. The start already passed the notYetValid check with
    // skew tolerance, so only the expiry needs a strict comparison here.
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    if (nowMs < payload.issuedAtMs - clockSkewTolerance.inMilliseconds) {
      return const LicenseVerification.rejected(
        LicenseRejectionReason.notYetValid,
      );
    }
    if (nowMs >= payload.expiresAtMs) {
      return const LicenseVerification.rejected(LicenseRejectionReason.expired);
    }

    return LicenseVerification.valid(payload);
  }
}
