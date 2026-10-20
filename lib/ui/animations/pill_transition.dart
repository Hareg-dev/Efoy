import 'package:flutter/material.dart';

/// Animated pill container used for navigation tabs and filter pills.
///
/// Animates background color and padding over 300 ms with an ease-out curve,
/// matching the pill transitions in the HTML mockups.
class PillTransition extends StatelessWidget {
  const PillTransition({
    super.key,
    required this.selected,
    required this.child,
    this.selectedColor,
    this.unselectedColor = Colors.transparent,
    this.selectedForeground,
    this.unselectedForeground,
    this.borderRadius = 999,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.duration = const Duration(milliseconds: 300),
    this.onTap,
  });

  final bool selected;
  final Widget child;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? selectedForeground;
  final Color? unselectedForeground;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Duration duration;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveSelectedColor = selectedColor ??
        colorScheme.primary.withValues(alpha: 0.12);

    final pill = AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        color: selected ? effectiveSelectedColor : unselectedColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected
              ? (selectedForeground ?? colorScheme.primary)
              : (unselectedForeground ?? colorScheme.onSurfaceVariant),
        ),
        child: IconTheme(
          data: IconThemeData(
            size: 20,
            color: selected
                ? (selectedForeground ?? colorScheme.primary)
                : (unselectedForeground ?? colorScheme.onSurfaceVariant),
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return pill;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: pill,
    );
  }
}
