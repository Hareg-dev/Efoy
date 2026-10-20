import 'package:isar/isar.dart';

import '../models/product_model.dart';
import '../models/sale_model.dart';
import 'base_repository.dart';
import 'repository_exceptions.dart';

class SalesTotals {
  const SalesTotals({
    required this.revenue,
    required this.cost,
    required this.grossProfit,
    required this.count,
  });

  final double revenue;
  final double cost;
  final double grossProfit;
  final int count;

  static const empty = SalesTotals(
    revenue: 0,
    cost: 0,
    grossProfit: 0,
    count: 0,
  );
}

class SaleRepository implements BaseRepository<SaleModel> {
  SaleRepository(this._isar);

  final Isar _isar;

  @override
  Future<SaleModel?> getById(int id) => _isar.saleModels.get(id);

  @override
  Future<List<SaleModel>> getAll() {
    return _isar.saleModels
        .filter()
        .isVoidedEqualTo(false)
        .sortBySaleDateDesc()
        .findAll();
  }

  /// Real-time stream of completed (non-voided) sales, newest first.
  Stream<List<SaleModel>> watchAll() {
    return _isar.saleModels
        .filter()
        .isVoidedEqualTo(false)
        .sortBySaleDateDesc()
        .watch(fireImmediately: true);
  }

  @override
  Future<SaleModel> create(SaleModel entity) async {
    await _isar.writeTxn(() async {
      entity.id = await _isar.saleModels.put(entity);
    });
    return entity;
  }

  /// Sales are immutable; updating replaces the record.
  @override
  Future<SaleModel> update(SaleModel entity) async {
    await _isar.writeTxn(() async {
      await _isar.saleModels.put(entity);
    });
    return entity;
  }

  /// Soft-void a sale instead of deleting it so audit history is preserved.
  @override
  Future<void> delete(int id) => voidSale(id);

  Future<void> voidSale(int id) async {
    await _isar.writeTxn(() async {
      final sale = await _isar.saleModels.get(id);
      if (sale == null || sale.isVoided) return;
      sale
        ..isVoided = true
        ..voidedAt = DateTime.now();
      await _isar.saleModels.put(sale);
    });
  }

  /// Persist a sale and decrement stock for every line item in one Isar
  /// write transaction. Any validation failure rolls the whole transaction
  /// back, so stock and sales can never diverge.
  Future<SaleModel> createWithStockUpdate(SaleModel sale) async {
    if (sale.lineItems.isEmpty) {
      throw RepositoryException('Cannot record a sale with no line items.');
    }

    await _isar.writeTxn(() async {
      final updatedProducts = <ProductModel>[];
      final now = DateTime.now();

      for (final item in sale.lineItems) {
        if (item.quantity <= 0) {
          throw RepositoryException(
            'Invalid quantity for "${item.productName}".',
          );
        }

        final product = await _isar.productModels.get(item.productId);
        if (product == null || product.isDeleted) {
          throw RepositoryException(
            'Product "${item.productName}" no longer exists.',
          );
        }
        if (product.currentStock < item.quantity) {
          throw InsufficientStockException(
            productName: product.name,
            requested: item.quantity,
            available: product.currentStock,
          );
        }

        product
          ..currentStock = product.currentStock - item.quantity
          ..updatedAt = now;
        updatedProducts.add(product);
      }

      await _isar.productModels.putAll(updatedProducts);
      sale.id = await _isar.saleModels.put(sale);
    });

    return sale;
  }

  /// Sum revenue, COGS and gross profit for a half-open date range.
  Future<SalesTotals> getTotalsByPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final sales = await _isar.saleModels
        .filter()
        .saleDateBetween(startDate, endDate, includeUpper: false)
        .isVoidedEqualTo(false)
        .findAll();

    var revenue = 0.0;
    var cost = 0.0;
    var grossProfit = 0.0;
    for (final sale in sales) {
      revenue += sale.totalAmount;
      cost += sale.totalCost;
      grossProfit += sale.grossProfit;
    }

    return SalesTotals(
      revenue: revenue,
      cost: cost,
      grossProfit: grossProfit,
      count: sales.length,
    );
  }
}
