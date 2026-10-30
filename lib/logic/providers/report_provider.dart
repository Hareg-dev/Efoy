import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../data/models/debt_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/restock_log_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/debt_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/sale_repository.dart';
import 'database_provider.dart';
import 'profit_provider.dart';
import 'repository_providers.dart';

/// The window the business report looks through.
final reportRangeProvider = StateProvider<ProfitPeriod>(
  (ref) => ProfitPeriod.month,
);

/// One day of trading, so the report can show a trend rather than a total.
class DailyTrading {
  const DailyTrading({
    required this.day,
    required this.revenue,
    required this.grossProfit,
    required this.salesCount,
  });

  final DateTime day;
  final double revenue;
  final double grossProfit;
  final int salesCount;
}

/// How much one product contributed to the period.
class ProductTrend {
  const ProductTrend({
    required this.productName,
    required this.quantity,
    required this.revenue,
    required this.profit,
  });

  final String productName;
  final int quantity;
  final double revenue;
  final double profit;
}

/// What one expense category cost, for the breakdown table.
class CategorySpend {
  const CategorySpend({required this.category, required this.amount});

  final ExpenseCategory category;
  final double amount;
}

/// A restock the merchant paid for, kept visible even though it never touches
/// profit: the money did leave the till, it just turned into stock.
class RestockEntry {
  const RestockEntry({
    required this.productName,
    required this.quantity,
    required this.totalCost,
    required this.date,
  });

  final String productName;
  final int quantity;
  final double totalCost;
  final DateTime date;
}

class BusinessReport {
  const BusinessReport({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.revenue,
    required this.grossProfit,
    required this.overhead,
    required this.salaries,
    required this.capital,
    required this.cashCollected,
    required this.outstanding,
    required this.salesCount,
    required this.daily,
    required this.products,
    required this.spending,
    required this.restocks,
  });

  final ProfitPeriod period;
  final DateTime startDate;
  final DateTime endDate;
  final double revenue;
  final double grossProfit;
  final double overhead;
  final double salaries;
  final double capital;
  final double cashCollected;
  final double outstanding;
  final int salesCount;
  final List<DailyTrading> daily;
  final List<ProductTrend> products;
  final List<CategorySpend> spending;
  final List<RestockEntry> restocks;

  double get deducted => overhead + salaries;
  double get netProfit => grossProfit - deducted;
  double get restockTotal =>
      restocks.fold(0.0, (sum, entry) => sum + entry.totalCost);
}

/// Rebuilt whenever sales, expenses, stock or settle-ups change, so a report
/// left open on the counter follows the till.
final businessReportProvider = StreamProvider<BusinessReport>((ref) async* {
  final isar = await ref.watch(databaseProvider.future);
  final saleRepository = await ref.watch(saleRepositoryProvider.future);
  final expenseRepository = await ref.watch(expenseRepositoryProvider.future);
  final debtRepository = await ref.watch(debtRepositoryProvider.future);
  final period = ref.watch(reportRangeProvider);
  final changes = StreamController<void>();
  final subscriptions = <StreamSubscription<void>>[
    isar.saleModels.watchLazy(fireImmediately: true).listen((_) {
      changes.add(null);
    }),
    isar.expenseModels.watchLazy(fireImmediately: true).listen((_) {
      changes.add(null);
    }),
    isar.restockLogModels.watchLazy(fireImmediately: true).listen((_) {
      changes.add(null);
    }),
    isar.debtModels.watchLazy(fireImmediately: true).listen((_) {
      changes.add(null);
    }),
  ];

  try {
    await for (final _ in changes.stream) {
      yield await _buildReport(
        isar: isar,
        saleRepository: saleRepository,
        expenseRepository: expenseRepository,
        debtRepository: debtRepository,
        period: period,
        now: DateTime.now(),
      );
    }
  } finally {
    await Future.wait(
      subscriptions.map((subscription) => subscription.cancel()),
    );
    await changes.close();
  }
});

Future<BusinessReport> _buildReport({
  required Isar isar,
  required SaleRepository saleRepository,
  required ExpenseRepository expenseRepository,
  required DebtRepository debtRepository,
  required ProfitPeriod period,
  required DateTime now,
}) async {
  final (startDate, endDate) = periodBounds(now, period);

  final salesTotals = await saleRepository.getTotalsByPeriod(
    startDate,
    endDate,
  );
  final expenseTotals = await expenseRepository.getTotalsByPeriod(
    startDate,
    endDate,
  );
  final settledLater = await debtRepository.settledBetween(startDate, endDate);
  final outstanding = await debtRepository.openBalanceBetween(
    startDate,
    endDate,
  );

  final sales = await isar.saleModels
      .filter()
      .saleDateBetween(startDate, endDate, includeUpper: false)
      .isVoidedEqualTo(false)
      .findAll();
  final expenses = await isar.expenseModels
      .filter()
      .expenseDateBetween(startDate, endDate, includeUpper: false)
      .isDeletedEqualTo(false)
      .findAll();
  final restocks = await isar.restockLogModels
      .filter()
      .restockDateBetween(startDate, endDate, includeUpper: false)
      .sortByRestockDateDesc()
      .findAll();

  return BusinessReport(
    period: period,
    startDate: startDate,
    endDate: endDate,
    revenue: salesTotals.revenue,
    grossProfit: salesTotals.grossProfit,
    overhead: expenseTotals.overheadTotal,
    salaries: expenseTotals.salaryTotal,
    capital: expenseTotals.capitalTotal,
    cashCollected: salesTotals.cashCollected + settledLater,
    outstanding: outstanding,
    salesCount: salesTotals.count,
    daily: _dailySeries(sales, startDate, endDate),
    products: _productTrends(sales),
    spending: _categorySpending(expenses),
    restocks: [
      for (final log in restocks.take(12))
        RestockEntry(
          productName: log.productName,
          quantity: log.quantityAdded,
          totalCost: log.totalCost,
          date: log.restockDate,
        ),
    ],
  );
}

/// One row per calendar day in the range, zero-filled so the trend line has no
/// gaps on days the shop did not trade.
List<DailyTrading> _dailySeries(
  List<SaleModel> sales,
  DateTime startDate,
  DateTime endDate,
) {
  final byDay = <DateTime, DailyTrading>{};
  final dayCount = endDate.difference(startDate).inDays;
  for (var index = 0; index < dayCount; index++) {
    final day = DateTime(
      startDate.year,
      startDate.month,
      startDate.day + index,
    );
    byDay[day] = DailyTrading(
      day: day,
      revenue: 0,
      grossProfit: 0,
      salesCount: 0,
    );
  }

  for (final sale in sales) {
    final day = DateTime(
      sale.saleDate.year,
      sale.saleDate.month,
      sale.saleDate.day,
    );
    final existing = byDay[day];
    if (existing == null) continue;
    byDay[day] = DailyTrading(
      day: day,
      revenue: existing.revenue + sale.totalAmount,
      grossProfit: existing.grossProfit + sale.grossProfit,
      salesCount: existing.salesCount + 1,
    );
  }

  return byDay.values.toList()..sort((a, b) => a.day.compareTo(b.day));
}

/// Products ranked by the money they made, not just the units they moved.
List<ProductTrend> _productTrends(List<SaleModel> sales) {
  final byName = <String, ProductTrend>{};
  for (final sale in sales) {
    for (final line in sale.lineItems) {
      final existing = byName[line.productName];
      byName[line.productName] = ProductTrend(
        productName: line.productName,
        quantity: (existing?.quantity ?? 0) + line.quantity,
        revenue: (existing?.revenue ?? 0) + line.lineTotal,
        profit: (existing?.profit ?? 0) + line.lineProfit,
      );
    }
  }

  final ranked = byName.values.toList()
    ..sort((a, b) => b.profit.compareTo(a.profit));
  return ranked.take(8).toList();
}

/// Operating spend grouped by category, biggest first. Restock is excluded on
/// purpose: it is capital, and the report shows it in its own section.
List<CategorySpend> _categorySpending(List<ExpenseModel> expenses) {
  final byCategory = <ExpenseCategory, double>{};
  for (final expense in expenses) {
    if (expense.isRestockExpense) continue;
    byCategory.update(
      expense.category,
      (value) => value + expense.amount,
      ifAbsent: () => expense.amount,
    );
  }

  final lines = [
    for (final entry in byCategory.entries)
      CategorySpend(category: entry.key, amount: entry.value),
  ]..sort((a, b) => b.amount.compareTo(a.amount));
  return lines;
}
