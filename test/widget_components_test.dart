import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/constants/app_colors.dart';
import 'package:efoy_retail_app/logic/providers/profit_provider.dart';
import 'package:efoy_retail_app/ui/animations/pulsing_dot.dart';
import 'package:efoy_retail_app/ui/widgets/alert_card.dart';
import 'package:efoy_retail_app/ui/widgets/net_profit_card.dart';

void main() {
  group('NetProfitCard', () {
    NetProfitData sampleData() {
      return const NetProfitData(
        netProfit: 1800,
        grossProfit: 3000,
        revenue: 5000,
        opex: 1200,
        salesCount: 4,
        period: ProfitPeriod.today,
      );
    }

    testWidgets('renders profit, breakdown, gradient and SYNCED indicator',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          netProfitProvider.overrideWith((ref) => Stream.value(sampleData())),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: NetProfitCard()),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('NET PROFIT · TODAY'), findsOneWidget);
      expect(find.text('1,800.00'), findsOneWidget);
      expect(find.text('5,000.00 ብር'), findsOneWidget);
      expect(find.text('1,200.00 ብር'), findsOneWidget);
      expect(find.text('SYNCED'), findsOneWidget);
      expect(find.byType(PulsingDot), findsOneWidget);

      final gradient = tester
          .widgetList<Container>(find.byType(Container))
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.gradient)
          .whereType<RadialGradient>();
      expect(gradient, isNotEmpty);
    });

    testWidgets('period pills update the selected period', (tester) async {
      final container = ProviderContainer(
        overrides: [
          netProfitProvider.overrideWith((ref) => Stream.value(sampleData())),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: NetProfitCard()),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(container.read(profitPeriodProvider), ProfitPeriod.today);

      await tester.tap(find.text('Week'));
      await tester.pump();

      expect(container.read(profitPeriodProvider), ProfitPeriod.week);

      await tester.tap(find.text('Month'));
      await tester.pump();

      expect(container.read(profitPeriodProvider), ProfitPeriod.month);
    });
  });

  group('AlertCard', () {
    testWidgets('amber card renders badge, pulse and action', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertCard(
              type: AlertType.amber,
              icon: Icons.inventory_2_outlined,
              title: 'INVENTORY LOW',
              subtitle: 'Sugar 1kg needs restocking',
              actionLabel: 'View all',
              onAction: () => tapped = true,
              showPulse: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('INVENTORY LOW'), findsOneWidget);
      expect(find.text('Sugar 1kg needs restocking'), findsOneWidget);
      expect(find.byType(PulsingDot), findsOneWidget);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.inventory_2_outlined)).color,
        AppColors.alertAmber,
      );

      await tester.tap(find.text('View all'));
      expect(tapped, isTrue);
    });

    testWidgets('crimson card uses the alert accent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertCard(
              type: AlertType.crimson,
              icon: Icons.warning_amber_rounded,
              title: 'PROFIT HEALTH: CAUTION',
              subtitle: 'Margin is below 5%',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PulsingDot), findsNothing);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.warning_amber_rounded)).color,
        AppColors.alertRed,
      );
    });

    testWidgets('dark card renders on the dark surface with light accent',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertCard(
              type: AlertType.dark,
              icon: Icons.point_of_sale_outlined,
              title: '0 TRANSACTIONS TODAY',
              subtitle: 'Record your first sale',
            ),
          ),
        ),
      );
      await tester.pump();

      final cardColor = tester
          .widgetList<Container>(find.byType(Container))
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.color)
          .firstWhere((color) => color == AppColors.darkCard);
      expect(cardColor, AppColors.darkCard);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.point_of_sale_outlined)).color,
        Colors.white,
      );
    });
  });
}
