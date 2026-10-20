import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../data/models/expense_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/sale_repository.dart';
import 'database_provider.dart';
import 'repository_providers.dart';

enum ProfitPeriod { today, week, month }

final profitPeriodProvider =
    StateProvider<ProfitPeriod>((ref) => ProfitPeriod.today);

final netProfitProvider = StreamProvider<NetProfitData>((ref) async* {
  final isar = await ref.watch(databaseProvider.future);
  final saleRepository = await ref.watch(saleRepositoryProvider.future);
  final expenseRepository = await ref.watch(expenseRepositoryProvider.future);
  final period = ref.watch(profitPeriodProvider);
  final changes = StreamController<void>();
  final subscriptions = <StreamSubscription<void>>[
    isar.saleModels.watchLazy(fireImmediately: true).listen((_) {
      changes.add(null);
    }),
    isar.expenseModels.watchLazy(fireImmediately: true).listen((_) {
      changes.add(null);
    }),
  ];

  try {
    await for (final _ in changes.stream) {
      yield await _loadNetProfit(saleRepository, expenseRepository, period);
    }
  } finally {
    await Future.wait(subscriptions.map((subscription) => subscription.cancel()));
    await changes.close();
  }
});

final dashboardSummaryProvider =
    StreamProvider<DashboardSummary>((ref) async* {
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
    await Future.wait(subscriptions.map((subscription) => subscription.cancel()));
    await changes.close();
  }
});

Future<NetProfitData> _loadNetProfit(
  SaleRepository saleRepository,
  ExpenseRepository expenseRepository,
  ProfitPeriod period,
) async {
  final (startDate, endDate) = periodBounds(DateTime.now(), period);
  final sales = await saleRepository.getTotalsByPeriod(startDate, endDate);
  final expenses =
      await expenseRepository.getTotalsByPeriod(startDate, endDate);

  return NetProfitData(
    netProfit: sales.grossProfit - expenses.operatingTotal,
    grossProfit: sales.grossProfit,
    revenue: sales.revenue,
    opex: expenses.operatingTotal,
    salesCount: sales.count,
    period: period,
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

  final lowStockProducts = products
      .where((product) => product.currentStock <= product.lowStockThreshold)
      .toList()
    ..sort((a, b) => a.currentStock.compareTo(b.currentStock));
  final salesAmount =
      sales.fold<double>(0, (sum, sale) => sum + sale.totalAmount);
  final grossProfit =
      sales.fold<double>(0, (sum, sale) => sum + sale.grossProfit);

  return DashboardSummary(
    transactionCount: sales.length,
    salesAmount: salesAmount,
    lowStockProducts: lowStockProducts,
    recentSales: sales.take(3).toList(),
    grossProfitMargin: salesAmount > 0 ? grossProfit / salesAmount : null,
  );
}

/// Half-open [start, end) bounds for a profit period, using the local
/// calendar. Weeks start on Monday.
@visibleForTesting
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
  });

  final double netProfit;
  final double grossProfit;
  final double revenue;
  final double opex;
  final int salesCount;
  final ProfitPeriod period;

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
    required this.lowStockProducts,
    required this.recentSales,
    required this.grossProfitMargin,
  });

  final int transactionCount;
  final double salesAmount;
  final List<ProductModel> lowStockProducts;
  final List<SaleModel> recentSales;
  final double? grossProfitMargin;
}
