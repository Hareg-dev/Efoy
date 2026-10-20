import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../animations/pill_transition.dart';

/// Custom five-tab navigation bar with an animated active pill.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <_NavItem>[
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: AppStrings.navHome),
    _NavItem(icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale, label: AppStrings.navSell),
    _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: AppStrings.navInventory),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: AppStrings.navExpenses),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: AppStrings.navProfile),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFF0F2F5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final selected = index == currentIndex;
              return Expanded(
                child: PillTransition(
                  selected: selected,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  borderRadius: 16,
                  selectedColor: colorScheme.primary.withValues(alpha: isDark ? 0.24 : 0.12),
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        size: 22,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppStrings.get(item.label, Localizations.localeOf(context).languageCode),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final Map<String, String> label;
}
