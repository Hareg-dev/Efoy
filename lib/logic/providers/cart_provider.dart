import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/debt_model.dart';
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

/// How much of this invoice is actually being settled at the counter.
enum SalePaymentPlan {
  /// The customer hands over the whole amount, in cash or by mobile money.
  paidInFull,

  /// Some of it now, the rest goes on the debts list under the customer's name.
  partPayment,

  /// Nothing now. The whole invoice goes on the debts list.
  onCredit,
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
    this.paymentPlan = SalePaymentPlan.paidInFull,
    this.customerName,
  });

  static const empty = CartState(
    items: [],
    paymentMethod: PaymentMethod.cash,
    amountReceived: null,
  );

  final List<CartItem> items;
  final PaymentMethod paymentMethod;
  final double? amountReceived;
  final SalePaymentPlan paymentPlan;

  /// Whose name the balance goes under when this invoice is not settled now.
  final String? customerName;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  double get total => items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get costTotal => items.fold(0.0, (sum, item) => sum + item.lineCost);

  double get grossProfit => total - costTotal;

  bool get isOnCredit => paymentPlan == SalePaymentPlan.onCredit;

  bool get leavesABalance => paymentPlan != SalePaymentPlan.paidInFull;

  /// Cash or mobile money actually taken at the counter for this invoice.
  double get collectedNow {
    switch (paymentPlan) {
      case SalePaymentPlan.onCredit:
        return 0;
      case SalePaymentPlan.partPayment:
        return (amountReceived ?? 0).clamp(0.0, total);
      case SalePaymentPlan.paidInFull:
        if (amountReceived == null) return total;
        return amountReceived! >= total ? total : amountReceived!;
    }
  }

  /// What still has to come in after this sale is recorded.
  double get balanceDue {
    final remaining = total - collectedNow;
    return remaining > 0 ? remaining : 0;
  }

  double? get change {
    if (paymentPlan != SalePaymentPlan.paidInFull || amountReceived == null) {
      return null;
    }
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
    SalePaymentPlan? paymentPlan,
    String? customerName,
    bool clearCustomerName = false,
  }) {
    return CartState(
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountReceived: clearAmountReceived
          ? null
          : (amountReceived ?? this.amountReceived),
      paymentPlan: paymentPlan ?? this.paymentPlan,
      customerName: clearCustomerName
          ? null
          : (customerName ?? this.customerName),
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
    final existingIndex = state.items.indexWhere(
      (item) => item.productId == product.id,
    );
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
    final index = state.items.indexWhere((item) => item.productId == productId);
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
    final index = state.items.indexWhere((item) => item.productId == productId);
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
      items: state.items.where((item) => item.productId != productId).toList(),
    );
  }

  void updatePrice(int productId, double newPrice) {
    if (newPrice <= 0) {
      throw CartException('Price must be greater than zero.');
    }
    final index = state.items.indexWhere((item) => item.productId == productId);
    if (index < 0) return;

    final items = [...state.items];
    items[index] = items[index].copyWith(unitPrice: newPrice);
    state = state.copyWith(items: items);
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(paymentMethod: method);
  }

  /// Choosing "on credit" takes the tender field away - there is nothing
  /// coming in at the counter to record.
  void setPaymentPlan(SalePaymentPlan plan) {
    state = state.copyWith(
      paymentPlan: plan,
      clearAmountReceived: plan == SalePaymentPlan.onCredit,
    );
  }

  void setCustomerName(String? name) {
    final trimmed = name?.trim() ?? '';
    state = state.copyWith(
      customerName: trimmed,
      clearCustomerName: trimmed.isEmpty,
    );
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
    final customerName = state.customerName?.trim() ?? '';
    switch (state.paymentPlan) {
      case SalePaymentPlan.paidInFull:
        if (state.requiresAmountReceived) {
          final received = state.amountReceived;
          if (received == null || received < state.total) {
            throw CartException('Amount received is less than the total.');
          }
        }
      case SalePaymentPlan.partPayment:
        final received = state.amountReceived;
        if (received == null || received <= 0) {
          throw CartException(
            'Enter the part payment the customer handed over.',
          );
        }
        if (received >= state.total) {
          throw CartException(
            'That covers the whole invoice - choose Paid in full instead.',
          );
        }
        _requireCustomerName(customerName);
      case SalePaymentPlan.onCredit:
        _requireCustomerName(customerName);
    }

    final balanceDue = state.balanceDue;
    final now = DateTime.now();
    final transactionId = 'EFY-${now.millisecondsSinceEpoch}';
    final sale = SaleModel(
      saleDate: now,
      transactionId: transactionId,
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
      paymentMethod: balanceDue > 0 && state.collectedNow == 0
          ? PaymentMethod.credit
          : state.paymentMethod,
      // What the till actually keeps: an 800 Birr tender on a 780 invoice is
      // 780 Birr of income and 20 Birr back to the customer, never 800.
      amountReceived: state.collectedNow,
      changeGiven: state.change,
      notes: customerName.isEmpty
          ? null
          : 'Customer: $customerName · Balance ${balanceDue.toStringAsFixed(2)}',
      cashierName: cashierName,
      createdAt: now,
    );

    // The invoice keeps its full value - the margin was earned today - and the
    // unpaid part becomes a separate receivable the merchant can settle later.
    final debt = balanceDue <= 0
        ? null
        : DebtModel(
            saleTransactionId: transactionId,
            customerName: customerName,
            totalAmount: state.total,
            paidAmount: state.collectedNow,
            openedAt: now,
          );

    final repository = await _ref.read(saleRepositoryProvider.future);
    await repository.createWithStockUpdate(sale, debt: debt);

    state = CartState.empty;
    return sale;
  }

  void _requireCustomerName(String customerName) {
    if (customerName.isEmpty) {
      throw CartException(
        'Write the customer name so the balance can be tracked.',
      );
    }
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
    final productRepository = await _ref.read(productRepositoryProvider.future);
    final heldOrderRepository = await _ref.read(
      heldOrderRepositoryProvider.future,
    );

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

    state = CartState(items: items, paymentMethod: state.paymentMethod);
    await heldOrderRepository.delete(order.id);
  }
}
