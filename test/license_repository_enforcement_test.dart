import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:efoy_retail_app/core/licensing/license_access_state.dart';
import 'package:efoy_retail_app/core/licensing/license_gate.dart';
import 'package:efoy_retail_app/core/licensing/license_service.dart';
import 'package:efoy_retail_app/core/licensing/license_store.dart';
import 'package:efoy_retail_app/data/local/app_database.dart';
import 'package:efoy_retail_app/data/models/expense_model.dart';
import 'package:efoy_retail_app/data/models/held_order_model.dart';
import 'package:efoy_retail_app/data/models/license_model.dart';
import 'package:efoy_retail_app/data/models/product_model.dart';
import 'package:efoy_retail_app/data/models/restock_log_model.dart';
import 'package:efoy_retail_app/data/models/sale_model.dart';
import 'package:efoy_retail_app/data/models/user_profile.dart';
import 'package:efoy_retail_app/data/repositories/expense_repository.dart';
import 'package:efoy_retail_app/data/repositories/held_order_repository.dart';
import 'package:efoy_retail_app/data/repositories/product_repository.dart';
import 'package:efoy_retail_app/data/repositories/sale_repository.dart';

import 'license_test_utils.dart';

/// Host-side integration tests for license enforcement over the real Isar
/// database. These exercise the repositories exactly as production uses
/// them: every mutation goes through [LicenseGate.ensureAllowed] before the
/// write transaction, while reads, reports and the export/backup path are
/// never gated — so an expired license can never corrupt or hide data.
void main() {
  const allowedGate = AlwaysAllowedLicenseGate();
  const blockedGate = AlwaysBlockedLicenseGate();

  late Isar isar;
  late Directory tempRoot;
  late String dbName;
  var dbCounter = 0;

  final t0 = DateTime.utc(2026, 1, 10);

  final schemas = [
    ProductModelSchema,
    SaleModelSchema,
    ExpenseModelSchema,
    RestockLogModelSchema,
    LicenseModelSchema,
    UserProfileSchema,
    HeldOrderModelSchema,
  ];

  Future<Isar> open(String name) =>
      Isar.open(schemas, directory: tempRoot.path, name: name);

  setUpAll(() async {
    final bundled = _findBundledIsarCore();
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
        fail(
          'Isar core could not be initialized on this host, so the '
          'repository enforcement tests cannot run. Bundled binary: '
          '${bundled ?? 'not found'} '
          '(${bundledError ?? 'not attempted'}). '
          'Download fallback failed: $error',
        );
      }
    }
    tempRoot = Directory.systemTemp.createTempSync('efoy_license_enforcement');
  });

  setUp(() async {
    dbCounter++;
    dbName = 'efoy_enforcement_$dbCounter';
    isar = await open(dbName);
  });

  tearDown(() async {
    if (isar.isOpen) {
      await isar.close(deleteFromDisk: true);
    }
  });

  tearDownAll(() {
    try {
      tempRoot.deleteSync(recursive: true);
    } on FileSystemException {
      // Best effort cleanup of the temporary database root.
    }
  });

  ProductModel product(String name) => ProductModel(
    name: name,
    sellingPrice: 100,
    costPrice: 60,
    currentStock: 50,
    lowStockThreshold: 10,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  ExpenseModel expense(String title, {double amount = 500}) => ExpenseModel(
    title: title,
    amount: amount,
    category: ExpenseCategory.rent,
    expenseDate: DateTime.utc(2026, 1, 5),
    createdAt: DateTime.utc(2026, 1, 5),
  );

  SaleModel sale(ProductModel item, {int quantity = 2}) {
    final line = SaleLineItem()
      ..productId = item.id
      ..productName = item.name
      ..quantity = quantity
      ..unitPrice = item.sellingPrice
      ..unitCost = item.costPrice
      ..lineTotal = quantity * item.sellingPrice
      ..lineCost = quantity * item.costPrice
      ..lineProfit = quantity * (item.sellingPrice - item.costPrice);
    return SaleModel(
      saleDate: DateTime.utc(2026, 1, 5),
      transactionId: 'TX-001',
      lineItems: [line],
      totalAmount: line.lineTotal,
      totalCost: line.lineCost,
      grossProfit: line.lineTotal - line.lineCost,
      paymentMethod: PaymentMethod.cash,
      createdAt: DateTime.utc(2026, 1, 5),
    );
  }

  HeldOrderModel heldOrder(ProductModel item) => HeldOrderModel(
    items: [
      HeldOrderItem()
        ..productId = item.id
        ..productName = item.name
        ..quantity = 1
        ..unitPrice = item.sellingPrice
        ..unitCost = item.costPrice
        ..availableStock = item.currentStock,
    ],
    heldAt: DateTime.utc(2026, 1, 5),
    note: 'held for tests',
  );

  group('Blocked license: every write path is refused at the repository', () {
    test('products: mutations refused, reads and streams served', () async {
      final repo = ProductRepository(isar, allowedGate);
      final oil = await repo.create(product('Cooking Oil'));

      final blocked = ProductRepository(isar, blockedGate);
      await expectBlocked(
        blocked.create(product('Sugar')),
        LicensedOperation.manageProducts,
      );
      await expectBlocked(
        blocked.update(oil..sellingPrice = 120),
        LicensedOperation.manageProducts,
      );
      await expectBlocked(
        blocked.delete(oil.id),
        LicensedOperation.manageProducts,
      );
      await expectBlocked(
        blocked.restock(productId: oil.id, quantityAdded: 10, costPerUnit: 55),
        LicensedOperation.restock,
      );

      final all = await blocked.getAll();
      expect(all, hasLength(1));
      expect(all.first.name, 'Cooking Oil');
      expect(await blocked.getLowStockProducts(), isEmpty);
      expect((await blocked.getById(oil.id))!.currentStock, 50);
      expect(await blocked.watchAll().first, hasLength(1));
    });

    test('sales: mutations refused, history and totals served', () async {
      final products = ProductRepository(isar, allowedGate);
      final sales = SaleRepository(isar, allowedGate);
      final oil = await products.create(product('Cooking Oil'));
      final recorded = await sales.create(sale(oil));

      final blocked = SaleRepository(isar, blockedGate);
      await expectBlocked(
        blocked.create(sale(oil)),
        LicensedOperation.recordSale,
      );
      await expectBlocked(
        blocked.createWithStockUpdate(sale(oil, quantity: 5)),
        LicensedOperation.recordSale,
      );
      await expectBlocked(
        blocked.voidSale(recorded.id),
        LicensedOperation.voidSale,
      );

      final history = await blocked.getAll();
      expect(history, hasLength(1));
      expect(history.first.transactionId, 'TX-001');
      expect(await blocked.watchAll().first, hasLength(1));

      final totals = await blocked.getTotalsByPeriod(
        DateTime.utc(2026, 1, 1),
        DateTime.utc(2026, 1, 8),
      );
      expect(totals.revenue, 200);
      expect(totals.cost, 120);
      expect(totals.grossProfit, 80);
      expect(totals.count, 1);
    });

    test('expenses: mutations refused, reads and totals served', () async {
      final repo = ExpenseRepository(isar, allowedGate);
      final rent = await repo.create(expense('January rent'));

      final blocked = ExpenseRepository(isar, blockedGate);
      await expectBlocked(
        blocked.create(expense('New')),
        LicensedOperation.manageExpenses,
      );
      await expectBlocked(
        blocked.update(rent..amount = 600),
        LicensedOperation.manageExpenses,
      );
      await expectBlocked(
        blocked.delete(rent.id),
        LicensedOperation.manageExpenses,
      );

      expect(await blocked.getAll(), hasLength(1));
      expect(await blocked.getByCategory(ExpenseCategory.rent), hasLength(1));
      final totals = await blocked.getTotalsByPeriod(
        DateTime.utc(2026, 1, 1),
        DateTime.utc(2026, 1, 8),
      );
      expect(totals.operatingTotal, 500);
      expect(totals.capitalTotal, 0);
    });

    test('held orders: mutations refused, reads and streams served', () async {
      final products = ProductRepository(isar, allowedGate);
      final oil = await products.create(product('Cooking Oil'));
      final repo = HeldOrderRepository(isar, allowedGate);
      final held = await repo.save(heldOrder(oil));

      final blocked = HeldOrderRepository(isar, blockedGate);
      await expectBlocked(
        blocked.save(heldOrder(oil)),
        LicensedOperation.manageHeldOrders,
      );
      await expectBlocked(
        blocked.delete(held.id),
        LicensedOperation.manageHeldOrders,
      );
      expect(await blocked.getAll(), hasLength(1));
      expect(await blocked.watchAll().first, hasLength(1));
    });
  });

  group('Gate ordering', () {
    test('a refused operation leaves no partial writes behind', () async {
      final products = ProductRepository(isar, allowedGate);
      final sales = SaleRepository(isar, allowedGate);
      final expenses = ExpenseRepository(isar, allowedGate);
      final oil = await products.create(product('Cooking Oil'));
      await sales.create(sale(oil));
      await expenses.create(expense('January rent'));

      final blockedProducts = ProductRepository(isar, blockedGate);
      final blockedSales = SaleRepository(isar, blockedGate);

      await expectBlocked(
        blockedProducts.restock(
          productId: oil.id,
          quantityAdded: 20,
          costPerUnit: 65,
        ),
        LicensedOperation.restock,
      );
      await expectBlocked(
        blockedSales.createWithStockUpdate(sale(oil, quantity: 3)),
        LicensedOperation.recordSale,
      );

      // Nothing changed: no extra sale, no CapEx expense, no restock log,
      // stock and WAC untouched.
      expect(await isar.saleModels.count(), 1);
      expect(await isar.expenseModels.count(), 1);
      expect(await isar.restockLogModels.count(), 0);
      final stored = await isar.productModels.get(oil.id);
      expect(stored!.currentStock, 50);
      expect(stored.costPrice, 60);
    });
  });

  group('End to end with the real license store', () {
    test('activated license survives a database close/reopen', () async {
      final harness = await LicenseHarness.create(now: t0);
      final service = LicenseService(
        licenseStore: IsarLicenseStore(isar),
        secureStore: harness.secureStore,
        verifier: harness.verifier,
        clock: harness.clock.call,
      );

      final result = await service.activate(await harness.monthlyCode());
      expect(result.success, isTrue);
      expect(result.state!.status, LicenseAccessStatus.licensed);

      // Simulate an app restart: close and reopen the same database file.
      await isar.close(deleteFromDisk: false);
      isar = await open(dbName);

      final restarted = LicenseService(
        licenseStore: IsarLicenseStore(isar),
        secureStore: harness.secureStore,
        verifier: harness.verifier,
        clock: harness.clock.call,
      );
      final state = await restarted.currentAccess();
      expect(state.status, LicenseAccessStatus.licensed);
      expect(state.licenseId, 'EFY-TEST-0001');
      expect(state.installationId, await harness.installationId());

      final active = await isar.licenseModels
          .filter()
          .isActiveEqualTo(true)
          .findAll();
      expect(active, hasLength(1));
      expect(active.first.licenseId, 'EFY-TEST-0001');
    });

    test(
      'renewal deactivates the previous license but keeps its record',
      () async {
        final harness = await LicenseHarness.create(now: t0);
        final service = LicenseService(
          licenseStore: IsarLicenseStore(isar),
          secureStore: harness.secureStore,
          verifier: harness.verifier,
          clock: harness.clock.call,
        );
        await service.activate(await harness.monthlyCode());

        harness.clock.now = t0.add(const Duration(days: 31));
        final renewed = await service.activate(
          await harness.monthlyCode(licenseId: 'EFY-TEST-0002'),
        );
        expect(renewed.state!.status, LicenseAccessStatus.licensed);

        final active = await isar.licenseModels
            .filter()
            .isActiveEqualTo(true)
            .findAll();
        expect(active, hasLength(1));
        expect(active.first.licenseId, 'EFY-TEST-0002');

        // Renewal history is preserved for support and audit.
        expect(await isar.licenseModels.count(), 2);
      },
    );

    test(
      'expiry keeps all business data readable and blocks only writes',
      () async {
        final harness = await LicenseHarness.create(now: t0);
        final service = LicenseService(
          licenseStore: IsarLicenseStore(isar),
          secureStore: harness.secureStore,
          verifier: harness.verifier,
          clock: harness.clock.call,
        );
        // Trial starts on first use.
        expect(
          (await service.currentAccess()).status,
          LicenseAccessStatus.trial,
        );

        // All repositories are wired to the service gate from the start.
        final gate = service.asGate();
        final products = ProductRepository(isar, gate);
        final sales = SaleRepository(isar, gate);
        final expenses = ExpenseRepository(isar, gate);

        final oil = await products.create(product('Cooking Oil'));
        await sales.create(sale(oil));
        await expenses.create(expense('January rent'));

        // Upgrade to a monthly license mid-trial.
        final activation = await service.activate(await harness.monthlyCode());
        expect(activation.state!.status, LicenseAccessStatus.licensed);

        // A month passes...
        harness.clock.now = t0.add(const Duration(days: 31));
        expect(
          (await service.currentAccess()).status,
          LicenseAccessStatus.expired,
        );

        // Every mutation is now refused...
        await expectBlocked(
          products.create(product('Sugar')),
          LicensedOperation.manageProducts,
        );
        await expectBlocked(
          sales.create(sale(oil)),
          LicensedOperation.recordSale,
        );
        await expectBlocked(
          expenses.create(expense('February rent')),
          LicensedOperation.manageExpenses,
        );
        await expectBlocked(
          sales.voidSale((await sales.getAll()).first.id),
          LicensedOperation.voidSale,
        );

        // ...while every read path still works with correct numbers.
        expect((await products.getAll()).map((p) => p.name), ['Cooking Oil']);
        expect(await sales.getAll(), hasLength(1));
        expect(await expenses.getAll(), hasLength(1));
        final totals = await sales.getTotalsByPeriod(
          DateTime.utc(2026, 1, 1),
          DateTime.utc(2026, 2, 1),
        );
        expect(totals.revenue, 200);
        expect(totals.grossProfit, 80);

        // Expiry deleted or corrupted nothing.
        expect(await isar.productModels.count(), 1);
        expect(await isar.saleModels.count(), 1);
        expect(await isar.expenseModels.count(), 1);
        expect(await isar.licenseModels.count(), 1);
      },
    );
  });

  group('Export and backup after expiry', () {
    test(
      'the real export path stays available with an expired license',
      () async {
        final exportDir = Directory(
          '${tempRoot.path}${Platform.pathSeparator}export_$dbCounter',
        );
        exportDir.createSync(recursive: true);
        final db = await AppDatabase().init(
          directory: exportDir.path,
          name: 'efoy_export_test',
        );
        addTearDown(AppDatabase().close);

        final products = ProductRepository(db, allowedGate);
        final oil = await products.create(product('Cooking Oil'));
        final sales = SaleRepository(db, allowedGate);
        await sales.create(sale(oil));
        final expenses = ExpenseRepository(db, allowedGate);
        await expenses.create(expense('January rent'));

        final harness = await LicenseHarness.create(now: t0);
        final service = LicenseService(
          licenseStore: IsarLicenseStore(db),
          secureStore: harness.secureStore,
          verifier: harness.verifier,
          clock: harness.clock.call,
        );
        await service.activate(await harness.monthlyCode());

        harness.clock.now = t0.add(const Duration(days: 31));
        expect(
          (await service.currentAccess()).status,
          LicenseAccessStatus.expired,
        );

        // The production export method never consults licensing.
        final export = await AppDatabase().exportToJson();
        expect(export['products'], hasLength(1));
        expect(export['sales'], hasLength(1));
        expect(export['expenses'], hasLength(1));
        expect(export['licenses'], hasLength(1));
        expect(export['sales']!.first['transactionId'], 'TX-001');
        expect(export['expenses']!.first['title'], 'January rent');

        // Writes remain blocked through the same service.
        final blocked = ProductRepository(db, service.asGate());
        await expectBlocked(
          blocked.create(product('Sugar')),
          LicensedOperation.manageProducts,
        );
      },
    );
  });
}

/// Locates the Isar native library bundled by `isar_flutter_libs` in the
/// local pub cache so host-side tests need no network download.
String? _findBundledIsarCore() {
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

  String platformDir;
  String libName;
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
