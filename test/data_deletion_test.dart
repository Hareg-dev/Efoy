import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:efoy_retail_app/core/backup/data_backup.dart';
import 'package:efoy_retail_app/core/security/password_hasher.dart';
import 'package:efoy_retail_app/core/settings/data_deletion_service.dart';
import 'package:efoy_retail_app/data/models/expense_model.dart';
import 'package:efoy_retail_app/data/models/held_order_model.dart';
import 'package:efoy_retail_app/data/models/license_model.dart';
import 'package:efoy_retail_app/data/models/product_model.dart';
import 'package:efoy_retail_app/data/models/restock_log_model.dart';
import 'package:efoy_retail_app/data/models/sale_model.dart';
import 'package:efoy_retail_app/data/models/user_profile.dart';

import 'isar_host.dart';

const _password = 'shop-keeper-2026';

void main() {
  group('DataDeletionService', () {
    late Directory tempRoot;
    late Isar isar;
    var dbCounter = 0;

    final t0 = DateTime.utc(2026, 3, 1);

    setUpAll(() async {
      await initializeIsarHost();
      tempRoot = Directory.systemTemp.createTempSync('efoy_deletion');
    });

    setUp(() async {
      dbCounter++;
      isar = await openTestIsar(
        directory: tempRoot.path,
        name: 'delete_$dbCounter',
      );
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

    Future<void> seed({String? password = _password}) async {
      await isar.writeTxn(() async {
        await isar.userProfiles.put(
          UserProfile(
            businessName: 'Test Shop',
            passwordHash: password == null ? null : PasswordHasher.hash(password),
          ),
        );
        await isar.licenseModels.put(
          LicenseModel(
            deviceId: 'dev-1',
            licenseKey: 'KEY-1',
            activatedAt: t0,
            expiresAt: t0.add(const Duration(days: 30)),
            licenseType: LicenseType.monthly,
          ),
        );
        final product = ProductModel(
          name: 'Sugar 1kg',
          sellingPrice: 60,
          costPrice: 50,
          currentStock: 10,
          createdAt: t0,
          updatedAt: t0,
        );
        await isar.productModels.put(product);
        await isar.productModels.put(
          ProductModel(
            name: 'Old tin',
            sellingPrice: 10,
            costPrice: 8,
            currentStock: 0,
            createdAt: t0,
            updatedAt: t0,
            isDeleted: true,
          ),
        );

        final line =
            SaleLineItem()
              ..productId = product.id
              ..productName = product.name
              ..quantity = 2
              ..unitPrice = 60
              ..unitCost = 50
              ..lineTotal = 120
              ..lineCost = 100
              ..lineProfit = 20;
        await isar.saleModels.put(
          SaleModel(
            saleDate: t0,
            transactionId: 'TX-001',
            lineItems: [line],
            totalAmount: 120,
            totalCost: 100,
            grossProfit: 20,
            paymentMethod: PaymentMethod.cash,
            createdAt: t0,
          ),
        );
        await isar.expenseModels.put(
          ExpenseModel(
            title: 'Rent',
            amount: 500,
            category: ExpenseCategory.rent,
            expenseDate: t0,
            createdAt: t0,
          ),
        );
        await isar.restockLogModels.put(
          RestockLogModel(
            productId: product.id,
            productName: product.name,
            quantityAdded: 10,
            purchasePrice: 50,
            totalCost: 500,
            stockBefore: 0,
            stockAfter: 10,
            wacBefore: 50,
            wacAfter: 50,
            restockDate: t0,
            createdAt: t0,
          ),
        );
        final held = HeldOrderItem()
          ..productId = product.id
          ..productName = product.name
          ..quantity = 1
          ..unitPrice = 60
          ..unitCost = 50;
        await isar.heldOrderModels.put(
          HeldOrderModel(items: [held], heldAt: t0),
        );
      });
    }

    test('summarize counts every collection it can delete', () async {
      await seed();
      final summary = await DataDeletionService(isar).summarize();

      // Soft-deleted rows still occupy the collection, so the merchant is told
      // the real number of lines that will vanish.
      expect(summary.products, 2);
      expect(summary.sales, 1);
      expect(summary.expenses, 1);
      expect(summary.restockLogs, 1);
      expect(summary.heldOrders, 1);
      expect(summary.licenses, 1);
      expect(summary.profileExists, isTrue);
      expect(summary.businessTotal, 6);
    });

    test('a wrong password deletes nothing', () async {
      await seed();
      final service = DataDeletionService(isar);

      await expectLater(
        service.delete(
          scope: DataDeletionScope.businessRecords,
          password: 'guess',
        ),
        throwsA(isA<DataDeletionDenied>()),
      );

      expect(await isar.productModels.count(), 2);
      expect(await isar.saleModels.count(), 1);
      expect(await isar.expenseModels.count(), 1);
    });

    test('an account without a password cannot delete', () async {
      await seed(password: null);
      final service = DataDeletionService(isar);

      await expectLater(
        service.delete(
          scope: DataDeletionScope.businessRecords,
          password: _password,
        ),
        throwsA(
          isA<DataDeletionDenied>().having(
            (e) => e.message,
            'message',
            contains('No account password'),
          ),
        ),
      );
      expect(await isar.productModels.count(), 2);
    });

    test('business records scope keeps the profile and the license', () async {
      await seed();
      final removed = await DataDeletionService(isar).delete(
        scope: DataDeletionScope.businessRecords,
        password: _password,
      );

      expect(removed.businessTotal, 6);
      expect(await isar.productModels.count(), 0);
      expect(await isar.saleModels.count(), 0);
      expect(await isar.expenseModels.count(), 0);
      expect(await isar.restockLogModels.count(), 0);
      expect(await isar.heldOrderModels.count(), 0);

      expect(await isar.userProfiles.count(), 1);
      expect(await isar.licenseModels.count(), 1);
    });

    test('entire account scope wipes the store and the license too', () async {
      await seed();
      await DataDeletionService(isar).delete(
        scope: DataDeletionScope.entireAccount,
        password: _password,
      );

      expect(await isar.productModels.count(), 0);
      expect(await isar.userProfiles.count(), 0);
      expect(await isar.licenseModels.count(), 0);
    });
  });

  group('DataBackup.parse', () {
    test('accepts a snapshot and drops unknown collections', () {
      final raw = jsonEncode({
        'products': [
          {'name': 'Sugar'},
        ],
        'sales': <String>[],
        'somethingElse': [
          {'x': 1},
        ],
      });

      final data = DataBackup.parse(raw);
      expect(data.keys, unorderedEquals(['products', 'sales']));
      expect(data['products'], hasLength(1));
    });

    test('rejects text that is not JSON', () {
      expect(
        () => DataBackup.parse('not json at all'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects valid JSON that is not a backup', () {
      expect(() => DataBackup.parse('{"hello": 1}'), throwsA(isA<BackupFormatException>()));
      expect(
        () => DataBackup.parse('{"products": {"name": "Sugar"}}'),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => DataBackup.parse('{"products": ["just a string"]}'),
        throwsA(isA<BackupFormatException>()),
      );
      expect(() => DataBackup.parse('[1, 2, 3]'), throwsA(isA<BackupFormatException>()));
    });
  });
}
