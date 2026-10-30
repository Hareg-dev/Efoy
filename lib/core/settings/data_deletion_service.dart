import 'package:isar/isar.dart';

import '../../data/models/debt_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/held_order_model.dart';
import '../../data/models/license_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/restock_log_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/user_profile.dart';
import '../security/password_hasher.dart';

/// What a destructive request covers.
enum DataDeletionScope {
  /// Products, sales, expenses, restock logs, held orders and open balances.
  /// The merchant keeps their profile, password and activated license, so the
  /// shop simply starts trading again from an empty book.
  businessRecords,

  /// Everything, including the profile and the license record. The app
  /// returns to first-run state.
  entireAccount,
}

/// Counts shown in the confirmation dialog so the merchant sees exactly what
/// is about to disappear before they agree to it.
class DataDeletionSummary {
  const DataDeletionSummary({
    required this.products,
    required this.sales,
    required this.expenses,
    required this.restockLogs,
    required this.heldOrders,
    required this.debts,
    required this.profileExists,
    required this.licenses,
  });

  final int products;
  final int sales;
  final int expenses;
  final int restockLogs;
  final int heldOrders;
  final int debts;
  final bool profileExists;
  final int licenses;

  int get businessTotal =>
      products + sales + expenses + restockLogs + heldOrders + debts;
}

/// Raised when a deletion was refused. The message is safe to show.
class DataDeletionDenied implements Exception {
  const DataDeletionDenied(this.message);

  final String message;

  @override
  String toString() => 'DataDeletionDenied: $message';
}

/// Password-gated deletion behind Settings → Delete data.
///
/// The app has no staff roles, so the only permission signal that exists is
/// the merchant's own account password: whoever knows it owns the shop. A
/// profile without a password cannot delete anything, because there is no way
/// to tell the owner from a stranger holding an unlocked phone.
///
/// This is the only place in the app that removes business records, and it is
/// never reachable from license expiry — an expired license stays read-only.
class DataDeletionService {
  const DataDeletionService(this._isar);

  final Isar _isar;

  Future<DataDeletionSummary> summarize() async {
    final counts = await Future.wait([
      _isar.productModels.where().count(),
      _isar.saleModels.where().count(),
      _isar.expenseModels.where().count(),
      _isar.restockLogModels.where().count(),
      _isar.heldOrderModels.where().count(),
      _isar.debtModels.where().count(),
    ]);
    return DataDeletionSummary(
      products: counts[0],
      sales: counts[1],
      expenses: counts[2],
      restockLogs: counts[3],
      heldOrders: counts[4],
      debts: counts[5],
      profileExists: await _isar.userProfiles.where().count() > 0,
      licenses: await _isar.licenseModels.where().count(),
    );
  }

  /// Deletes after confirming the password. Returns the counts that were
  /// removed, captured before the write so the UI can report them.
  Future<DataDeletionSummary> delete({
    required DataDeletionScope scope,
    required String password,
  }) async {
    final profile = await _isar.userProfiles.where().findFirst();
    if (profile == null || profile.passwordHash == null) {
      throw const DataDeletionDenied(
        'No account password is set, so this device cannot verify who is '
        'asking. Create a password in Profile first.',
      );
    }
    if (!PasswordHasher.verify(password, profile.passwordHash)) {
      throw const DataDeletionDenied('That password is not correct.');
    }

    final before = await summarize();

    await _isar.writeTxn(() async {
      switch (scope) {
        case DataDeletionScope.businessRecords:
          await _isar.productModels.where().deleteAll();
          await _isar.saleModels.where().deleteAll();
          await _isar.expenseModels.where().deleteAll();
          await _isar.restockLogModels.where().deleteAll();
          await _isar.heldOrderModels.where().deleteAll();
          await _isar.debtModels.where().deleteAll();
        case DataDeletionScope.entireAccount:
          await _isar.clear();
      }
    });

    return before;
  }
}
