import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:efoy_retail_app/core/licensing/license_gate.dart';
import 'package:efoy_retail_app/data/models/expense_model.dart';
import 'package:efoy_retail_app/data/models/product_model.dart';
import 'package:efoy_retail_app/data/models/restock_log_model.dart';
import 'package:efoy_retail_app/data/models/sale_model.dart';
import 'package:efoy_retail_app/logic/providers/database_provider.dart';
import 'package:efoy_retail_app/logic/providers/license_provider.dart';
import 'package:efoy_retail_app/logic/providers/report_provider.dart';

import 'isar_host.dart';

/// The business report is assembled from four collections, so it is checked
/// against a real database rather than a hand-made object: the numbers a
/// merchant reads must come from the rows they actually recorded.
void main() {
  late Directory tempRoot;
  late Isar isar;
  var dbCounter = 0;

  setUpAll(() async {
    await initializeIsarHost();
    tempRoot = Directory.systemTemp.createTempSync('efoy_report');
  });

  setUp(() async {
    dbCounter++;
    isar = await openTestIsar(
      directory: tempRoot.path,
      name: 'report_$dbCounter',
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

  SaleLineItem line(String name, int qty, double price, double cost) {
    return SaleLineItem()
      ..productName = name
      ..quantity = qty
      ..unitPrice = price
      ..unitCost = cost
      ..lineTotal = qty * price
      ..lineCost = qty * cost
      ..lineProfit = qty * (price - cost);
  }

  Future<void> seed() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 10);

    await isar.writeTxn(() async {
      await isar.productModels.put(
        ProductModel(
          name: 'Sugar 1kg',
          sellingPrice: 260,
          costPrice: 200,
          currentStock: 20,
          lowStockThreshold: 4,
          createdAt: today,
          updatedAt: today,
        ),
      );

      await isar.saleModels.put(
        SaleModel(
          saleDate: today,
          transactionId: 'TX-A',
          lineItems: [line('Sugar 1kg', 10, 260, 200)],
          totalAmount: 2600,
          totalCost: 2000,
          grossProfit: 600,
          paymentMethod: PaymentMethod.cash,
          amountReceived: 2600,
          createdAt: today,
        ),
      );
      await isar.saleModels.put(
        SaleModel(
          saleDate: today,
          transactionId: 'TX-B',
          lineItems: [line('Cooking oil', 2, 300, 250)],
          totalAmount: 600,
          totalCost: 500,
          grossProfit: 100,
          paymentMethod: PaymentMethod.cash,
          amountReceived: 300,
          createdAt: today,
        ),
      );

      await isar.expenseModels.put(
        ExpenseModel(
          title: 'Shop rent',
          amount: 700,
          category: ExpenseCategory.rent,
          expenseDate: today,
          createdAt: today,
        ),
      );
      await isar.expenseModels.put(
        ExpenseModel(
          title: 'Monthly wages',
          amount: 2500,
          category: ExpenseCategory.salary,
          expenseDate: today,
          createdAt: today,
        ),
      );
      await isar.expenseModels.put(
        ExpenseModel(
          title: 'Stock purchase',
          amount: 5000,
          category: ExpenseCategory.restock,
          expenseDate: today,
          createdAt: today,
          isRestockExpense: true,
        ),
      );

      await isar.restockLogModels.put(
        RestockLogModel(
          productId: 1,
          productName: 'Sugar 1kg',
          quantityAdded: 25,
          purchasePrice: 200,
          totalCost: 5000,
          stockBefore: 0,
          stockAfter: 25,
          wacBefore: 200,
          wacAfter: 200,
          restockDate: today,
          createdAt: today,
        ),
      );
    });
  }

  Future<BusinessReport> buildReport() async {
    final container = ProviderContainer(
      overrides: [
        isarProvider.overrideWith((ref) => Future.value(isar)),
        licenseGateProvider.overrideWith(
          (ref) => const AlwaysAllowedLicenseGate(),
        ),
      ],
    );
    try {
      return await container.read(businessReportProvider.future);
    } finally {
      // Disposed here, not in a tear-down: the report watches the database and
      // must stop listening before the test closes it.
      container.dispose();
    }
  }

  test('totals agree with what was recorded', () async {
    await seed();
    final report = await buildReport();

    expect(report.revenue, 3200);
    expect(report.grossProfit, 700);
    expect(report.salesCount, 2);
    expect(report.capital, 5000);
    expect(report.restockTotal, 5000);
  });

  test('overhead and salaries are split, never mixed', () async {
    await seed();
    final report = await buildReport();

    expect(report.overhead, 700);
    expect(report.salaries, 2500);
    expect(report.deducted, 3200);
    expect(report.netProfit, -2500, reason: '700 - 3,200');
  });

  test('products are ranked by the profit they made', () async {
    await seed();
    final report = await buildReport();

    expect(report.products.map((product) => product.productName), [
      'Sugar 1kg',
      'Cooking oil',
    ]);
    expect(report.products.first.quantity, 10);
    expect(report.products.first.revenue, 2600);
    expect(report.products.first.profit, 600);
  });

  test('spending is grouped by category and leaves restock out', () async {
    await seed();
    final report = await buildReport();

    expect(report.spending, hasLength(2));
    expect(report.spending.first.category, ExpenseCategory.salary);
    expect(report.spending.first.amount, 2500);
    expect(report.spending.last.category, ExpenseCategory.rent);
    expect(
      report.spending.any((line) => line.category == ExpenseCategory.restock),
      isFalse,
    );
  });

  test('cash taken counts what the till actually kept', () async {
    await seed();
    final report = await buildReport();

    // 2,600 paid in full + 300 of a 600 invoice on credit.
    expect(report.cashCollected, 2900);
    expect(report.outstanding, 0, reason: 'no ledger row was opened here');
  });

  test('the daily series covers every day of the month so far', () async {
    await seed();
    final report = await buildReport();

    expect(report.daily.first.day, report.startDate);
    expect(report.daily.last.day.isBefore(report.endDate), isTrue);
    final today = report.daily.lastWhere(
      (day) => day.salesCount > 0,
      orElse: () => report.daily.first,
    );
    expect(today.revenue, 3200);
    expect(today.grossProfit, 700);
  });

  test('the restock list shows what was bought back in', () async {
    await seed();
    final report = await buildReport();

    expect(report.restocks, hasLength(1));
    expect(report.restocks.single.productName, 'Sugar 1kg');
    expect(report.restocks.single.quantity, 25);
    expect(report.restocks.single.totalCost, 5000);
  });
}
