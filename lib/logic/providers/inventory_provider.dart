import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product_model.dart';
import 'repository_providers.dart';

enum StockFilter { all, inStock, lowStock, outOfStock }

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
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          (product.barcode?.toLowerCase().contains(query) ?? false);
      if (!matchesQuery) return false;

      switch (filter) {
        case StockFilter.all:
          return true;
        case StockFilter.inStock:
          return product.currentStock > 0;
        case StockFilter.lowStock:
          return product.isLowStock;
        case StockFilter.outOfStock:
          return product.isOutOfStock;
      }
    }).toList();
  }

  List<ProductModel> get lowStockProducts {
    return allProducts
        .where((product) =>
            product.currentStock <= product.lowStockThreshold)
        .toList()
      ..sort((a, b) => a.currentStock.compareTo(b.currentStock));
  }

  int get lowStockCount => lowStockProducts.length;

  int get outOfStockCount =>
      allProducts.where((product) => product.isOutOfStock).length;

  int get activeCount => allProducts.length;

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
