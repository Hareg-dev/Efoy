import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal async key-value contract over platform secure storage.
///
/// An interface (instead of using `FlutterSecureStorage` directly) keeps the
/// licensing service testable and allows graceful recovery when the
/// platform keystore is unavailable.
abstract class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Production implementation backed by the platform keystore / keychain.
class FlutterSecureStore implements SecureStore {
  const FlutterSecureStore();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Simulated keystore failure, used by tests and by the recovery path.
class SecureStoreUnavailableException implements Exception {
  const SecureStoreUnavailableException(this.cause);

  final Object cause;

  @override
  String toString() => 'SecureStoreUnavailableException: $cause';
}

/// In-memory implementation for tests.
class InMemorySecureStore implements SecureStore {
  final Map<String, String> _values = {};

  /// When true, all operations throw [SecureStoreUnavailableException] to
  /// simulate a missing or corrupted keystore.
  bool broken = false;

  void _ensureAvailable() {
    if (broken) {
      throw const SecureStoreUnavailableException('keystore unavailable');
    }
  }

  @override
  Future<String?> read(String key) async {
    _ensureAvailable();
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _ensureAvailable();
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _ensureAvailable();
    _values.remove(key);
  }
}
