import 'package:isar/isar.dart';
import '../data/models/expense_model.dart';
import '../data/models/product_model.dart';
import '../data/models/sale_model.dart';

class TestDataGenerator {
  static Future<void> generateSampleProducts(Isar isar) async {
    final now = DateTime.now();
    final products = [
      ProductModel(
        name: 'Coca-Cola 500ml',
        description: 'Refreshing drink',
        category: 'Beverages',
        barcode: '5449000000996',
        sellingPrice: 20.0,
        costPrice: 15.0,
        currentStock: 100,
        lowStockThreshold: 20,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        name: 'Milk 1L',
        description: 'Fresh milk',
        category: 'Dairy',
        barcode: '8901234567890',
        sellingPrice: 80.0,
        costPrice: 65.0,
        currentStock: 50,
        lowStockThreshold: 15,
        createdAt: now,
        updatedAt: now,
      ),
      ProductModel(
        name: 'Sugar 1kg',
        description: 'White sugar',
        category: 'Groceries',
        barcode: '5555555555555',
        sellingPrice: 85.0,
        costPrice: 70.0,
        currentStock: 5,
        lowStockThreshold: 10,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await isar.writeTxn(() async {
      await isar.productModels.putAll(products);
    });
  }

  static Future<void> generateSampleSales(Isar isar) async {
    final products = await isar.productModels.where().findAll();
    if (products.isEmpty) return;

    final item = SaleLineItem()
      ..productId = products[0].id
      ..productName = products[0].name
      ..quantity = 3
      ..unitPrice = 20.0
      ..unitCost = 15.0
      ..lineTotal = 60.0
      ..lineCost = 45.0
      ..lineProfit = 15.0;

    final sale = SaleModel(
      saleDate: DateTime.now(),
      transactionId: 'sale-demo-001',
      lineItems: [item],
      totalAmount: 60.0,
      totalCost: 45.0,
      grossProfit: 15.0,
      paymentMethod: PaymentMethod.cash,
      amountReceived: 100.0,
      changeGiven: 40.0,
      createdAt: DateTime.now(),
    );

    await isar.writeTxn(() async {
      await isar.saleModels.put(sale);
    });
  }

  static Future<void> generateSampleExpenses(Isar isar) async {
    final now = DateTime.now();
    final expenses = [
      ExpenseModel(
        title: 'Rent',
        description: 'Monthly shop rent',
        amount: 5000.0,
        category: ExpenseCategory.rent,
        expenseDate: now,
        createdAt: now,
      ),
      ExpenseModel(
        title: 'Salaries',
        description: 'Staff salary',
        amount: 3000.0,
        category: ExpenseCategory.salary,
        expenseDate: now,
        createdAt: now,
      ),
    ];

    await isar.writeTxn(() async {
      await isar.expenseModels.putAll(expenses);
    });
  }

  static Future<void> generateAllSampleData(Isar isar) async {
    await generateSampleProducts(isar);
    await generateSampleSales(isar);
    await generateSampleExpenses(isar);
  }

  static Future<void> clearAllData(Isar isar) async {
    await isar.writeTxn(() async {
      await isar.productModels.clear();
      await isar.saleModels.clear();
      await isar.expenseModels.clear();
    });
  }
}
