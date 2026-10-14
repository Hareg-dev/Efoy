import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../models/expense_model.dart';
import '../models/restock_log_model.dart';
import '../models/license_model.dart';

/// Efoy Local Database Manager using Isar
class AppDatabase {
  static AppDatabase? _instance;
  static Isar? _isar;

  AppDatabase._();

  factory AppDatabase() {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  /// Initialize the Isar database
  Future<Isar> init() async {
    if (_isar != null && _isar!.isOpen) {
      return _isar!;
    }

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        ProductModelSchema,
        SaleModelSchema,
        ExpenseModelSchema,
        RestockLogModelSchema,
        LicenseModelSchema,
      ],
      directory: dir.path,
      name: 'efoy_retail_db',
    );

    return _isar!;
  }

  /// Get the initialized Isar instance
  Isar get instance {
    if (_isar == null || !_isar!.isOpen) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _isar!;
  }

  /// Close the database
  Future<void> close() async {
    if (_isar != null && _isar!.isOpen) {
      await _isar!.close();
      _isar = null;
    }
  }

  /// Clear all data (use with caution!)
  Future<void> clearAll() async {
    final isar = instance;
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }

  /// Export database to JSON (for backup/sync)
  Future<Map<String, List<Map<String, dynamic>>>> exportToJson() async {
    final isar = instance;

    final products = await isar.productModels.where().findAll();
    final sales = await isar.saleModels.where().findAll();
    final expenses = await isar.expenseModels.where().findAll();
    final restockLogs = await isar.restockLogModels.where().findAll();
    final licenses = await isar.licenseModels.where().findAll();

    return {
      'products': products.map((p) => p.toJson()).toList(),
      'sales': sales.map((s) => s.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'restockLogs': restockLogs.map((r) => r.toJson()).toList(),
      'licenses': licenses.map((l) => l.toJson()).toList(),
    };
  }

  /// Import database from JSON (for restore/sync)
  Future<void> importFromJson(Map<String, List<Map<String, dynamic>>> data) async {
    final isar = instance;

    await isar.writeTxn(() async {
      // Import products
      if (data.containsKey('products')) {
        final products = data['products']!
            .map((json) => ProductModel.fromJson(json))
            .toList();
        await isar.productModels.putAll(products);
      }

      // Import sales
      if (data.containsKey('sales')) {
        final sales = data['sales']!
            .map((json) => SaleModel.fromJson(json))
            .toList();
        await isar.saleModels.putAll(sales);
      }

      // Import expenses
      if (data.containsKey('expenses')) {
        final expenses = data['expenses']!
            .map((json) => ExpenseModel.fromJson(json))
            .toList();
        await isar.expenseModels.putAll(expenses);
      }

      // Import restock logs
      if (data.containsKey('restockLogs')) {
        final restockLogs = data['restockLogs']!
            .map((json) => RestockLogModel.fromJson(json))
            .toList();
        await isar.restockLogModels.putAll(restockLogs);
      }

      // Import licenses
      if (data.containsKey('licenses')) {
        final licenses = data['licenses']!
            .map((json) => LicenseModel.fromJson(json))
            .toList();
        await isar.licenseModels.putAll(licenses);
      }
    });
  }
}
