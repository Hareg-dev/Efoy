import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../logic/providers/profit_provider.dart';
import '../../logic/providers/theme_provider.dart';

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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.successGreen,
            AppColors.primaryTeal,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.successGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: profitAsync.when(
        data: (data) => _buildContent(context, ref, data, period, language),
        loading: () => _buildLoading(),
        error: (error, stack) => _buildError(error),
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
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with SYNCED badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                language == 'am' ? 'ንጹህ ትርፍ' : 'Net Profit',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      language == 'am' ? 'ተመዝግቧል' : 'SYNCED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceL),
          
          // Large Birr amount
          Center(
            child: Column(
              children: [
                Text(
                  CurrencyFormatter.format(data.netProfit, language: language),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  language == 'am' ? data.periodLabelAm : data.periodLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceL),
          
          // Revenue vs Expenses bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    language == 'am' ? 'ገቢ' : 'Revenue',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(data.revenue, language: language),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: data.revenue > 0 
                      ? (data.revenue - data.opex) / data.revenue
                      : 0,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    language == 'am' ? 'ወጪ' : 'Expenses',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(data.opex, language: language),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceL),
          
          // Period filter chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPeriodChip(
                context,
                ref,
                ProfitPeriod.today,
                language == 'am' ? 'ዛሬ' : 'Today',
                period == ProfitPeriod.today,
              ),
              const SizedBox(width: 8),
              _buildPeriodChip(
                context,
                ref,
                ProfitPeriod.week,
                language == 'am' ? 'ሳምንት' : 'Week',
                period == ProfitPeriod.week,
              ),
              const SizedBox(width: 8),
              _buildPeriodChip(
                context,
                ref,
                ProfitPeriod.month,
                language == 'am' ? 'ወር' : 'Month',
                period == ProfitPeriod.month,
              ),
            ],
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.white
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? AppColors.primaryTeal
                : Colors.white,
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
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
