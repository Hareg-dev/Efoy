import 'package:isar/isar.dart';

import '../models/license_model.dart';
import '../models/user_profile.dart';

class UserRepository {
  UserRepository(this._isar);

  final Isar _isar;

  Future<UserProfile?> getProfile() {
    return _isar.userProfiles.where().findFirst();
  }

  /// Emits the current profile and re-emits whenever it changes.
  Stream<UserProfile?> watchProfile() async* {
    yield await getProfile();
    await for (final _ in _isar.userProfiles.watchLazy()) {
      yield await getProfile();
    }
  }

  Future<UserProfile> saveProfile(UserProfile profile) async {
    profile.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      profile.id = await _isar.userProfiles.put(profile);
    });
    return profile;
  }

  Future<LicenseModel?> getActiveLicense() {
    return _isar.licenseModels
        .filter()
        .isActiveEqualTo(true)
        .findFirst();
  }

  /// Most recently activated license, active or not.
  Future<LicenseModel?> getLicense() {
    return _isar.licenseModels
        .where()
        .sortByActivatedAtDesc()
        .findFirst();
  }

  /// Persist a verified license and deactivate any previous active license
  /// atomically.
  Future<LicenseModel> activateLicense(LicenseModel license) async {
    await _isar.writeTxn(() async {
      final active = await _isar.licenseModels
          .filter()
          .isActiveEqualTo(true)
          .findAll();
      for (final previous in active) {
        if (previous.id == license.id) continue;
        previous.isActive = false;
        await _isar.licenseModels.put(previous);
      }
      license.id = await _isar.licenseModels.put(license);
    });
    return license;
  }
}
