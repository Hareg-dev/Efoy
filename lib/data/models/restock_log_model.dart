import 'package:isar/isar.dart';

part 'restock_log_model.g.dart';

@collection
class RestockLogModel {
  Id id = Isar.autoIncrement;

  // Product reference
  @Index()
  late int productId;
  late String productName;

  // Restock details
  late int quantityAdded;
  late double purchasePrice; // Unit purchase price for this batch
  late double totalCost; // quantityAdded * purchasePrice

  // Stock levels at time of restock
  late int stockBefore;
  late int stockAfter;

  // WAC calculation
  late double wacBefore; // Weighted Average Cost before restock
  late double wacAfter; // New WAC after applying formula

  // Timestamp
  @Index()
  late DateTime restockDate;
  late DateTime createdAt;

  // Optional metadata
  String? supplierName;
  String? invoiceNumber;
  String? notes;

  RestockLogModel({
    required this.productId,
    required this.productName,
    required this.quantityAdded,
    required this.purchasePrice,
    required this.totalCost,
    required this.stockBefore,
    required this.stockAfter,
    required this.wacBefore,
    required this.wacAfter,
    required this.restockDate,
    required this.createdAt,
    this.supplierName,
    this.invoiceNumber,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantityAdded': quantityAdded,
      'purchasePrice': purchasePrice,
      'totalCost': totalCost,
      'stockBefore': stockBefore,
      'stockAfter': stockAfter,
      'wacBefore': wacBefore,
      'wacAfter': wacAfter,
      'restockDate': restockDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'supplierName': supplierName,
      'invoiceNumber': invoiceNumber,
      'notes': notes,
    };
  }

  factory RestockLogModel.fromJson(Map<String, dynamic> json) {
    return RestockLogModel(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      quantityAdded: json['quantityAdded'] as int,
      purchasePrice: (json['purchasePrice'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      stockBefore: json['stockBefore'] as int,
      stockAfter: json['stockAfter'] as int,
      wacBefore: (json['wacBefore'] as num).toDouble(),
      wacAfter: (json['wacAfter'] as num).toDouble(),
      restockDate: json['restockDate'] != null ? DateTime.parse(json['restockDate'] as String) : DateTime.now(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      supplierName: json['supplierName'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      notes: json['notes'] as String?,
    )..id = json['id'] as int;
  }
}
