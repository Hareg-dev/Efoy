import '../../data/models/product_model.dart';

/// Whole-stock valuation, computed in exactly one place.
///
/// The inventory summary card, the home dashboard and the Excel export all
/// read these numbers so a figure can never disagree between screens.
///
/// Definitions (kept consistent with [ProductModel]):
/// - [costValue] = stock units x weighted-average cost. What the shop has
///   tied up in goods.
/// - [retailValue] = stock units x current selling price. What that stock
///   would bring in if it all sold, i.e. its liquidity.
/// - Low stock means `0 < stock <= threshold`. Sold-out lines are counted
///   separately in [outOfStockCount] so a merchant is not told to restock
///   something twice.
class InventoryValuation {
  const InventoryValuation({
    required this.productCount,
    required this.stockUnits,
    required this.costValue,
    required this.retailValue,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  factory InventoryValuation.of(List<ProductModel> products) {
    var units = 0;
    var cost = 0.0;
    var retail = 0.0;
    var low = 0;
    var out = 0;

    for (final product in products) {
      units += product.currentStock;
      cost += product.inventoryValue;
      retail += product.liquidityValue;
      if (product.isOutOfStock) {
        out++;
      } else if (product.isLowStock) {
        low++;
      }
    }

    return InventoryValuation(
      productCount: products.length,
      stockUnits: units,
      costValue: cost,
      retailValue: retail,
      lowStockCount: low,
      outOfStockCount: out,
    );
  }

  static const InventoryValuation empty = InventoryValuation(
    productCount: 0,
    stockUnits: 0,
    costValue: 0,
    retailValue: 0,
    lowStockCount: 0,
    outOfStockCount: 0,
  );

  final int productCount;
  final int stockUnits;
  final double costValue;
  final double retailValue;
  final int lowStockCount;
  final int outOfStockCount;

  /// Profit still locked in the shelves.
  double get potentialProfit => retailValue - costValue;

  /// Share of stock value that would turn into profit at current prices.
  double get marginOnStock => costValue == 0 ? 0 : potentialProfit / costValue;

  /// Products needing attention: low or sold out.
  int get attentionCount => lowStockCount + outOfStockCount;
}
