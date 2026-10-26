import 'dart:convert';

import 'package:efoy_licensing/efoy_licensing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'license_test_utils.dart';

void main() {
  // Fixed fixture values so expected byte strings are stable.
  const installationId = 'AAAA-BBBB-CCCC-DDDD';
  final issuedAt = DateTime.utc(2026, 1, 10);
  final issuedAtMs = issuedAt.millisecondsSinceEpoch;
  final expiresAtMs = issuedAtMs + const Duration(days: 30).inMilliseconds;

  LicensePayload monthly() => monthlyPayload(
    installationId: installationId,
    issuedAtMs: issuedAtMs,
    expiresAtMs: expiresAtMs,
  );

  group('LicensePayload canonical bytes', () {
    test('are a fixed-order, domain-prefixed, newline-separated string', () {
      final bytes = monthly().canonicalBytes();
      final text = utf8.decode(bytes);
      expect(
        text,
        'EFOY-LIC-v1\n'
        'EFY-TEST-0001\n'
        '$installationId\n'
        'monthly\n'
        '$issuedAtMs\n'
        '$expiresAtMs',
      );
    });

    test('are deterministic for identical payloads', () {
      expect(monthly().canonicalBytes(), monthly().canonicalBytes());
    });

    test('change when any signed field changes', () {
      final base = monthly();
      expect(
        base.copyWith(installationId: 'ZZZZ').canonicalBytes(),
        isNot(base.canonicalBytes()),
      );
      expect(
        base.copyWith(expiresAtMs: expiresAtMs + 1).canonicalBytes(),
        isNot(base.canonicalBytes()),
      );
      expect(
        base.copyWith(plan: LicensePlan.lifetime).canonicalBytes(),
        isNot(base.canonicalBytes()),
      );
    });
  });

  group('LicensePayload validation', () {
    test('accepts a well-formed monthly payload', () {
      expect(() => monthly().validate(), returnsNormally);
    });

    test('accepts a lifetime payload using the sentinel expiry', () {
      expect(
        () => lifetimePayload(
          installationId: installationId,
          issuedAtMs: issuedAtMs,
        ).validate(),
        returnsNormally,
      );
    });

    test('rejects an unsupported version', () {
      expect(
        () => monthly().copyWith(version: 2).validate(),
        throwsA(isA<LicensePayloadException>()),
      );
    });

    test('rejects a lifetime payload with a non-sentinel expiry', () {
      expect(
        () => lifetimePayload(
          installationId: installationId,
          issuedAtMs: issuedAtMs,
        ).copyWith(expiresAtMs: expiresAtMs).validate(),
        throwsA(isA<LicensePayloadException>()),
      );
    });

    test('rejects expiry at or before issued-at', () {
      expect(
        () => monthly().copyWith(expiresAtMs: issuedAtMs).validate(),
        throwsA(isA<LicensePayloadException>()),
      );
      expect(
        () => monthly().copyWith(expiresAtMs: issuedAtMs - 1).validate(),
        throwsA(isA<LicensePayloadException>()),
      );
    });

    test('rejects empty license or installation ids and bad timestamps', () {
      expect(
        () => monthly().copyWith(licenseId: '').validate(),
        throwsA(isA<LicensePayloadException>()),
      );
      expect(
        () => monthly().copyWith(installationId: '').validate(),
        throwsA(isA<LicensePayloadException>()),
      );
      expect(
        () => monthly().copyWith(issuedAtMs: 0).validate(),
        throwsA(isA<LicensePayloadException>()),
      );
    });
  });

  group('LicensePayload JSON transport', () {
    test('round-trips through toJson/fromJson', () {
      final payload = monthly();
      final restored = LicensePayload.fromJson(payload.toJson());
      expect(restored, payload);
    });

    test('rejects wrong field types strictly', () {
      final json = monthly().toJson();
      json['v'] = '1'; // version as string instead of int
      expect(
        () => LicensePayload.fromJson(json),
        throwsA(isA<LicensePayloadException>()),
      );
      final json2 = monthly().toJson();
      json2['iat'] = issuedAtMs.toString(); // timestamp as string
      expect(
        () => LicensePayload.fromJson(json2),
        throwsA(isA<LicensePayloadException>()),
      );
    });

    test('throws UnsupportedLicensePlanException for unknown plans', () {
      final json = monthly().toJson();
      json['plan'] = 'yearly';
      expect(
        () => LicensePayload.fromJson(json),
        throwsA(
          isA<UnsupportedLicensePlanException>().having(
            (error) => error.planName,
            'planName',
            'yearly',
          ),
        ),
      );
    });
  });

  group('ActivationCode codec', () {
    test('round-trips a signed payload', () async {
      final issuer = await TestIssuer.create();
      final payload = monthly();
      final code = await issuer.issueCode(payload);
      final decoded = ActivationCode.decode(code);
      expect(decoded.isOk, isTrue);
      expect(decoded.payload, payload);
      expect(decoded.signature, await issuer.sign(payload));
    });

    test('tolerates line breaks and spaces from copy-paste', () async {
      final issuer = await TestIssuer.create();
      final code = await issuer.issueCode(monthly());
      final grouped = code.replaceAllMapped(
        RegExp('.{4}'),
        (match) => '${match.group(0)} ',
      );
      final decoded = ActivationCode.decode(grouped.trim());
      expect(decoded.isOk, isTrue);
    });

    test('tolerates padded standard base64 input', () async {
      final issuer = await TestIssuer.create();
      final code = await issuer.issueCode(monthly());
      // Convert base64url to padded standard base64.
      final standard = code.replaceAll('-', '+').replaceAll('_', '/');
      final padded = standard + '=' * ((4 - standard.length % 4) % 4);
      expect(ActivationCode.decode(padded).isOk, isTrue);
    });

    test('reports empty, non-base64, and non-JSON input precisely', () {
      expect(
        ActivationCode.decode('   \n ').error,
        ActivationCodeFormatError.empty,
      );
      expect(
        ActivationCode.decode('not base64 at all!!').error,
        ActivationCodeFormatError.notBase64,
      );
      // Valid base64 of non-JSON bytes.
      final notJson = base64.encode(utf8.encode('hello world'));
      expect(
        ActivationCode.decode(notJson).error,
        ActivationCodeFormatError.malformedJson,
      );
      // Valid base64 of JSON that is not the envelope object.
      final jsonArray = base64.encode(utf8.encode('[1,2,3]'));
      expect(
        ActivationCode.decode(jsonArray).error,
        ActivationCodeFormatError.badEnvelope,
      );
      // Envelope missing the signature.
      final noSig = base64.encode(
        utf8.encode(json.encode({'v': 1, 'lic': monthly().toJson()})),
      );
      expect(
        ActivationCode.decode(noSig).error,
        ActivationCodeFormatError.badEnvelope,
      );
      // Signature present but not base64.
      final badSig = base64.encode(
        utf8.encode(
          json.encode({'v': 1, 'lic': monthly().toJson(), 'sig': '???!'}),
        ),
      );
      expect(
        ActivationCode.decode(badSig).error,
        ActivationCodeFormatError.badEnvelope,
      );
    });

    test('reports unsupported plans as a distinct transport error', () {
      final payloadJson = monthly().toJson();
      payloadJson['plan'] = 'yearly';
      final code = base64.encode(
        utf8.encode(
          json.encode({
            'v': 1,
            'lic': payloadJson,
            'sig': base64.encode([1, 2, 3]),
          }),
        ),
      );
      expect(
        ActivationCode.decode(code).error,
        ActivationCodeFormatError.unsupportedPlan,
      );
    });
  });

  group('LicenseVerifier', () {
    late TestIssuer issuer;
    late LicenseVerifier verifier;

    setUp(() async {
      issuer = await TestIssuer.create();
      verifier = LicenseVerifier(publicKeyBytes: issuer.publicKeyBytes);
    });

    test('accepts a correctly signed code for this installation', () async {
      final payload = monthly();
      final verification = await verifier.verify(
        await issuer.issueCode(payload),
        installationId: installationId,
        now: issuedAt,
      );
      expect(verification.isValid, isTrue);
      expect(verification.payload, payload);
    });

    test('rejects a signature made with a different private key', () async {
      final attacker = await TestIssuer.create();
      final forged = await attacker.issueCode(monthly());
      final verification = await verifier.verify(
        forged,
        installationId: installationId,
        now: issuedAt,
      );
      expect(verification.reason, LicenseRejectionReason.invalidSignature);
    });

    test(
      'rejects a modified payload carrying the original signature',
      () async {
        final payload = monthly();
        final signature = await issuer.sign(payload);
        // Attacker re-encodes a different payload with the stolen signature.
        final tampered = ActivationCode.encode(
          payload.copyWith(
            expiresAtMs: expiresAtMs + const Duration(days: 365).inMilliseconds,
          ),
          signature,
        );
        final verification = await verifier.verify(
          tampered,
          installationId: installationId,
          now: issuedAt,
        );
        expect(verification.reason, LicenseRejectionReason.invalidSignature);
      },
    );

    test('rejects a flipped signature byte', () async {
      final payload = monthly();
      final signature = await issuer.sign(payload);
      signature[0] = signature[0] ^ 0xFF;
      final verification = await verifier.verify(
        ActivationCode.encode(payload, signature),
        installationId: installationId,
        now: issuedAt,
      );
      expect(verification.reason, LicenseRejectionReason.invalidSignature);
    });

    test('rejects an expired license', () async {
      final code = await issuer.issueCode(monthly());
      final verification = await verifier.verify(
        code,
        installationId: installationId,
        now: issuedAt.add(const Duration(days: 31)),
      );
      expect(verification.reason, LicenseRejectionReason.expired);
    });

    test(
      'accepts minor clock skew but rejects far-future issue dates',
      () async {
        final payload = monthly();
        final code = await issuer.issueCode(payload);
        // Issued "10 minutes in the future": tolerated.
        expect(
          (await verifier.verify(
            code,
            installationId: installationId,
            now: issuedAt.subtract(const Duration(minutes: 10)),
          )).isValid,
          isTrue,
        );
        // Issued "one hour in the future": rejected.
        expect(
          (await verifier.verify(
            code,
            installationId: installationId,
            now: issuedAt.subtract(const Duration(hours: 1)),
          )).reason,
          LicenseRejectionReason.notYetValid,
        );
      },
    );

    test('rejects a license bound to a different installation', () async {
      final code = await issuer.issueCode(monthly());
      final verification = await verifier.verify(
        code,
        installationId: 'EEEE-EEEE-EEEE-EEEE',
        now: issuedAt,
      );
      expect(verification.reason, LicenseRejectionReason.installationMismatch);
    });

    test('rejects a payload from an unsupported format version', () async {
      final future = monthly().copyWith(version: 2);
      final code = await issuer.issueCode(future);
      final verification = await verifier.verify(
        code,
        installationId: installationId,
        now: issuedAt,
      );
      expect(verification.reason, LicenseRejectionReason.unsupportedVersion);
    });

    test('rejects an unsupported plan', () async {
      final payloadJson = monthly().toJson();
      payloadJson['plan'] = 'yearly';
      final code = base64.encode(
        utf8.encode(
          json.encode({
            'v': 1,
            'lic': payloadJson,
            'sig': base64.encode([1, 2, 3]),
          }),
        ),
      );
      final verification = await verifier.verify(
        code,
        installationId: installationId,
        now: issuedAt,
      );
      expect(verification.reason, LicenseRejectionReason.unsupportedPlan);
    });

    test(
      'rejects a correctly signed but structurally invalid payload',
      () async {
        // Lifetime plan with a non-sentinel expiry, signed by the real key:
        // signature is fine, schema invariants are not.
        final invalid = lifetimePayload(
          installationId: installationId,
          issuedAtMs: issuedAtMs,
        ).copyWith(expiresAtMs: expiresAtMs);
        final code = await issuer.issueCode(invalid);
        final verification = await verifier.verify(
          code,
          installationId: installationId,
          now: issuedAt,
        );
        expect(verification.reason, LicenseRejectionReason.invalidPayload);
      },
    );

    test('rejects malformed activation codes', () async {
      for (final junk in ['', '   ', 'hello world', 'aGVsbG8=']) {
        final verification = await verifier.verify(
          junk,
          installationId: installationId,
          now: issuedAt,
        );
        expect(verification.reason, LicenseRejectionReason.malformedCode);
      }
    });

    test('accepts a lifetime license far in the future', () async {
      final code = await issuer.issueCode(
        lifetimePayload(installationId: installationId, issuedAtMs: issuedAtMs),
      );
      final verification = await verifier.verify(
        code,
        installationId: installationId,
        now: issuedAt.add(const Duration(days: 365 * 50)),
      );
      expect(verification.isValid, isTrue);
    });
  });
}
