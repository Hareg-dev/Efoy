import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/l10n.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../logic/providers/inventory_provider.dart';
import '../../logic/providers/repository_providers.dart';
import '../animations/pill_transition.dart';
import '../animations/pulsing_dot.dart';
import '../widgets/restock_modal.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inventory = ref.watch(inventoryProvider);
    final notifier = ref.read(inventoryProvider.notifier);
    final products = inventory.products;
    final hasQuery = inventory.searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceM,
                AppTheme.spaceM,
                AppTheme.spaceM,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _Header(
                  productCount: inventory.activeCount,
                  onAdd: () => _openProductForm(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceM,
                AppTheme.spaceM,
                AppTheme.spaceM,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (inventory.lowStockCount > 0) ...[
                      _LowStockCard(
                        products: inventory.lowStockProducts,
                        onProductTap: _openProductDetail,
                        onViewAll: () {
                          _searchController.clear();
                          notifier
                            ..setSearchQuery('')
                            ..setFilter(StockFilter.lowStock);
                        },
                      ),
                      const SizedBox(height: AppTheme.spaceM),
                    ],
                    TextField(
                      controller: _searchController,
                      onChanged: notifier.setSearchQuery,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: context.tr(
                          'Search by name or barcode',
                          'በስም ወይም በባርኮድ ይፈልጉ',
                        ),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: hasQuery
                            ? IconButton(
                                tooltip: context.tr('Clear', 'አጽዳ'),
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  notifier.setSearchQuery('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: theme.brightness == Brightness.dark
                            ? scheme.surfaceContainerHighest
                                .withValues(alpha: 0.35)
                            : Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceM,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide(
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                          borderSide: BorderSide(
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FilterRow(
                      inventory: inventory,
                      onSelected: notifier.setFilter,
                    ),
                  ],
                ),
              ),
            ),
            if (inventory.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (products.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyProducts(
                  hasQuery: hasQuery || inventory.filter != StockFilter.all,
                  onAdd: () => _openProductForm(),
                  onReset: () {
                    _searchController.clear();
                    notifier
                      ..setSearchQuery('')
                      ..setFilter(StockFilter.all);
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceM,
                  AppTheme.spaceM,
                  AppTheme.spaceM,
                  120,
                ),
                sliver: SliverList.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTheme.spaceS),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductTile(
                      product: product,
                      onTap: () => _openProductDetail(product),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProductDetail(ProductModel product) async {
    final action = await showModalBottomSheet<_DetailAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(product: product),
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _DetailAction.restock:
        await _restock(product);
      case _DetailAction.edit:
        await _openProductForm(product: product);
      case _DetailAction.delete:
        await _confirmDelete(product);
    }
  }

  Future<void> _restock(ProductModel product) async {
    final result = await showDialog<RestockResult>(
      context: context,
      builder: (_) => RestockModal(product: product),
    );
    if (!mounted || result == null) return;
    _showMessage(
      context.tr(
        'Restocked ${result.log.quantityAdded} units · new WAC '
        '${CurrencyFormatter.formatBirr(result.product.costPrice)}',
        '${result.log.quantityAdded} አሃድ ተጨምሯል · አዲስ አማካይ ወጪ '
        '${CurrencyFormatter.formatBirr(result.product.costPrice)}',
      ),
    );
  }

  Future<void> _openProductForm({ProductModel? product}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ProductFormDialog(product: product),
    );
    if (!mounted || saved != true) return;
    _showMessage(
      product == null
          ? context.tr('Product added', 'እቃ ተጨምሯል')
          : context.tr('Product updated', 'እቃ ተስተካክሏል'),
    );
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Delete product?', 'እቃውን ይሰርዙ?')),
        content: Text(
          context.tr(
            '"${product.name}" will be removed from inventory. Past sales '
            'history stays intact.',
            '"${product.name}" ከክምችት ይወገዳል። ያለፈው የሽያጭ ታሪክ አይጠፋም።',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('Cancel', 'ሰርዝ')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('Delete', 'አጥፋ')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    try {
      final repository = await ref.read(productRepositoryProvider.future);
      await repository.delete(product.id);
      if (!mounted) return;
      _showMessage(context.tr('Product deleted', 'እቃው ተሰርዟል'));
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString(), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.alertRed : AppColors.primaryTeal,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.productCount, required this.onAdd});

  final int productCount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('INVENTORY', 'ክምችት'),
                style: TextStyle(
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(
                  '$productCount products tracked',
                  '$productCount እቃዎች በክትትል ላይ',
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onAdd,
          style: FilledButton.styleFrom(
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            context.tr('Add', 'ጨምር'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Low stock alert
// ---------------------------------------------------------------------------

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({
    required this.products,
    required this.onProductTap,
    required this.onViewAll,
  });

  final List<ProductModel> products;
  final ValueChanged<ProductModel> onProductTap;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const accent = AppColors.alertAmber;
    final visible = products.take(4).toList();
    final remaining = products.length - visible.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? accent.withValues(alpha: 0.10) : AppColors.alertAmberBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isDark
              ? accent.withValues(alpha: 0.35)
              : AppColors.alertAmberBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PulsingDot(size: 8, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('Low stock alert', 'ዝቅተኛ ክምችት ማስጠንቀቂያ'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${products.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              context.tr(
                '${products.length} products at or below their threshold',
                '${products.length} እቃዎች ከተቀመጠው መጠን በታች ናቸው',
              ),
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...visible.map(
            (product) => InkWell(
              onTap: () => onProductTap(product),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.isOutOfStock
                          ? context.tr('Out', 'ከክምችት ውጪ')
                          : context.tr(
                              '${product.currentStock} left',
                              '${product.currentStock} ቀሪ',
                            ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: accent.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  context.tr(
                    'View all $remaining low-stock items',
                    'ሁሉንም $remaining ዝቅተኛ ክምችቶች ይመልከቱ',
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.inventory, required this.onSelected});

  final InventoryState inventory;
  final ValueChanged<StockFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final counts = {
      StockFilter.all: inventory.activeCount,
      StockFilter.inStock:
          inventory.allProducts.where((p) => p.currentStock > 0).length,
      StockFilter.lowStock:
          inventory.allProducts.where((p) => p.isLowStock).length,
      StockFilter.outOfStock: inventory.outOfStockCount,
    };

    String label(StockFilter filter) {
      final String name;
      switch (filter) {
        case StockFilter.all:
          name = context.tr('All', 'ሁሉም');
        case StockFilter.inStock:
          name = context.tr('In Stock', 'በክምችት');
        case StockFilter.lowStock:
          name = context.tr('Low Stock', 'ዝቅተኛ');
        case StockFilter.outOfStock:
          name = context.tr('Out', 'ውጪ');
      }
      return '$name (${counts[filter]})';
    }

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: StockFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = StockFilter.values[index];
          return PillTransition(
            selected: inventory.filter == filter,
            selectedColor: scheme.primary,
            selectedForeground: scheme.onPrimary,
            unselectedColor:
                isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
            unselectedForeground: scheme.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            onTap: () => onSelected(filter),
            child: Text(label(filter)),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product tile
// ---------------------------------------------------------------------------

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});

  final ProductModel product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? scheme.primary.withValues(alpha: 0.16)
                      : AppColors.tealTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: isDark ? scheme.primary : AppColors.primaryTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.category ??
                          product.barcode ??
                          context.tr('Uncategorized', 'ምድብ የለውም'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      CurrencyFormatter.formatBirrWhole(product.sellingPrice),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StockBadge(product: product),
                  const SizedBox(height: 6),
                  Text(
                    context.tr(
                      'min ${product.lowStockThreshold}',
                      'ዝቅተኛ ${product.lowStockThreshold}',
                    ),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (product.isOutOfStock) {
      color = AppColors.alertRed;
      label = context.tr('Out', 'ውጪ');
    } else if (product.isLowStock) {
      color = AppColors.alertAmber;
      label = context.tr(
        'Low · ${product.currentStock}',
        'ዝቅተኛ · ${product.currentStock}',
      );
    } else {
      color = AppColors.successGreen;
      label = context.tr(
        '${product.currentStock} in stock',
        '${product.currentStock} በክምችት',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({
    required this.hasQuery,
    required this.onAdd,
    required this.onReset,
  });

  final bool hasQuery;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                hasQuery ? Icons.search_off : Icons.inventory_2_outlined,
                size: 34,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              hasQuery
                  ? context.tr('No products found', 'ምንም እቃ አልተገኘም')
                  : context.tr('No products yet', 'እስካሁን እቃ የለም'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? context.tr(
                      'Try a different search or filter.',
                      'ሌላ ፍለጋ ወይም ማጣሪያ ይሞክሩ።',
                    )
                  : context.tr(
                      'Add your first product to start tracking stock.',
                      'ክምችት መከታተል ለመጀመር የመጀመሪያውን እቃ ይጨምሩ።',
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceM),
            if (hasQuery)
              OutlinedButton(
                onPressed: onReset,
                child: Text(context.tr('Clear filters', 'ማጣሪያዎችን አጽዳ')),
              )
            else
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text(context.tr('Add product', 'እቃ ጨምር')),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product detail sheet
// ---------------------------------------------------------------------------

enum _DetailAction { restock, edit, delete }

class _ProductDetailSheet extends StatelessWidget {
  const _ProductDetailSheet({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXLarge),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceM,
              10,
              AppTheme.spaceM,
              AppTheme.spaceL,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.primary.withValues(alpha: 0.16)
                            : AppColors.tealTint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: isDark ? scheme.primary : AppColors.primaryTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (product.category != null) product.category!,
                              if (product.barcode != null) product.barcode!,
                            ].join(' · '),
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: context.tr('Close', 'ዝጋ'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StockBadge(product: product),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.formatBirrWhole(product.sellingPrice),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: context.tr('Inventory value', 'የክምችት ዋጋ'),
                        value: CurrencyFormatter.formatBirrWhole(
                          product.inventoryValue,
                        ),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        label: context.tr('Liquidity value', 'የመሸጫ ዋጋ'),
                        value: CurrencyFormatter.formatBirrWhole(
                          product.liquidityValue,
                        ),
                        icon: Icons.trending_up,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: context.tr('Profit margin', 'የትርፍ መጠን'),
                        value: CurrencyFormatter.formatPercentageSimple(
                          product.profitMargin,
                        ),
                        icon: Icons.percent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricTile(
                        label: context.tr('Unit profit', 'የአሃድ ትርፍ'),
                        value: CurrencyFormatter.formatBirr(
                          product.sellingPrice - product.costPrice,
                        ),
                        icon: Icons.savings_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (product.description != null &&
                    product.description!.trim().isNotEmpty) ...[
                  Text(
                    product.description!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _InfoRow(
                  label: context.tr('Cost price (WAC)', 'የወጪ ዋጋ (WAC)'),
                  value: CurrencyFormatter.formatBirr(product.costPrice),
                ),
                _InfoRow(
                  label: context.tr('Stock on hand', 'በክምችት ያለ'),
                  value: context.tr(
                    '${product.currentStock} units',
                    '${product.currentStock} አሃድ',
                  ),
                ),
                _InfoRow(
                  label: context.tr('Low stock threshold', 'ዝቅተኛ ክምችት መጠን'),
                  value: '${product.lowStockThreshold}',
                ),
                if (product.barcode != null)
                  _InfoRow(
                    label: context.tr('Barcode', 'ባርኮድ'),
                    value: product.barcode!,
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(_DetailAction.restock),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                    ),
                    icon: const Icon(Icons.add_box_outlined, size: 20),
                    label: Text(
                      context.tr('Restock product', 'እቃ እንደገና ሙላ'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pop(_DetailAction.edit),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.primary,
                          side: BorderSide(
                            color: scheme.primary.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text(context.tr('Edit', 'አስተካክል')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.of(context).pop(_DetailAction.delete),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.alertRed,
                          side: BorderSide(
                            color: AppColors.alertRed.withValues(alpha: 0.4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(context.tr('Delete', 'አጥፋ')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : scheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: scheme.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add / edit product
// ---------------------------------------------------------------------------

class _ProductFormDialog extends ConsumerStatefulWidget {
  const _ProductFormDialog({this.product});

  final ProductModel? product;

  @override
  ConsumerState<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _barcode;
  late final TextEditingController _category;
  late final TextEditingController _sellingPrice;
  late final TextEditingController _costPrice;
  late final TextEditingController _stock;
  late final TextEditingController _threshold;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    String number(double value) {
      if (value == value.roundToDouble()) return value.toInt().toString();
      return value.toString();
    }

    _name = TextEditingController(text: product?.name ?? '');
    _description = TextEditingController(text: product?.description ?? '');
    _barcode = TextEditingController(text: product?.barcode ?? '');
    _category = TextEditingController(text: product?.category ?? '');
    _sellingPrice = TextEditingController(
      text: product == null ? '' : number(product.sellingPrice),
    );
    _costPrice = TextEditingController(
      text: product == null ? '' : number(product.costPrice),
    );
    _stock = TextEditingController(
      text: product == null ? '0' : '${product.currentStock}',
    );
    _threshold = TextEditingController(
      text: product == null ? '10' : '${product.lowStockThreshold}',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _barcode.dispose();
    _category.dispose();
    _sellingPrice.dispose();
    _costPrice.dispose();
    _stock.dispose();
    _threshold.dispose();
    super.dispose();
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final selling = double.tryParse(_sellingPrice.text.trim());
    final cost = _costPrice.text.trim().isEmpty
        ? 0.0
        : double.tryParse(_costPrice.text.trim());
    final stock = int.tryParse(_stock.text.trim());
    final threshold = int.tryParse(_threshold.text.trim());

    final error = switch (null) {
      _ when name.isEmpty => context.tr(
          'Product name is required.',
          'የእቃው ስም ያስፈልጋል።',
        ),
      _ when selling == null || selling <= 0 => context.tr(
          'Enter a valid selling price.',
          'ትክክለኛ የመሸጫ ዋጋ ያስገቡ።',
        ),
      _ when cost == null || cost < 0 => context.tr(
          'Enter a valid cost price.',
          'ትክክለኛ የወጪ ዋጋ ያስገቡ።',
        ),
      _ when stock == null || stock < 0 => context.tr(
          'Stock cannot be negative.',
          'ክምችት አሉታዊ መሆን አይችልም።',
        ),
      _ when threshold == null || threshold < 0 => context.tr(
          'Low stock threshold cannot be negative.',
          'ዝቅተኛ ክምችት መጠን አሉታዊ መሆን አይችልም።',
        ),
      _ => null,
    };
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repository = await ref.read(productRepositoryProvider.future);
      final now = DateTime.now();
      final entity = ProductModel(
        name: name,
        description: _emptyToNull(_description.text),
        barcode: _emptyToNull(_barcode.text),
        category: _emptyToNull(_category.text),
        sellingPrice: selling!,
        costPrice: cost!,
        currentStock: stock!,
        lowStockThreshold: threshold!,
        createdAt: widget.product?.createdAt ?? now,
        updatedAt: now,
      );
      if (widget.product != null) {
        entity.id = widget.product!.id;
        await repository.update(entity);
      } else {
        await repository.create(entity);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    InputDecoration decoration(String label, {String? prefix}) {
      return InputDecoration(
        labelText: label,
        prefixText: prefix,
        isDense: true,
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : Colors.white,
      );
    }

    Widget field({
      required TextEditingController controller,
      required String label,
      IconData? icon,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters,
      int maxLines = 1,
      bool autofocus = false,
      String? prefix,
    }) {
      return TextField(
        controller: controller,
        autofocus: autofocus,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: decoration(label, prefix: prefix).copyWith(
          prefixIcon: icon == null ? null : Icon(icon, size: 18),
        ),
      );
    }

    final numberFormatters = [
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
    ];

    return AlertDialog(
      title: Text(
        _isEditing
            ? context.tr('Edit product', 'እቃ አስተካክል')
            : context.tr('Add product', 'እቃ ጨምር'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              field(
                controller: _name,
                label: context.tr('Product name *', 'የእቃ ስም *'),
                icon: Icons.label_outline,
                autofocus: true,
              ),
              const SizedBox(height: 10),
              field(
                controller: _description,
                label: context.tr('Description (optional)', 'መግለጫ (አማራጭ)'),
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: field(
                      controller: _barcode,
                      label: context.tr('Barcode', 'ባርኮድ'),
                      icon: Icons.qr_code_2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: field(
                      controller: _category,
                      label: context.tr('Category', 'ምድብ'),
                      icon: Icons.category_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: field(
                      controller: _sellingPrice,
                      label: context.tr('Selling price *', 'የመሸጫ ዋጋ *'),
                      prefix: 'ብር ',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: numberFormatters,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: field(
                      controller: _costPrice,
                      label: context.tr('Cost price', 'የወጪ ዋጋ'),
                      prefix: 'ብር ',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: numberFormatters,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: field(
                      controller: _stock,
                      label: context.tr('Current stock', 'የአሁኑ ክምችት'),
                      icon: Icons.inventory_2_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: field(
                      controller: _threshold,
                      label: context.tr('Low stock alert at', 'ዝቅተኛ ማስጠንቀቂያ'),
                      icon: Icons.notifications_active_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                ],
              ),
              if (_isEditing) ...[
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    'Tip: use Restock to change stock or cost so the WAC and '
                    'expense log stay accurate.',
                    'ማስታወሻ፦ ክምችት ወይም ወጪ ለመቀየር Restock ይጠቀሙ።',
                  ),
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.alertRed,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(context.tr('Cancel', 'ሰርዝ')),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _isEditing
                      ? context.tr('Save changes', 'አስቀምጥ')
                      : context.tr('Add product', 'እቃ ጨምር'),
                ),
        ),
      ],
    );
  }
}
