import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/expense_model.dart';
import 'database_provider.dart';

// Period filter enum
enum ProfitPeriod { today, week, month }

// Period filter provider
final profitPeriodProvider = StateProvider<ProfitPeriod>((ref) => ProfitPeriod.today);

// Net profit data provider
final netProfitProvider = FutureProvider<NetProfitData>((ref) async {
  final isar = await ref.watch(databaseProvider.future);
  final period = ref.watch(profitPeriodProvider);
  
  final now = DateTime.now();
  final DateTime startDate;
  
  switch (period) {
    case ProfitPeriod.today:
      startDate = DateTime(now.year, now.month, now.day);
      break;
    case ProfitPeriod.week:
      startDate = now.subtract(Duration(days: now.weekday - 1));
      break;
    case ProfitPeriod.month:
      startDate = DateTime(now.year, now.month, 1);
      break;
  }
  
  // Get sales in period
  final sales = await isar.saleModels
      .filter()
      .saleDateGreaterThan(startDate)
      .isVoidedEqualTo(false)
      .findAll();
  
  // Get operating expenses in period (exclude restock CapEx)
  final expenses = await isar.expenseModels
      .filter()
      .expenseDateGreaterThan(startDate)
      .isRestockExpenseEqualTo(false) // Only OpEx for profit
      .findAll();
  
  // Calculate totals
  final revenue = sales.fold<double>(0, (sum, sale) => sum + sale.totalAmount);
  final salesProfit = sales.fold<double>(0, (sum, sale) => sum + sale.grossProfit);
  final opex = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
  
  // Net Profit = Gross Profit from Sales - Operating Expenses
  final netProfit = salesProfit - opex;
  
  return NetProfitData(
    netProfit: netProfit,
    revenue: revenue,
    opex: opex,
    salesCount: sales.length,
    period: period,
  );
});

// Net profit data model
class NetProfitData {
  final double netProfit;
  final double revenue;
  final double opex;
  final int salesCount;
  final ProfitPeriod period;
  
  NetProfitData({
    required this.netProfit,
    required this.revenue,
    required this.opex,
    required this.salesCount,
    required this.period,
  });
  
  String get periodLabel {
    switch (period) {
      case ProfitPeriod.today:
        return 'Today';
      case ProfitPeriod.week:
        return 'This Week';
      case ProfitPeriod.month:
        return 'This Month';
    }
  }
  
  String get periodLabelAm {
    switch (period) {
      case ProfitPeriod.today:
        return 'ዛሬ';
      case ProfitPeriod.week:
        return 'ዚህ ሳምንት';
      case ProfitPeriod.month:
        return 'ዚህ ወር';
    }
  }
}
