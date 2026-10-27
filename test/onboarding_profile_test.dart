import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:efoy_retail_app/core/security/password_hasher.dart';
import 'package:efoy_retail_app/data/models/user_profile.dart';
import 'package:efoy_retail_app/data/repositories/user_repository.dart';

import 'isar_host.dart';

/// The sign-up wizard runs again on every trial, activation and renewal, long
/// after the merchant has named the store and picked a photo. It used to write
/// a brand new row and take everything else with it.
void main() {
  late Directory tempRoot;
  late Isar isar;
  late UserRepository users;
  var dbCounter = 0;

  setUpAll(() async {
    await initializeIsarHost();
    tempRoot = Directory.systemTemp.createTempSync('efoy_onboarding');
  });

  setUp(() async {
    dbCounter++;
    isar = await openTestIsar(
      directory: tempRoot.path,
      name: 'onboarding_$dbCounter',
    );
    users = UserRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  tearDownAll(() {
    try {
      tempRoot.deleteSync(recursive: true);
    } on FileSystemException {
      // The OS reclaims the temp folder.
    }
  });

  test(
    'a new password keeps the names, photo and language already stored',
    () async {
      final createdAt = DateTime.now();
      await users.saveProfile(
        UserProfile(
          businessName: 'Rift Valley Grocery',
          businessNameAm: 'ሱቅ',
          ownerName: 'Hareg Alemu Bekele',
          profilePhotoPath: '/documents/profile.jpg',
          language: 'am',
        )..createdAt = createdAt,
      );

      await users.savePassword(PasswordHasher.hash('4321'));

      final stored = await users.getProfile();
      expect(stored, isNotNull);
      expect(stored!.businessName, 'Rift Valley Grocery');
      expect(stored.businessNameAm, 'ሱቅ');
      expect(stored.ownerName, 'Hareg Alemu Bekele');
      expect(stored.profilePhotoPath, '/documents/profile.jpg');
      expect(stored.language, 'am');
      expect(stored.createdAt, createdAt);
      expect(PasswordHasher.verify('4321', stored.passwordHash!), isTrue);
      expect(stored.lastLogin, isNotNull);
    },
  );

  test('renewing overwrites the old password and nothing else', () async {
    await users.savePassword(PasswordHasher.hash('1111'));
    await users.saveProfile(
      (await users.getProfile())!..businessName = 'Blue Nile Hardware',
    );

    await users.savePassword(PasswordHasher.hash('2222'));

    final stored = await users.getProfile();
    expect(await isar.userProfiles.where().count(), 1);
    expect(stored!.businessName, 'Blue Nile Hardware');
    expect(PasswordHasher.verify('1111', stored.passwordHash!), isFalse);
    expect(PasswordHasher.verify('2222', stored.passwordHash!), isTrue);
  });

  test('the very first run creates the row it needs', () async {
    expect(await users.getProfile(), isNull);

    final created = await users.savePassword(PasswordHasher.hash('9999'));

    expect(created.id, isNot(Isar.autoIncrement));
    final stored = await users.getProfile();
    expect(stored!.businessName, isNull);
    expect(stored.language, 'en');
    expect(PasswordHasher.verify('9999', stored.passwordHash!), isTrue);
  });
}
