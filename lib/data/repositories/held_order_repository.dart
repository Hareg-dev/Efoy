import 'package:isar/isar.dart';

import '../models/held_order_model.dart';

class HeldOrderRepository {
  HeldOrderRepository(this._isar);

  final Isar _isar;

  Stream<List<HeldOrderModel>> watchAll() {
    return _isar.heldOrderModels
        .where()
        .sortByHeldAtDesc()
        .watch(fireImmediately: true);
  }

  Future<List<HeldOrderModel>> getAll() {
    return _isar.heldOrderModels.where().sortByHeldAtDesc().findAll();
  }

  Future<HeldOrderModel> save(HeldOrderModel order) async {
    await _isar.writeTxn(() async {
      order.id = await _isar.heldOrderModels.put(order);
    });
    return order;
  }

  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.heldOrderModels.delete(id);
    });
  }
}
