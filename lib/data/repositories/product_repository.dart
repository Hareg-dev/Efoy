import 'package:isar/isar.dart';

import '../../core/licensing/license_gate.dart';
import '../../logic/calculators/wac_calculator.dart';
import '../models/expense_model.dart';
import '../models/product_model.dart';
import '../models/restock_log_model.dart';
import 'base_repository.dart';
import 'repository_exceptions.dart';

/// Result of a restock operation containing the three records written
/// atomically.
class RestockResult {
  const RestockResult({
    required this.product,
    required this.log,
    required this.expense,
  });

  final ProductModel product;
  final RestockLogModel log;
  final ExpenseModel expense;
}

class ProductRepository implements BaseRepository<ProductModel> {
  ProductRepository(this._isar, this._licenseGate);

  final Isar _isar;

  /// Enforces the offline licensing policy before product mutations.
  final LicenseGate _licenseGate;

  Isar get isar => _isar;

  @override
  Future<ProductModel?> getById(int id) => _isar.productModels.get(id);

  @override
  Future<List<ProductModel>> getAll() {
    return _isar.productModels
        .filter()
        .isDeletedEqualTo(false)
        .sortByName()
        .findAll();
  }

  /// Real-time stream of active products sorted by name.
  Stream<List<ProductModel>> watchAll() {
    return _isar.productModels
        .filter()
        .isDeletedEqualTo(false)
        .sortByName()
        .watch(fireImmediately: true);
  }

  /// Products at or below their low-stock threshold, lowest stock first.
  Future<List<ProductModel>> getLowStockProducts() async {
    final products = await getAll();
    return products
        .where((product) => product.needsRestock)
        .toList()
      ..sort((a, b) => a.currentStock.compareTo(b.currentStock));
  }

  @override
  Future<ProductModel> create(ProductModel entity) async {
    await _licenseGate.ensureAllowed(LicensedOperation.manageProducts);
    entity
      ..createdAt = entity.createdAt
      ..updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      entity.id = await _isar.productModels.put(entity);
    });
    return entity;
  }

  @override
  Future<ProductModel> update(ProductModel entity) async {
    await _licenseGate.ensureAllowed(LicensedOperation.manageProducts);
    entity.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.productModels.put(entity);
    });
    return entity;
  }

  /// Soft-delete a product so historical sale line items stay resolvable.
  @override
  Future<void> delete(int id) async {
    await _licenseGate.ensureAllowed(LicensedOperation.manageProducts);
    await _isar.writeTxn(() async {
      final product = await _isar.productModels.get(id);
      if (product == null) return;
      product
        ..isDeleted = true
        ..updatedAt = DateTime.now();
      await _isar.productModels.put(product);
    });
  }

  /// Restock a product atomically:
  /// 1. Recalculate WAC,
  /// 2. Update stock and cost price,
  /// 3. Write a restock log,
  /// 4. Write a CapEx expense (excluded from operating profit).
  Future<RestockResult> restock({
    required int productId,
    required int quantityAdded,
    required double costPerUnit,
    DateTime? restockedAt,
    String? supplierName,
    String? notes,
  }) async {
    await _licenseGate.ensureAllowed(LicensedOperation.restock);
    if (quantityAdded <= 0) {
      throw RepositoryException('Quantity added must be greater than zero.');
    }
    if (costPerUnit < 0) {
      throw RepositoryException('Cost per unit cannot be negative.');
    }

    final now = restockedAt ?? DateTime.now();
    late RestockResult result;

    await _isar.writeTxn(() async {
      final product = await _isar.productModels.get(productId);
      if (product == null || product.isDeleted) {
        throw RepositoryException('Product not found.');
      }

      final oldStock = product.currentStock;
      final oldWac = product.costPrice;
      final newWac = WACCalculator.calculateNewWAC(
        currentStock: oldStock,
        currentCost: oldWac,
        addedQuantity: quantityAdded,
        purchasePrice: costPerUnit,
      );
      final totalCost = quantityAdded * costPerUnit;

      product
        ..currentStock = oldStock + quantityAdded
        ..costPrice = newWac
        ..updatedAt = now;

      final log = RestockLogModel(
        productId: product.id,
        productName: product.name,
        quantityAdded: quantityAdded,
        purchasePrice: costPerUnit,
        totalCost: totalCost,
        stockBefore: oldStock,
        stockAfter: product.currentStock,
        wacBefore: oldWac,
        wacAfter: newWac,
        restockDate: now,
        createdAt: now,
        supplierName: supplierName,
        notes: notes,
      );

      final expense = ExpenseModel(
        title: 'Restock: ${product.name}',
        description: '$quantityAdded units @ ${costPerUnit.toStringAsFixed(2)}',
        amount: totalCost,
        category: ExpenseCategory.restock,
        expenseDate: now,
        createdAt: now,
        notes: notes,
        isRestockExpense: true,
      );

      await _isar.productModels.put(product);
      log.id = await _isar.restockLogModels.put(log);
      expense.id = await _isar.expenseModels.put(expense);

      result = RestockResult(
        product: product,
        log: log,
        expense: expense,
      );
    });

    return result;
  }
}
