import 'package:isar/isar.dart';

part 'sale_model.g.dart';

@collection
class SaleModel {
  Id id = Isar.autoIncrement;

  // Transaction metadata
  @Index()
  late DateTime saleDate;
  
  late String transactionId; // UUID for unique identification

  // Line items stored as JSON-encoded list
  late List<SaleLineItem> lineItems;

  // Financial totals
  late double totalAmount; // Revenue
  late double totalCost; // COGS (sum of line item costs)
  late double grossProfit; // totalAmount - totalCost

  // Payment information
  @enumerated
  late PaymentMethod paymentMethod;
  
  double? amountReceived;
  double? changeGiven;

  // Optional metadata
  String? notes;
  String? cashierName;

  // Audit
  late DateTime createdAt;
  bool isVoided = false;
  DateTime? voidedAt;

  SaleModel({
    required this.saleDate,
    required this.transactionId,
    required this.lineItems,
    required this.totalAmount,
    required this.totalCost,
    required this.grossProfit,
    required this.paymentMethod,
    this.amountReceived,
    this.changeGiven,
    this.notes,
    this.cashierName,
    required this.createdAt,
    this.isVoided = false,
    this.voidedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleDate': saleDate.toIso8601String(),
      'transactionId': transactionId,
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'totalCost': totalCost,
      'grossProfit': grossProfit,
      'paymentMethod': paymentMethod.name,
      'amountReceived': amountReceived,
      'changeGiven': changeGiven,
      'notes': notes,
      'cashierName': cashierName,
      'createdAt': createdAt.toIso8601String(),
      'isVoided': isVoided,
      'voidedAt': voidedAt?.toIso8601String(),
    };
  }

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      saleDate: json['saleDate'] != null ? DateTime.parse(json['saleDate'] as String) : DateTime.now(),
      transactionId: json['transactionId'] as String,
      lineItems: (json['lineItems'] as List)
          .map((item) => SaleLineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      totalCost: (json['totalCost'] as num).toDouble(),
      grossProfit: (json['grossProfit'] as num).toDouble(),
      paymentMethod: PaymentMethod.values.byName(json['paymentMethod'] as String),
      amountReceived: (json['amountReceived'] as num?)?.toDouble(),
      changeGiven: (json['changeGiven'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      cashierName: json['cashierName'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      isVoided: json['isVoided'] as bool? ?? false,
      voidedAt: json['voidedAt'] != null ? DateTime.parse(json['voidedAt'] as String) : null,
    )..id = json['id'] as int;
  }
}

@embedded
class SaleLineItem {
  int productId = 0;
  String productName = '';
  int quantity = 0;
  double unitPrice = 0.0; // Selling price used in this transaction
  double unitCost = 0.0; // WAC at time of sale
  double lineTotal = 0.0; // quantity * unitPrice
  double lineCost = 0.0; // quantity * unitCost
  double lineProfit = 0.0; // lineTotal - lineCost

  SaleLineItem();

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'unitCost': unitCost,
      'lineTotal': lineTotal,
      'lineCost': lineCost,
      'lineProfit': lineProfit,
    };
  }

  factory SaleLineItem.fromJson(Map<String, dynamic> json) {
    return SaleLineItem()
      ..productId = json['productId'] as int
      ..productName = json['productName'] as String
      ..quantity = json['quantity'] as int
      ..unitPrice = (json['unitPrice'] as num).toDouble()
      ..unitCost = (json['unitCost'] as num).toDouble()
      ..lineTotal = (json['lineTotal'] as num).toDouble()
      ..lineCost = (json['lineCost'] as num).toDouble()
      ..lineProfit = (json['lineProfit'] as num).toDouble();
  }
}

enum PaymentMethod {
  cash,
  telebirr,
  cbeBirr,
  amharaBank,
  mixed,
}
