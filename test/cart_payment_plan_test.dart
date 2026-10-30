import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/constants/app_locales.dart';
import 'package:efoy_retail_app/data/models/product_model.dart';
import 'package:efoy_retail_app/logic/providers/cart_provider.dart';
import 'package:efoy_retail_app/ui/widgets/cart_sheet.dart';

/// The three ways a customer can settle at the counter.
///
/// Paid in full used to be the only one offered, so a split payment had to be
/// typed as a smaller total and the invoice lost its real value. The plan row
/// is what keeps the invoice whole and moves the difference to the ledger.
void main() {
  final product = ProductModel(
    name: 'Sugar 1kg',
    sellingPrice: 260,
    costPrice: 200,
    currentStock: 10,
    lowStockThreshold: 2,
    createdAt: DateTime(2026, 10, 12),
    updatedAt: DateTime(2026, 10, 12),
  )..id = 7;

  Future<ProviderContainer> pumpCart(
    WidgetTester tester, {
    void Function(CartNotifier cart)? setup,
  }) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final cart = container.read(cartProvider.notifier);
    cart.addItem(product);
    cart.incrementQuantity(product.id);
    cart.incrementQuantity(product.id);
    setup?.call(cart);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          supportedLocales: appSupportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: Scaffold(
            bottomSheet: const CartSheet(),
            body: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('the plan row', () {
    testWidgets('offers full, split and credit beside the tender choices', (
      tester,
    ) async {
      await pumpCart(tester);

      expect(find.text('How is this being paid?'), findsOneWidget);
      expect(find.text('Paid in full'), findsOneWidget);
      expect(find.text('Part payment'), findsOneWidget);
      expect(find.text('On credit'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
    });

    testWidgets('credit is a plan, never a tender you can tap', (tester) async {
      await pumpCart(tester);

      // Tenders: cash, telebirr, CBE Birr, Amhara Bank, mixed - no credit.
      expect(find.text('On credit'), findsOneWidget);
      expect(find.text('Bank'), findsNothing);
    });

    testWidgets('paid in full still asks for the tender and shows change', (
      tester,
    ) async {
      final container = await pumpCart(
        tester,
        setup: (cart) => cart.setAmountReceived(800),
      );

      expect(find.text('Amount received'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.textContaining('780.00'), findsWidgets);
      expect(find.textContaining('20.00'), findsOneWidget);
      expect(container.read(cartProvider).balanceDue, 0);
      expect(find.text('Customer name'), findsNothing);
    });
  });

  group('part payment', () {
    testWidgets('asks whose balance it is and shows what stays owing', (
      tester,
    ) async {
      final container = await pumpCart(tester);
      await tester.tap(find.text('Part payment'));
      await tester.pumpAndSettle();

      expect(find.text('Customer name'), findsOneWidget);
      expect(find.text('Part payment'), findsWidgets);

      await tester.enterText(find.byType(TextField).first, 'Wondimu');
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, '300');
      await tester.pump();

      final cart = container.read(cartProvider);
      expect(cart.customerName, 'Wondimu');
      expect(cart.balanceDue, 480);
      expect(find.text('Still owed by the customer'), findsOneWidget);
      expect(find.textContaining('480.00'), findsOneWidget);
      expect(find.text('Record with balance'), findsOneWidget);
    });
  });

  group('on credit', () {
    testWidgets('takes no tender amount and puts the whole invoice on hold', (
      tester,
    ) async {
      final container = await pumpCart(tester);
      await tester.tap(find.text('On credit'));
      await tester.pumpAndSettle();

      expect(find.text('Amount received'), findsNothing);
      expect(find.text('Customer name'), findsOneWidget);
      expect(find.textContaining('780.00'), findsWidgets);

      await tester.enterText(find.byType(TextField).first, 'Kebede');
      await tester.pump();

      final cart = container.read(cartProvider);
      expect(cart.collectedNow, 0);
      expect(cart.balanceDue, 780);
      expect(cart.isOnCredit, isTrue);
    });

    testWidgets('switching plans clears the amount typed for the old one', (
      tester,
    ) async {
      final container = await pumpCart(
        tester,
        setup: (cart) {
          cart.setPaymentPlan(SalePaymentPlan.partPayment);
          cart.setAmountReceived(300);
        },
      );

      await tester.tap(find.text('On credit'));
      await tester.pumpAndSettle();

      expect(container.read(cartProvider).collectedNow, 0);
    });
  });
}
