import 'package:isar/isar.dart';

import '../../core/licensing/license_gate.dart';
import '../models/held_order_model.dart';

class HeldOrderRepository {
  HeldOrderRepository(this._isar, this._licenseGate);

  final Isar _isar;

  /// Enforces the offline licensing policy before held-order mutations.
  final LicenseGate _licenseGate;

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
    await _licenseGate.ensureAllowed(LicensedOperation.manageHeldOrders);
    await _isar.writeTxn(() async {
      order.id = await _isar.heldOrderModels.put(order);
    });
    return order;
  }

  Future<void> delete(int id) async {
    await _licenseGate.ensureAllowed(LicensedOperation.manageHeldOrders);
    await _isar.writeTxn(() async {
      await _isar.heldOrderModels.delete(id);
    });
  }
}
