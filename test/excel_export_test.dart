import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:efoy_retail_app/core/export/excel_exporter.dart';
import 'package:efoy_retail_app/data/models/expense_model.dart';
import 'package:efoy_retail_app/data/models/product_model.dart';
import 'package:efoy_retail_app/data/models/sale_model.dart';
import 'package:efoy_retail_app/logic/calculators/inventory_valuation.dart';

import 'isar_host.dart';

/// The package wraps text cells in a TextSpan, so reading one back takes two
/// hops.
String cellText(CellValue? value) => (value! as TextCellValue).value.text ?? '';

/// A whole double is written back out as an int cell, so numeric assertions
/// have to accept either shape.
num cellNum(CellValue? value) => switch (value) {
  final IntCellValue v => v.value,
  final DoubleCellValue v => v.value,
  _ => throw StateError('Expected a numeric cell, got ${value.runtimeType}'),
};

/// Covers the single valuation model the dashboard and the workbook share, and
/// the Excel export that must keep working for an expired (read-only) merchant.
void main() {
  group('InventoryValuation', () {
    ProductModel product({
      required String name,
      required int stock,
      double cost = 100,
      double sell = 150,
      int threshold = 10,
    }) {
      return ProductModel(
        name: name,
        sellingPrice: sell,
        costPrice: cost,
        currentStock: stock,
        lowStockThreshold: threshold,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );
    }

    test('totals cost and retail value across products', () {
      final valuation = InventoryValuation.of([
        product(name: 'A', stock: 10, cost: 100, sell: 150), // 1000 / 1500
        product(name: 'B', stock: 4, cost: 50, sell: 80), // 200 / 320
      ]);

      expect(valuation.productCount, 2);
      expect(valuation.stockUnits, 14);
      expect(valuation.costValue, 1200);
      expect(valuation.retailValue, 1820);
      expect(valuation.potentialProfit, 620);
      expect(valuation.marginOnStock, closeTo(620 / 1200, 1e-12));
    });

    test('counts sold out separately from low stock', () {
      // Sold-out lines must not be double-reported as low stock: the model's
      // isLowStock already excludes zero quantity.
      final valuation = InventoryValuation.of([
        product(name: 'Out', stock: 0),
        product(name: 'Low', stock: 3),
        product(name: 'Fine', stock: 500),
      ]);

      expect(valuation.lowStockCount, 1);
      expect(valuation.outOfStockCount, 1);
      expect(valuation.attentionCount, 2);
      // A zero-stock product contributes no value even at a price.
      expect(valuation.costValue, 50300);
    });

    test('empty shop reports zeroes instead of dividing by zero', () {
      const empty = InventoryValuation.empty;
      expect(empty.productCount, 0);
      expect(empty.costValue, 0);
      expect(empty.retailValue, 0);
      expect(empty.marginOnStock, 0);
      expect(InventoryValuation.of([]).marginOnStock, 0);
    });
  });

  group('ExcelExporter', () {
    late Directory tempRoot;
    late Isar isar;
    late Directory outDir;
    var dbCounter = 0;

    final t0 = DateTime.utc(2026, 2, 5);

    setUpAll(() async {
      await initializeIsarHost();
      tempRoot = Directory.systemTemp.createTempSync('efoy_excel_export');
    });

    setUp(() async {
      dbCounter++;
      isar = await openTestIsar(
        directory: tempRoot.path,
        name: 'export_$dbCounter',
      );
      outDir = Directory(
        '${tempRoot.path}${Platform.pathSeparator}out_$dbCounter',
      )..createSync(recursive: true);
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
    });

    tearDownAll(() async {
      try {
        tempRoot.deleteSync(recursive: true);
      } on FileSystemException {
        // A locked temp file must not fail the suite.
      }
    });

    ProductModel makeProduct({
      required String name,
      required int stock,
      double cost = 100,
      double sell = 150,
      String? category,
      bool deleted = false,
    }) {
      return ProductModel(
        name: name,
        sellingPrice: sell,
        costPrice: cost,
        currentStock: stock,
        lowStockThreshold: 10,
        category: category,
        createdAt: t0,
        updatedAt: t0,
        isDeleted: deleted,
      );
    }

    SaleModel makeSale({
      required String transactionId,
      required double revenue,
      required double cost,
      required int quantity,
      bool voided = false,
    }) {
      return SaleModel(
        saleDate: t0,
        transactionId: transactionId,
        lineItems: [
          SaleLineItem()
            ..productId = 1
            ..productName = 'Tea 500g'
            ..quantity = quantity
            ..unitPrice = revenue / quantity
            ..unitCost = cost / quantity
            ..lineTotal = revenue
            ..lineCost = cost
            ..lineProfit = revenue - cost,
        ],
        totalAmount: revenue,
        totalCost: cost,
        grossProfit: revenue - cost,
        paymentMethod: PaymentMethod.telebirr,
        createdAt: t0,
        isVoided: voided,
      );
    }

    ExpenseModel makeExpense({
      required String title,
      required double amount,
      required ExpenseCategory category,
      bool restock = false,
      bool deleted = false,
    }) {
      return ExpenseModel(
        title: title,
        amount: amount,
        category: category,
        expenseDate: t0,
        createdAt: t0,
        isRestockExpense: restock,
        isDeleted: deleted,
      );
    }

    Future<Excel> exportFixtureWorkbook() async {
      await isar.writeTxn(() async {
        await isar.productModels.putAll([
          makeProduct(name: 'Tea 500g', stock: 20, cost: 100, sell: 150, category: 'Groceries'),
          makeProduct(name: 'Sugar 1kg', stock: 5, cost: 60, sell: 90, category: 'Groceries'),
          makeProduct(name: 'Gone', stock: 3, deleted: true),
        ]);
        await isar.saleModels.putAll([
          makeSale(transactionId: 'S-1', revenue: 1000, cost: 700, quantity: 10),
          makeSale(
            transactionId: 'S-2',
            revenue: 400,
            cost: 300,
            quantity: 4,
            voided: true,
          ),
        ]);
        await isar.expenseModels.putAll([
          makeExpense(title: 'Shop rent', amount: 500, category: ExpenseCategory.rent),
          makeExpense(
            title: 'Restock Tea 500g',
            amount: 2000,
            category: ExpenseCategory.restock,
            restock: true,
          ),
          makeExpense(
            title: 'Deleted cost',
            amount: 999,
            category: ExpenseCategory.other,
            deleted: true,
          ),
        ]);
      });

      final file = await ExcelExporter(isar).export(
        businessName: 'Test Shop',
        toDirectory: outDir,
      );
      return Excel.decodeBytes(await file.readAsBytes());
    }

    test('writes a workbook containing every report sheet', () async {
      final excel = await exportFixtureWorkbook();

      expect(
        excel.sheets.keys,
        containsAll(['Summary', 'Products', 'Sales', 'Sale items', 'Expenses']),
      );
      expect(excel.sheets.containsKey('Sheet1'), isFalse);
    });

    test('Products sheet lists live products only, sorted by name', () async {
      final excel = await exportFixtureWorkbook();
      final rows = excel['Products'].rows;

      expect(rows.first.map((cell) => cell?.value?.toString()), hasLength(11));
      expect(rows.length, 3); // header + 2 live products (soft-deleted excluded)
      final names = rows
          .skip(1)
          .map((row) => cellText(row[0]?.value))
          .toList();
      expect(names, ['Sugar 1kg', 'Tea 500g']);
    });

    test('money cells stay numeric so spreadsheets can total them', () async {
      final excel = await exportFixtureWorkbook();
      final teaRow = excel['Products'].rows.last;

      // Columns: cost(5) sell(6) stockAtCost(7) stockAtSelling(8) profit(9)
      expect(cellNum(teaRow[5]!.value), 100);
      expect(cellNum(teaRow[6]!.value), 150);
      expect(cellNum(teaRow[7]!.value), 2000); // 20 x 100
      expect(cellNum(teaRow[8]!.value), 3000); // 20 x 150
      expect(cellNum(teaRow[9]!.value), 1000);
    });

    test('Summary excludes voided sales, deleted expenses and restock capital',
        () async {
      final excel = await exportFixtureWorkbook();
      final values = <String, CellValue?>{
        for (final row in excel['Summary'].rows)
          if (row.length >= 2 && row[0]?.value != null)
            cellText(row[0]!.value): row[1]?.value,
      };

      double? money(String label) {
        final value = values[label];
        return value == null ? null : cellNum(value).toDouble();
      }

      // Only S-1 counts: 1000 revenue, 700 cost, 300 gross.
      expect(money('Revenue (non-voided sales)'), 1000);
      expect(money('Cost of goods sold'), 700);
      expect(money('Gross profit'), 300);
      // Rent only — the deleted expense and the restock capital are excluded.
      expect(money('Operating expenses'), 500);
      expect(money('Net profit (gross - operating)'), -200);
      expect(money('Restock spend (capital, not counted in net profit)'), 2000);

      // Stock: (20x100 + 5x60) cost, (20x150 + 5x90) retail.
      expect(money('Stock value at cost'), 2300);
      expect(money('Stock value at selling price (liquidity)'), 3450);
      expect(money('Profit still tied up in stock'), 1150);
      expect((values['Low stock items'] as IntCellValue).value, 1);
      expect((values['Products listed'] as IntCellValue).value, 2);
    });

    test('Expenses sheet labels capital and operating spend', () async {
      final excel = await exportFixtureWorkbook();
      final rows = excel['Expenses'].rows.skip(1).toList();

      expect(rows, hasLength(2)); // deleted expense is not exported
      final byTitle = {
        for (final row in rows)
          cellText(row[1]!.value): row,
      };
      expect(cellText(byTitle['Shop rent']![3]!.value), 'Operating');
      expect(
        cellText(byTitle['Restock Tea 500g']![3]!.value),
        'Capital (restock)',
      );
    });

    test('an empty shop still produces a valid workbook', () async {
      final file = await ExcelExporter(isar).export(toDirectory: outDir);

      expect(await file.exists(), isTrue);
      expect(await file.length(), greaterThan(0));
      expect(file.path, endsWith('.xlsx'));
      final excel = Excel.decodeBytes(await file.readAsBytes());
      expect(excel['Products'].rows.length, 1); // header only
      expect(excel['Sale items'].rows.length, 1);
    });

    test('export works with no merchant profile and a blank business name',
        () async {
      final file = await ExcelExporter(
        isar,
      ).export(toDirectory: outDir, businessName: '   ');
      expect(await file.exists(), isTrue);
    });
  });
}
