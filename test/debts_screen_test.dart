import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/constants/app_locales.dart';
import 'package:efoy_retail_app/data/models/debt_model.dart';
import 'package:efoy_retail_app/logic/providers/repository_providers.dart';
import 'package:efoy_retail_app/ui/screens/debts_screen.dart';

/// The creditors list: who was trusted with goods, how much is still out, and
/// the fact that a settled invoice leaves the open list instead of vanishing.
void main() {
  DebtModel balance({
    required String name,
    required double total,
    required double paid,
    required DateTime openedAt,
    List<DebtPayment> payments = const [],
    String? phone,
  }) {
    return DebtModel(
      saleTransactionId: 'EFY-$name',
      customerName: name,
      customerPhone: phone,
      totalAmount: total,
      paidAmount: paid,
      openedAt: openedAt,
      payments: payments,
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    required List<DebtModel> open,
    List<DebtModel> settled = const [],
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          openDebtsProvider.overrideWith((ref) => Stream.value(open.toList())),
          settledDebtsProvider.overrideWith(
            (ref) => Stream.value(settled.toList()),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          supportedLocales: appSupportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: const DebtsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the open list', () {
    testWidgets('names every debtor with what is still owed', (tester) async {
      await pump(
        tester,
        open: [
          balance(
            name: 'Kebede',
            total: 1000,
            paid: 0,
            openedAt: DateTime(2026, 9, 3, 9),
          ),
          balance(
            name: 'Wondimu Alemu',
            total: 780,
            paid: 300,
            openedAt: DateTime(2026, 10, 12, 9),
            phone: '0911 223 344',
          ),
        ],
      );

      expect(find.text('Kebede'), findsOneWidget);
      expect(find.text('Wondimu Alemu'), findsOneWidget);
      // 1,000 + 480 still to come in.
      expect(find.textContaining('1,480'), findsOneWidget);
      expect(find.textContaining('1,000.00'), findsWidgets);
      expect(find.textContaining('480.00'), findsOneWidget);
      expect(find.text('0911 223 344'), findsOneWidget);
      expect(find.textContaining('2 customers'), findsOneWidget);
    });

    testWidgets('says what the oldest balance is waiting on', (tester) async {
      await pump(
        tester,
        open: [
          balance(
            name: 'Hirut',
            total: 500,
            paid: 450,
            openedAt: DateTime.now().subtract(const Duration(days: 40)),
          ),
        ],
      );

      expect(find.textContaining('of 500'), findsOneWidget);
      expect(find.textContaining('40 days ago'), findsOneWidget);
    });

    testWidgets('lists instalments already taken', (tester) async {
      final debt = balance(
        name: 'Mese',
        total: 600,
        paid: 250,
        openedAt: DateTime(2026, 10, 1),
      );
      debt.recordPayment(150, at: DateTime(2026, 10, 4));
      debt.recordPayment(100, at: DateTime(2026, 10, 9));

      await pump(tester, open: [debt]);

      expect(find.text('Payments received'), findsOneWidget);
      expect(
        find.textContaining('150.00'),
        findsWidgets,
        reason: 'the invoice total and the instalment both show 150.00',
      );
      expect(find.textContaining('100.00'), findsWidgets);
    });

    testWidgets('speaks Amharic when the app does', (tester) async {
      await pump(
        tester,
        locale: const Locale('am'),
        open: [
          balance(
            name: 'ፃላማው',
            total: 300,
            paid: 100,
            openedAt: DateTime(2026, 10, 12),
          ),
        ],
      );

      expect(find.text('ማን ይዳናል'), findsOneWidget);
      expect(find.text('ክፍያ ተቀበል'), findsOneWidget);
      expect(find.text('ፃላማው'), findsOneWidget);
    });
  });

  group('empty and settled', () {
    testWidgets('an empty shelf of debts says so plainly', (tester) async {
      await pump(tester, open: []);

      expect(find.text('Nobody owes you'), findsOneWidget);
      expect(find.textContaining('STILL TO COME IN'), findsOneWidget);
      expect(find.textContaining('0 ብር'), findsWidgets);
    });

    testWidgets('nothing is folded away when nobody has paid up yet', (
      tester,
    ) async {
      await pump(tester, open: []);

      expect(find.text('Settled up'), findsOneWidget);
      expect(find.textContaining('none yet'), findsOneWidget);
    });

    testWidgets('settled balances stay out of the way until asked for', (
      tester,
    ) async {
      final cleared = balance(
        name: 'Abeba',
        total: 120,
        paid: 120,
        openedAt: DateTime(2026, 8, 2),
      );
      await pump(tester, open: [], settled: [cleared]);

      expect(find.text('Abeba'), findsNothing);
      expect(find.textContaining('1 shown'), findsOneWidget);

      await tester.tap(find.text('Settled up'));
      await tester.pumpAndSettle();

      expect(find.text('Abeba'), findsOneWidget);
      expect(find.textContaining('Cleared on'), findsOneWidget);
    });

    testWidgets('expanding shows who has paid off', (tester) async {
      final cleared = balance(
        name: 'Tigist',
        total: 400,
        paid: 400,
        openedAt: DateTime(2026, 8, 2),
      );
      await pump(
        tester,
        open: [
          balance(
            name: 'Still open',
            total: 90,
            paid: 0,
            openedAt: DateTime(2026, 10, 12),
          ),
        ],
        settled: [cleared],
      );

      expect(find.text('Tigist'), findsNothing);
      await tester.tap(find.text('Settled up'));
      await tester.pumpAndSettle();

      expect(find.text('Tigist'), findsOneWidget);
      expect(find.textContaining('Cleared on'), findsOneWidget);
    });
  });
}
