import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../data/models/product_model.dart';
import '../data/models/sale_model.dart';
import '../data/models/expense_model.dart';
import '../logic/providers/database_provider.dart';

class TestDataGenerator {
  static Future<void> generateSampleProducts(Isar isar) async {
    final products = [
      ProductModel()
        ..name = 'Coca-Cola 500ml'
        ..nameAm = 'ኮካ ኮላ 500ሚሊ'
        ..description = 'Refreshing drink'
        ..category = 'Beverages'
        ..barcode = '5449000000996'
        ..sellingPrice = 20.0
        ..costPrice = 15.0
        ..weightedAverageCost = 15.0
        ..stockQuantity = 100
        ..lowStockThreshold = 20
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now(),
      
      ProductModel()
        ..name = 'Milk 1L'
        ..nameAm = 'ወተት 1ሊትር'
        ..description = 'Fresh milk'
        ..category = 'Dairy'
        ..barcode = '8901234567890'
        ..sellingPrice = 80.0
        ..costPrice = 65.0
        ..weightedAverageCost = 65.0
        ..stockQuantity = 50
        ..lowStockThreshold = 15
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now(),
      
      ProductModel()
        ..name = 'Sugar 1kg'
        ..nameAm = 'ስኳር 1ኪሎ'
        ..description = 'White sugar'
        ..category = 'Groceries'
        ..barcode = '5555555555555'
        ..sellingPrice = 85.0
        ..costPrice = 70.0
        ..weightedAverageCost = 70.0
        ..stockQuantity = 5
        ..lowStockThreshold = 10
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now(),
    ];

    await isar.writeTxn(() async {
      await isar.productModels.putAll(products);
    });
  }

  static Future<void> generateSampleSales(Isar isar) async {
    final products = await isar.productModels.where().findAll();
    if (products.isEmpty) return;

    final sale = SaleModel()
      ..saleItems = [
        SaleItemModel()
          ..productId = products[0].id
          ..productName = products[0].name
          ..quantity = 3
          ..unitPrice = 20.0
          ..costPrice = 15.0
          ..subtotal = 60.0
          ..profit = 15.0,
      ]
      ..totalAmount = 60.0
      ..totalProfit = 15.0
      ..paymentMethod = 'Cash'
      ..amountReceived = 100.0
      ..changeGiven = 40.0
      ..timestamp = DateTime.now()
      ..isVoided = false;

    await isar.writeTxn(() async {
      await isar.saleModels.put(sale);
    });
  }

  static Future<void> generateSampleExpenses(Isar isar) async {
    final expenses = [
      ExpenseModel()
        ..title = 'Rent'
        ..amount = 5000.0
        ..description = 'Monthly shop rent'
        ..descriptionAm = 'ወርሃዊ የሱቅ ኪራይ'
        ..isCapitalExpenditure = false
        ..timestamp = DateTime.now(),
      
      ExpenseModel()
        ..title = 'Salaries'
        ..amount = 3000.0
        ..description = 'Staff salary'
        ..descriptionAm = 'የሰራተኛ ደሞዝ'
        ..isCapitalExpenditure = false
        ..timestamp = DateTime.now(),
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
      await isar.restockLogModels.clear();
    });
  }
}
