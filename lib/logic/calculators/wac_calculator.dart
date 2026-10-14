/// Weighted Average Cost (WAC) Calculator
/// 
/// Implements the accounting formula for calculating inventory cost
/// when items are purchased at varying prices over time.
/// 
/// Formula:
/// New WAC = [(Current Stock × Current Cost) + (Added Quantity × Purchase Price)] 
///           / (Current Stock + Added Quantity)
class WACCalculator {
  WACCalculator._();

  /// Calculate new Weighted Average Cost after restocking
  /// 
  /// Parameters:
  /// - [currentStock]: Quantity currently in stock
  /// - [currentCost]: Current WAC per unit
  /// - [addedQuantity]: New quantity being added
  /// - [purchasePrice]: Purchase price per unit for new stock
  /// 
  /// Returns: New WAC value
  static double calculateNewWAC({
    required int currentStock,
    required double currentCost,
    required int addedQuantity,
    required double purchasePrice,
  }) {
    // Handle edge case: first purchase (no existing stock)
    if (currentStock == 0) {
      return purchasePrice;
    }

    // Handle edge case: no quantity added
    if (addedQuantity == 0) {
      return currentCost;
    }

    final totalValue = (currentStock * currentCost) + (addedQuantity * purchasePrice);
    final totalQuantity = currentStock + addedQuantity;

    return totalValue / totalQuantity;
  }

  /// Calculate inventory value at current WAC
  /// 
  /// Parameters:
  /// - [quantity]: Number of units
  /// - [wac]: Weighted Average Cost per unit
  /// 
  /// Returns: Total inventory value (capital invested)
  static double calculateInventoryValue({
    required int quantity,
    required double wac,
  }) {
    return quantity * wac;
  }

  /// Calculate potential profit margin for a product
  /// 
  /// Parameters:
  /// - [sellingPrice]: Retail price per unit
  /// - [wac]: Weighted Average Cost per unit
  /// 
  /// Returns: Profit margin as a percentage (0.0 to 1.0)
  static double calculateProfitMargin({
    required double sellingPrice,
    required double wac,
  }) {
    if (sellingPrice <= 0) return 0.0;
    return (sellingPrice - wac) / sellingPrice;
  }

  /// Calculate gross profit for a sale
  /// 
  /// Parameters:
  /// - [quantity]: Units sold
  /// - [sellingPrice]: Price per unit
  /// - [wac]: Cost per unit (WAC at time of sale)
  /// 
  /// Returns: Gross profit amount
  static double calculateGrossProfit({
    required int quantity,
    required double sellingPrice,
    required double wac,
  }) {
    final revenue = quantity * sellingPrice;
    final cost = quantity * wac;
    return revenue - cost;
  }

  /// Calculate COGS (Cost of Goods Sold) for a sale
  /// 
  /// Parameters:
  /// - [quantity]: Units sold
  /// - [wac]: Weighted Average Cost per unit
  /// 
  /// Returns: Total COGS for the transaction
  static double calculateCOGS({
    required int quantity,
    required double wac,
  }) {
    return quantity * wac;
  }

  /// Calculate recommended retail price based on desired margin
  /// 
  /// Parameters:
  /// - [wac]: Weighted Average Cost per unit
  /// - [desiredMargin]: Target profit margin (e.g., 0.30 for 30%)
  /// 
  /// Returns: Recommended selling price
  static double calculateRecommendedPrice({
    required double wac,
    required double desiredMargin,
  }) {
    if (desiredMargin >= 1.0 || desiredMargin < 0) {
      throw ArgumentError('Margin must be between 0 and 1');
    }
    return wac / (1 - desiredMargin);
  }

  /// Calculate potential liquidity value (if all stock sold at current price)
  /// 
  /// Parameters:
  /// - [quantity]: Current stock quantity
  /// - [sellingPrice]: Current retail price per unit
  /// 
  /// Returns: Total potential revenue
  static double calculateLiquidityValue({
    required int quantity,
    required double sellingPrice,
  }) {
    return quantity * sellingPrice;
  }

  /// Calculate break-even quantity needed to recover fixed costs
  /// 
  /// Parameters:
  /// - [fixedCosts]: Total fixed expenses to recover
  /// - [sellingPrice]: Price per unit
  /// - [wac]: Cost per unit
  /// 
  /// Returns: Number of units needed to break even
  static int calculateBreakEvenQuantity({
    required double fixedCosts,
    required double sellingPrice,
    required double wac,
  }) {
    final contributionMargin = sellingPrice - wac;
    if (contributionMargin <= 0) return -1; // Can't break even
    
    return (fixedCosts / contributionMargin).ceil();
  }
}
