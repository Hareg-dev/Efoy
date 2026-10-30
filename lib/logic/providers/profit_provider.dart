import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../data/models/debt_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/debt_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/sale_repository.dart';
import 'database_provider.dart';
import 'repository_providers.dart';

enum ProfitPeriod { today, week, month }

final profitPeriodProvider = StateProvider<ProfitPeriod>(
  (ref) => ProfitPeriod.today,
);

final netProfitProvider = StreamProvider<NetProfitData>((ref) async* {
  final isar = await ref.watch(databaseProvider.future);
  final saleRepository = await ref.watch(saleRepositoryProvider.future);
  final expenseRepository = await ref.watch(expenseRepositoryProvider.future);
  final debtRepository = await ref.watch(debtRepositoryProvider.future);
  final period = ref.watch(profitPeriodProvider);
  final changes = StreamController<void>();
  final subscriptions = <StreamSubscription<void>>[
    isar.saleModels.watchLazy(fireImmediately: true).listen((_) {
      changes.add(null);
    }),
    isar.expenseModels.watchLazy(fireImmediately: true).listen((_) {
      changes.add(null);
    }),
    isar.debtModels.watchLazy(fireImmediately: true).listen((_) {
      changes.add(null);
    }),
  ];

  try {
    await for (final _ in changes.stream) {
      yield await _loadNetProfit(
        saleRepository,
        expenseRepository,
        debtRepository,
        period,
      );
    }
  } finally {
    await Future.wait(
      subscriptions.map((subscription) => subscription.cancel()),
    );
    await changes.close();
  }
});

final dashboardSummaryProvider = StreamProvider<DashboardSummary>((ref) async* {
  final isar = await ref.watch(databaseProvider.future);
  final changes = StreamController<void>();
  final subscriptions = <StreamSubscription<void>>[
    isar.saleModels.watchLazy(fireImmediately: true).listen((_) {
      changes.add(null);
    }),
    isar.productModels.watchLazy(fireImmediately: true).listen((_) {
      changes.add(null);
    }),
  ];

  try {
    await for (final _ in changes.stream) {
      yield await _loadDashboardSummary(isar);
    }
  } finally {
    await Future.wait(
      subscriptions.map((subscription) => subscription.cancel()),
    );
    await changes.close();
  }
});

/// What each view is allowed to subtract.
///
/// A day is judged on the margin it earned - a shop does not pay rent three
/// times a day. Overhead belongs to the week it was spent in, and salaries are
/// monthly money, so only the month view takes them out. Restock is capital
/// either way and never appears here.
Future<NetProfitData> _loadNetProfit(
  SaleRepository saleRepository,
  ExpenseRepository expenseRepository,
  DebtRepository debtRepository,
  ProfitPeriod period,
) async {
  final (startDate, endDate) = periodBounds(DateTime.now(), period);
  final sales = await saleRepository.getTotalsByPeriod(startDate, endDate);
  final expenses = await expenseRepository.getTotalsByPeriod(
    startDate,
    endDate,
  );
  final collectedLater = await debtRepository.settledBetween(
    startDate,
    endDate,
  );
  final outstanding = await debtRepository.openBalanceBetween(
    startDate,
    endDate,
  );

  return buildPeriodProfit(
    sales: sales,
    expenses: expenses,
    settledLater: collectedLater,
    outstanding: outstanding,
    period: period,
  );
}

/// The period rule on its own, so the three answers can be checked without a
/// database: today subtracts nothing, the week subtracts overhead, the month
/// subtracts overhead and salaries.
NetProfitData buildPeriodProfit({
  required SalesTotals sales,
  required ExpenseTotals expenses,
  required ProfitPeriod period,
  double settledLater = 0,
  double outstanding = 0,
}) {
  final subtractsOverhead = period != ProfitPeriod.today;
  final subtractsSalaries = period == ProfitPeriod.month;
  final overhead = subtractsOverhead ? expenses.overheadTotal : 0.0;
  final salaries = subtractsSalaries ? expenses.salaryTotal : 0.0;

  return NetProfitData(
    netProfit: sales.grossProfit - overhead - salaries,
    grossProfit: sales.grossProfit,
    revenue: sales.revenue,
    opex: overhead + salaries,
    salesCount: sales.count,
    period: period,
    overhead: overhead,
    salaries: salaries,
    cashCollected: sales.cashCollected + settledLater,
    outstanding: outstanding,
    restockCapital: expenses.capitalTotal,
  );
}

Future<DashboardSummary> _loadDashboardSummary(Isar isar) async {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  final sales = await isar.saleModels
      .filter()
      .saleDateBetween(startOfDay, endOfDay, includeUpper: false)
      .isVoidedEqualTo(false)
      .sortBySaleDateDesc()
      .findAll();
  final products = await isar.productModels
      .filter()
      .isDeletedEqualTo(false)
      .findAll();

  final needsRestockProducts =
      products.where((product) => product.needsRestock).toList()
        ..sort((a, b) => a.currentStock.compareTo(b.currentStock));
  final salesAmount = sales.fold<double>(
    0,
    (sum, sale) => sum + sale.totalAmount,
  );
  final grossProfit = sales.fold<double>(
    0,
    (sum, sale) => sum + sale.grossProfit,
  );

  return DashboardSummary(
    transactionCount: sales.length,
    salesAmount: salesAmount,
    needsRestockProducts: needsRestockProducts,
    recentSales: sales.take(3).toList(),
    grossProfitMargin: salesAmount > 0 ? grossProfit / salesAmount : null,
  );
}

/// Half-open [start, end) bounds for a profit period, using the local
/// calendar. Weeks start on Monday.
(DateTime, DateTime) periodBounds(DateTime now, ProfitPeriod period) {
  switch (period) {
    case ProfitPeriod.today:
      final start = DateTime(now.year, now.month, now.day);
      return (start, start.add(const Duration(days: 1)));
    case ProfitPeriod.week:
      final today = DateTime(now.year, now.month, now.day);
      final start = today.subtract(Duration(days: now.weekday - 1));
      return (start, start.add(const Duration(days: 7)));
    case ProfitPeriod.month:
      final start = DateTime(now.year, now.month);
      return (start, DateTime(now.year, now.month + 1));
  }
}

class NetProfitData {
  const NetProfitData({
    required this.netProfit,
    required this.grossProfit,
    required this.revenue,
    required this.opex,
    required this.salesCount,
    required this.period,
    this.overhead = 0,
    this.salaries = 0,
    this.cashCollected = 0,
    this.outstanding = 0,
    this.restockCapital = 0,
  });

  final double netProfit;
  final double grossProfit;
  final double revenue;

  /// Everything actually subtracted from the margin: [overhead] + [salaries].
  final double opex;

  /// Rent, transport, utilities, airtime, supplies and other - week and month.
  final double overhead;

  /// Wages - month only, because they are paid monthly.
  final double salaries;

  /// Money that reached the till in this period, counter payments plus later
  /// settle-ups. Profit is counted on the invoice, so this is the cash view.
  final double cashCollected;

  /// Balances from this period's selling that are still with customers.
  final double outstanding;

  /// Money spent buying stock. Never subtracted: it turned into inventory.
  final double restockCapital;

  final int salesCount;
  final ProfitPeriod period;

  /// A day only shows selling minus cost, so the card can say what was left out.
  bool get countsGrossOnly => period == ProfitPeriod.today;

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

class DashboardSummary {
  const DashboardSummary({
    required this.transactionCount,
    required this.salesAmount,
    required this.needsRestockProducts,
    required this.recentSales,
    required this.grossProfitMargin,
  });

  final int transactionCount;
  final double salesAmount;

  /// Products at or below their threshold, sold-out ones included.
  final List<ProductModel> needsRestockProducts;
  final List<SaleModel> recentSales;
  final double? grossProfitMargin;
}
