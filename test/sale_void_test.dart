import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:efoy_retail_app/core/licensing/license_gate.dart';
import 'package:efoy_retail_app/data/models/debt_model.dart';
import 'package:efoy_retail_app/data/models/product_model.dart';
import 'package:efoy_retail_app/data/models/sale_model.dart';
import 'package:efoy_retail_app/data/repositories/sale_repository.dart';

import 'isar_host.dart';

/// Undoing a sale rung up by mistake.
///
/// Marking the invoice void only fixes profit; the shop also has to get its
/// stock back and stop chasing a balance for an invoice that never happened.
/// All three happen in one transaction, and undoing twice changes nothing.
void main() {
  const allowedGate = AlwaysAllowedLicenseGate();
  const blockedGate = AlwaysBlockedLicenseGate();

  late Directory tempRoot;
  late Isar isar;
  late SaleRepository sales;
  var dbCounter = 0;

  setUpAll(() async {
    await initializeIsarHost();
    tempRoot = Directory.systemTemp.createTempSync('efoy_void');
  });

  setUp(() async {
    dbCounter++;
    isar = await openTestIsar(
      directory: tempRoot.path,
      name: 'void_$dbCounter',
    );
    sales = SaleRepository(isar, allowedGate);
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

  Future<ProductModel> product({
    int stock = 10,
    String name = 'Sugar 1kg',
  }) async {
    final now = DateTime(2026, 10, 20);
    final model = ProductModel(
      name: name,
      sellingPrice: 260,
      costPrice: 200,
      currentStock: stock,
      lowStockThreshold: 2,
      createdAt: now,
      updatedAt: now,
    );
    await isar.writeTxn(() async {
      model.id = await isar.productModels.put(model);
    });
    return model;
  }

  SaleLineItem line(ProductModel product, int quantity) {
    return SaleLineItem()
      ..productId = product.id
      ..productName = product.name
      ..quantity = quantity
      ..unitPrice = 260
      ..unitCost = 200
      ..lineTotal = quantity * 260
      ..lineCost = quantity * 200
      ..lineProfit = quantity * 60;
  }

  Future<SaleModel> sell(ProductModel product, {int quantity = 3}) {
    final now = DateTime.now();
    final total = quantity * 260.0;
    return sales.createWithStockUpdate(
      SaleModel(
        saleDate: now,
        transactionId: 'EFY-$dbCounter-${product.id}',
        lineItems: [line(product, quantity)],
        totalAmount: total,
        totalCost: quantity * 200.0,
        grossProfit: quantity * 60.0,
        paymentMethod: PaymentMethod.cash,
        amountReceived: total,
        createdAt: now,
      ),
    );
  }

  test('undoing puts the stock back and clears the balance', () async {
    final sugar = await product();
    final sale = await sell(sugar);

    expect((await isar.productModels.get(sugar.id))!.currentStock, 7);

    // A credit sale opens a receivable that must disappear with the sale.
    await isar.writeTxn(() async {
      await isar.debtModels.put(
        DebtModel(
          saleTransactionId: sale.transactionId,
          customerName: 'Wondimu',
          totalAmount: sale.totalAmount,
          paidAmount: 300,
          openedAt: sale.saleDate,
        ),
      );
    });
    expect(await isar.debtModels.count(), 1);

    await sales.voidSale(sale.id);

    expect((await isar.productModels.get(sugar.id))!.currentStock, 10);
    expect(await isar.debtModels.count(), 0);

    final stored = await isar.saleModels.get(sale.id);
    expect(stored!.isVoided, isTrue);
    expect(stored.voidedAt, isNotNull);
  });

  test('the voided sale leaves profit and revenue', () async {
    final sugar = await product();
    final sale = await sell(sugar);

    final before = await sales.getTotalsByPeriod(
      DateTime.now().subtract(const Duration(days: 1)),
      DateTime.now().add(const Duration(days: 1)),
    );
    expect(before.revenue, 780);
    expect(before.count, 1);

    await sales.voidSale(sale.id);

    final after = await sales.getTotalsByPeriod(
      DateTime.now().subtract(const Duration(days: 1)),
      DateTime.now().add(const Duration(days: 1)),
    );
    expect(after.revenue, 0);
    expect(after.grossProfit, 0);
    expect(after.count, 0);
    expect(await sales.getAll(), isEmpty);
  });

  test('undoing twice does not inflate the stock', () async {
    final sugar = await product();
    final sale = await sell(sugar);

    await sales.voidSale(sale.id);
    await sales.voidSale(sale.id);

    expect((await isar.productModels.get(sugar.id))!.currentStock, 10);
  });

  test('only the undone sale gives its own units back', () async {
    final sugar = await product(stock: 20);
    final oil = await product(stock: 20, name: 'Cooking oil');

    final sugarSale = await sell(sugar);
    await sell(oil);

    await sales.voidSale(sugarSale.id);

    expect((await isar.productModels.get(sugar.id))!.currentStock, 20);
    expect(
      (await isar.productModels.get(oil.id))!.currentStock,
      17,
      reason: 'the sale that was kept still owns its units',
    );
  });

  test('an expired licence cannot undo a sale', () async {
    final sugar = await product();
    final sale = await sell(sugar);
    final blocked = SaleRepository(isar, blockedGate);

    await expectLater(
      blocked.voidSale(sale.id),
      throwsA(isA<LicenseRequiredException>()),
    );

    expect((await isar.productModels.get(sugar.id))!.currentStock, 7);
    expect((await isar.saleModels.get(sale.id))!.isVoided, isFalse);
  });

  test('a sale whose product was deleted still voids cleanly', () async {
    final sugar = await product();
    final sale = await sell(sugar);

    await isar.writeTxn(() async {
      final stored = (await isar.productModels.get(sugar.id))!;
      stored.isDeleted = true;
      await isar.productModels.put(stored);
    });

    await sales.voidSale(sale.id);

    expect((await isar.saleModels.get(sale.id))!.isVoided, isTrue);
    expect((await isar.productModels.get(sugar.id))!.isDeleted, isTrue);
  });
}
