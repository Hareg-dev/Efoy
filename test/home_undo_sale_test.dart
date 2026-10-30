import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/constants/app_locales.dart';
import 'package:efoy_retail_app/core/licensing/license_access_state.dart';
import 'package:efoy_retail_app/data/models/sale_model.dart';
import 'package:efoy_retail_app/data/models/user_profile.dart';
import 'package:efoy_retail_app/data/repositories/sale_repository.dart';
import 'package:efoy_retail_app/logic/providers/license_provider.dart';
import 'package:efoy_retail_app/logic/providers/profit_provider.dart';
import 'package:efoy_retail_app/logic/providers/repository_providers.dart';
import 'package:efoy_retail_app/ui/screens/home_screen.dart';

/// A sale rung up by mistake must be undoable from the last three on Home,
/// with the stock and the balance restored and a plain answer afterwards.
class _FakeSaleRepository implements SaleRepository {
  int voided = 0;
  int lastVoidedId = -1;

  @override
  Future<void> voidSale(int id) async {
    voided++;
    lastVoidedId = id;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Lets a dialog or snackbar finish its transition without waiting for the
/// profit card's endless pulse animation.
Future<void> _pumpDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The undo buttons sit under the profit card, so the list has to be scrolled
/// into view before it can be tapped in an 800x600 test surface.
Future<void> _tapUndo(
  WidgetTester tester, {
  bool last = false,
  String label = 'Undo',
}) async {
  final finder = last ? find.text(label).last : find.text(label).first;
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _pumpDialog(tester);
}

void main() {
  SaleLineItem line(String name, int quantity, double price) {
    return SaleLineItem()
      ..productName = name
      ..quantity = quantity
      ..unitPrice = price
      ..unitCost = price * 0.7
      ..lineTotal = quantity * price
      ..lineCost = quantity * price * 0.7
      ..lineProfit = quantity * price * 0.3;
  }

  SaleModel sale({
    required int id,
    required String transactionId,
    required double total,
    required int quantity,
    double? paid,
  }) {
    return SaleModel(
      saleDate: DateTime(2026, 10, 30, 9),
      transactionId: transactionId,
      lineItems: [line('Sugar 1kg', quantity, total / quantity)],
      totalAmount: total,
      totalCost: total * 0.7,
      grossProfit: total * 0.3,
      paymentMethod: paid == null ? PaymentMethod.cash : PaymentMethod.credit,
      amountReceived: paid,
      createdAt: DateTime(2026, 10, 30, 9),
    )..id = id;
  }

  final cashSale = sale(
    id: 1,
    transactionId: 'EFY-111',
    total: 780,
    quantity: 3,
    paid: 780,
  );
  final creditSale = sale(
    id: 2,
    transactionId: 'EFY-222',
    total: 520,
    quantity: 2,
    paid: 0,
  );

  Future<_FakeSaleRepository> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    final fake = _FakeSaleRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardSummaryProvider.overrideWith(
            (ref) => Stream.value(
              DashboardSummary(
                transactionCount: 2,
                salesAmount: 1300,
                needsRestockProducts: const [],
                recentSales: [cashSale, creditSale],
                grossProfitMargin: 0.3,
              ),
            ),
          ),
          netProfitProvider.overrideWith(
            (ref) => Stream.value(
              const NetProfitData(
                netProfit: 390,
                grossProfit: 390,
                revenue: 1300,
                opex: 0,
                salesCount: 2,
                period: ProfitPeriod.today,
              ),
            ),
          ),
          licenseAccessProvider.overrideWith(
            (ref) => Stream.value(
              LicenseAccessState(
                status: LicenseAccessStatus.licensed,
                installationId: 'AAAA-BBBB-CCCC-DDDD',
                plan: 'monthly',
                expiresAt: DateTime.now().add(const Duration(days: 20)),
              ),
            ),
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream<UserProfile?>.value(
              UserProfile(businessName: 'Rift Valley Grocery'),
            ),
          ),
          saleRepositoryProvider.overrideWith((ref) async => fake),
        ],
        child: MaterialApp(
          locale: locale,
          supportedLocales: appSupportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: const HomeScreen(),
        ),
      ),
    );
    // The profit card's pulse never stops, so settling would time out.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return fake;
  }

  testWidgets('every recent sale carries its own undo', (tester) async {
    await pump(tester);

    expect(find.text('RECENT ACTIVITY'), findsOneWidget);
    expect(find.text('Undo'), findsNWidgets(2));
    expect(find.textContaining('EFY-111'), findsOneWidget);
    expect(find.textContaining('EFY-222'), findsOneWidget);
  });

  testWidgets('keeping the sale changes nothing', (tester) async {
    final fake = await pump(tester);

    await _tapUndo(tester);

    expect(find.text('Undo this sale?'), findsOneWidget);
    expect(find.textContaining('3 unit(s) back on the shelf'), findsOneWidget);

    await tester.tap(find.text('Keep it'));
    await _pumpDialog(tester);

    expect(find.text('Undo this sale?'), findsNothing);
    expect(fake.voided, 0);
  });

  testWidgets('a credit sale warns that its balance is cleared too', (
    tester,
  ) async {
    await pump(tester);

    await _tapUndo(tester, last: true);

    expect(
      find.textContaining('removes the balance on the debts list'),
      findsOneWidget,
    );
    expect(find.textContaining('520.00'), findsOneWidget);
  });

  testWidgets('undoing reports what came back', (tester) async {
    final fake = await pump(tester);

    await _tapUndo(tester);
    await tester.tap(find.text('Undo sale'));
    await _pumpDialog(tester);

    expect(fake.voided, 1);
    expect(fake.lastVoidedId, cashSale.id);
    expect(
      find.textContaining('3 unit(s) went back into stock'),
      findsOneWidget,
    );
  });

  testWidgets('the dialog speaks Amharic when the app does', (tester) async {
    await pump(tester, locale: const Locale('am'));

    await _tapUndo(tester, label: 'ቀልብስ');

    expect(find.text('ይህን ሽያጭ ይቀልብሱ?'), findsOneWidget);
    expect(find.text('ሽያጩን ቀልብስ'), findsOneWidget);
  });
}
