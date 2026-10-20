import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/l10n.dart';
import '../../data/models/product_model.dart';

/// Product tile used in the sell grid.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.quantityInCart = 0,
    this.onTap,
  });

  final ProductModel product;
  final int quantityInCart;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = quantityInCart > 0;
    final outOfStock = product.isOutOfStock;
    final lowStock = product.isLowStock;

    final stockColor = outOfStock
        ? AppColors.alertRed
        : lowStock
            ? AppColors.alertAmber
            : AppColors.primaryGreen;

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
              color: isSelected
                  ? scheme.primary
                  : (isDark ? Colors.white12 : AppColors.borderLight),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.tealTint.withValues(
                        alpha: isDark ? 0.16 : 1,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.primaryTeal,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        quantityInCart.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  CurrencyFormatter.formatBirrWhole(product.sellingPrice),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                outOfStock
                    ? context.tr('Out of stock', 'ከመጋዘን አልቋል')
                    : lowStock
                        ? context.tr(
                            '${product.currentStock} left',
                            '${product.currentStock} ቀርቷል',
                          )
                        : context.tr(
                            '${product.currentStock} in stock',
                            '${product.currentStock} በክምችት',
                          ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: stockColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
