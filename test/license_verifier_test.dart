import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/security/license_verifier.dart';
import 'package:efoy_retail_app/data/models/license_model.dart';

void main() {
  const deviceId = 'TEST-DEVICE-0001';

  String encodeKey(Map<String, dynamic> payload) {
    return base64.encode(utf8.encode(json.encode(payload)));
  }

  group('LicenseVerifier.generateLicenseKey / verifyLicense', () {
    test('verifies a valid license generated for this device', () {
      final expiry = DateTime.now().add(const Duration(days: 30));
      final key = LicenseVerifier.generateLicenseKey(
        deviceId: deviceId,
        expiryDate: expiry,
      );

      final result = LicenseVerifier.verifyLicense(
        licenseKey: key,
        deviceId: deviceId,
      );

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.deviceId, deviceId);
      expect(result.licenseType, LicenseType.monthly);
      expect(
        result.expiryDate!.millisecondsSinceEpoch,
        expiry.millisecondsSinceEpoch,
      );
    });

    test('accepts keys with whitespace and added dashes', () {
      final key = LicenseVerifier.generateLicenseKey(
        deviceId: deviceId,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );
      final messyKey = '  ${key.replaceAll('-', '-\n ')}  ';

      final result = LicenseVerifier.verifyLicense(
        licenseKey: messyKey,
        deviceId: deviceId,
      );

      expect(result.isValid, isTrue);
    });

    test('detects an expired license', () {
      final key = LicenseVerifier.generateLicenseKey(
        deviceId: deviceId,
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      final result = LicenseVerifier.verifyLicense(
        licenseKey: key,
        deviceId: deviceId,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('expired'));
      expect(result.expiryDate, isNotNull);
    });

    test('rejects a license bound to another device', () {
      final key = LicenseVerifier.generateLicenseKey(
        deviceId: 'OTHER-DEVICE-9999',
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );

      final result = LicenseVerifier.verifyLicense(
        licenseKey: key,
        deviceId: deviceId,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('not valid for this device'));
    });

    test('rejects a malformed key', () {
      final result = LicenseVerifier.verifyLicense(
        licenseKey: 'not-a-real-license',
        deviceId: deviceId,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, 'Invalid license key format');
    });

    test('rejects a tampered expiry date because the signature no longer matches', () {
      final key = LicenseVerifier.generateLicenseKey(
        deviceId: deviceId,
        expiryDate: DateTime.now().add(const Duration(days: 10)),
      );
      final decoded =
          json.decode(utf8.decode(base64.decode(key.replaceAll('-', ''))))
              as Map<String, dynamic>;
      decoded['expiryDate'] =
          DateTime.now().add(const Duration(days: 3650)).millisecondsSinceEpoch;

      final result = LicenseVerifier.verifyLicense(
        licenseKey: encodeKey(decoded),
        deviceId: deviceId,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('signature verification failed'));
    });

    test('rejects a payload with missing fields', () {
      final result = LicenseVerifier.verifyLicense(
        licenseKey: encodeKey({'deviceId': deviceId}),
        deviceId: deviceId,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('License verification error'));
    });
  });

  group('LicenseVerifier license types', () {
    test('maps remaining duration to trial, monthly, yearly and lifetime', () {
      LicenseType typeFor(int days) {
        final key = LicenseVerifier.generateLicenseKey(
          deviceId: deviceId,
          expiryDate: DateTime.now().add(Duration(days: days)),
        );
        return LicenseVerifier.verifyLicense(
          licenseKey: key,
          deviceId: deviceId,
        ).licenseType!;
      }

      expect(typeFor(10), LicenseType.trial);
      expect(typeFor(30), LicenseType.monthly);
      expect(typeFor(200), LicenseType.yearly);
      expect(typeFor(500), LicenseType.lifetime);
    });
  });

  group('LicenseVerifier.isExpiringSoon', () {
    test('is true only within the next seven days', () {
      expect(
        LicenseVerifier.isExpiringSoon(
          DateTime.now().add(const Duration(days: 3)),
        ),
        isTrue,
      );
      expect(
        LicenseVerifier.isExpiringSoon(
          DateTime.now().add(const Duration(days: 20)),
        ),
        isFalse,
      );
      expect(
        LicenseVerifier.isExpiringSoon(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        isFalse,
      );
    });
  });
}
