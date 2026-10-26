import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/data/models/product_model.dart';
import 'package:efoy_retail_app/logic/calculators/inventory_valuation.dart';
import 'package:efoy_retail_app/logic/providers/inventory_provider.dart';

ProductModel _product({
  required String name,
  required int stock,
  double cost = 40,
  double price = 50,
  int threshold = 10,
}) {
  final now = DateTime(2026, 10, 23);
  return ProductModel(
    name: name,
    sellingPrice: price,
    costPrice: cost,
    currentStock: stock,
    lowStockThreshold: threshold,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  // The shelf: 1 healthy line, 1 running low, 1 sold out.
  final products = [
    _product(name: 'Sugar 1kg', stock: 40, cost: 55, price: 70),
    _product(name: 'Oil 500ml', stock: 4, cost: 210, price: 260),
    _product(name: 'Soap bar', stock: 0, cost: 25, price: 35),
  ];

  group('one restock rule everywhere', () {
    test('sold-out lines are still on the reorder list', () {
      expect(products[1].needsRestock, isTrue);
      expect(products[2].needsRestock, isTrue);
      expect(products[0].needsRestock, isFalse);

      // The strict "low" badge excludes empty shelves so a line is never
      // labelled both Low and Out.
      expect(products[2].isLowStock, isFalse);
      expect(products[2].isOutOfStock, isTrue);
    });

    test('the filter pill count and the alert card agree', () {
      final state = InventoryState(
        allProducts: products,
        searchQuery: '',
        filter: StockFilter.all,
      );

      expect(state.needsRestockCount, 2);
      expect(state.needsRestockProducts.first.name, 'Soap bar');
      expect(
        state.products.where((p) => p.needsRestock).length,
        state.needsRestockCount,
      );
      expect(state.outOfStockCount, 1);
      expect(state.stockUnits, 44);
    });

    test('valuation splits low and sold out but totals the same list', () {
      final valuation = InventoryValuation.of(products);

      expect(valuation.productCount, 3);
      expect(valuation.stockUnits, 44);
      expect(valuation.costValue, 40 * 55 + 4 * 210);
      expect(valuation.retailValue, 40 * 70 + 4 * 260);
      expect(
        valuation.potentialProfit,
        valuation.retailValue - valuation.costValue,
      );
      expect(valuation.lowStockCount, 1);
      expect(valuation.outOfStockCount, 1);
      expect(valuation.attentionCount, 2);
    });

    test('margin on stock is measured against the money tied up', () {
      final valuation = InventoryValuation.of(products);
      expect(
        valuation.marginOnStock,
        valuation.potentialProfit / valuation.costValue,
      );
      expect(InventoryValuation.empty.marginOnStock, 0);
    });
  });
}
