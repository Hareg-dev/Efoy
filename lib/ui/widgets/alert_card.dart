import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../animations/pulsing_dot.dart';

enum AlertType { amber, crimson, dark }

/// Reusable alert card matching the HTML mockup variants.
class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.showPulse = false,
    this.accentColor,
  });

  final AlertType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showPulse;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    late final Color accent;
    late final Color background;
    late final Color border;

    switch (type) {
      case AlertType.amber:
        accent = accentColor ?? AppColors.alertAmber;
        background = isDark
            ? accent.withValues(alpha: 0.12)
            : AppColors.alertAmberBg;
        border = isDark
            ? accent.withValues(alpha: 0.35)
            : AppColors.alertAmberBorder;
      case AlertType.crimson:
        accent = accentColor ?? AppColors.alertRed;
        background = colorScheme.surface;
        border = isDark ? Colors.white12 : AppColors.borderLight;
      case AlertType.dark:
        accent = accentColor ?? Colors.white;
        background = isDark ? AppColors.darkCard : const Color(0xFF1C1D1C);
        border = Colors.white12;
    }

    final subtitleColor = type == AlertType.dark
        ? AppColors.textOnDark.withValues(alpha: 0.7)
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: type == AlertType.dark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: type == AlertType.dark ? accent : accent,
                        ),
                      ),
                    ),
                    if (showPulse) ...[
                      PulsingDot(size: 7, color: accent),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: accent,
                    ),
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
