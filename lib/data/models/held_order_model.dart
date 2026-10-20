import 'package:isar/isar.dart';

part 'held_order_model.g.dart';

/// A cart saved for later ("hold order").
@collection
class HeldOrderModel {
  Id id = Isar.autoIncrement;

  late List<HeldOrderItem> items;

  @Index()
  late DateTime heldAt;

  String? note;

  HeldOrderModel({
    required this.items,
    required this.heldAt,
    this.note,
  });

  double get total => items.fold(0, (sum, item) => sum + item.lineTotal);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'heldAt': heldAt.toIso8601String(),
      'note': note,
    };
  }

  factory HeldOrderModel.fromJson(Map<String, dynamic> json) {
    return HeldOrderModel(
      items: (json['items'] as List)
          .map((item) => HeldOrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      heldAt: json['heldAt'] != null
          ? DateTime.parse(json['heldAt'] as String)
          : DateTime.now(),
      note: json['note'] as String?,
    )..id = json['id'] as int;
  }
}

@embedded
class HeldOrderItem {
  int productId = 0;
  String productName = '';
  int quantity = 0;
  double unitPrice = 0.0;
  double unitCost = 0.0;
  int availableStock = 0;

  HeldOrderItem();

  double get lineTotal => quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unitCost': unitCost,
      'availableStock': availableStock,
    };
  }

  factory HeldOrderItem.fromJson(Map<String, dynamic> json) {
    return HeldOrderItem()
      ..productId = json['productId'] as int
      ..productName = json['productName'] as String
      ..quantity = json['quantity'] as int
      ..unitPrice = (json['unitPrice'] as num).toDouble()
      ..unitCost = (json['unitCost'] as num).toDouble()
      ..availableStock = json['availableStock'] as int? ?? 0;
  }
}
