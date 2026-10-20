import 'package:isar/isar.dart';

import '../models/expense_model.dart';
import 'base_repository.dart';

class ExpenseTotals {
  const ExpenseTotals({
    required this.total,
    required this.operatingTotal,
    required this.capitalTotal,
  });

  final double total;
  final double operatingTotal;
  final double capitalTotal;

  static const empty = ExpenseTotals(
    total: 0,
    operatingTotal: 0,
    capitalTotal: 0,
  );
}

class ExpenseRepository implements BaseRepository<ExpenseModel> {
  ExpenseRepository(this._isar);

  final Isar _isar;

  @override
  Future<ExpenseModel?> getById(int id) => _isar.expenseModels.get(id);

  @override
  Future<List<ExpenseModel>> getAll() {
    return _isar.expenseModels
        .filter()
        .isDeletedEqualTo(false)
        .sortByExpenseDateDesc()
        .findAll();
  }

  /// Real-time stream of active expenses, newest first.
  Stream<List<ExpenseModel>> watchAll() {
    return _isar.expenseModels
        .filter()
        .isDeletedEqualTo(false)
        .sortByExpenseDateDesc()
        .watch(fireImmediately: true);
  }

  Future<List<ExpenseModel>> getByCategory(ExpenseCategory category) {
    return _isar.expenseModels
        .filter()
        .isDeletedEqualTo(false)
        .categoryEqualTo(category)
        .sortByExpenseDateDesc()
        .findAll();
  }

  @override
  Future<ExpenseModel> create(ExpenseModel entity) async {
    await _isar.writeTxn(() async {
      entity.id = await _isar.expenseModels.put(entity);
    });
    return entity;
  }

  @override
  Future<ExpenseModel> update(ExpenseModel entity) async {
    await _isar.writeTxn(() async {
      await _isar.expenseModels.put(entity);
    });
    return entity;
  }

  /// Soft-delete so CapEx/OpEx history stays auditable.
  @override
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      final expense = await _isar.expenseModels.get(id);
      if (expense == null) return;
      expense.isDeleted = true;
      await _isar.expenseModels.put(expense);
    });
  }

  /// Totals for a half-open date range.
  ///
  /// [excludeRestock] (default true) keeps CapEx restocking out of the
  /// operating expense total used for net-profit calculations.
  Future<ExpenseTotals> getTotalsByPeriod(
    DateTime startDate,
    DateTime endDate, {
    bool excludeRestock = true,
  }) async {
    final expenses = await _isar.expenseModels
        .filter()
        .expenseDateBetween(startDate, endDate, includeUpper: false)
        .isDeletedEqualTo(false)
        .findAll();

    var total = 0.0;
    var operating = 0.0;
    var capital = 0.0;
    for (final expense in expenses) {
      if (expense.isRestockExpense) {
        capital += expense.amount;
        if (!excludeRestock) total += expense.amount;
      } else {
        operating += expense.amount;
        total += expense.amount;
      }
    }

    return ExpenseTotals(
      total: total,
      operatingTotal: operating,
      capitalTotal: capital,
    );
  }
}
