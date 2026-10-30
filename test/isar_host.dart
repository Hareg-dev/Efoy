import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';

import 'package:efoy_retail_app/data/models/debt_model.dart';
import 'package:efoy_retail_app/data/models/expense_model.dart';
import 'package:efoy_retail_app/data/models/held_order_model.dart';
import 'package:efoy_retail_app/data/models/license_model.dart';
import 'package:efoy_retail_app/data/models/product_model.dart';
import 'package:efoy_retail_app/data/models/restock_log_model.dart';
import 'package:efoy_retail_app/data/models/sale_model.dart';
import 'package:efoy_retail_app/data/models/user_profile.dart';

/// Shared bootstrap for host-side tests that need a real Isar database.
///
/// Isar ships its native binary inside `isar_flutter_libs`; pointing the
/// generator at it lets `flutter test` open genuine databases on Windows,
/// macOS and Linux with no network access.
List<CollectionSchema<dynamic>> get efoySchemas => [
  ProductModelSchema,
  SaleModelSchema,
  ExpenseModelSchema,
  RestockLogModelSchema,
  LicenseModelSchema,
  UserProfileSchema,
  HeldOrderModelSchema,
  DebtModelSchema,
];

Future<void> initializeIsarHost() async {
  final bundled = findBundledIsarCore();
  Object? bundledError;
  if (bundled != null) {
    try {
      await Isar.initializeIsarCore(libraries: {Abi.current(): bundled});
    } on Object catch (error) {
      bundledError = error;
    }
  }
  if (bundled == null || bundledError != null) {
    try {
      await Isar.initializeIsarCore(download: true);
    } on Object catch (error) {
      throw StateError(
        'Isar core could not be initialized on this host, so the real '
        'database tests cannot run. Bundled binary: '
        '${bundled ?? 'not found'} (${bundledError ?? 'not attempted'}). '
        'Download fallback failed: $error',
      );
    }
  }
}

Future<Isar> openTestIsar({required String directory, required String name}) =>
    Isar.open(efoySchemas, directory: directory, name: name);

/// Path to the Isar dynamic library bundled by `isar_flutter_libs`, or null
/// when this platform has no bundled copy.
String? findBundledIsarCore() {
  if (Platform.isAndroid || Platform.isIOS) return null;

  final env = Platform.environment;
  final sep = Platform.pathSeparator;
  final String pubCache;
  if (env['PUB_CACHE']?.isNotEmpty ?? false) {
    pubCache = env['PUB_CACHE']!;
  } else if (Platform.isWindows && (env['LOCALAPPDATA']?.isNotEmpty ?? false)) {
    pubCache = [env['LOCALAPPDATA']!, 'Pub', 'Cache'].join(sep);
  } else if (env['HOME']?.isNotEmpty ?? false) {
    pubCache = [env['HOME']!, '.pub-cache'].join(sep);
  } else {
    return null;
  }

  final String platformDir;
  final String libName;
  switch (Abi.current()) {
    case Abi.windowsArm64:
    case Abi.windowsX64:
      platformDir = 'windows';
      libName = 'isar.dll';
    case Abi.macosArm64:
    case Abi.macosX64:
      platformDir = 'macos';
      libName = 'libisar.dylib';
    case Abi.linuxX64:
      platformDir = 'linux';
      libName = 'libisar.so';
    default:
      return null;
  }

  final hosted = Directory([pubCache, 'hosted', 'pub.dev'].join(sep));
  if (!hosted.existsSync()) return null;

  try {
    for (final entity in hosted.listSync()) {
      if (entity is! Directory) continue;
      if (!entity.path.split(sep).last.startsWith('isar_flutter_libs-')) {
        continue;
      }
      final platformPath = '${entity.path}$sep$platformDir';
      if (!Directory(platformPath).existsSync()) continue;
      for (final file in Directory(platformPath).listSync()) {
        if (file is File && file.path.split(sep).last == libName) {
          return file.path;
        }
      }
      // Fall back to any dynamic library shipped in the platform folder.
      for (final file in Directory(platformPath).listSync()) {
        if (file is File &&
            (file.path.endsWith('.dll') ||
                file.path.endsWith('.dylib') ||
                file.path.endsWith('.so'))) {
          return file.path;
        }
      }
    }
  } on FileSystemException {
    return null;
  }
  return null;
}
