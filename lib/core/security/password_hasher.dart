import 'dart:convert';

import 'package:crypto/crypto.dart';

/// SHA-256 password hashing shared by login, onboarding and profile security.
class PasswordHasher {
  PasswordHasher._();

  static String hash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  static bool verify(String password, String? storedHash) {
    if (storedHash == null || storedHash.isEmpty) return false;
    return hash(password) == storedHash;
  }
}
