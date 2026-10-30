import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/constants/app_locales.dart';
import 'package:efoy_retail_app/data/models/expense_model.dart';
import 'package:efoy_retail_app/logic/providers/profit_provider.dart';
import 'package:efoy_retail_app/logic/providers/report_provider.dart';
import 'package:efoy_retail_app/ui/screens/reports_screen.dart';

/// The report behind Profile. It has to answer four questions with numbers that
/// agree with the profit tab: what was made, which products made it, what the
/// overhead was, and what went back into stock.
void main() {
  BusinessReport sample({bool empty = false}) {
    final now = DateTime(2026, 10, 29);
    return BusinessReport(
      period: ProfitPeriod.month,
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 11, 1),
      revenue: empty ? 0 : 10000,
      grossProfit: empty ? 0 : 4000,
      overhead: empty ? 0 : 1000,
      salaries: empty ? 0 : 2500,
      capital: empty ? 0 : 5000,
      cashCollected: empty ? 0 : 9000,
      outstanding: empty ? 0 : 1500,
      salesCount: empty ? 0 : 12,
      daily: empty
          ? const []
          : [
              DailyTrading(
                day: now.subtract(const Duration(days: 2)),
                revenue: 4000,
                grossProfit: 1800,
                salesCount: 5,
              ),
              DailyTrading(
                day: now.subtract(const Duration(days: 1)),
                revenue: 6000,
                grossProfit: 2200,
                salesCount: 7,
              ),
            ],
      products: empty
          ? const []
          : const [
              ProductTrend(
                productName: 'Sugar 1kg',
                quantity: 30,
                revenue: 7800,
                profit: 1800,
              ),
              ProductTrend(
                productName: 'Cooking oil 500ml',
                quantity: 8,
                revenue: 2200,
                profit: 900,
              ),
            ],
      spending: empty
          ? const []
          : const [
              CategorySpend(category: ExpenseCategory.salary, amount: 2500),
              CategorySpend(category: ExpenseCategory.rent, amount: 700),
              CategorySpend(category: ExpenseCategory.transport, amount: 300),
            ],
      restocks: empty
          ? const []
          : [
              RestockEntry(
                productName: 'Sugar 1kg',
                quantity: 40,
                totalCost: 5000,
                date: now.subtract(const Duration(days: 5)),
              ),
            ],
    );
  }

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    BusinessReport? report,
    Locale locale = const Locale('en'),
  }) async {
    final container = ProviderContainer(
      overrides: [
        businessReportProvider.overrideWith(
          (ref) => Stream.value(report ?? sample()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: locale,
          supportedLocales: appSupportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: const ReportsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('profit window', () {
    testWidgets('shows the margin after overhead and salaries', (tester) async {
      await pump(tester);

      expect(find.text('REPORT'), findsOneWidget);
      expect(find.text('PROFIT FOR THE PERIOD'), findsOneWidget);
      // 4,000 margin - 1,000 overhead - 2,500 salaries = 500.
      expect(find.text('500.00'), findsOneWidget);
      expect(find.text('Less overhead'), findsOneWidget);
      expect(find.text('-1,000.00 ብር'), findsOneWidget);
      expect(find.text('Less salaries'), findsOneWidget);
      expect(find.text('-2,500.00 ብር'), findsOneWidget);
      expect(find.text('Cash taken'), findsOneWidget);
      expect(find.text('Still with customers'), findsOneWidget);
    });
  });

  group('product trends', () {
    testWidgets('ranks products and shows what each brought in', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Product trends'), findsOneWidget);
      expect(find.text('Sugar 1kg'), findsWidgets);
      expect(find.text('Cooking oil 500ml'), findsOneWidget);
      expect(find.textContaining('30 sold'), findsOneWidget);
      expect(find.text('1,800.00 ብር'), findsWidgets);
    });
  });

  group('costs and restock', () {
    testWidgets('lists overhead by category and keeps restock separate', (
      tester,
    ) async {
      await pump(tester);

      expect(find.text('Operational costs'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Total operating'), findsOneWidget);
      expect(find.text('3,500.00 ብር'), findsWidgets);

      expect(find.text('Restock history'), findsOneWidget);
      expect(find.textContaining('40 units'), findsOneWidget);
      expect(find.textContaining('is capital, not an expense'), findsOneWidget);
    });

    testWidgets('speaks Amharic when the app does', (tester) async {
      await pump(tester, locale: const Locale('am'));

      expect(find.text('ሪፖርት'), findsOneWidget);
      expect(find.text('የስራ ወጪዎች'), findsOneWidget);
      expect(find.text('ደሞዝ'), findsOneWidget);
      expect(find.text('የእቃ መሙላት ታሪክ'), findsOneWidget);
    });
  });

  group('an empty period', () {
    testWidgets('explains that nothing has been recorded yet', (tester) async {
      await pump(tester, report: sample(empty: true));

      expect(find.text('0.00'), findsOneWidget);
      expect(find.textContaining('No products sold'), findsOneWidget);
      expect(find.textContaining('No rent, wages'), findsOneWidget);
      expect(find.text('Restock history'), findsNothing);
    });
  });

  group('the range', () {
    testWidgets('switching to the week asks the provider for the week', (
      tester,
    ) async {
      final container = await pump(tester);

      expect(container.read(reportRangeProvider), ProfitPeriod.month);

      await tester.tap(find.text('Last 7 days'));
      await tester.pumpAndSettle();

      expect(container.read(reportRangeProvider), ProfitPeriod.week);
    });
  });
}
