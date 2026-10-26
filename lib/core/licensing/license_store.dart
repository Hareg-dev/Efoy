import 'dart:async';

import 'package:efoy_licensing/efoy_licensing.dart';
import 'package:isar/isar.dart';

import '../../data/models/license_model.dart';

/// Persistence-agnostic record of an activated license. Stored in Isar by
/// [IsarLicenseStore]; kept as a plain class so the licensing service can
/// be tested without a database.
class StoredLicenseRecord {
  const StoredLicenseRecord({
    required this.installationId,
    required this.activationCode,
    required this.activatedAt,
    required this.expiresAt,
    required this.plan,
    this.licenseId,
    this.issuedAt,
  });

  /// Installation identifier the license is bound to.
  final String installationId;

  /// Full activation code as entered (whitespace-stripped), kept so the
  /// license can be re-verified offline at any time.
  final String activationCode;

  /// Issuer-minted unique id.
  final String? licenseId;

  /// When the issuer created the license (payload `iat`).
  final DateTime? issuedAt;

  /// When the customer activated it on this device.
  final DateTime activatedAt;

  /// End of the validity window (lifetime sentinel for lifetime plans).
  final DateTime expiresAt;

  final LicensePlan plan;
}

/// Persistence contract for activated licenses.
abstract class LicenseStore {
  /// The most recently activated license, active or expired.
  Future<StoredLicenseRecord?> latest();

  /// Saves a newly activated license and deactivates any previous one
  /// atomically.
  Future<void> save(StoredLicenseRecord record);

  /// Emits whenever persisted licenses change.
  Stream<void> watchChanges();
}

/// In-memory store for tests.
class InMemoryLicenseStore implements LicenseStore {
  final _records = <StoredLicenseRecord>[];
  final _changes = StreamController<void>.broadcast();

  @override
  Future<StoredLicenseRecord?> latest() async =>
      _records.isEmpty ? null : _records.last;

  @override
  Future<void> save(StoredLicenseRecord record) async {
    _records.add(record);
    _changes.add(null);
  }

  @override
  Stream<void> watchChanges() => _changes.stream;

  void dispose() => _changes.close();
}

/// Isar-backed store mapping [LicenseModel] to [StoredLicenseRecord].
///
/// Schema notes: the legacy `deviceId` field stores the installation
/// identifier, and the legacy `licenseType` enum stores the plan name
/// (`trial` / `monthly` / `lifetime`; legacy `yearly` records map back to a
/// monthly plan with their stored expiry).
class IsarLicenseStore implements LicenseStore {
  const IsarLicenseStore(this._isar);

  final Isar _isar;

  @override
  Future<StoredLicenseRecord?> latest() async {
    final model = await _isar.licenseModels
        .where()
        .sortByActivatedAtDesc()
        .findFirst();
    if (model == null) return null;
    return _toRecord(model);
  }

  @override
  Future<void> save(StoredLicenseRecord record) async {
    final model = LicenseModel(
      deviceId: record.installationId,
      licenseKey: record.activationCode,
      licenseId: record.licenseId,
      issuedAt: record.issuedAt,
      activatedAt: record.activatedAt,
      expiresAt: record.expiresAt,
      licenseType: _planToType(record.plan),
      isActive: true,
      isExpired: false,
    );

    await _isar.writeTxn(() async {
      // Deactivate any previously active licenses atomically.
      final active = await _isar.licenseModels
          .filter()
          .isActiveEqualTo(true)
          .findAll();
      for (final previous in active) {
        previous.isActive = false;
        await _isar.licenseModels.put(previous);
      }
      model.id = await _isar.licenseModels.put(model);
    });
  }

  @override
  Stream<void> watchChanges() => _isar.licenseModels.watchLazy();

  static StoredLicenseRecord _toRecord(LicenseModel model) {
    return StoredLicenseRecord(
      installationId: model.deviceId,
      activationCode: model.licenseKey,
      licenseId: model.licenseId,
      issuedAt: model.issuedAt,
      activatedAt: model.activatedAt,
      expiresAt: model.expiresAt,
      plan: _typeToPlan(model.licenseType),
    );
  }

  static LicenseType _planToType(LicensePlan plan) =>
      LicenseType.values.byName(plan.wireName);

  static LicensePlan _typeToPlan(LicenseType type) {
    switch (type) {
      case LicenseType.trial:
        return LicensePlan.trial;
      case LicenseType.monthly:
      case LicenseType.yearly:
        // Legacy records: honor their stored expiry under the monthly plan.
        return LicensePlan.monthly;
      case LicenseType.lifetime:
        return LicensePlan.lifetime;
    }
  }
}
