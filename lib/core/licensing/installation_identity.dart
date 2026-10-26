import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'secure_store.dart';

/// Service interface reserved for future stronger device binding using
/// platform-protected key pairs (Android Keystore / iOS Secure Enclave).
///
/// Intentionally NOT implemented for the initial release: it exists so the
/// licensing pipeline can adopt hardware-backed binding later without
/// changing call sites. No custom native code is used.
abstract class DeviceKeyService {
  /// Returns the platform-protected public key for this installation, or
  /// null when the platform does not support it.
  Future<List<int>?> getDevicePublicKey();
}

/// Installation identity for license binding.
///
/// The identifier is 128 bits of cryptographically secure randomness
/// (`Random.secure`), generated once and persisted in platform secure
/// storage. It deliberately does NOT rely on IMEI, MAC addresses, processor
/// serials or other unsupported hardware fingerprinting.
///
/// Behavior:
/// - Reinstall / "clear app data": secure storage is wiped, so a NEW
///   installation id is generated. The old license no longer matches; the
///   customer shares the new id and the operator reissues (a monthly code
///   for the remaining period, or a replacement lifetime code after
///   verifying the purchase register).
/// - New phone: same as reinstall.
/// - Secure storage unavailable: [getInstallationId] returns null and the
///   licensing service blocks paid operations until the store recovers;
///   business data is untouched.
class InstallationIdentity {
  InstallationIdentity({SecureStore? secureStore})
    : _secureStore = secureStore ?? const FlutterSecureStore();

  static const String _storageKey = 'efoy_installation_id';

  final SecureStore _secureStore;

  /// Overridden by tests to simulate a different host platform.
  @visibleForTesting
  static TargetPlatform? overrideTargetPlatform;

  /// Reads the installation id, creating one on first use.
  ///
  /// Returns null when secure storage is unavailable (recovery mode).
  Future<String?> getInstallationId() async {
    try {
      final existing = await _secureStore.read(_storageKey);
      if (existing != null && existing.isNotEmpty) {
        return existing;
      }

      final generated = _generateId();
      await _secureStore.write(_storageKey, generated);
      return generated;
    } on SecureStoreUnavailableException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Generates a readable identifier: 4-4-4-4 uppercase hex groups.
  static String _generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join();
    return [
      hex.substring(0, 4),
      hex.substring(4, 8),
      hex.substring(8, 12),
      hex.substring(12, 16),
    ].join('-');
  }

  /// Human-readable device description for support and diagnostics only.
  /// Never used for license binding.
  static Future<InstallationDeviceInfo> getDeviceInfo() async {
    if (kIsWeb) {
      return const InstallationDeviceInfo(
        platform: 'Web',
        model: 'Browser',
        osVersion: '-',
        manufacturer: '-',
      );
    }
    final plugin = DeviceInfoPlugin();
    try {
      switch (overrideTargetPlatform ?? defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await plugin.androidInfo;
          return InstallationDeviceInfo(
            platform: 'Android',
            model: info.model,
            osVersion: info.version.release,
            manufacturer: info.manufacturer,
          );
        case TargetPlatform.iOS:
          final info = await plugin.iosInfo;
          return InstallationDeviceInfo(
            platform: 'iOS',
            model: info.model,
            osVersion: info.systemVersion,
            manufacturer: 'Apple',
          );
        case TargetPlatform.windows:
          final info = await plugin.windowsInfo;
          return InstallationDeviceInfo(
            platform: 'Windows',
            model: info.computerName,
            osVersion: 'build ${info.buildNumber}',
            manufacturer: 'Microsoft',
          );
        default:
          return const InstallationDeviceInfo(
            platform: 'Unknown',
            model: 'Unknown',
            osVersion: 'Unknown',
            manufacturer: 'Unknown',
          );
      }
    } catch (_) {
      return const InstallationDeviceInfo(
        platform: 'Unknown',
        model: 'Unknown',
        osVersion: 'Unknown',
        manufacturer: 'Unknown',
      );
    }
  }
}

/// Display-only device description.
class InstallationDeviceInfo {
  const InstallationDeviceInfo({
    required this.platform,
    required this.model,
    required this.osVersion,
    required this.manufacturer,
  });

  final String platform;
  final String model;
  final String osVersion;
  final String manufacturer;

  String get displayName => '$manufacturer $model';
  String get fullDescription => '$platform $osVersion';
}
