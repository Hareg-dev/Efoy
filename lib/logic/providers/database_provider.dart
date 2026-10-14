import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../data/models/expense.dart';
import '../../data/models/restock_log.dart';
import '../../data/models/license.dart';
import '../../data/models/user_profile.dart';

// Isar database provider
final isarProvider = Provider<Future<Isar>>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  return Isar.open(
    [
      ProductSchema,
      SaleSchema,
      ExpenseSchema,
      RestockLogSchema,
      LicenseSchema,
      UserProfileSchema,
    ],
    directory: dir.path,
  );
});

// Database helper provider (synchronous access after init)
final databaseProvider = FutureProvider<Isar>((ref) async {
  return await ref.watch(isarProvider);
});
