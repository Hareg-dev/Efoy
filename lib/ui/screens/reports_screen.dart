import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/l10n.dart';
import '../../data/models/expense_model.dart';
import '../../logic/providers/profit_provider.dart';
import '../../logic/providers/report_provider.dart';
import '../../logic/providers/theme_provider.dart';
import '../widgets/screen_header.dart';

/// The report behind Profile: what the shop actually made, which lines carried
/// it, what the overhead was, and what went back into stock.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final reportAsync = ref.watch(businessReportProvider);
    final range = ref.watch(reportRangeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceM,
            AppTheme.spaceS,
            AppTheme.spaceM,
            AppTheme.spaceXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                leading: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: context.tr('Back', 'ተመለስ'),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                title: context.tr('REPORT', 'ሪፖርት'),
                subtitle: context.tr(
                  'Profit, product trends, costs and restock',
                  'ትርፍ፣ የእቃ አዝማሚያ፣ ወጪና እቃ መሙላት',
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              _RangeChips(
                selected: range,
                onSelected: (period) =>
                    ref.read(reportRangeProvider.notifier).state = period,
              ),
              const SizedBox(height: AppTheme.spaceM),
              reportAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppTheme.spaceXL),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceL),
                  child: Text(
                    context.tr(
                      'The report could not be built: $error',
                      'ሪፖርቱ ሊሠራ አልቻለም፦ $error',
                    ),
                    style: const TextStyle(color: AppColors.alertRed),
                  ),
                ),
                data: (report) => _ReportBody(report: report),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Range
// ---------------------------------------------------------------------------

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.selected, required this.onSelected});

  final ProfitPeriod selected;
  final ValueChanged<ProfitPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final options = [
      (ProfitPeriod.week, context.tr('Last 7 days', 'ያለፉት 7 ቀናት')),
      (ProfitPeriod.month, context.tr('This month', 'ይህ ወር')),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final (period, label) in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(period),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected == period
                        ? scheme.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: selected == period
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: selected == period
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
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
// Body
// ---------------------------------------------------------------------------

class _ReportBody extends ConsumerWidget {
  const _ReportBody({required this.report});

  final BusinessReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfitWindow(report: report),
        const SizedBox(height: AppTheme.spaceL),
        _SectionTitle(
          title: context.tr('Recent trading', 'የቅርብ ጊዜ ሽያጭ'),
          trailing: context.tr(
            '${report.salesCount} sales',
            '${report.salesCount} ሽያጮች',
          ),
        ),
        const SizedBox(height: 10),
        _TradingCard(daily: report.daily),
        const SizedBox(height: AppTheme.spaceL),
        _SectionTitle(
          title: context.tr('Product trends', 'የእቃ አዝማሚያ'),
          trailing: context.tr('by profit', 'በትርፍ'),
        ),
        const SizedBox(height: 10),
        _ProductTrends(products: report.products),
        const SizedBox(height: AppTheme.spaceL),
        _SectionTitle(
          title: context.tr('Operational costs', 'የስራ ወጪዎች'),
          trailing: context.tr('this period', 'በዚህ ጊዜ'),
        ),
        const SizedBox(height: 10),
        _SpendingCard(spending: report.spending, report: report),
        if (report.restocks.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceL),
          _SectionTitle(
            title: context.tr('Restock history', 'የእቃ መሙላት ታሪክ'),
            trailing: context.tr(
              CurrencyFormatter.formatBirr(report.restockTotal),
              CurrencyFormatter.formatBirr(report.restockTotal),
            ),
          ),
          const SizedBox(height: 10),
          _RestockList(entries: report.restocks),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profit window
// ---------------------------------------------------------------------------

class _ProfitWindow extends ConsumerWidget {
  const _ProfitWindow({required this.report});

  final BusinessReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentProvider);
    final loss = report.netProfit < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: accent.profitGradient,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: accent.profitStart.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('PROFIT FOR THE PERIOD', 'የዚህ ጊዜ ትርፍ'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.formatBirr(
                      report.netProfit,
                      showSymbol: false,
                    ),
                    style: TextStyle(
                      fontSize: 34,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: loss ? AppColors.rose300 : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'ብር',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${DateHelper.formatDate(report.startDate)} - '
            '${DateHelper.formatDate(report.endDate.subtract(const Duration(days: 1)))}',
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
            child: Column(
              children: [
                _WindowLine(
                  context.tr('Selling', 'ሽያጭ'),
                  report.revenue,
                  Colors.white,
                ),
                _WindowLine(
                  context.tr('Cost of the goods sold', 'የተሸጠው እቃ ዋጋ'),
                  report.revenue - report.grossProfit,
                  Colors.white,
                ),
                _WindowLine(
                  context.tr('Gross margin', 'ጠቅላላ ትርፍ'),
                  report.grossProfit,
                  AppColors.emerald200,
                ),
                if (report.overhead > 0)
                  _WindowLine(
                    context.tr('Less overhead', 'የስራ ወጪ ተቀንሷል'),
                    -report.overhead,
                    AppColors.rose300,
                  ),
                if (report.salaries > 0)
                  _WindowLine(
                    context.tr('Less salaries', 'ደሞዝ ተቀንሷል'),
                    -report.salaries,
                    AppColors.rose300,
                  ),
                _WindowLine(
                  context.tr('Cash taken', 'የተቀበለው ገንዘብ'),
                  report.cashCollected,
                  AppColors.emerald200,
                ),
                _WindowLine(
                  context.tr('Still with customers', 'በደንበኞች ያለ ቀሪ'),
                  report.outstanding,
                  const Color(0xFFFCD34D),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowLine extends StatelessWidget {
  const _WindowLine(this.label, this.amount, this.color);

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount < 0
                ? '-${CurrencyFormatter.formatBirr(-amount)}'
                : CurrencyFormatter.formatBirr(amount),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Daily trading
// ---------------------------------------------------------------------------

class _TradingCard extends StatelessWidget {
  const _TradingCard({required this.daily});

  final List<DailyTrading> daily;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final busiest = daily.isEmpty
        ? null
        : daily.reduce((a, b) => a.grossProfit >= b.grossProfit ? a : b);
    final maxProfit = daily.fold<double>(
      0,
      (max, day) => day.grossProfit > max ? day.grossProfit : max,
    );
    final recent = daily.length <= 7
        ? daily.reversed.toList()
        : daily.sublist(daily.length - 7).reversed.toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in daily)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Tooltip(
                        message:
                            '${DateHelper.formatDate(day.day)} · '
                            '${CurrencyFormatter.formatBirr(day.grossProfit)}',
                        child: Container(
                          height: maxProfit <= 0
                              ? 3
                              : 6 + (44 * day.grossProfit / maxProfit),
                          decoration: BoxDecoration(
                            color: day.grossProfit <= 0
                                ? scheme.outlineVariant
                                : scheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (busiest != null) ...[
            const SizedBox(height: 8),
            Text(
              busiest.grossProfit <= 0
                  ? context.tr(
                      'No margin earned in this period yet.',
                      'በዚህ ጊዜ ገና ትርፍ አልተገኘም።',
                    )
                  : context.tr(
                      'Best day: ${DateHelper.formatDate(busiest.day)} with '
                          '${CurrencyFormatter.formatBirr(busiest.grossProfit)} '
                          'margin.',
                      'ምርጥ ቀን፡ ${DateHelper.formatDate(busiest.day)} - '
                          '${CurrencyFormatter.formatBirr(busiest.grossProfit)} ትርፍ።',
                    ),
              style: TextStyle(
                fontSize: 10.5,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          for (final day in recent)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    child: Text(
                      DateHelper.formatDateShort(day.day),
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      context.tr(
                        '${day.salesCount} sales',
                        '${day.salesCount} ሽያጭ',
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatBirr(day.grossProfit),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: day.grossProfit > 0
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product trends
// ---------------------------------------------------------------------------

class _ProductTrends extends StatelessWidget {
  const _ProductTrends({required this.products});

  final List<ProductTrend> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (products.isEmpty) {
      return _EmptyLine(
        context.tr(
          'No products sold in this period yet.',
          'በዚህ ጊዜ ምንም እቃ አልተሸጠም።',
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.5),
        ),
      ),
      child: Column(
        children: [
          for (final (index, product) in products.indexed) ...[
            if (index > 0)
              Divider(
                height: 14,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr(
                          '${product.quantity} sold · '
                              '${CurrencyFormatter.formatBirr(product.revenue)} '
                              'taken',
                          '${product.quantity} ተሽጧል · '
                              '${CurrencyFormatter.formatBirr(product.revenue)}',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.formatBirr(product.profit),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Operational costs
// ---------------------------------------------------------------------------

class _SpendingCard extends StatelessWidget {
  const _SpendingCard({required this.spending, required this.report});

  final List<CategorySpend> spending;
  final BusinessReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final total = spending.fold<double>(0, (sum, line) => sum + line.amount);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (spending.isEmpty)
            _EmptyLine(
              context.tr(
                'No rent, wages or running costs recorded for this period.',
                'በዚህ ጊዜ ኪራይ፣ ደሞዝ ወይም ሌላ ወጪ አልተመዘገበም።',
              ),
            )
          else ...[
            for (final line in spending) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.isAmharic
                          ? line.category.displayNameAmharic
                          : line.category.displayName,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatBirr(line.amount),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: total <= 0 ? 0 : line.amount / total,
                  minHeight: 4,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    line.category == ExpenseCategory.salary
                        ? scheme.primary
                        : AppColors.alertAmber,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Divider(
              height: 6,
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('Total operating', 'ጠቅላላ የስራ ወጪ'),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  CurrencyFormatter.formatBirr(report.deducted),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.alertRed,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.alertAmber.withValues(
                alpha: isDark ? 0.16 : 0.1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 15,
                  color: AppColors.alertAmber,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    context.tr(
                      'Restock ${CurrencyFormatter.formatBirr(report.capital)} '
                          'is capital, not an expense - it became stock.',
                      'የእቃ መሙላት ${CurrencyFormatter.formatBirr(report.capital)} '
                          'ካፒታል ነው፣ ወጪ አይደለም - ክምችት ሆኗል።',
                    ),
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      color: isDark
                          ? AppColors.textOnDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Restock history
// ---------------------------------------------------------------------------

class _RestockList extends StatelessWidget {
  const _RestockList({required this.entries});

  final List<RestockEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.5),
        ),
      ),
      child: Column(
        children: [
          for (final (index, entry) in entries.indexed) ...[
            if (index > 0)
              Divider(
                height: 14,
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateHelper.formatDate(entry.date)} · '
                        '${entry.quantity} ${context.tr('units', 'እቃ')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  CurrencyFormatter.formatBirr(entry.totalCost),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.alertAmber,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(fontSize: 10.5, color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 11.5,
          height: 1.4,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
