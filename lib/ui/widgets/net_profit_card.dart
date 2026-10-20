import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../logic/providers/profit_provider.dart';
import '../../logic/providers/theme_provider.dart';
import '../animations/pulsing_dot.dart';

class NetProfitCard extends ConsumerWidget {
  const NetProfitCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profitAsync = ref.watch(netProfitProvider);
    final period = ref.watch(profitPeriodProvider);
    final language = ref.watch(languageProvider);

    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceL),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(-0.75, -0.8),
          radius: 1.7,
          colors: [
            AppColors.profitGradStart,
            AppColors.profitGradMid,
            AppColors.profitGradEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.profitGradStart.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        child: Stack(
          children: [
            Positioned(
              right: -72,
              bottom: -82,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            profitAsync.when(
              data: (data) =>
                  _buildContent(context, ref, data, period, language),
              loading: () => _buildLoading(),
              error: (error, stack) => _buildError(error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    NetProfitData data,
    ProfitPeriod period,
    String language,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                language == 'am'
                    ? 'ንጹህ ትርፍ'
                    : 'NET PROFIT · ${data.periodLabel.toUpperCase()}',
                style: const TextStyle(
                  color: AppColors.emerald200,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PulsingDot(
                      size: 8,
                      color: Color(0xFF10EF64),
                      glow: true,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      language == 'am' ? 'ተመዝግቧል' : 'SYNCED',
                      style: const TextStyle(
                        color: Color(0xFFD1FAE5),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                      data.netProfit,
                      showSymbol: false,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ብር',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildBreakdownItem(
                    label: language == 'am' ? 'ገቢ' : 'REVENUE',
                    amount: data.revenue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBreakdownItem(
                    label: language == 'am' ? 'ወጪዎች' : 'EXPENSES',
                    amount: data.opex,
                    amountColor: AppColors.rose300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF07321A).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPeriodChip(
                  context,
                  ref,
                  ProfitPeriod.today,
                  language == 'am' ? 'ዛሬ' : 'Today',
                  period == ProfitPeriod.today,
                ),
                _buildPeriodChip(
                  context,
                  ref,
                  ProfitPeriod.week,
                  language == 'am' ? 'ሳምንት' : 'Week',
                  period == ProfitPeriod.week,
                ),
                _buildPeriodChip(
                  context,
                  ref,
                  ProfitPeriod.month,
                  language == 'am' ? 'ወር' : 'Month',
                  period == ProfitPeriod.month,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem({
    required String label,
    required double amount,
    Color amountColor = Colors.white,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.emerald200,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            CurrencyFormatter.formatBirr(amount),
            style: TextStyle(
              color: amountColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(
    BuildContext context,
    WidgetRef ref,
    ProfitPeriod periodValue,
    String label,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        ref.read(profitPeriodProvider.notifier).state = periodValue;
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(AppTheme.spaceXL),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Center(
        child: Text(
          'Error loading profit data',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
