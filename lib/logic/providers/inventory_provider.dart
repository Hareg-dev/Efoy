import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product_model.dart';
import '../calculators/inventory_valuation.dart';
import 'repository_providers.dart';

/// Stock buckets shown as filter pills.
///
/// [needsRestock] is deliberately the wider bucket (`stock <= threshold`,
/// sold-out included) because that is the list a merchant acts on; the same
/// rule backs the low-stock card and the home alerts so no two screens can
/// report a different count. [outOfStock] is the drill-down of that list.
enum StockFilter { all, inStock, needsRestock, outOfStock }

class InventoryState {
  const InventoryState({
    required this.allProducts,
    required this.searchQuery,
    required this.filter,
    this.isLoading = false,
  });

  static const empty = InventoryState(
    allProducts: [],
    searchQuery: '',
    filter: StockFilter.all,
    isLoading: true,
  );

  final List<ProductModel> allProducts;
  final String searchQuery;
  final StockFilter filter;
  final bool isLoading;

  List<ProductModel> get products {
    final query = searchQuery.trim().toLowerCase();
    return allProducts.where((product) {
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          (product.barcode?.toLowerCase().contains(query) ?? false);
      if (!matchesQuery) return false;

      switch (filter) {
        case StockFilter.all:
          return true;
        case StockFilter.inStock:
          return product.currentStock > 0;
        case StockFilter.needsRestock:
          return product.needsRestock;
        case StockFilter.outOfStock:
          return product.isOutOfStock;
      }
    }).toList();
  }

  /// Everything the merchant should reorder, lowest stock first.
  List<ProductModel> get needsRestockProducts {
    return allProducts.where((product) => product.needsRestock).toList()
      ..sort((a, b) => a.currentStock.compareTo(b.currentStock));
  }

  int get needsRestockCount => needsRestockProducts.length;

  int get outOfStockCount =>
      allProducts.where((product) => product.isOutOfStock).length;

  int get activeCount => allProducts.length;

  /// Total units sitting on the shelves.
  int get stockUnits =>
      allProducts.fold<int>(0, (sum, product) => sum + product.currentStock);

  InventoryState copyWith({
    List<ProductModel>? allProducts,
    String? searchQuery,
    StockFilter? filter,
    bool? isLoading,
  }) {
    return InventoryState(
      allProducts: allProducts ?? this.allProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
      return InventoryNotifier(ref);
    });

class InventoryNotifier extends StateNotifier<InventoryState> {
  InventoryNotifier(this._ref) : super(InventoryState.empty) {
    _init();
  }

  final Ref _ref;
  StreamSubscription<List<ProductModel>>? _subscription;

  Future<void> _init() async {
    try {
      final repository = await _ref.read(productRepositoryProvider.future);
      _subscription = repository.watchAll().listen((products) {
        if (!mounted) return;
        state = state.copyWith(allProducts: products, isLoading: false);
      });
      _ref.onDispose(() {
        _subscription?.cancel();
      });
    } catch (_) {
      // The database may be unavailable (e.g. web). The UI shows the empty
      // state in that case.
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(StockFilter filter) {
    state = state.copyWith(filter: filter);
  }
}

/// Whole-stock valuation (units, cost value, liquidity value) for the live
/// product list. Same calculator the Excel report uses.
final inventoryValuationProvider = Provider<InventoryValuation>((ref) {
  return InventoryValuation.of(ref.watch(inventoryProvider).allProducts);
});
