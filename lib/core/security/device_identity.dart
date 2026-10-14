import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device Identity Service
/// 
/// Generates a persistent, hardware-bound device fingerprint
/// used for offline license activation and device binding.
class DeviceIdentity {
  static const String _storageKey = 'efoy_device_id';
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const _storage = FlutterSecureStorage();

  /// Get or generate device ID
  /// 
  /// Returns a persistent device identifier that survives app reinstalls
  /// on the same physical device.
  static Future<String> getDeviceId() async {
    // Try to retrieve existing device ID from secure storage
    String? existingId = await _storage.read(key: _storageKey);
    
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    // Generate new device ID based on hardware parameters
    final deviceId = await _generateDeviceId();
    
    // Store for future use
    await _storage.write(key: _storageKey, value: deviceId);
    
    return deviceId;
  }

  /// Generate device ID from hardware parameters
  static Future<String> _generateDeviceId() async {
    try {
      if (Platform.isAndroid) {
        return await _generateAndroidId();
      } else if (Platform.isIOS) {
        return await _generateIOSId();
      } else if (Platform.isWindows) {
        return await _generateWindowsId();
      } else {
        // Fallback for other platforms
        return _generateFallbackId();
      }
    } catch (e) {
      // If hardware info fails, generate fallback
      return _generateFallbackId();
    }
  }

  /// Generate Android device ID
  static Future<String> _generateAndroidId() async {
    final androidInfo = await _deviceInfo.androidInfo;
    
    // Combine multiple hardware identifiers for uniqueness
    final components = [
      androidInfo.id, // Android ID
      androidInfo.device, // Device model
      androidInfo.board, // Board name
      androidInfo.hardware, // Hardware name
      androidInfo.model, // Model name
      androidInfo.product, // Product name
    ].join('|');

    return _hashComponents(components);
  }

  /// Generate iOS device ID
  static Future<String> _generateIOSId() async {
    final iosInfo = await _deviceInfo.iosInfo;
    
    final components = [
      iosInfo.identifierForVendor ?? '', // Vendor identifier
      iosInfo.model, // Device model
      iosInfo.systemName, // OS name
      iosInfo.utsname.machine, // Machine identifier
    ].join('|');

    return _hashComponents(components);
  }

  /// Generate Windows device ID
  static Future<String> _generateWindowsId() async {
    final windowsInfo = await _deviceInfo.windowsInfo;
    
    final components = [
      windowsInfo.deviceId, // Windows device ID
      windowsInfo.computerName, // Computer name
      windowsInfo.systemMemoryInMegabytes.toString(), // RAM
    ].join('|');

    return _hashComponents(components);
  }

  /// Generate fallback ID using timestamp
  static String _generateFallbackId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return _hashComponents('EFOY_FALLBACK_$timestamp');
  }

  /// Hash components using SHA-256
  static String _hashComponents(String components) {
    final bytes = utf8.encode(components);
    final digest = sha256.convert(bytes);
    
    // Return first 16 characters of hex digest (64-bit hash)
    // Format: XXXX-XXXX-XXXX-XXXX
    final hash = digest.toString().substring(0, 16).toUpperCase();
    return '${hash.substring(0, 4)}-${hash.substring(4, 8)}-${hash.substring(8, 12)}-${hash.substring(12, 16)}';
  }

  /// Get device information for display
  static Future<DeviceInfo> getDeviceInfo() async {
    final deviceId = await getDeviceId();

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return DeviceInfo(
        deviceId: deviceId,
        platform: 'Android',
        model: androidInfo.model,
        osVersion: androidInfo.version.release,
        manufacturer: androidInfo.manufacturer,
      );
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return DeviceInfo(
        deviceId: deviceId,
        platform: 'iOS',
        model: iosInfo.model,
        osVersion: iosInfo.systemVersion,
        manufacturer: 'Apple',
      );
    } else if (Platform.isWindows) {
      final windowsInfo = await _deviceInfo.windowsInfo;
      return DeviceInfo(
        deviceId: deviceId,
        platform: 'Windows',
        model: windowsInfo.computerName,
        osVersion: windowsInfo.buildNumber.toString(),
        manufacturer: 'Microsoft',
      );
    }

    return DeviceInfo(
      deviceId: deviceId,
      platform: 'Unknown',
      model: 'Unknown',
      osVersion: 'Unknown',
      manufacturer: 'Unknown',
    );
  }

  /// Reset device ID (for testing purposes only)
  static Future<void> resetDeviceId() async {
    await _storage.delete(key: _storageKey);
  }
}

/// Device information data class
class DeviceInfo {
  final String deviceId;
  final String platform;
  final String model;
  final String osVersion;
  final String manufacturer;

  DeviceInfo({
    required this.deviceId,
    required this.platform,
    required this.model,
    required this.osVersion,
    required this.manufacturer,
  });

  String get displayName => '$manufacturer $model';
  String get fullDescription => '$platform $osVersion';
}
