import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_theme.dart';
import '../../core/licensing/license_access_state.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/l10n.dart';
import '../../logic/calculators/profit_engine.dart';
import '../../logic/providers/license_provider.dart';
import '../../logic/providers/profit_provider.dart';
import '../../logic/providers/repository_providers.dart';
import '../animations/pulsing_dot.dart';
import '../widgets/alert_card.dart';
import '../widgets/net_profit_card.dart';
import '../widgets/screen_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.onQuickSell, this.onOpenSettings});

  final VoidCallback? onQuickSell;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final accessAsync = ref.watch(licenseAccessProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shopName = profile?.businessName?.trim().isNotEmpty == true
        ? profile!.businessName!.trim()
        : context.tr('HOME', 'መነሻ');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceL,
                  AppTheme.spaceM,
                  AppTheme.spaceL,
                  0,
                ),
                child: ScreenHeader(
                  leading: const HeaderBrand(
                    child: Icon(Icons.check, color: Colors.white, size: 22),
                  ),
                  title: shopName,
                  subtitle: context.tr(
                    'Rest easy - business made easy',
                    'በእፎይ እርፍ ይበሉ',
                  ),
                  actions: [
                    IconButton(
                      tooltip: context.tr('Settings', 'ቅንብሮች'),
                      onPressed: onOpenSettings,
                      icon: const Icon(Icons.settings_outlined),
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _LicenseStatusBanner(access: accessAsync.valueOrNull),
            ),
            const SliverToBoxAdapter(child: NetProfitCard()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceL,
                ),
                child: summaryAsync.when(
                  data: (summary) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.receipt_long_outlined,
                              label: context.tr(
                                'TRANSACTIONS TODAY',
                                'የዛሬ ግብይቶች',
                              ),
                              value: summary.transactionCount.toString(),
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceM),
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.trending_up,
                              label: context.tr('SALES TODAY', 'የዛሬ ሽያጮች'),
                              value: CurrencyFormatter.formatBirrWhole(
                                summary.salesAmount,
                              ),
                              color: AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceL),
                      _buildAlerts(context, summary),
                      const SizedBox(height: AppTheme.spaceL),
                      _buildRecentActivity(context, summary),
                      const SizedBox(height: AppTheme.spaceL),
                      _buildQuickSellButton(context),
                      const SizedBox(height: AppTheme.spaceXL),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppTheme.spaceXL),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => _DashboardLoadError(
                    onRetry: () => ref.invalidate(dashboardSummaryProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlerts(BuildContext context, DashboardSummary summary) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final alerts = <Widget>[];

    if (summary.needsRestockProducts.isNotEmpty) {
      final names = summary.needsRestockProducts
          .take(3)
          .map(
            (product) => product.isOutOfStock
                ? '${product.name} (0)'
                : '${product.name} (${product.currentStock})',
          )
          .join(', ');
      final remaining = summary.needsRestockProducts.length - 3;
      alerts.add(
        AlertCard(
          type: AlertType.amber,
          icon: Icons.inventory_2_outlined,
          title: context.tr('NEEDS RESTOCK', 'እቃ ያስፈልጋል'),
          subtitle: remaining > 0
              ? context.tr(
                  '$names and $remaining more to reorder',
                  '$names እና ተጨማሪ $remaining ለመግዛት',
                )
              : names,
          showPulse: true,
        ),
      );
    }
    if (summary.transactionCount == 0) {
      alerts.add(
        AlertCard(
          type: AlertType.dark,
          icon: Icons.point_of_sale_outlined,
          title: context.tr('0 TRANSACTIONS TODAY', 'ዛሬ 0 ግብይቶች'),
          subtitle: context.tr(
            'Record your first sale to see today\'s activity.',
            'የዛሬን እንቅስቃሴ ለማየት የመጀመሪያ ሽያጭዎን ይመዝግቡ።',
          ),
        ),
      );
    }
    if (summary.grossProfitMargin != null &&
        summary.grossProfitMargin! < ProfitEngine.criticalGrossMargin) {
      final criticalPercent = (ProfitEngine.criticalGrossMargin * 100).round();
      alerts.add(
        AlertCard(
          type: AlertType.crimson,
          icon: Icons.warning_amber_rounded,
          title: context.tr('PROFIT HEALTH: CAUTION', 'የትርፍ ሁኔታ፡ ጥንቃቄ'),
          subtitle: context.tr(
            'Today\'s gross profit margin is below $criticalPercent%.',
            'የዛሬ አጠቃላይ ትርፍ ህዳግ ከ$criticalPercent% በታች ነው።',
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('CRITICAL ALERTS', 'ወሳኝ ማሳወቂያዎች'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const PulsingDot(size: 7, color: AppColors.alertRed),
            const SizedBox(width: 5),
            Text(
              context.tr('LIVE', 'በቀጥታ'),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.alertRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceM),
        if (alerts.isEmpty)
          AlertCard(
            type: AlertType.amber,
            accentColor: AppColors.primaryTeal,
            icon: Icons.check_circle_outline,
            title: context.tr('ALL CLEAR', 'ሁሉም ጥሩ ነው'),
            subtitle: context.tr(
              'No critical alerts for your store.',
              'ለሱቅዎ ወሳኝ ማሳወቂያ የለም።',
            ),
          )
        else
          for (var i = 0; i < alerts.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            alerts[i],
          ],
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, DashboardSummary summary) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('RECENT ACTIVITY', 'የቅርብ እንቅስቃሴ'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: AppTheme.spaceM),
        if (summary.recentSales.isEmpty)
          const _EmptyActivityCard()
        else
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Column(
              children: [
                for (var i = 0; i < summary.recentSales.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 68,
                      endIndent: 16,
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.tealTint.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                    title: Text(
                      context.tr(
                        'Sale ${summary.recentSales[i].transactionId}',
                        'ሽያጭ ${summary.recentSales[i].transactionId}',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      context.tr(
                        '${summary.recentSales[i].lineItems.length} item(s)',
                        '${summary.recentSales[i].lineItems.length} ዕቃዎች',
                      ),
                    ),
                    trailing: Text(
                      CurrencyFormatter.formatBirrWhole(
                        summary.recentSales[i].totalAmount,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuickSellButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onQuickSell,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B5E32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.point_of_sale_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr('Quick Sell & Record', 'ፈጣን ሽያጭ እና መዝገብ'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.emerald200),
          ],
        ),
      ),
    );
  }
}

/// Trial countdown / expiry / recovery banner shown at the top of the
/// dashboard. View-only in every state: it informs, never blocks reads.
class _LicenseStatusBanner extends StatelessWidget {
  const _LicenseStatusBanner({required this.access});

  final LicenseAccessState? access;

  @override
  Widget build(BuildContext context) {
    if (access == null) return const SizedBox.shrink();

    switch (access!.status) {
      case LicenseAccessStatus.trial:
        final days = access!.daysRemaining;
        return _banner(
          context,
          color: AppColors.primaryTeal,
          icon: Icons.hourglass_top_outlined,
          message: context.tr(
            'Trial: $days day${days == 1 ? '' : 's'} left. Activate any time to keep selling.',
            'ሙከራ፦ $days ቀናት ቀርተዋል። ለመሽየጭ መቀጠል በየትኛውም ጊዜ ፈቃድ ያንቁ።',
          ),
        );
      case LicenseAccessStatus.licensed:
        if (access!.isLifetime || !access!.isExpiringSoon) {
          return const SizedBox.shrink();
        }
        final days = access!.daysRemaining;
        return _banner(
          context,
          color: AppColors.alertAmber,
          icon: Icons.schedule_outlined,
          message: context.tr(
            'License expires in $days day${days == 1 ? '' : 's'}. Renew to keep recording sales.',
            'ፈቃዱ በ$days ቀናት ውስጥ ያበቃል። ሽያጭዎን ለመቀጠል ያድሱት።',
          ),
        );
      case LicenseAccessStatus.expired:
      case LicenseAccessStatus.trialExpired:
        return _banner(
          context,
          color: AppColors.alertAmber,
          icon: Icons.lock_outline,
          message: access!.clockRollbackSuspected
              ? context.tr(
                  'Set the correct device date and time to use Efoy again.',
                  'እፎይን እንደገና ለመጠቀም ትክክለኛውን ቀንና ሰዓት ያስተካክሉ።',
                )
              : context.tr(
                  'Read-only mode. Pay with Telebirr to '
                      '${AppStrings.supportPhone} (${AppStrings.supportTeam}) '
                      'and enter the activation key in Profile to record sales '
                      'again. Your records stay available for viewing and '
                      'export.',
                  'ለማንባት ብቻ ሁነታ። ሽያጭ ለመመዝገብ በቴሌብር '
                      '${AppStrings.supportPhone} '
                      '(${AppStrings.supportTeam}) ክፈሉና በመገለጫው ውስጥ የማንቂያ '
                      'ኮዱን ያስገቡ። መዛግብቶችዎ ለመመልከትና ለማውጣት ይገኛሉ።',
                ),
        );
      case LicenseAccessStatus.blocked:
        return _banner(
          context,
          color: AppColors.alertRed,
          icon: Icons.security_outlined,
          message: context.tr(
            'Secure storage is unavailable. Restart the device or contact '
                'support. Your business data is safe.',
            'የደህንነት ማከማቻ አይገኝም። መሣሪያውን እንደገና ያስኩሩ ወይም '
                'ድጋፍ ይጠይቁ። የንግድ መረጃዎ ደህና ነው።',
          ),
        );
    }
  }

  Widget _banner(
    BuildContext context, {
    required Color color,
    required IconData icon,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceL,
        AppTheme.spaceM,
        AppTheme.spaceL,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? color.withValues(alpha: 0.95)
                      : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.25 : 0.04,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivityCard extends StatelessWidget {
  const _EmptyActivityCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spaceL),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            context.tr('No recent activity', 'የቅርብ እንቅስቃሴ የለም'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr(
              'Completed sales will appear here.',
              'የተጠናቀቁ ሽያጮች እዚህ ይታያሉ።',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoadError extends StatelessWidget {
  const _DashboardLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceL),
      child: Column(
        children: [
          Text(
            context.tr(
              'Dashboard data could not be loaded.',
              'የዳሽቦርድ ውሂብ መጫን አልተቻለም።',
            ),
            style: const TextStyle(color: AppColors.alertRed),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(context.tr('Retry', 'እንደገና ሞክር')),
          ),
        ],
      ),
    );
  }
}
