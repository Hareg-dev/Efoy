import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:efoy_retail_app/core/licensing/license_gate.dart';
import 'package:efoy_retail_app/data/models/debt_model.dart';
import 'package:efoy_retail_app/data/repositories/debt_repository.dart';
import 'package:efoy_retail_app/data/repositories/repository_exceptions.dart';

import 'isar_host.dart';

/// The receivables ledger behind "Who owes me".
///
/// A credit sale must stay whole on the sale row - only this ledger moves - so
/// these tests pin down the arithmetic of settle-ups, the refusal to overpay or
/// delete, and the licence gate that keeps the ledger still while a renewal is
/// outstanding.
void main() {
  const allowedGate = AlwaysAllowedLicenseGate();
  const blockedGate = AlwaysBlockedLicenseGate();

  late Directory tempRoot;
  late Isar isar;
  late DebtRepository debts;
  var dbCounter = 0;

  setUpAll(() async {
    await initializeIsarHost();
    tempRoot = Directory.systemTemp.createTempSync('efoy_debts');
  });

  setUp(() async {
    dbCounter++;
    isar = await openTestIsar(
      directory: tempRoot.path,
      name: 'debts_$dbCounter',
    );
    debts = DebtRepository(isar, allowedGate);
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

  /// A 1,000 Birr invoice with [paid] already handed over at the counter.
  Future<DebtModel> openBalance({
    double paid = 0,
    String name = 'Wondimu',
    DateTime? openedAt,
  }) {
    return debts.create(
      DebtModel(
        saleTransactionId: 'EFY-TEST-$dbCounter-$name',
        customerName: name,
        totalAmount: 1000,
        paidAmount: paid,
        openedAt: openedAt ?? DateTime(2026, 10, 12, 9),
      ),
    );
  }

  group('opening a balance', () {
    test('a part payment at the counter leaves the remainder open', () async {
      final debt = await openBalance(paid: 400);

      expect(debt.balanceDue, 600);
      expect(debt.isOpen, isTrue);
      expect(debt.payments, isEmpty);
      expect(debt.paidProportion, closeTo(0.4, 1e-9));
    });

    test('an invoice already paid in full never reaches the list', () async {
      await openBalance(paid: 1000);

      expect(await debts.getOpenDebts(), isEmpty);
      final totals = await debts.openTotals();
      expect(totals.outstanding, 0);
      expect(totals.openCount, 0);
    });
  });

  group('settle-ups', () {
    test(
      'a partial payment keeps the debt open and records the line',
      () async {
        final debt = await openBalance();

        final after = await debts.recordPayment(
          debtId: debt.id,
          amount: 250,
          note: 'half by telephone',
        );

        expect(after.paidAmount, 250);
        expect(after.balanceDue, 750);
        expect(after.isOpen, isTrue);
        expect(after.payments, hasLength(1));
        expect(after.payments.single.amount, 250);
        expect(after.payments.single.note, 'half by telephone');
        expect(after.lastPaymentAt, isNotNull);
      },
    );

    test('the last cent clears it and it leaves the open list', () async {
      final debt = await openBalance(paid: 400);

      await debts.recordPayment(debtId: debt.id, amount: 600);

      expect(await debts.getOpenDebts(), isEmpty);
      final settled = await debts.watchSettledDebts().first;
      expect(settled, hasLength(1));
      expect(settled.single.balanceDue, 0);
      expect(settled.single.isOpen, isFalse);
      expect(settled.single.paidAmount, 1000);
    });

    test('payments stack instead of replacing each other', () async {
      final debt = await openBalance();

      await debts.recordPayment(debtId: debt.id, amount: 100);
      final last = await debts.recordPayment(debtId: debt.id, amount: 200);

      expect(last.paidAmount, 300);
      expect(last.balanceDue, 700);
      expect(last.payments.map((payment) => payment.amount), [100.0, 200.0]);
    });

    test(
      'rounding a cent short of the invoice still counts as settled',
      () async {
        final debt = await openBalance();

        // 0.1 + 0.2 is not exactly 0.3 in binary floating point, which is the
        // real shape of a customer paying an invoice in instalments.
        final first = await debts.recordPayment(
          debtId: debt.id,
          amount: 333.33,
        );
        final second = await debts.recordPayment(
          debtId: debt.id,
          amount: 333.33,
        );
        final third = await debts.recordPayment(
          debtId: debt.id,
          amount: 333.34,
        );

        expect(first.isOpen, isTrue);
        expect(second.isOpen, isTrue);
        expect(third.isOpen, isFalse);
        expect(third.balanceDue, 0);
      },
    );
  });

  group('refusals', () {
    test('overpaying is turned down and the ledger is untouched', () async {
      final debt = await openBalance(paid: 900);

      await expectLater(
        debts.recordPayment(debtId: debt.id, amount: 200),
        throwsA(isA<RepositoryException>()),
      );

      final stored = await debts.getById(debt.id);
      expect(stored!.paidAmount, 900);
      expect(stored.payments, isEmpty);
    });

    test('zero and negative amounts never move the balance', () async {
      final debt = await openBalance();

      await expectLater(
        debts.recordPayment(debtId: debt.id, amount: 0),
        throwsA(isA<RepositoryException>()),
      );
      await expectLater(
        debts.recordPayment(debtId: debt.id, amount: -50),
        throwsA(isA<RepositoryException>()),
      );

      expect((await debts.getById(debt.id))!.paidAmount, 0);
    });

    test('a settled balance cannot take another payment', () async {
      final debt = await openBalance();
      await debts.recordPayment(debtId: debt.id, amount: 1000);

      await expectLater(
        debts.recordPayment(debtId: debt.id, amount: 10),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('deleting a balance is refused - history stays', () async {
      final debt = await openBalance();

      await expectLater(
        debts.delete(debt.id),
        throwsA(isA<RepositoryException>()),
      );
      expect(await debts.getById(debt.id), isNotNull);
    });

    test('a balance needs a name on it', () async {
      final debt = await openBalance();

      await expectLater(
        debts.setContact(debtId: debt.id, customerName: '   '),
        throwsA(isA<RepositoryException>()),
      );
    });
  });

  group('the counter', () {
    test('totals add every open balance and count the customers', () async {
      await openBalance(paid: 400, name: 'Abeba');
      await openBalance(paid: 0, name: 'Kebede');
      await openBalance(paid: 1000, name: 'Hirut');

      final totals = await debts.openTotals();

      expect(totals.outstanding, 1600);
      expect(totals.openCount, 2);
    });

    test('the oldest debt is the one shown first', () async {
      await openBalance(name: 'Newer', openedAt: DateTime(2026, 10, 20, 9));
      await openBalance(name: 'Waiting', openedAt: DateTime(2026, 9, 3, 9));

      final open = await debts.getOpenDebts();

      expect(open.map((debt) => debt.customerName), ['Waiting', 'Newer']);
    });

    test('the open list updates live when money comes in', () async {
      final debt = await openBalance();
      final emitted = <int>[];

      final subscription = debts.watchOpenDebts().listen(
        (open) => emitted.add(open.length),
      );
      addTearDown(subscription.cancel);

      await debts.recordPayment(debtId: debt.id, amount: 1000);
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(emitted.last, 0);
    });
  });

  group('cash collected in a period', () {
    test(
      'a balance is credited to the period of the invoice, not of paying',
      () async {
        final march = await openBalance(
          paid: 0,
          openedAt: DateTime(2026, 3, 10),
        );
        await debts.recordPayment(debtId: march.id, amount: 300);
        await openBalance(
          paid: 100,
          name: 'October buyer',
          openedAt: DateTime(2026, 10, 5),
        );

        final june = await debts.collectedBetween(
          DateTime(2026, 6, 1),
          DateTime(2026, 7, 1),
        );
        final october = await debts.collectedBetween(
          DateTime(2026, 10, 1),
          DateTime(2026, 11, 1),
        );

        // The March invoice settled in June still belongs to March's business,
        // so June sees nothing while October only sees its own counter payment.
        expect(june, 0);
        expect(october, 100);
      },
    );

    test(
      'the range is half-open so midnight on the last day is excluded',
      () async {
        final debt = await openBalance(
          paid: 500,
          openedAt: DateTime(2026, 10, 1),
        );

        final same = await debts.collectedBetween(
          debt.openedAt,
          DateTime(2026, 10, 2),
        );

        expect(same, 500);
      },
    );

    test('settle-ups count in the period the cash actually came in', () async {
      final march = await openBalance(paid: 0, openedAt: DateTime(2026, 3, 10));
      await debts.recordPayment(
        debtId: march.id,
        amount: 300,
        at: DateTime(2026, 6, 4),
      );
      await debts.recordPayment(
        debtId: march.id,
        amount: 100,
        at: DateTime(2026, 7, 2),
      );

      final june = await debts.settledBetween(
        DateTime(2026, 6, 1),
        DateTime(2026, 7, 1),
      );
      final july = await debts.settledBetween(
        DateTime(2026, 7, 1),
        DateTime(2026, 8, 1),
      );

      expect(june, 300);
      expect(july, 100);
    });

    test(
      'open balances are reported for the period that sold on credit',
      () async {
        final open = await openBalance(
          paid: 250,
          openedAt: DateTime(2026, 10, 8),
        );
        await openBalance(
          paid: 1000,
          name: 'PaidAtCounter',
          openedAt: DateTime(2026, 10, 9),
        );
        await openBalance(
          paid: 0,
          name: 'SeptemberBuyer',
          openedAt: DateTime(2026, 9, 20),
        );

        final october = await debts.openBalanceBetween(
          DateTime(2026, 10, 1),
          DateTime(2026, 11, 1),
        );

        expect(october, open.balanceDue);
      },
    );
  });

  group('licence enforcement', () {
    test('an expired licence cannot open a balance', () async {
      final gated = DebtRepository(isar, blockedGate);

      await expectLater(
        gated.create(
          DebtModel(
            saleTransactionId: 'EFY-BLOCKED',
            customerName: 'Anyone',
            totalAmount: 100,
            paidAmount: 0,
            openedAt: DateTime(2026, 10, 12),
          ),
        ),
        throwsA(isA<LicenseRequiredException>()),
      );
      expect(await debts.getAll(), isEmpty);
    });

    test('an expired licence cannot take a payment either', () async {
      final debt = await openBalance();
      final gated = DebtRepository(isar, blockedGate);

      await expectLater(
        gated.recordPayment(debtId: debt.id, amount: 10),
        throwsA(isA<LicenseRequiredException>()),
      );

      // Reading the list is never gated: the merchant must still be able to
      // see who owes them while the licence is expired.
      expect(await gated.getOpenDebts(), hasLength(1));
    });
  });

  group('contact details', () {
    test('a phone number added later survives on the same row', () async {
      final debt = await openBalance();

      final updated = await debts.setContact(
        debtId: debt.id,
        customerName: ' Wondimu Alemu ',
        customerPhone: ' 0911 223 344 ',
      );

      expect(updated.customerName, 'Wondimu Alemu');
      expect(updated.customerPhone, '0911 223 344');
      expect(updated.balanceDue, 1000);

      final stored = await debts.getById(debt.id);
      expect(stored!.customerName, 'Wondimu Alemu');
    });

    test('blanking the phone clears it rather than storing spaces', () async {
      final debt = await openBalance();
      await debts.setContact(
        debtId: debt.id,
        customerName: 'Wondimu',
        customerPhone: '0911',
      );

      final cleared = await debts.setContact(
        debtId: debt.id,
        customerName: 'Wondimu',
        customerPhone: '   ',
      );

      expect(cleared.customerPhone, isNull);
    });
  });
}
