import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/constants/app_locales.dart';
import 'package:efoy_retail_app/ui/widgets/bottom_nav_bar.dart';
import 'package:efoy_retail_app/ui/widgets/screen_header.dart';

void main() {
  group('ScreenHeader', () {
    testWidgets('shows title, subtitle and one trailing action', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ScreenHeader(
            title: 'INVENTORY',
            subtitle: '12 products tracked',
            actions: [Icon(Icons.add)],
          ),
        ),
      );

      expect(find.text('INVENTORY'), findsOneWidget);
      expect(find.text('12 products tracked'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('renders the leading brand mark when one is supplied', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const Scaffold(
            body: ScreenHeader(
              title: 'SETTINGS',
              leading: HeaderBrand(child: Icon(Icons.check)),
            ),
          ),
        ),
      );

      expect(find.byType(HeaderBrand), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('AppBottomNavBar', () {
    Future<void> pumpBar(
      WidgetTester tester, {
      required Locale locale,
      required ValueChanged<int> onTap,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: appSupportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: Scaffold(
            body: const SizedBox(height: 400),
            bottomNavigationBar: AppBottomNavBar(
              currentIndex: 0,
              onTap: onTap,
            ),
          ),
        ),
      );
    }

    testWidgets('the five tabs keep the standard order and captions', (
      tester,
    ) async {
      final taps = <int>[];
      await pumpBar(tester, locale: const Locale('en'), onTap: taps.add);

      expect(find.byType(NavigationBar), findsOneWidget);
      for (final label in ['Home', 'Sell', 'Inventory', 'Expenses', 'Profile']) {
        expect(find.text(label), findsOneWidget);
      }

      await tester.tap(find.text('Expenses'));
      await tester.pump();
      expect(taps, [3]);
    });

    testWidgets('captions switch with the app language', (tester) async {
      await pumpBar(tester, locale: const Locale('am'), onTap: (_) {});

      expect(find.text('ሽያጭ'), findsOneWidget);
      expect(find.text('እቃዎች'), findsOneWidget);
      expect(find.text('Sell'), findsNothing);
    });
  });
}
