import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/expense_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import '../../logic/calculators/inventory_valuation.dart';

/// Writes the merchant's books into a single .xlsx workbook.
///
/// Read-only by design: exporting is one of the capabilities that must keep
/// working after a license expires, so nothing here goes through the license
/// gate and nothing here mutates the database.
///
/// Money cells are written as numbers (never "1,200.00 ብር" text) so totals,
/// filters and pivots keep working in Excel and Google Sheets.
class ExcelExporter {
  const ExcelExporter(this._isar);

  final Isar _isar;

  static final DateFormat _date = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTime = DateFormat('yyyy-MM-dd HH:mm');

  /// Builds the workbook and returns the written file.
  ///
  /// [businessName] only labels the Summary sheet.
  Future<File> export({String? businessName, Directory? toDirectory}) async {
    final products = await _isar
        .productModels
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
    final sales = await _isar.saleModels.where().findAll();
    final expenses = await _isar
        .expenseModels
        .filter()
        .isDeletedEqualTo(false)
        .findAll();

    final excel = Excel.createExcel();

    _summary(
      excel,
      businessName: businessName,
      products: products,
      sales: sales,
      expenses: expenses,
    );
    _products(excel, products);
    _sales(excel, sales);
    _saleItems(excel, sales);
    _expenses(excel, expenses);

    // Every workbook starts with one default sheet. It can only be dropped
    // once at least one other sheet exists, so this runs last.
    excel.delete('Sheet1');

    final bytes = excel.save(fileName: 'efoy_export.xlsx');
    if (bytes == null) {
      throw const ExcelExportException('The workbook could not be encoded.');
    }

    final dir = toDirectory ?? await getApplicationDocumentsDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final file = File(
      '${dir.path}${Platform.pathSeparator}efoy_export_$stamp.xlsx',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  // ---- sheets --------------------------------------------------------------

  void _summary(
    Excel excel, {
    required String? businessName,
    required List<ProductModel> products,
    required List<SaleModel> sales,
    required List<ExpenseModel> expenses,
  }) {
    final sheet = excel['Summary'];
    final valuation = InventoryValuation.of(products);
    final posted = sales.where((sale) => !sale.isVoided).toList();

    double sum(Iterable<SaleModel> source, double Function(SaleModel) pick) =>
        source.fold<double>(0, (total, sale) => total + pick(sale));
    double sumExpenses({required bool capital}) => expenses
        .where((e) => e.isRestockExpense == capital)
        .fold<double>(0, (total, e) => total + e.amount);

    final revenue = sum(posted, (s) => s.totalAmount);
    final cogs = sum(posted, (s) => s.totalCost);
    final grossProfit = sum(posted, (s) => s.grossProfit);
    final operating = sumExpenses(capital: false);
    final capital = sumExpenses(capital: true);

    _title(sheet, 'Efoy business report');
    _blank(sheet);
    _kv(sheet, 'Business', _orDash(businessName));
    _kv(sheet, 'Generated', _dateTime.format(DateTime.now()));
    _kv(sheet, 'Products listed', valuation.productCount);
    _kv(sheet, 'Sales recorded', sales.length);
    _kv(sheet, 'Expenses recorded', expenses.length);
    _blank(sheet);

    _section(sheet, 'Trading');
    _kv(sheet, 'Revenue (non-voided sales)', revenue, money: true);
    _kv(sheet, 'Cost of goods sold', cogs, money: true);
    _kv(sheet, 'Gross profit', grossProfit, money: true);
    _kv(sheet, 'Operating expenses', operating, money: true);
    _kv(sheet, 'Net profit (gross - operating)', grossProfit - operating, money: true);
    _kv(
      sheet,
      'Restock spend (capital, not counted in net profit)',
      capital,
      money: true,
    );
    _blank(sheet);

    _section(sheet, 'Stock');
    _kv(sheet, 'Stock units on hand', valuation.stockUnits);
    _kv(sheet, 'Stock value at cost', valuation.costValue, money: true);
    _kv(
      sheet,
      'Stock value at selling price (liquidity)',
      valuation.retailValue,
      money: true,
    );
    _kv(sheet, 'Profit still tied up in stock', valuation.potentialProfit, money: true);
    _kv(sheet, 'Low stock items', valuation.lowStockCount);
    _kv(sheet, 'Sold out items', valuation.outOfStockCount);

    sheet.setColumnWidth(0, 46);
    sheet.setColumnWidth(1, 20);
  }

  void _products(Excel excel, List<ProductModel> products) {
    final sheet = excel['Products'];
    _head(sheet, [
      'Name',
      'Category',
      'Barcode',
      'Stock',
      'Low-stock at',
      'Cost price (avg)',
      'Selling price',
      'Stock at cost',
      'Stock at selling',
      'Profit if sold',
      'Status',
    ]);

    final sorted = [...products]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    for (final p in sorted) {
      _row(
        sheet,
        [
          p.name,
          p.category ?? '',
          p.barcode ?? '',
          p.currentStock,
          p.lowStockThreshold,
          p.costPrice,
          p.sellingPrice,
          p.inventoryValue,
          p.liquidityValue,
          p.potentialProfit,
          p.isOutOfStock
              ? 'Sold out'
              : p.isLowStock
              ? 'Low stock'
              : 'Ok',
        ],
        money: const {5, 6, 7, 8, 9},
      );
    }
    _widths(sheet, first: 30);
  }

  void _sales(Excel excel, List<SaleModel> sales) {
    final sheet = excel['Sales'];
    _head(sheet, [
      'Date',
      'Transaction',
      'Units sold',
      'Revenue',
      'Cost',
      'Gross profit',
      'Payment',
      'Voided',
      'Notes',
    ]);

    final sorted = [...sales]
      ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
    for (final s in sorted) {
      _row(
        sheet,
        [
          _date.format(s.saleDate),
          s.transactionId,
          s.lineItems.fold<int>(0, (n, i) => n + i.quantity),
          s.totalAmount,
          s.totalCost,
          s.grossProfit,
          _paymentLabel(s.paymentMethod),
          s.isVoided,
          s.notes ?? '',
        ],
        money: const {3, 4, 5},
      );
    }
    _widths(sheet, first: 14);
  }

  void _saleItems(Excel excel, List<SaleModel> sales) {
    final sheet = excel['Sale items'];
    _head(sheet, [
      'Date',
      'Transaction',
      'Product',
      'Quantity',
      'Unit price',
      'Line total',
      'Unit cost',
      'Line profit',
    ]);

    final sorted = [...sales]
      ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
    for (final sale in sorted) {
      for (final item in sale.lineItems) {
        _row(
          sheet,
          [
            _date.format(sale.saleDate),
            sale.transactionId,
            item.productName,
            item.quantity,
            item.unitPrice,
            item.lineTotal,
            item.unitCost,
            item.lineProfit,
          ],
          money: const {4, 5, 6, 7},
        );
      }
    }
    _widths(sheet, first: 14);
  }

  void _expenses(Excel excel, List<ExpenseModel> expenses) {
    final sheet = excel['Expenses'];
    _head(sheet, [
      'Date',
      'Title',
      'Category',
      'Type',
      'Amount',
      'Description',
    ]);

    final sorted = [...expenses]
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    for (final e in sorted) {
      _row(
        sheet,
        [
          _date.format(e.expenseDate),
          e.title,
          e.category.displayName,
          e.isRestockExpense ? 'Capital (restock)' : 'Operating',
          e.amount,
          e.description ?? '',
        ],
        money: const {4},
      );
    }
    _widths(sheet, first: 14);
  }

  // ---- row helpers ---------------------------------------------------------

  /// Appends one row and styles it in the same pass.
  ///
  /// [money] columns get thousands grouping with two decimals; everything
  /// else keeps the type Excel infers from the value.
  void _row(
    Sheet sheet,
    List<Object?> values, {
    Set<int> money = const {},
    bool bold = false,
  }) {
    final rowIndex = sheet.maxRows;
    sheet.appendRow([for (final value in values) _toCell(value)]);

    for (var column = 0; column < values.length; column++) {
      final isMoney = money.contains(column);
      if (!bold && !isMoney) continue;
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: column, rowIndex: rowIndex),
        _toCell(values[column]),
        cellStyle: CellStyle(
          bold: bold,
          numberFormat: isMoney ? NumFormat.standard_4 : NumFormat.standard_0,
        ),
      );
    }
  }

  void _head(Sheet sheet, List<String> labels) =>
      _row(sheet, labels, bold: true);

  void _title(Sheet sheet, String text) {
    final rowIndex = sheet.maxRows;
    _row(sheet, [text], bold: true);
    sheet.updateCell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
      TextCellValue(text),
      cellStyle: CellStyle(bold: true, fontSize: 14),
    );
  }

  void _section(Sheet sheet, String text) => _row(sheet, [text], bold: true);

  void _blank(Sheet sheet) => sheet.appendRow([null]);

  void _kv(Sheet sheet, String label, Object value, {bool money = false}) =>
      _row(sheet, [label, value], money: money ? const {1} : const {});

  void _widths(Sheet sheet, {required double first}) {
    sheet.setColumnWidth(0, first);
    for (var column = 1; column < sheet.maxColumns; column++) {
      sheet.setColumnWidth(column, 18);
    }
  }

  CellValue? _toCell(Object? value) => switch (value) {
    null => null,
    final int v => IntCellValue(v),
    final double v => DoubleCellValue(v),
    final bool v => BoolCellValue(v),
    final String v => TextCellValue(v),
    _ => TextCellValue('$value'),
  };

  String _orDash(String? value) =>
      value == null || value.trim().isEmpty ? '-' : value.trim();

  String _paymentLabel(PaymentMethod method) => switch (method) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.telebirr => 'Telebirr',
    PaymentMethod.cbeBirr => 'CBE Birr',
    PaymentMethod.amharaBank => 'Amhara Bank',
    PaymentMethod.mixed => 'Mixed',
  };
}

class ExcelExportException implements Exception {
  const ExcelExportException(this.message);

  final String message;

  @override
  String toString() => 'ExcelExportException: $message';
}
