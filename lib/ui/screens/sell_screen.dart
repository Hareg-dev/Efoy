import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/l10n.dart';
import '../../data/models/held_order_model.dart';
import '../../data/models/product_model.dart';
import '../../logic/providers/cart_provider.dart';
import '../../logic/providers/repository_providers.dart';
import '../../logic/providers/theme_provider.dart';
import '../widgets/cart_sheet.dart';
import '../widgets/product_card.dart';
import '../widgets/screen_header.dart';

class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key, this.onSaleComplete});

  final VoidCallback? onSaleComplete;

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  Future<void> _openCart() async {
    if (ref.read(cartProvider).isEmpty) return;
    final completed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CartSheet(),
    );
    if (!mounted) return;
    if (completed == true) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.tr('Sale completed successfully', 'ሽያጭ በተሳካ ሁኔታ ተጠናቅቋል'),
            ),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
      widget.onSaleComplete?.call();
    }
  }

  Future<void> _handleHold() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      await _showHeldOrders();
      return;
    }

    try {
      await ref.read(cartProvider.notifier).holdOrder();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.tr('Order held', 'ትዕዛዝ ተቀመጠ')),
            backgroundColor: AppColors.primaryTeal,
          ),
        );
    } on CartException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _showHeldOrders() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _HeldOrdersSheet(),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.alertRed),
      );
  }

  void _addToCart(ProductModel product) {
    try {
      ref.read(cartProvider.notifier).addItem(product);
    } on CartException catch (error) {
      _showError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final cart = ref.watch(cartProvider);
    final heldCount = ref.watch(heldOrdersProvider).valueOrNull?.length ?? 0;
    final openDebtCount = ref.watch(openDebtsProvider).valueOrNull?.length ?? 0;
    final accent = ref.watch(accentProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceL,
                AppTheme.spaceM,
                AppTheme.spaceL,
                AppTheme.spaceS,
              ),
              child: ScreenHeader(
                title: context.tr('SELL', 'ሽያጭ'),
                subtitle: context.tr(
                  'Tap a product to add it to the cart',
                  'ለጋሪ ለመጨመር እቃውን ይንኩ',
                ),
                actions: [
                  HeaderBadgeButton(
                    tooltip: context.tr('Hold / resume order', 'ትዕዛዝ አቆይ'),
                    icon: Icons.pause_circle_outline,
                    count: heldCount,
                    onPressed: _handleHold,
                  ),
                  HeaderBadgeButton(
                    tooltip: context.tr('Who owes me', 'ማን ይዳናል'),
                    icon: Icons.handshake_outlined,
                    count: openDebtCount,
                    onPressed: () => Navigator.of(context).pushNamed('/debts'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return _EmptyProducts(
                      onAddSample: () => _seedSampleProducts(context),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceL,
                      AppTheme.spaceS,
                      AppTheme.spaceL,
                      AppTheme.spaceM,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        quantityInCart: cart.quantityFor(product.id),
                        onTap: product.isOutOfStock
                            ? () => _showError(
                                context.tr(
                                  '${product.name} is out of stock',
                                  '${product.name} ከመጋዘን አልቋል',
                                ),
                              )
                            : () => _addToCart(product),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceL),
                    child: Text(
                      context.tr(
                        'Products could not be loaded.\n$error',
                        'እቃዎችን መጫን አልተቻለም።\n$error',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: EdgeInsets.fromLTRB(
                AppTheme.spaceL,
                cart.isEmpty ? 0 : AppTheme.spaceM,
                AppTheme.spaceL,
                cart.isEmpty ? 0 : AppTheme.spaceM,
              ),
              child: cart.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent.profitStart, accent.profitEnd],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusLarge,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.profitStart.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr(
                                    '${cart.itemCount} item(s)',
                                    '${cart.itemCount} ዕቃዎች',
                                  ),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatBirr(cart.total),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _openCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primaryDark,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              context.tr('Checkout', 'ክፍያ'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedSampleProducts(BuildContext context) async {
    try {
      final repository = await ref.read(productRepositoryProvider.future);
      final now = DateTime.now();
      final samples = [
        ('Rice 25kg', 1200.0, 1000.0, 14, 'Groceries'),
        ('Cooking Oil 3L', 540.0, 450.0, 9, 'Groceries'),
        ('Soda Pack', 180.0, 140.0, 18, 'Beverages'),
        ('Sugar 1kg', 85.0, 70.0, 5, 'Groceries'),
        ('Milk 1L', 80.0, 65.0, 24, 'Dairy'),
        ('Soap Bar', 45.0, 32.0, 40, 'Household'),
      ];
      for (final sample in samples) {
        await repository.create(
          ProductModel(
            name: sample.$1,
            description: 'Sample product',
            category: sample.$5,
            sellingPrice: sample.$2,
            costPrice: sample.$3,
            currentStock: sample.$4,
            lowStockThreshold: 10,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Sample products added', 'የናሙና እቃዎች ተጨመሩ')),
          backgroundColor: AppColors.primaryTeal,
        ),
      );
    } catch (error) {
      _showError(error.toString());
    }
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.onAddSample});

  final VoidCallback onAddSample;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('No products yet', 'እስካሁን እቃ የለም'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr(
                'Add products from the Inventory tab to start selling.',
                'ለመሸጥ ከእቃዎች ገጽ እቃ ይጨምሩ።',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAddSample,
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(context.tr('Add sample products', 'የናሙና እቃዎች ጨምር')),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeldOrdersSheet extends ConsumerWidget {
  const _HeldOrdersSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heldAsync = ref.watch(heldOrdersProvider);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('Held orders', 'የተቀመጡ ትዕዛዞች'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            heldAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceXL),
                    child: Text(
                      context.tr(
                        'No held orders. Tap pause with items in the cart to hold one.',
                        'የተቀመጠ ትዕዛዝ የለም።',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  );
                }
                return Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _HeldOrderTile(order: order);
                    },
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppTheme.spaceL),
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(AppTheme.spaceL),
                child: Text(error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeldOrderTile extends ConsumerWidget {
  const _HeldOrderTile({required this.order});

  final HeldOrderModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CurrencyFormatter.formatBirr(order.total),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.itemCount} item(s) · '
                  '${DateHelper.formatRelativeTime(order.heldAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: () async {
              final repository = await ref.read(
                heldOrderRepositoryProvider.future,
              );
              await repository.delete(order.id);
            },
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(cartProvider.notifier).restoreHeldOrder(order);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              } on CartException catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error.message)));
              }
            },
            child: Text(context.tr('Restore', 'መልስ')),
          ),
        ],
      ),
    );
  }
}
