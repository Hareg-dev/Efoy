import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/local/app_database.dart';

/// Raised when pasted text is not an Efoy backup. The message is safe to show.
class BackupFormatException implements Exception {
  const BackupFormatException([
    this.message = 'That does not look like a valid Efoy backup.',
  ]);

  final String message;

  @override
  String toString() => 'BackupFormatException: $message';
}

/// JSON backup of the whole local database, shared by Settings.
///
/// Backups are deliberately not license-gated: a merchant whose license has
/// expired must still be able to take their data with them.
class DataBackup {
  DataBackup({AppDatabase? database, FlutterSecureStorage? storage})
    : _database = database ?? AppDatabase(),
      _storage = storage ?? const FlutterSecureStorage();

  static const _lastBackupKey = 'efoy_last_backup_at';

  static const _collectionKeys = <String>{
    'products',
    'sales',
    'expenses',
    'restockLogs',
    'licenses',
    'userProfiles',
    'heldOrders',
  };

  final AppDatabase _database;
  final FlutterSecureStorage _storage;

  Future<DateTime?> lastBackupAt() async {
    try {
      final raw = await _storage.read(key: _lastBackupKey);
      return raw == null ? null : DateTime.tryParse(raw);
    } on Exception {
      return null;
    }
  }

  /// Writes an indented JSON snapshot and returns the file.
  Future<File> export({Directory? toDirectory}) async {
    await _database.init();
    final data = await _database.exportToJson();
    final json = const JsonEncoder.withIndent('  ').convert(data);

    final dir = toDirectory ?? await getApplicationDocumentsDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(
      '${dir.path}${Platform.pathSeparator}efoy_backup_$stamp.json',
    );
    await file.writeAsString(json);

    try {
      await _storage.write(
        key: _lastBackupKey,
        value: DateTime.now().toIso8601String(),
      );
    } on Exception {
      // Losing the "last backup" timestamp must not fail the backup itself.
    }
    return file;
  }

  /// Imports [raw] over the current data. Returns the number of records read.
  Future<int> restore(String raw) async {
    final data = parse(raw);
    await _database.init();
    await _database.importFromJson(data);
    return data.values.fold<int>(0, (sum, list) => sum + list.length);
  }

  /// Validates a backup document, ignoring unknown keys.
  ///
  /// Throws [BackupFormatException] when the text is not JSON or holds none of
  /// the known collections.
  static Map<String, List<Map<String, dynamic>>> parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const BackupFormatException();
    }
    if (decoded is! Map) throw const BackupFormatException();

    final data = <String, List<Map<String, dynamic>>>{};
    for (final entry in decoded.entries) {
      final key = entry.key.toString();
      if (!_collectionKeys.contains(key)) continue;
      final value = entry.value;
      if (value is! List) throw const BackupFormatException();
      final items = <Map<String, dynamic>>[];
      for (final item in value) {
        if (item is! Map) throw const BackupFormatException();
        items.add(Map<String, dynamic>.from(item));
      }
      data[key] = items;
    }
    if (data.isEmpty) throw const BackupFormatException();
    return data;
  }
}
