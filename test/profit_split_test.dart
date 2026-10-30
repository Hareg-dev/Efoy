import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/data/repositories/expense_repository.dart';
import 'package:efoy_retail_app/data/repositories/sale_repository.dart';
import 'package:efoy_retail_app/logic/providers/profit_provider.dart';

/// What each profit view is allowed to subtract.
///
/// A shop does not pay rent three times a day and salaries are monthly money,
/// so the three tabs answer three different questions. These tests pin the
/// rule down without a database: selling minus cost is the day, overhead
/// belongs to the week, salaries to the month, and restock is never subtracted
/// because it turned into stock rather than leaving the business.
void main() {
  // 10,000 sold, 6,000 cost, so 4,000 earned.
  const sales = SalesTotals(
    revenue: 10000,
    cost: 6000,
    grossProfit: 4000,
    count: 12,
    cashCollected: 9000,
  );

  // 500 rent + 200 transport + 300 airtime = 1,000 overhead, 2,500 salaries,
  // and 5,000 spent restocking the shelves.
  const expenses = ExpenseTotals(
    total: 8500,
    operatingTotal: 3500,
    capitalTotal: 5000,
    salaryTotal: 2500,
  );

  group('today', () {
    test('is selling minus cost and nothing else', () {
      final data = buildPeriodProfit(
        sales: sales,
        expenses: expenses,
        period: ProfitPeriod.today,
        settledLater: 200,
      );

      expect(data.grossProfit, 4000);
      expect(data.overhead, 0);
      expect(data.salaries, 0);
      expect(data.opex, 0);
      expect(data.netProfit, 4000);
      expect(data.countsGrossOnly, isTrue);
    });

    test('still shows cash taken and what is out on credit', () {
      final data = buildPeriodProfit(
        sales: sales,
        expenses: expenses,
        period: ProfitPeriod.today,
        settledLater: 200,
        outstanding: 1500,
      );

      expect(data.cashCollected, 9200);
      expect(data.outstanding, 1500);
    });
  });

  group('week', () {
    test('subtracts rent, transport and other overhead but not salaries', () {
      final data = buildPeriodProfit(
        sales: sales,
        expenses: expenses,
        period: ProfitPeriod.week,
      );

      expect(data.overhead, 1000);
      expect(data.salaries, 0);
      expect(data.opex, 1000);
      expect(data.netProfit, 3000);
      expect(data.countsGrossOnly, isFalse);
    });
  });

  group('month', () {
    test('subtracts overhead and the monthly salaries', () {
      final data = buildPeriodProfit(
        sales: sales,
        expenses: expenses,
        period: ProfitPeriod.month,
      );

      expect(data.overhead, 1000);
      expect(data.salaries, 2500);
      expect(data.opex, 3500);
      expect(data.netProfit, 500);
    });

    test('a slow month can go negative once wages are paid', () {
      final data = buildPeriodProfit(
        sales: const SalesTotals(
          revenue: 6000,
          cost: 5000,
          grossProfit: 1000,
          count: 5,
          cashCollected: 6000,
        ),
        expenses: expenses,
        period: ProfitPeriod.month,
      );

      expect(data.netProfit, -2500);
    });
  });

  test('restock is reported but never subtracted in any view', () {
    for (final period in ProfitPeriod.values) {
      final data = buildPeriodProfit(
        sales: sales,
        expenses: expenses,
        period: period,
      );
      expect(data.restockCapital, 5000);
      expect(
        data.opex,
        lessThanOrEqualTo(3500),
        reason: 'capital spend must stay out of the deducted total',
      );
    }
  });
}
