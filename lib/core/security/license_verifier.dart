import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../../data/models/license_model.dart';

/// Offline License Verification System
/// 
/// Validates license keys without internet connection using
/// cryptographic signature verification.
/// 
/// License Key Format: BASE64(deviceId|expiryDate|signature)
class LicenseVerifier {
  // Secret salt embedded in app (in production, use code obfuscation)
  static const String _secretSalt = 'EFOY_RETAIL_2026_SECRET_SALT_KEY';

  /// Verify license key validity
  /// 
  /// Parameters:
  /// - [licenseKey]: The activation key provided by user
  /// - [deviceId]: Current device hardware fingerprint
  /// 
  /// Returns: Verification result with license details or error
  static LicenseVerificationResult verifyLicense({
    required String licenseKey,
    required String deviceId,
  }) {
    try {
      // Decode base64 license key
      final decoded = _decodeLicenseKey(licenseKey);
      
      if (decoded == null) {
        return LicenseVerificationResult.failed(
          'Invalid license key format',
        );
      }

      final keyDeviceId = decoded['deviceId'] as String;
      final expiryTimestamp = decoded['expiryDate'] as int;
      final signature = decoded['signature'] as String;

      // Verify device ID match
      if (keyDeviceId != deviceId) {
        return LicenseVerificationResult.failed(
          'This license key is not valid for this device',
        );
      }

      // Verify cryptographic signature
      final expectedSignature = _generateSignature(
        deviceId: keyDeviceId,
        expiryTimestamp: expiryTimestamp,
      );

      if (signature != expectedSignature) {
        return LicenseVerificationResult.failed(
          'License key signature verification failed',
        );
      }

      // Check expiration
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);
      final now = DateTime.now();

      if (now.isAfter(expiryDate)) {
        return LicenseVerificationResult.expired(
          expiryDate: expiryDate,
        );
      }

      // Determine license type based on duration
      final licenseType = _determineLicenseType(expiryDate);

      // Success
      return LicenseVerificationResult.success(
        deviceId: keyDeviceId,
        expiryDate: expiryDate,
        licenseType: licenseType,
      );
    } catch (e) {
      return LicenseVerificationResult.failed(
        'License verification error: ${e.toString()}',
      );
    }
  }

  /// Decode license key from base64
  static Map<String, dynamic>? _decodeLicenseKey(String licenseKey) {
    try {
      // Remove any whitespace and dashes
      final cleaned = licenseKey.replaceAll(RegExp(r'[\s-]'), '');
      
      // Decode base64
      final bytes = base64.decode(cleaned);
      final jsonString = utf8.decode(bytes);
      
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Generate cryptographic signature
  static String _generateSignature({
    required String deviceId,
    required int expiryTimestamp,
  }) {
    final payload = '$deviceId|$expiryTimestamp|$_secretSalt';
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Determine license type from expiry date
  static LicenseType _determineLicenseType(DateTime expiryDate) {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;

    if (daysUntilExpiry <= 14) {
      return LicenseType.trial;
    } else if (daysUntilExpiry <= 60) {
      return LicenseType.monthly;
    } else if (daysUntilExpiry <= 400) {
      return LicenseType.yearly;
    } else {
      return LicenseType.lifetime;
    }
  }

  /// Generate a license key (Admin function - would be server-side in production)
  /// 
  /// This is included for testing and MVP admin key generation.
  /// In production, this should only exist on a secure server.
  static String generateLicenseKey({
    required String deviceId,
    required DateTime expiryDate,
  }) {
    final expiryTimestamp = expiryDate.millisecondsSinceEpoch;
    
    final signature = _generateSignature(
      deviceId: deviceId,
      expiryTimestamp: expiryTimestamp,
    );

    final payload = {
      'deviceId': deviceId,
      'expiryDate': expiryTimestamp,
      'signature': signature,
    };

    final jsonString = json.encode(payload);
    final bytes = utf8.encode(jsonString);
    final encoded = base64.encode(bytes);

    // Format with dashes for readability: XXXX-XXXX-XXXX-XXXX
    return _formatLicenseKey(encoded);
  }

  /// Format license key with dashes for readability
  static String _formatLicenseKey(String key) {
    // Insert dash every 4 characters
    final buffer = StringBuffer();
    for (var i = 0; i < key.length; i += 4) {
      if (i > 0) buffer.write('-');
      final end = (i + 4 < key.length) ? i + 4 : key.length;
      buffer.write(key.substring(i, end));
    }
    return buffer.toString();
  }

  /// Check if license is about to expire (within 7 days)
  static bool isExpiringSoon(DateTime expiryDate) {
    final now = DateTime.now();
    final daysRemaining = expiryDate.difference(now).inDays;
    return daysRemaining > 0 && daysRemaining <= 7;
  }
}

/// License verification result
class LicenseVerificationResult {
  final bool isValid;
  final String? errorMessage;
  final String? deviceId;
  final DateTime? expiryDate;
  final LicenseType? licenseType;

  LicenseVerificationResult._({
    required this.isValid,
    this.errorMessage,
    this.deviceId,
    this.expiryDate,
    this.licenseType,
  });

  factory LicenseVerificationResult.success({
    required String deviceId,
    required DateTime expiryDate,
    required LicenseType licenseType,
  }) {
    return LicenseVerificationResult._(
      isValid: true,
      deviceId: deviceId,
      expiryDate: expiryDate,
      licenseType: licenseType,
    );
  }

  factory LicenseVerificationResult.failed(String errorMessage) {
    return LicenseVerificationResult._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }

  factory LicenseVerificationResult.expired({
    required DateTime expiryDate,
  }) {
    return LicenseVerificationResult._(
      isValid: false,
      errorMessage: 'License expired on ${expiryDate.toLocal()}',
      expiryDate: expiryDate,
    );
  }
}
