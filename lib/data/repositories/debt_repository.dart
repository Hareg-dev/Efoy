import 'package:isar/isar.dart';

import '../../core/licensing/license_gate.dart';
import '../models/debt_model.dart';
import 'base_repository.dart';
import 'repository_exceptions.dart';

/// Who owes the shop money, and how much of it has come in since.
class DebtTotals {
  const DebtTotals({required this.outstanding, required this.openCount});

  static const empty = DebtTotals(outstanding: 0, openCount: 0);

  /// Still to come in, across every unsettled invoice.
  final double outstanding;

  /// How many customers are on the list.
  final int openCount;
}

/// The receivables ledger.
///
/// A sale is never edited when a customer pays later: the invoice keeps its
/// full value, so profit stays where it was earned and only this ledger moves.
class DebtRepository implements BaseRepository<DebtModel> {
  DebtRepository(this._isar, this._licenseGate);

  final Isar _isar;

  /// Collecting against a credit sale is a sale-side money movement, so an
  /// expired license must not be able to keep the ledger moving.
  final LicenseGate _licenseGate;

  @override
  Future<DebtModel?> getById(int id) => _isar.debtModels.get(id);

  @override
  Future<List<DebtModel>> getAll() =>
      _isar.debtModels.where().sortByOpenedAtDesc().findAll();

  /// Balances still open, oldest first - the one to chase is the one that has
  /// been waiting longest.
  Future<List<DebtModel>> getOpenDebts() =>
      _isar.debtModels.filter().isOpenEqualTo(true).sortByOpenedAt().findAll();

  /// Live open balances for the creditors screen.
  Stream<List<DebtModel>> watchOpenDebts() => _isar.debtModels
      .filter()
      .isOpenEqualTo(true)
      .sortByOpenedAt()
      .watch(fireImmediately: true);

  Stream<List<DebtModel>> watchSettledDebts() => _isar.debtModels
      .filter()
      .isOpenEqualTo(false)
      .sortByLastPaymentAtDesc()
      .watch(fireImmediately: true);

  Future<DebtTotals> openTotals() async {
    final open = await getOpenDebts();
    var outstanding = 0.0;
    for (final debt in open) {
      outstanding += debt.balanceDue;
    }
    return DebtTotals(outstanding: outstanding, openCount: open.length);
  }

  /// Cash handed in against unsettled invoices, within a half-open date range.
  ///
  /// The invoice date, not today, decides which period a payment falls into:
  /// a balance opened in March and cleared in June was March's business.
  Future<double> collectedBetween(DateTime startDate, DateTime endDate) async {
    final debts = await _isar.debtModels
        .filter()
        .openedAtBetween(startDate, endDate, includeUpper: false)
        .findAll();
    var collected = 0.0;
    for (final debt in debts) {
      collected += debt.paidAmount;
    }
    return collected;
  }

  /// Settle-ups taken inside a half-open date range, whenever the invoice was
  /// opened. This is cash reaching the till today, which is what the profit
  /// card reports beside the margin.
  Future<double> settledBetween(DateTime startDate, DateTime endDate) async {
    // Scanned rather than filtered on lastPaymentAt: a balance paid twice may
    // have its latest payment outside the window while an earlier one is in
    // it, and the ledger is a shop-sized table.
    final debts = await _isar.debtModels.where().findAll();
    var collected = 0.0;
    for (final debt in debts) {
      for (final payment in debt.payments) {
        if (!payment.at.isBefore(startDate) && payment.at.isBefore(endDate)) {
          collected += payment.amount;
        }
      }
    }
    return collected;
  }

  /// Balances opened in a range that are still with customers.
  Future<double> openBalanceBetween(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final debts = await _isar.debtModels
        .filter()
        .openedAtBetween(startDate, endDate, includeUpper: false)
        .isOpenEqualTo(true)
        .findAll();
    var outstanding = 0.0;
    for (final debt in debts) {
      outstanding += debt.balanceDue;
    }
    return outstanding;
  }

  @override
  Future<DebtModel> create(DebtModel entity) async {
    await _licenseGate.ensureAllowed(LicensedOperation.recordSale);
    await _isar.writeTxn(() async {
      entity.id = await _isar.debtModels.put(entity);
    });
    return entity;
  }

  @override
  Future<DebtModel> update(DebtModel entity) async {
    await _licenseGate.ensureAllowed(LicensedOperation.recordSale);
    await _isar.writeTxn(() async {
      await _isar.debtModels.put(entity);
    });
    return entity;
  }

  /// Removing a debt also hides the fact that someone was trusted with goods,
  /// so this is refused. Settled balances simply leave the open list.
  @override
  Future<void> delete(int id) async {
    throw RepositoryException(
      'A balance is cleared by taking the payment, not by deleting it.',
    );
  }

  /// Take [amount] against an open balance. Overpaying is refused rather than
  /// turned into change, because the invoice is the agreement.
  Future<DebtModel> recordPayment({
    required int debtId,
    required double amount,
    String? note,
    DateTime? at,
  }) async {
    await _licenseGate.ensureAllowed(LicensedOperation.recordSale);
    if (amount <= 0) {
      throw RepositoryException('Enter an amount greater than zero.');
    }

    final debt = await _isar.debtModels.get(debtId);
    if (debt == null) {
      throw RepositoryException('This balance no longer exists.');
    }
    if (!debt.isOpen) {
      throw RepositoryException(
        '${debt.customerName} has nothing left to pay.',
      );
    }
    if (amount > debt.balanceDue + DebtModel.tolerance) {
      throw RepositoryException(
        'That is more than the ${debt.balanceDue.toStringAsFixed(2)} Birr '
        'still outstanding.',
      );
    }

    debt.recordPayment(amount, note: note, at: at);
    await _isar.writeTxn(() async {
      await _isar.debtModels.put(debt);
    });
    return debt;
  }

  /// Add or correct the phone number the counter left blank.
  Future<DebtModel> setContact({
    required int debtId,
    required String customerName,
    String? customerPhone,
  }) async {
    await _licenseGate.ensureAllowed(LicensedOperation.recordSale);
    final name = customerName.trim();
    if (name.isEmpty) {
      throw RepositoryException('A balance needs a name on it.');
    }

    final debt = await _isar.debtModels.get(debtId);
    if (debt == null) {
      throw RepositoryException('This balance no longer exists.');
    }
    debt
      ..customerName = name
      ..customerPhone = customerPhone?.trim().isEmpty ?? true
          ? null
          : customerPhone!.trim();
    await _isar.writeTxn(() async {
      await _isar.debtModels.put(debt);
    });
    return debt;
  }
}
