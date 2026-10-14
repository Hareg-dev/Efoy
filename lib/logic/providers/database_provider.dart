import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/restock_log_model.dart';
import '../../data/models/license_model.dart';
import '../../data/models/user_profile.dart';

// Isar database provider
final isarProvider = Provider<Future<Isar>>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [
      ProductModelSchema,
      SaleModelSchema,
      ExpenseModelSchema,
      RestockLogModelSchema,
      LicenseModelSchema,
      UserProfileSchema,
    ],
    directory: dir.path,
  );
});

// Database helper provider (synchronous access after init)
final databaseProvider = FutureProvider<Isar>((ref) async {
  return await ref.watch(isarProvider);
});
