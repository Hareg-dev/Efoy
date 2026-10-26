import 'dart:convert';
import 'dart:typed_data';

import 'license_plan.dart';

/// Thrown when a payload violates schema or date invariants.
class LicensePayloadException implements Exception {
  const LicensePayloadException(this.message);

  final String message;

  @override
  String toString() => 'LicensePayloadException: $message';
}

/// Thrown when the transport payload declares a plan this app does not know.
///
/// Kept distinct from [LicensePayloadException] so the transport layer can
/// surface a precise "unsupported plan" rejection instead of a generic
/// malformed-code error.
class UnsupportedLicensePlanException extends LicensePayloadException {
  const UnsupportedLicensePlanException(this.planName)
    : super('Unsupported plan: $planName');

  /// The unknown plan wire name found in the payload.
  final String planName;
}

/// Version 1 of the Efoy license payload.
///
/// The payload is signed over [canonicalBytes]: a fixed-order,
/// newline-separated UTF-8 string with a domain prefix. The signature is
/// **never** computed over a serialized map, so field order, number
/// formatting and JSON escaping can never change what was signed.
class LicensePayload {
  /// Current payload version produced and accepted by this build.
  static const int supportedVersion = 1;

  /// Expiry sentinel (3000-01-01T00:00:00Z) used by lifetime licenses so the
  /// signed payload always carries a concrete expiry value.
  static const int lifetimeExpirySentinelMs = 32503680000000;

  const LicensePayload({
    required this.version,
    required this.licenseId,
    required this.installationId,
    required this.plan,
    required this.issuedAtMs,
    required this.expiresAtMs,
  });

  /// Payload format version. Must equal [supportedVersion] to verify.
  final int version;

  /// Unique identifier minted by the issuer for this license.
  final String licenseId;

  /// Installation identifier the license is bound to.
  final String installationId;

  /// Subscription plan granted by this license.
  final LicensePlan plan;

  /// Epoch milliseconds (UTC) at which the issuer created the license.
  final int issuedAtMs;

  /// Epoch milliseconds (UTC) at which the license stops being valid.
  /// Lifetime licenses use [lifetimeExpirySentinelMs].
  final int expiresAtMs;

  DateTime get issuedAtUtc =>
      DateTime.fromMillisecondsSinceEpoch(issuedAtMs, isUtc: true);

  DateTime get expiresAtUtc =>
      DateTime.fromMillisecondsSinceEpoch(expiresAtMs, isUtc: true);

  /// Canonical byte representation covered by the Ed25519 signature.
  ///
  /// Format (UTF-8, `\n` separated, fixed field order):
  /// ```
  /// EFOY-LIC-v1
  /// <licenseId>
  /// <installationId>
  /// <plan wire name>
  /// <issuedAtMs>
  /// <expiresAtMs>
  /// ```
  Uint8List canonicalBytes() {
    final canonical = [
      'EFOY-LIC-v$version',
      licenseId,
      installationId,
      plan.wireName,
      issuedAtMs.toString(),
      expiresAtMs.toString(),
    ].join('\n');
    return Uint8List.fromList(utf8.encode(canonical));
  }

  /// Returns a copy with the given fields replaced.
  LicensePayload copyWith({
    int? version,
    String? licenseId,
    String? installationId,
    LicensePlan? plan,
    int? issuedAtMs,
    int? expiresAtMs,
  }) {
    return LicensePayload(
      version: version ?? this.version,
      licenseId: licenseId ?? this.licenseId,
      installationId: installationId ?? this.installationId,
      plan: plan ?? this.plan,
      issuedAtMs: issuedAtMs ?? this.issuedAtMs,
      expiresAtMs: expiresAtMs ?? this.expiresAtMs,
    );
  }

  /// Validate schema and date invariants. Throws [LicensePayloadException].
  void validate() {
    if (version != supportedVersion) {
      throw LicensePayloadException('Unsupported payload version: $version');
    }
    if (licenseId.isEmpty) {
      throw const LicensePayloadException('License id is empty.');
    }
    if (installationId.isEmpty) {
      throw const LicensePayloadException('Installation id is empty.');
    }
    if (issuedAtMs <= 0) {
      throw const LicensePayloadException('Issued-at timestamp is invalid.');
    }
    if (plan == LicensePlan.lifetime) {
      if (expiresAtMs != lifetimeExpirySentinelMs) {
        throw const LicensePayloadException(
          'Lifetime licenses must use the lifetime expiry sentinel.',
        );
      }
    } else {
      if (expiresAtMs <= issuedAtMs) {
        throw const LicensePayloadException(
          'Expiry must be after the issued-at timestamp.',
        );
      }
    }
  }

  /// Transport representation embedded in the activation code envelope.
  /// Field types are checked strictly on [fromJson].
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'v': version,
      'id': licenseId,
      'inst': installationId,
      'plan': plan.wireName,
      'iat': issuedAtMs,
      'exp': expiresAtMs,
    };
  }

  /// Strictly parses the transport map. Unknown versions or plans are
  /// accepted here (so the signature can still be checked) and rejected by
  /// [validate]; a tampered payload will simply fail signature verification.
  static LicensePayload fromJson(Map<String, dynamic> json) {
    final version = json['v'];
    final licenseId = json['id'];
    final installationId = json['inst'];
    final planName = json['plan'];
    final issuedAtMs = json['iat'];
    final expiresAtMs = json['exp'];

    if (version is! int ||
        licenseId is! String ||
        installationId is! String ||
        planName is! String ||
        issuedAtMs is! int ||
        expiresAtMs is! int) {
      throw const LicensePayloadException('Malformed license payload.');
    }

    final plan =
        LicensePlan.tryFromWireName(planName) ??
        (throw UnsupportedLicensePlanException(planName));

    return LicensePayload(
      version: version,
      licenseId: licenseId,
      installationId: installationId,
      plan: plan,
      issuedAtMs: issuedAtMs,
      expiresAtMs: expiresAtMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LicensePayload &&
      other.version == version &&
      other.licenseId == licenseId &&
      other.installationId == installationId &&
      other.plan == plan &&
      other.issuedAtMs == issuedAtMs &&
      other.expiresAtMs == expiresAtMs;

  @override
  int get hashCode => Object.hash(
    version,
    licenseId,
    installationId,
    plan,
    issuedAtMs,
    expiresAtMs,
  );
}
