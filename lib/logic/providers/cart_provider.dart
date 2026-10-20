import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/held_order_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import 'repository_providers.dart';

class CartException implements Exception {
  CartException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CartItem {
  const CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.unitCost,
    required this.availableStock,
  });

  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double unitCost;
  final int availableStock;

  double get lineTotal => quantity * unitPrice;

  double get lineCost => quantity * unitCost;

  CartItem copyWith({int? quantity, double? unitPrice}) {
    return CartItem(
      productId: productId,
      productName: productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      unitCost: unitCost,
      availableStock: availableStock,
    );
  }
}

class CartState {
  const CartState({
    required this.items,
    required this.paymentMethod,
    this.amountReceived,
  });

  static const empty = CartState(
    items: [],
    paymentMethod: PaymentMethod.cash,
    amountReceived: null,
  );

  final List<CartItem> items;
  final PaymentMethod paymentMethod;
  final double? amountReceived;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get total => items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get costTotal => items.fold(0.0, (sum, item) => sum + item.lineCost);

  double get grossProfit => total - costTotal;

  double? get change {
    if (amountReceived == null) return null;
    final value = amountReceived! - total;
    return value > 0 ? value : 0;
  }

  bool get requiresAmountReceived =>
      paymentMethod == PaymentMethod.cash ||
      paymentMethod == PaymentMethod.mixed;

  int quantityFor(int productId) {
    for (final item in items) {
      if (item.productId == productId) return item.quantity;
    }
    return 0;
  }

  CartState copyWith({
    List<CartItem>? items,
    PaymentMethod? paymentMethod,
    double? amountReceived,
    bool clearAmountReceived = false,
  }) {
    return CartState(
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountReceived: clearAmountReceived
          ? null
          : (amountReceived ?? this.amountReceived),
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(this._ref) : super(CartState.empty);

  final Ref _ref;

  void addItem(ProductModel product) {
    final existingIndex =
        state.items.indexWhere((item) => item.productId == product.id);
    if (existingIndex >= 0) {
      incrementQuantity(product.id);
      return;
    }
    if (product.currentStock <= 0) {
      throw CartException('${product.name} is out of stock.');
    }
    state = state.copyWith(
      items: [
        ...state.items,
        CartItem(
          productId: product.id,
          productName: product.name,
          quantity: 1,
          unitPrice: product.sellingPrice,
          unitCost: product.costPrice,
          availableStock: product.currentStock,
        ),
      ],
      clearAmountReceived: true,
    );
  }

  void incrementQuantity(int productId) {
    final index =
        state.items.indexWhere((item) => item.productId == productId);
    if (index < 0) return;

    final item = state.items[index];
    if (item.quantity >= item.availableStock) {
      throw CartException(
        'Only ${item.availableStock} of ${item.productName} in stock.',
      );
    }

    final items = [...state.items];
    items[index] = item.copyWith(quantity: item.quantity + 1);
    state = state.copyWith(items: items);
  }

  void decrementQuantity(int productId) {
    final index =
        state.items.indexWhere((item) => item.productId == productId);
    if (index < 0) return;

    final items = [...state.items];
    if (items[index].quantity <= 1) {
      items.removeAt(index);
    } else {
      items[index] = items[index].copyWith(quantity: items[index].quantity - 1);
    }
    state = state.copyWith(items: items);
  }

  void removeItem(int productId) {
    state = state.copyWith(
      items: state.items
          .where((item) => item.productId != productId)
          .toList(),
    );
  }

  void updatePrice(int productId, double newPrice) {
    if (newPrice <= 0) {
      throw CartException('Price must be greater than zero.');
    }
    final index =
        state.items.indexWhere((item) => item.productId == productId);
    if (index < 0) return;

    final items = [...state.items];
    items[index] = items[index].copyWith(unitPrice: newPrice);
    state = state.copyWith(items: items);
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setAmountReceived(double? amount) {
    state = state.copyWith(
      amountReceived: amount,
      clearAmountReceived: amount == null,
    );
  }

  void clearCart() {
    state = CartState.empty;
  }

  /// Records the sale and updates stock atomically. Throws [CartException]
  /// for validation problems before touching the database.
  Future<SaleModel> completeSale({String? cashierName}) async {
    if (state.isEmpty) {
      throw CartException('Cart is empty.');
    }
    if (state.requiresAmountReceived) {
      final received = state.amountReceived;
      if (received == null || received < state.total) {
        throw CartException('Amount received is less than the total.');
      }
    }

    final now = DateTime.now();
    final sale = SaleModel(
      saleDate: now,
      transactionId: 'EFY-${now.millisecondsSinceEpoch}',
      lineItems: state.items
          .map(
            (item) => SaleLineItem()
              ..productId = item.productId
              ..productName = item.productName
              ..quantity = item.quantity
              ..unitPrice = item.unitPrice
              ..unitCost = item.unitCost
              ..lineTotal = item.lineTotal
              ..lineCost = item.lineCost
              ..lineProfit = item.lineTotal - item.lineCost,
          )
          .toList(),
      totalAmount: state.total,
      totalCost: state.costTotal,
      grossProfit: state.grossProfit,
      paymentMethod: state.paymentMethod,
      amountReceived: state.amountReceived,
      changeGiven: state.change,
      cashierName: cashierName,
      createdAt: now,
    );

    final repository = await _ref.read(saleRepositoryProvider.future);
    await repository.createWithStockUpdate(sale);

    state = CartState.empty;
    return sale;
  }

  /// Saves the current cart for later and clears it.
  Future<void> holdOrder({String? note}) async {
    if (state.isEmpty) {
      throw CartException('Cart is empty.');
    }
    final repository = await _ref.read(heldOrderRepositoryProvider.future);
    final order = HeldOrderModel(
      items: state.items
          .map(
            (item) => HeldOrderItem()
              ..productId = item.productId
              ..productName = item.productName
              ..quantity = item.quantity
              ..unitPrice = item.unitPrice
              ..unitCost = item.unitCost
              ..availableStock = item.availableStock,
          )
          .toList(),
      heldAt: DateTime.now(),
      note: note,
    );
    await repository.save(order);
    state = CartState.empty;
  }

  /// Restores a held order, dropping products that were deleted or are now
  /// out of stock.
  Future<void> restoreHeldOrder(HeldOrderModel order) async {
    final productRepository =
        await _ref.read(productRepositoryProvider.future);
    final heldOrderRepository =
        await _ref.read(heldOrderRepositoryProvider.future);

    final items = <CartItem>[];
    for (final heldItem in order.items) {
      final product = await productRepository.getById(heldItem.productId);
      if (product == null || product.isDeleted || product.currentStock <= 0) {
        continue;
      }
      final quantity = heldItem.quantity.clamp(1, product.currentStock);
      items.add(
        CartItem(
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          unitPrice: heldItem.unitPrice,
          unitCost: product.costPrice,
          availableStock: product.currentStock,
        ),
      );
    }

    if (items.isEmpty) {
      throw CartException(
        'None of the products in this held order are still available.',
      );
    }

    state = CartState(
      items: items,
      paymentMethod: state.paymentMethod,
    );
    await heldOrderRepository.delete(order.id);
  }
}
