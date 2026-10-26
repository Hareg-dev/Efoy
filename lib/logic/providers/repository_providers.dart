import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/expense_model.dart';
import '../../data/models/held_order_model.dart';
import '../../data/models/license_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/held_order_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/sale_repository.dart';
import '../../data/repositories/user_repository.dart';
import 'database_provider.dart';
import 'license_provider.dart';

final productRepositoryProvider = FutureProvider<ProductRepository>((ref) async {
  final isar = await ref.watch(databaseProvider.future);
  final gate = await ref.watch(licenseGateProvider.future);
  return ProductRepository(isar, gate);
});

final saleRepositoryProvider = FutureProvider<SaleRepository>((ref) async {
  final isar = await ref.watch(databaseProvider.future);
  final gate = await ref.watch(licenseGateProvider.future);
  return SaleRepository(isar, gate);
});

final expenseRepositoryProvider = FutureProvider<ExpenseRepository>((ref) async {
  final isar = await ref.watch(databaseProvider.future);
  final gate = await ref.watch(licenseGateProvider.future);
  return ExpenseRepository(isar, gate);
});

final heldOrderRepositoryProvider =
    FutureProvider<HeldOrderRepository>((ref) async {
  final isar = await ref.watch(databaseProvider.future);
  final gate = await ref.watch(licenseGateProvider.future);
  return HeldOrderRepository(isar, gate);
});

final userRepositoryProvider = FutureProvider<UserRepository>((ref) async {
  final isar = await ref.watch(databaseProvider.future);
  return UserRepository(isar);
});

/// Live product list used by the sell grid and inventory screen.
final productListProvider = StreamProvider<List<ProductModel>>((ref) async* {
  final repository = await ref.watch(productRepositoryProvider.future);
  yield* repository.watchAll();
});

/// Live expense list used by the expenses screen.
final expenseListProvider = StreamProvider<List<ExpenseModel>>((ref) async* {
  final repository = await ref.watch(expenseRepositoryProvider.future);
  yield* repository.watchAll();
});

/// Live held orders.
final heldOrdersProvider = StreamProvider<List<HeldOrderModel>>((ref) async* {
  final repository = await ref.watch(heldOrderRepositoryProvider.future);
  yield* repository.watchAll();
});

/// Live user profile.
final userProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  final repository = await ref.watch(userRepositoryProvider.future);
  yield* repository.watchProfile();
});

/// Currently active license (if any).
final activeLicenseProvider = FutureProvider<LicenseModel?>((ref) async {
  final repository = await ref.watch(userRepositoryProvider.future);
  return repository.getActiveLicense();
});

/// Most recently activated license, regardless of status.
final latestLicenseProvider = FutureProvider<LicenseModel?>((ref) async {
  final repository = await ref.watch(userRepositoryProvider.future);
  return repository.getLicense();
});
