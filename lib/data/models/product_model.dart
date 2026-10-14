import 'package:isar/isar.dart';

part 'product_model.g.dart';

@collection
class ProductModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String name;

  String? description;

  @Index()
  String? barcode;

  // Financial fields
  late double sellingPrice; // Retail price per unit
  late double costPrice; // Weighted Average Cost (WAC)
  
  // Stock management
  late int currentStock;
  late int lowStockThreshold;

  // Category & organization
  String? category;
  String? imageUrl;

  // Audit timestamps
  late DateTime createdAt;
  late DateTime updatedAt;

  // Track if product was deleted (soft delete)
  @Index()
  bool isDeleted = false;

  ProductModel({
    required this.name,
    this.description,
    this.barcode,
    required this.sellingPrice,
    required this.costPrice,
    required this.currentStock,
    this.lowStockThreshold = 10,
    this.category,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  // Computed properties
  bool get isLowStock => currentStock <= lowStockThreshold && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;
  
  double get liquidityValue => currentStock * sellingPrice;
  double get inventoryValue => currentStock * costPrice;
  
  double get potentialProfit => liquidityValue - inventoryValue;
  double get profitMargin => sellingPrice > 0 
      ? (sellingPrice - costPrice) / sellingPrice 
      : 0;

  // Copy with method for updates
  ProductModel copyWith({
    String? name,
    String? description,
    String? barcode,
    double? sellingPrice,
    double? costPrice,
    int? currentStock,
    int? lowStockThreshold,
    String? category,
    String? imageUrl,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return ProductModel(
      name: name ?? this.name,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      currentStock: currentStock ?? this.currentStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
    )..id = id;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'barcode': barcode,
      'sellingPrice': sellingPrice,
      'costPrice': costPrice,
      'currentStock': currentStock,
      'lowStockThreshold': lowStockThreshold,
      'category': category,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      name: json['name'] as String,
      description: json['description'] as String?,
      barcode: json['barcode'] as String?,
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      costPrice: (json['costPrice'] as num).toDouble(),
      currentStock: json['currentStock'] as int,
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 10,
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
      isDeleted: json['isDeleted'] as bool? ?? false,
    )..id = json['id'] as int;
  }
}
