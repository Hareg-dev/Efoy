import 'package:flutter/foundation.dart';
import '../security/device_identity.dart';
import '../security/license_verifier.dart';

/// Helper utilities for testing and development
class TestHelpers {
  TestHelpers._();

  /// Generate test license keys for development
  /// 
  /// Run this in main() during development to get license keys
  static Future<void> generateTestLicenses() async {
    debugPrint('\n═══════════════════════════════════════════');
    debugPrint('🔑 EFOY TEST LICENSE GENERATOR');
    debugPrint('═══════════════════════════════════════════\n');
    
    final deviceId = await DeviceIdentity.getDeviceId();
    final deviceInfo = await DeviceIdentity.getDeviceInfo();
    
    debugPrint('📱 Device Information:');
    debugPrint('   Platform: ${deviceInfo.platform}');
    debugPrint('   Model: ${deviceInfo.model}');
    debugPrint('   Manufacturer: ${deviceInfo.manufacturer}');
    debugPrint('\n📍 Device ID: $deviceId');
    debugPrint('═══════════════════════════════════════════\n');
    
    // Generate 7-day trial
    final trialKey = LicenseVerifier.generateLicenseKey(
      deviceId: deviceId,
      expiryDate: DateTime.now().add(const Duration(days: 7)),
    );
    debugPrint('🎫 7-Day Trial License:');
    debugPrint('   $trialKey\n');
    
    // Generate 30-day license
    final monthlyKey = LicenseVerifier.generateLicenseKey(
      deviceId: deviceId,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
    );
    debugPrint('📅 30-Day Monthly License:');
    debugPrint('   $monthlyKey\n');
    
    // Generate 1-year license
    final yearlyKey = LicenseVerifier.generateLicenseKey(
      deviceId: deviceId,
      expiryDate: DateTime.now().add(const Duration(days: 365)),
    );
    debugPrint('📆 1-Year License:');
    debugPrint('   $yearlyKey\n');
    
    // Generate lifetime license
    final lifetimeKey = LicenseVerifier.generateLicenseKey(
      deviceId: deviceId,
      expiryDate: DateTime.now().add(const Duration(days: 36500)), // 100 years
    );
    debugPrint('♾️  Lifetime License:');
    debugPrint('   $lifetimeKey\n');
    
    debugPrint('═══════════════════════════════════════════');
    debugPrint('✅ Copy any key above and paste in the app');
    debugPrint('═══════════════════════════════════════════\n');
  }
}
