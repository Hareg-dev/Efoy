import 'package:isar/isar.dart';

import '../../core/licensing/license_gate.dart';
import '../models/debt_model.dart';
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
    this.cashCollected = 0,
  });

  final double revenue;
  final double cost;
  final double grossProfit;
  final int count;

  /// Money actually handed over at the counter for these invoices. A credit
  /// sale counts in [revenue] but not here until it is settled.
  final double cashCollected;

  static const empty = SalesTotals(
    revenue: 0,
    cost: 0,
    grossProfit: 0,
    count: 0,
  );
}

class SaleRepository implements BaseRepository<SaleModel> {
  SaleRepository(this._isar, this._licenseGate);

  final Isar _isar;

  /// Enforces the offline licensing policy before any sale mutation.
  final LicenseGate _licenseGate;

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
    await _licenseGate.ensureAllowed(LicensedOperation.recordSale);
    await _isar.writeTxn(() async {
      entity.id = await _isar.saleModels.put(entity);
    });
    return entity;
  }

  /// Sales are immutable; updating replaces the record.
  @override
  Future<SaleModel> update(SaleModel entity) async {
    await _licenseGate.ensureAllowed(LicensedOperation.recordSale);
    await _isar.writeTxn(() async {
      await _isar.saleModels.put(entity);
    });
    return entity;
  }

  /// Undo a sale recorded by mistake.
  ///
  /// The row is kept and flagged so the audit trail survives, and everything
  /// the sale moved is put back in the same transaction: the stock returns to
  /// the shelf and the balance it opened leaves the receivables list, so
  /// profit, inventory and "who owes me" all agree again.
  @override
  Future<void> delete(int id) => voidSale(id);

  Future<void> voidSale(int id) async {
    await _licenseGate.ensureAllowed(LicensedOperation.voidSale);
    await _isar.writeTxn(() async {
      final sale = await _isar.saleModels.get(id);
      if (sale == null || sale.isVoided) return;

      final now = DateTime.now();
      for (final item in sale.lineItems) {
        final product = await _isar.productModels.get(item.productId);
        if (product == null || product.isDeleted) continue;
        product
          ..currentStock = product.currentStock + item.quantity
          ..updatedAt = now;
        await _isar.productModels.put(product);
      }

      // The invoice this balance belonged to never happened, so the customer
      // should not be chased for it. The voided sale row is the audit trail.
      final debts = await _isar.debtModels
          .filter()
          .saleTransactionIdEqualTo(sale.transactionId)
          .findAll();
      if (debts.isNotEmpty) {
        await _isar.debtModels.deleteAll(debts.map((debt) => debt.id).toList());
      }

      sale
        ..isVoided = true
        ..voidedAt = now;
      await _isar.saleModels.put(sale);
    });
  }

  /// Persist a sale, decrement stock for every line item and open the matching
  /// receivable in one Isar write transaction. Any validation failure rolls the
  /// whole transaction back, so stock, sales and debts can never diverge.
  Future<SaleModel> createWithStockUpdate(
    SaleModel sale, {
    DebtModel? debt,
  }) async {
    await _licenseGate.ensureAllowed(LicensedOperation.recordSale);
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
      if (debt != null) {
        await _isar.debtModels.put(debt);
      }
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
    var cash = 0.0;
    for (final sale in sales) {
      revenue += sale.totalAmount;
      cost += sale.totalCost;
      grossProfit += sale.grossProfit;
      // Older rows predate the field; they were all paid in full at the till.
      cash += sale.amountReceived ?? sale.totalAmount;
    }

    return SalesTotals(
      revenue: revenue,
      cost: cost,
      grossProfit: grossProfit,
      count: sales.length,
      cashCollected: cash,
    );
  }
}
