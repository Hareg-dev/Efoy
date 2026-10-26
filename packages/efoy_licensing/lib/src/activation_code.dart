import 'dart:convert';

import 'license_payload.dart';

/// Reason an activation code could not be decoded into a payload + signature.
enum ActivationCodeFormatError {
  /// The code contained no usable characters.
  empty,

  /// The code is not valid base64url.
  notBase64,

  /// The decoded bytes are not valid UTF-8 JSON.
  malformedJson,

  /// The JSON envelope is missing required keys or has wrong types.
  badEnvelope,

  /// The payload references a plan this app does not support.
  unsupportedPlan,
}

/// Result of decoding the transport layer of an activation code.
class ActivationCodeDecodeResult {
  const ActivationCodeDecodeResult._({
    this.payload,
    this.signature,
    this.error,
  });

  const ActivationCodeDecodeResult.failed(ActivationCodeFormatError error)
    : this._(error: error);

  const ActivationCodeDecodeResult.ok({
    required LicensePayload payload,
    required List<int> signature,
  }) : this._(payload: payload, signature: signature);

  final LicensePayload? payload;
  final List<int>? signature;
  final ActivationCodeFormatError? error;

  bool get isOk => payload != null && signature != null;
}

/// Codec for the copyable activation code exchanged with customers.
///
/// The code is unpadded base64url over a compact JSON envelope:
/// ```json
/// {"v":1,"lic":{"v":1,"id":"...","inst":"...","plan":"monthly","iat":1,"exp":2},"sig":"<base64 signature>"}
/// ```
/// The signature is computed over the payload's canonical bytes, not over
/// this envelope, so re-serializing the envelope never breaks verification.
class ActivationCode {
  const ActivationCode._();

  /// Encodes a signed payload into a copyable activation code.
  static String encode(LicensePayload payload, List<int> signature) {
    final envelope = json.encode(<String, dynamic>{
      'v': payload.version,
      'lic': payload.toJson(),
      'sig': base64.encode(signature),
    });
    return base64Url.encode(utf8.encode(envelope)).replaceAll('=', '');
  }

  /// Decodes an activation code. Whitespace (spaces, tabs, newlines) is
  /// tolerated; base64url alphabet characters (`-`, `_`) are preserved.
  static ActivationCodeDecodeResult decode(String input) {
    final cleaned = input.replaceAll(RegExp(r'\s'), '');
    if (cleaned.isEmpty) {
      return const ActivationCodeDecodeResult.failed(
        ActivationCodeFormatError.empty,
      );
    }

    final normalized = _normalizeBase64(cleaned);
    List<int> bytes;
    try {
      bytes = base64.decode(normalized);
    } on FormatException {
      return const ActivationCodeDecodeResult.failed(
        ActivationCodeFormatError.notBase64,
      );
    }

    String jsonString;
    try {
      jsonString = utf8.decode(bytes);
    } on FormatException {
      return const ActivationCodeDecodeResult.failed(
        ActivationCodeFormatError.malformedJson,
      );
    }

    Object? decoded;
    try {
      decoded = json.decode(jsonString);
    } on FormatException {
      return const ActivationCodeDecodeResult.failed(
        ActivationCodeFormatError.malformedJson,
      );
    }
    if (decoded is! Map) {
      return const ActivationCodeDecodeResult.failed(
        ActivationCodeFormatError.badEnvelope,
      );
    }
    final envelope = decoded.cast<String, dynamic>();

    final payloadJson = envelope['lic'];
    final signatureText = envelope['sig'];
    if (payloadJson is! Map || signatureText is! String) {
      return const ActivationCodeDecodeResult.failed(
        ActivationCodeFormatError.badEnvelope,
      );
    }

    List<int> signature;
    try {
      signature = base64.decode(signatureText);
    } on FormatException {
      return const ActivationCodeDecodeResult.failed(
        ActivationCodeFormatError.badEnvelope,
      );
    }

    final LicensePayload payload;
    try {
      payload = LicensePayload.fromJson(payloadJson.cast<String, dynamic>());
    } on UnsupportedLicensePlanException {
      return const ActivationCodeDecodeResult.failed(
        ActivationCodeFormatError.unsupportedPlan,
      );
    } on LicensePayloadException {
      return const ActivationCodeDecodeResult.failed(
        ActivationCodeFormatError.badEnvelope,
      );
    }

    return ActivationCodeDecodeResult.ok(
      payload: payload,
      signature: signature,
    );
  }

  /// Accepts both base64 and base64url input, padding to a multiple of four.
  static String _normalizeBase64(String input) {
    final urlSafe = input.replaceAll('-', '+').replaceAll('_', '/');
    final remainder = urlSafe.length % 4;
    if (remainder == 0) return urlSafe;
    return urlSafe + '=' * (4 - remainder);
  }
}
