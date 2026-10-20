import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../data/local/app_database.dart';

final isarProvider = Provider<Future<Isar>>((ref) {
  return AppDatabase().init();
});

final databaseProvider = FutureProvider<Isar>((ref) async {
  return ref.watch(isarProvider);
});
