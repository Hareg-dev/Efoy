import '../security/device_identity.dart';
import '../security/license_verifier.dart';

/// Helper utilities for testing and development
class TestHelpers {
  TestHelpers._();

  /// Generate test license keys for development
  /// 
  /// Run this in main() during development to get license keys
  static Future<void> generateTestLicenses() async {
    print('\n═══════════════════════════════════════════');
    print('🔑 EFOY TEST LICENSE GENERATOR');
    print('═══════════════════════════════════════════\n');
    
    final deviceId = await DeviceIdentity.getDeviceId();
    final deviceInfo = await DeviceIdentity.getDeviceInfo();
    
    print('📱 Device Information:');
    print('   Platform: ${deviceInfo.platform}');
    print('   Model: ${deviceInfo.model}');
    print('   Manufacturer: ${deviceInfo.manufacturer}');
    print('\n📍 Device ID: $deviceId');
    print('═══════════════════════════════════════════\n');
    
    // Generate 7-day trial
    final trialKey = LicenseVerifier.generateLicenseKey(
      deviceId: deviceId,
      expiryDate: DateTime.now().add(const Duration(days: 7)),
    );
    print('🎫 7-Day Trial License:');
    print('   $trialKey\n');
    
    // Generate 30-day license
    final monthlyKey = LicenseVerifier.generateLicenseKey(
      deviceId: deviceId,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
    );
    print('📅 30-Day Monthly License:');
    print('   $monthlyKey\n');
    
    // Generate 1-year license
    final yearlyKey = LicenseVerifier.generateLicenseKey(
      deviceId: deviceId,
      expiryDate: DateTime.now().add(const Duration(days: 365)),
    );
    print('📆 1-Year License:');
    print('   $yearlyKey\n');
    
    // Generate lifetime license
    final lifetimeKey = LicenseVerifier.generateLicenseKey(
      deviceId: deviceId,
      expiryDate: DateTime.now().add(const Duration(days: 36500)), // 100 years
    );
    print('♾️  Lifetime License:');
    print('   $lifetimeKey\n');
    
    print('═══════════════════════════════════════════');
    print('✅ Copy any key above and paste in the app');
    print('═══════════════════════════════════════════\n');
  }
}
