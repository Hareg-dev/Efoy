import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/logic/calculators/profit_engine.dart';

void main() {
  group('ProfitEngine profit calculations', () {
    test('gross profit is revenue minus COGS', () {
      expect(
        ProfitEngine.calculateGrossProfit(revenue: 10000, cogs: 6000),
        4000,
      );
    });

    test('net profit is gross profit minus operating expenses only', () {
      // Restocking is capital expenditure (cash → inventory) and is excluded
      // from operating expenses, so it never reaches this subtraction.
      const revenue = 10000.0;
      const cogs = 6000.0;
      const operatingExpenses = 1500.0;
      const restockCapital = 8000.0;

      final gross = ProfitEngine.calculateGrossProfit(
        revenue: revenue,
        cogs: cogs,
      );
      final net = ProfitEngine.calculateNetProfit(
        grossProfit: gross,
        operatingExpenses: operatingExpenses,
      );

      expect(net, 2500);
      expect(net, isNot(gross - operatingExpenses - restockCapital));
    });

    test('net profit can be negative when overhead exceeds gross profit', () {
      final net = ProfitEngine.calculateNetProfit(
        grossProfit: 800,
        operatingExpenses: 1500,
      );

      expect(net, -700);
    });
  });

  group('ProfitEngine margins and ratios', () {
    test('calculates gross and net margins', () {
      expect(
        ProfitEngine.calculateGrossProfitMargin(
          grossProfit: 4000,
          revenue: 10000,
        ),
        closeTo(0.4, 1e-9),
      );
      expect(
        ProfitEngine.calculateNetProfitMargin(
          netProfit: 2500,
          revenue: 10000,
        ),
        closeTo(0.25, 1e-9),
      );
    });

    test('returns zero margins when revenue is zero', () {
      expect(
        ProfitEngine.calculateGrossProfitMargin(grossProfit: 0, revenue: 0),
        0,
      );
      expect(
        ProfitEngine.calculateNetProfitMargin(netProfit: 0, revenue: 0),
        0,
      );
      expect(
        ProfitEngine.calculateOpExRatio(operatingExpenses: 500, revenue: 0),
        0,
      );
    });

    test('calculates operating expense ratio', () {
      expect(
        ProfitEngine.calculateOpExRatio(
          operatingExpenses: 1500,
          revenue: 10000,
        ),
        closeTo(0.15, 1e-9),
      );
    });

    test('calculates ROI against inventory investment', () {
      expect(
        ProfitEngine.calculateROI(netProfit: 2500, totalInvestment: 20000),
        closeTo(0.125, 1e-9),
      );
      expect(
        ProfitEngine.calculateROI(netProfit: 2500, totalInvestment: 0),
        0,
      );
    });
  });

  group('ProfitEngine.calculateFinancialSummary', () {
    test('builds a complete, internally consistent breakdown', () {
      final summary = ProfitEngine.calculateFinancialSummary(
        revenue: 10000,
        cogs: 6000,
        operatingExpenses: 1500,
        inventoryValue: 20000,
      );

      expect(summary.revenue, 10000);
      expect(summary.cogs, 6000);
      expect(summary.grossProfit, 4000);
      expect(summary.operatingExpenses, 1500);
      expect(summary.netProfit, 2500);
      expect(summary.grossMargin, closeTo(0.4, 1e-9));
      expect(summary.netMargin, closeTo(0.25, 1e-9));
      expect(summary.opExRatio, closeTo(0.15, 1e-9));
      expect(summary.roi, closeTo(0.125, 1e-9));
      expect(summary.inventoryValue, 20000);
    });

    test('handles a period with no sales', () {
      final summary = ProfitEngine.calculateFinancialSummary(
        revenue: 0,
        cogs: 0,
        operatingExpenses: 500,
        inventoryValue: 12000,
      );

      expect(summary.grossProfit, 0);
      expect(summary.netProfit, -500);
      expect(summary.grossMargin, 0);
      expect(summary.netMargin, 0);
      expect(summary.opExRatio, 0);
    });
  });

  group('ProfitEngine.analyzeProfitHealth', () {
    test('flags a loss as critical', () {
      final health = ProfitEngine.analyzeProfitHealth(
        netProfit: -100,
        grossMargin: 0.35,
        opExRatio: 0.2,
      );

      expect(health.status, HealthStatus.critical);
    });

    test('warns when gross margin is below 20%', () {
      final health = ProfitEngine.analyzeProfitHealth(
        netProfit: 200,
        grossMargin: 0.15,
        opExRatio: 0.1,
      );

      expect(health.status, HealthStatus.warning);
    });

    test('warns when operating expenses exceed 40% of revenue', () {
      final health = ProfitEngine.analyzeProfitHealth(
        netProfit: 200,
        grossMargin: 0.35,
        opExRatio: 0.45,
      );

      expect(health.status, HealthStatus.warning);
    });

    test('reports healthy when margins are strong and overhead is low', () {
      final health = ProfitEngine.analyzeProfitHealth(
        netProfit: 2500,
        grossMargin: 0.35,
        opExRatio: 0.2,
      );

      expect(health.status, HealthStatus.healthy);
    });

    test('reports moderate for profitable but unremarkable margins', () {
      final health = ProfitEngine.analyzeProfitHealth(
        netProfit: 500,
        grossMargin: 0.25,
        opExRatio: 0.35,
      );

      expect(health.status, HealthStatus.moderate);
    });
  });
}
