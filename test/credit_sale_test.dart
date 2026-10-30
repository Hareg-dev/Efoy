import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:efoy_retail_app/core/licensing/license_gate.dart';
import 'package:efoy_retail_app/data/models/debt_model.dart';
import 'package:efoy_retail_app/data/models/product_model.dart';
import 'package:efoy_retail_app/data/models/sale_model.dart';
import 'package:efoy_retail_app/logic/providers/cart_provider.dart';
import 'package:efoy_retail_app/logic/providers/database_provider.dart';
import 'package:efoy_retail_app/logic/providers/license_provider.dart';

import 'isar_host.dart';

/// What the counter does when the money does not all arrive today.
///
/// Three plans - paid in full, part payment, on credit - and the rule that
/// holds them together: the invoice is never edited afterwards. The sale keeps
/// its full value and margin, and only the receivable beside it moves.
void main() {
  const allowedGate = AlwaysAllowedLicenseGate();

  late Directory tempRoot;
  late Isar isar;
  var dbCounter = 0;

  setUpAll(() async {
    await initializeIsarHost();
    tempRoot = Directory.systemTemp.createTempSync('efoy_credit_sale');
  });

  setUp(() async {
    dbCounter++;
    isar = await openTestIsar(
      directory: tempRoot.path,
      name: 'credit_$dbCounter',
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  tearDownAll(() {
    try {
      tempRoot.deleteSync(recursive: true);
    } on FileSystemException {
      // The OS reclaims the temp folder.
    }
  });

  /// A shelf line at 200 Birr cost, 260 selling, 10 in stock.
  Future<ProductModel> stockProduct({int stock = 10}) async {
    final now = DateTime(2026, 10, 12);
    final product = ProductModel(
      name: 'Sugar 1kg',
      sellingPrice: 260,
      costPrice: 200,
      currentStock: stock,
      lowStockThreshold: 2,
      createdAt: now,
      updatedAt: now,
    );
    await isar.writeTxn(() async {
      product.id = await isar.productModels.put(product);
    });
    return product;
  }

  /// A cart with 3 x Sugar 1kg = 780 Birr, cost 600, margin 180.
  Future<(SaleModel, List<DebtModel>)> complete(
    void Function(CartNotifier cart) plan, {
    ProductModel? product,
  }) async {
    final container = ProviderContainer(
      overrides: [
        isarProvider.overrideWith((ref) => Future.value(isar)),
        licenseGateProvider.overrideWith((ref) => allowedGate),
      ],
    );
    addTearDown(container.dispose);

    final item = product ?? await stockProduct();
    final cart = container.read(cartProvider.notifier);
    cart.addItem(item);
    cart.incrementQuantity(item.id);
    cart.incrementQuantity(item.id);
    plan(cart);
    final sale = await cart.completeSale(cashierName: 'Hareg');

    final debts = await isar.debtModels.where().findAll();
    return (sale, debts);
  }

  group('paid in full', () {
    test('the whole invoice is taken and no receivable is opened', () async {
      final (sale, debts) = await complete((cart) {
        cart.setPaymentMethod(PaymentMethod.cash);
        cart.setAmountReceived(800);
      });

      expect(sale.totalAmount, 780);
      expect(sale.grossProfit, 180);
      expect(sale.paymentMethod, PaymentMethod.cash);
      expect(sale.amountReceived, 780);
      expect(sale.changeGiven, 20);
      expect(sale.notes, isNull);
      expect(debts, isEmpty);
    });

    test('cash with less than the total is still refused', () async {
      await expectLater(
        complete((cart) => cart.setAmountReceived(100)),
        throwsA(
          isA<CartException>().having(
            (e) => e.message,
            'message',
            contains('less than the total'),
          ),
        ),
      );
    });
  });

  group('part payment', () {
    test(
      'the counter takes what came in and the rest becomes a balance',
      () async {
        final (sale, debts) = await complete((cart) {
          cart.setPaymentPlan(SalePaymentPlan.partPayment);
          cart.setCustomerName('Wondimu Alemu');
          cart.setAmountReceived(300);
        });

        expect(sale.totalAmount, 780);
        expect(
          sale.grossProfit,
          180,
          reason: 'margin was earned on the invoice',
        );
        expect(sale.amountReceived, 300);
        expect(sale.paymentMethod, PaymentMethod.cash);

        expect(debts, hasLength(1));
        final debt = debts.single;
        expect(debt.customerName, 'Wondimu Alemu');
        expect(debt.totalAmount, 780);
        expect(debt.paidAmount, 300);
        expect(debt.balanceDue, 480);
        expect(debt.isOpen, isTrue);
        expect(debt.saleTransactionId, sale.transactionId);
        expect(sale.notes, contains('Wondimu Alemu'));
        expect(sale.notes, contains('480.00'));
      },
    );

    test(
      'a balance without a name is refused before anything is written',
      () async {
        await expectLater(
          complete((cart) {
            cart.setPaymentPlan(SalePaymentPlan.partPayment);
            cart.setAmountReceived(300);
          }),
          throwsA(
            isA<CartException>().having(
              (e) => e.message,
              'message',
              contains('customer name'),
            ),
          ),
        );

        expect(await isar.saleModels.count(), 0);
        expect(await isar.debtModels.count(), 0);
        expect(
          (await isar.productModels.where().findFirst())!.currentStock,
          10,
        );
      },
    );

    test('an amount that covers the invoice asks for the other plan', () async {
      await expectLater(
        complete((cart) {
          cart.setPaymentPlan(SalePaymentPlan.partPayment);
          cart.setCustomerName('Wondimu');
          cart.setAmountReceived(780);
        }),
        throwsA(
          isA<CartException>().having(
            (e) => e.message,
            'message',
            contains('Paid in full'),
          ),
        ),
      );
    });
  });

  group('on credit', () {
    test(
      'nothing taken at the counter puts the whole invoice on the list',
      () async {
        final (sale, debts) = await complete((cart) {
          cart.setPaymentPlan(SalePaymentPlan.onCredit);
          cart.setCustomerName('Kebede');
        });

        expect(sale.paymentMethod, PaymentMethod.credit);
        expect(sale.amountReceived, 0);
        expect(sale.totalAmount, 780);
        expect(sale.grossProfit, 180);

        expect(debts.single.balanceDue, 780);
        expect(debts.single.paidAmount, 0);
        expect(debts.single.customerName, 'Kebede');
      },
    );

    test('credit needs a name too', () async {
      await expectLater(
        complete((cart) => cart.setPaymentPlan(SalePaymentPlan.onCredit)),
        throwsA(isA<CartException>()),
      );
      expect(await isar.saleModels.count(), 0);
    });

    test(
      'stock still leaves the shelf while the cash has not arrived',
      () async {
        final product = await stockProduct();
        await complete((cart) {
          cart.setPaymentPlan(SalePaymentPlan.onCredit);
          cart.setCustomerName('Kebede');
        }, product: product);

        final stored = await isar.productModels.get(product.id);
        expect(stored!.currentStock, 7);
      },
    );

    test('changing the plan drops a tender typed for the old one', () async {
      final (sale, debts) = await complete((cart) {
        cart.setPaymentPlan(SalePaymentPlan.partPayment);
        cart.setCustomerName('Wondimu');
        cart.setAmountReceived(300);
        cart.setPaymentPlan(SalePaymentPlan.onCredit);
      });

      expect(sale.amountReceived, 0);
      expect(sale.paymentMethod, PaymentMethod.credit);
      expect(debts.single.balanceDue, 780);
    });
  });

  group('settling afterwards', () {
    test('a settle-up moves the ledger and leaves the sale alone', () async {
      final (sale, debts) = await complete((cart) {
        cart.setPaymentPlan(SalePaymentPlan.onCredit);
        cart.setCustomerName('Kebede');
      });

      final debt = debts.single;
      debt.recordPayment(780);
      await isar.writeTxn(() => isar.debtModels.put(debt));

      final storedSale = await isar.saleModels.get(sale.id);
      expect(storedSale!.totalAmount, 780);
      expect(storedSale.amountReceived, 0);
      expect(storedSale.grossProfit, 180);
      expect(storedSale.paymentMethod, PaymentMethod.credit);

      final storedDebt = await isar.debtModels.get(debt.id);
      expect(storedDebt!.isOpen, isFalse);
      expect(storedDebt.paidAmount, 780);
    });
  });

  group('cart maths', () {
    test('the state reports collected, owed and change for each plan', () {
      const items = [
        CartItem(
          productId: 1,
          productName: 'Sugar 1kg',
          quantity: 3,
          unitPrice: 260,
          unitCost: 200.0,
          availableStock: 10,
        ),
      ];

      const full = CartState(
        items: items,
        paymentMethod: PaymentMethod.cash,
        amountReceived: 800,
      );
      expect(full.total, 780);
      expect(full.collectedNow, 780);
      expect(full.balanceDue, 0);
      expect(full.change, 20);
      expect(full.leavesABalance, isFalse);

      final part = CartState(
        items: items,
        paymentMethod: PaymentMethod.cash,
        amountReceived: 300,
        paymentPlan: SalePaymentPlan.partPayment,
        customerName: 'Wondimu',
      );
      expect(part.collectedNow, 300);
      expect(part.balanceDue, 480);
      expect(part.change, isNull);
      expect(part.leavesABalance, isTrue);

      const credit = CartState(
        items: items,
        paymentMethod: PaymentMethod.cash,
        paymentPlan: SalePaymentPlan.onCredit,
        customerName: 'Kebede',
      );
      expect(credit.collectedNow, 0);
      expect(credit.balanceDue, 780);
      expect(credit.isOnCredit, isTrue);

      // A part payment typed larger than the invoice cannot invent change.
      final greedy = CartState(
        items: items,
        paymentMethod: PaymentMethod.cash,
        amountReceived: 5000,
        paymentPlan: SalePaymentPlan.partPayment,
        customerName: 'Wondimu',
      );
      expect(greedy.collectedNow, 780);
      expect(greedy.balanceDue, 0);
    });
  });
}
