/// Profit & Financial Calculation Engine
/// 
/// Correctly separates Capital Expenditure (Restocking) from
/// Operating Expenses to prevent false daily loss reporting.
/// 
/// Key Principle:
/// - Restocking = Asset Conversion (Cash → Inventory)
/// - Operating Expenses = Daily overhead (Rent, Salary, etc.)
/// - COGS flows incrementally only when items are sold
class ProfitEngine {
  ProfitEngine._();

  /// Calculate Gross Profit for a period
  /// 
  /// Formula: Gross Profit = Revenue - COGS
  /// 
  /// Parameters:
  /// - [revenue]: Total sales revenue
  /// - [cogs]: Cost of Goods Sold (WAC × quantity sold)
  /// 
  /// Returns: Gross profit amount
  static double calculateGrossProfit({
    required double revenue,
    required double cogs,
  }) {
    return revenue - cogs;
  }

  /// Calculate Net Profit for a period
  /// 
  /// Formula: Net Profit = Gross Profit - Operating Expenses
  /// 
  /// CRITICAL: Restock expenses are NOT included in operating expenses.
  /// They are capital conversions tracked separately.
  /// 
  /// Parameters:
  /// - [grossProfit]: Gross profit from sales
  /// - [operatingExpenses]: Daily overhead (excludes restocking)
  /// 
  /// Returns: Net profit amount
  static double calculateNetProfit({
    required double grossProfit,
    required double operatingExpenses,
  }) {
    return grossProfit - operatingExpenses;
  }

  /// Calculate Gross Profit Margin as percentage
  /// 
  /// Formula: (Gross Profit / Revenue) × 100
  /// 
  /// Parameters:
  /// - [grossProfit]: Gross profit amount
  /// - [revenue]: Total revenue
  /// 
  /// Returns: Margin percentage (0.0 to 1.0)
  static double calculateGrossProfitMargin({
    required double grossProfit,
    required double revenue,
  }) {
    if (revenue == 0) return 0.0;
    return grossProfit / revenue;
  }

  /// Calculate Net Profit Margin as percentage
  /// 
  /// Formula: (Net Profit / Revenue) × 100
  /// 
  /// Parameters:
  /// - [netProfit]: Net profit amount
  /// - [revenue]: Total revenue
  /// 
  /// Returns: Margin percentage (0.0 to 1.0)
  static double calculateNetProfitMargin({
    required double netProfit,
    required double revenue,
  }) {
    if (revenue == 0) return 0.0;
    return netProfit / revenue;
  }

  /// Calculate Operating Expense Ratio
  /// 
  /// Formula: (Operating Expenses / Revenue) × 100
  /// 
  /// Indicates what percentage of revenue goes to overhead.
  /// Lower is generally better.
  /// 
  /// Parameters:
  /// - [operatingExpenses]: Total OpEx (excludes restocking)
  /// - [revenue]: Total revenue
  /// 
  /// Returns: Ratio percentage (0.0 to 1.0+)
  static double calculateOpExRatio({
    required double operatingExpenses,
    required double revenue,
  }) {
    if (revenue == 0) return 0.0;
    return operatingExpenses / revenue;
  }

  /// Calculate Return on Investment (ROI)
  /// 
  /// Formula: (Net Profit / Total Investment) × 100
  /// 
  /// Parameters:
  /// - [netProfit]: Net profit for period
  /// - [totalInvestment]: Total capital invested (inventory value)
  /// 
  /// Returns: ROI percentage (0.0 to 1.0+)
  static double calculateROI({
    required double netProfit,
    required double totalInvestment,
  }) {
    if (totalInvestment == 0) return 0.0;
    return netProfit / totalInvestment;
  }

  /// Calculate comprehensive financial summary
  /// 
  /// Returns a complete breakdown of financial health metrics
  static FinancialSummary calculateFinancialSummary({
    required double revenue,
    required double cogs,
    required double operatingExpenses,
    required double inventoryValue,
  }) {
    final grossProfit = calculateGrossProfit(
      revenue: revenue,
      cogs: cogs,
    );

    final netProfit = calculateNetProfit(
      grossProfit: grossProfit,
      operatingExpenses: operatingExpenses,
    );

    final grossMargin = calculateGrossProfitMargin(
      grossProfit: grossProfit,
      revenue: revenue,
    );

    final netMargin = calculateNetProfitMargin(
      netProfit: netProfit,
      revenue: revenue,
    );

    final opExRatio = calculateOpExRatio(
      operatingExpenses: operatingExpenses,
      revenue: revenue,
    );

    final roi = calculateROI(
      netProfit: netProfit,
      totalInvestment: inventoryValue,
    );

    return FinancialSummary(
      revenue: revenue,
      cogs: cogs,
      grossProfit: grossProfit,
      operatingExpenses: operatingExpenses,
      netProfit: netProfit,
      grossMargin: grossMargin,
      netMargin: netMargin,
      opExRatio: opExRatio,
      roi: roi,
      inventoryValue: inventoryValue,
    );
  }

  /// Analyze profit health and generate insights
  /// 
  /// Returns descriptive status and recommendations
  static ProfitHealthStatus analyzeProfitHealth({
    required double netProfit,
    required double grossMargin,
    required double opExRatio,
  }) {
    // Critical: Negative profit
    if (netProfit < 0) {
      return ProfitHealthStatus(
        status: HealthStatus.critical,
        message: 'Business is losing money. Operating expenses exceed gross profit.',
        recommendation: 'Reduce overhead costs or increase sales volume and pricing.',
      );
    }

    // Warning: Low gross margin
    if (grossMargin < 0.20) {
      return ProfitHealthStatus(
        status: HealthStatus.warning,
        message: 'Profit margin is below 20%. Product pricing may be too low.',
        recommendation: 'Review product costs and consider price adjustments.',
      );
    }

    // Warning: High operating expense ratio
    if (opExRatio > 0.40) {
      return ProfitHealthStatus(
        status: HealthStatus.warning,
        message: 'Operating expenses consume over 40% of revenue.',
        recommendation: 'Look for opportunities to reduce overhead costs.',
      );
    }

    // Healthy status
    if (grossMargin >= 0.30 && opExRatio <= 0.30) {
      return ProfitHealthStatus(
        status: HealthStatus.healthy,
        message: 'Business is performing well with healthy margins.',
        recommendation: 'Maintain current strategy and look for growth opportunities.',
      );
    }

    // Default moderate status
    return ProfitHealthStatus(
      status: HealthStatus.moderate,
      message: 'Business is profitable but has room for improvement.',
      recommendation: 'Focus on optimizing both pricing and cost control.',
    );
  }
}

/// Financial summary data class
class FinancialSummary {
  final double revenue;
  final double cogs;
  final double grossProfit;
  final double operatingExpenses;
  final double netProfit;
  final double grossMargin;
  final double netMargin;
  final double opExRatio;
  final double roi;
  final double inventoryValue;

  FinancialSummary({
    required this.revenue,
    required this.cogs,
    required this.grossProfit,
    required this.operatingExpenses,
    required this.netProfit,
    required this.grossMargin,
    required this.netMargin,
    required this.opExRatio,
    required this.roi,
    required this.inventoryValue,
  });
}

/// Profit health status data class
class ProfitHealthStatus {
  final HealthStatus status;
  final String message;
  final String recommendation;

  ProfitHealthStatus({
    required this.status,
    required this.message,
    required this.recommendation,
  });
}

enum HealthStatus {
  critical,
  warning,
  moderate,
  healthy,
}
