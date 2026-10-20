import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/l10n.dart';
import '../../data/models/expense_model.dart';
import '../../logic/providers/repository_providers.dart';
import '../animations/pill_transition.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  ExpenseCategory? _category;
  bool _showAllExpenses = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final expensesAsync = ref.watch(expenseListProvider);
    final expenses = expensesAsync.valueOrNull ?? const <ExpenseModel>[];

    final visible = expenses.where((expense) {
      if (_category != null && expense.category != _category) return false;
      if (!_showAllExpenses && expense.isRestockExpense) return false;
      return true;
    }).toList();

    final summary = _ExpenseSummary.from(expenses);
    final hasFilters = _category != null || !_showAllExpenses;

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
                  expenseCount: expenses.length,
                  onAdd: () => _openExpenseForm(),
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
                child: _SummaryCard(summary: summary),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceM,
                AppTheme.spaceL,
                AppTheme.spaceM,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _CategorySection(
                  selected: _category,
                  onSelected: (category) {
                    setState(() {
                      _category = category;
                      if (category == ExpenseCategory.restock) {
                        _showAllExpenses = true;
                      }
                    });
                  },
                  onClear: () => setState(() => _category = null),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceM,
                AppTheme.spaceL,
                AppTheme.spaceM,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Expenses', 'ወጪዎች'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr(
                              '${visible.length} of ${expenses.length} shown',
                              '${visible.length} ከ${expenses.length} ታይቷል',
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ViewToggle(
                      showAll: _showAllExpenses,
                      onChanged: (value) =>
                          setState(() => _showAllExpenses = value),
                    ),
                  ],
                ),
              ),
            ),
            if (expensesAsync.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyExpenses(
                  hasFilters: hasFilters || expenses.isNotEmpty,
                  onAdd: () => _openExpenseForm(),
                  onReset: () => setState(() {
                    _category = null;
                    _showAllExpenses = true;
                  }),
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
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTheme.spaceS),
                  itemBuilder: (context, index) =>
                      _ExpenseTile(expense: visible[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExpenseForm() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const _ExpenseFormDialog(),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('Expense recorded', 'ወጪ ተመዝግቧል')),
        backgroundColor: AppColors.primaryTeal,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.expenseCount, required this.onAdd});

  final int expenseCount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('EXPENSES', 'ወጪዎች'),
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
                  '$expenseCount expenses recorded',
                  '$expenseCount ወጪዎች ተመዝግበዋል',
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
// Summary card
// ---------------------------------------------------------------------------

class _ExpenseSummary {
  const _ExpenseSummary({
    required this.todayOperating,
    required this.yesterdayOperating,
    required this.todayCapital,
  });

  final double todayOperating;
  final double yesterdayOperating;
  final double todayCapital;

  factory _ExpenseSummary.from(List<ExpenseModel> expenses) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    bool inRange(DateTime date, DateTime start, DateTime end) =>
        !date.isBefore(start) && date.isBefore(end);

    var todayOperating = 0.0;
    var yesterdayOperating = 0.0;
    var todayCapital = 0.0;

    for (final expense in expenses) {
      if (!expense.isRestockExpense &&
          inRange(expense.expenseDate, todayStart, tomorrowStart)) {
        todayOperating += expense.amount;
      }
      if (!expense.isRestockExpense &&
          inRange(expense.expenseDate, yesterdayStart, todayStart)) {
        yesterdayOperating += expense.amount;
      }
      if (expense.isRestockExpense &&
          inRange(expense.expenseDate, todayStart, tomorrowStart)) {
        todayCapital += expense.amount;
      }
    }

    return _ExpenseSummary(
      todayOperating: todayOperating,
      yesterdayOperating: yesterdayOperating,
      todayCapital: todayCapital,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final _ExpenseSummary summary;

  @override
  Widget build(BuildContext context) {
    final change = summary.yesterdayOperating > 0
        ? (summary.todayOperating - summary.yesterdayOperating) /
            summary.yesterdayOperating
        : null;
    final isUp = change != null && change > 0;
    final isDown = change != null && change < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF12786B),
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.tr("TODAY'S OPERATING SPEND", 'የዛሬ የስራ ወጪ'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const Spacer(),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatBirrWhole(summary.todayOperating),
            style: const TextStyle(
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: Text(
                  '${context.tr('Operating only', 'የስራ ወጪ ብቻ')} · '
                  '${DateHelper.formatDate(DateTime.now())}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (change != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUp
                            ? Icons.arrow_upward_rounded
                            : isDown
                                ? Icons.arrow_downward_rounded
                                : Icons.remove,
                        size: 12,
                        color: isUp
                            ? AppColors.rose300
                            : isDown
                                ? AppColors.emerald200
                                : Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${(change.abs() * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isUp
                              ? AppColors.rose300
                              : isDown
                                  ? AppColors.emerald200
                                  : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        context.tr('vs yesterday', 'ከትናንት'),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (summary.todayCapital > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.tr(
                        'Restock CapEx today (excluded)',
                        'የዛሬ የእቃ መሙላት ወጪ (አልተካተተም)',
                      ),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatBirrWhole(summary.todayCapital),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category grid
// ---------------------------------------------------------------------------

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.selected,
    required this.onSelected,
    required this.onClear,
  });

  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.tr('Categories', 'ምድቦች'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const Spacer(),
            PillTransition(
              selected: selected == null,
              selectedColor: scheme.primary.withValues(alpha: 0.12),
              selectedForeground: scheme.primary,
              unselectedForeground: scheme.onSurfaceVariant,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              onTap: onClear,
              child: Text(context.tr('All', 'ሁሉም')),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.92,
          children: [
            for (final category in ExpenseCategory.values)
              _CategoryTile(
                category: category,
                selected: selected == category,
                onTap: () =>
                    selected == category ? onClear() : onSelected(category),
              ),
          ],
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ExpenseCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = expenseCategoryColor(category);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: isDark ? 0.22 : 0.12)
              : scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.55)
                : scheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.5),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.13),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(categoryIcon(category), size: 16, color: color),
            ),
            const SizedBox(height: 5),
            Text(
              _categoryLabel(context, category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? color : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// View toggle
// ---------------------------------------------------------------------------

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.showAll, required this.onChanged});

  final bool showAll;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.neutralBg.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PillTransition(
            selected: !showAll,
            selectedColor: scheme.primary,
            selectedForeground: scheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            onTap: () => onChanged(false),
            child: Text(context.tr('OpEx', 'ስራ')),
          ),
          PillTransition(
            selected: showAll,
            selectedColor: scheme.primary,
            selectedForeground: scheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            onTap: () => onChanged(true),
            child: Text(context.tr('All', 'ሁሉም')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Expense list
// ---------------------------------------------------------------------------

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});

  final ExpenseModel expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final color = expenseCategoryColor(expense.category);
    final isCapital = expense.isRestockExpense;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              categoryIcon(expense.category),
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_categoryLabel(context, expense.category)} · '
                  '${DateHelper.formatRelativeTime(expense.expenseDate)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 5),
                _ExpenseKindBadge(isCapital: isCapital),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '-${CurrencyFormatter.formatBirrWhole(expense.amount)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isCapital ? AppColors.alertAmber : AppColors.alertRed,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseKindBadge extends StatelessWidget {
  const _ExpenseKindBadge({required this.isCapital});

  final bool isCapital;

  @override
  Widget build(BuildContext context) {
    final color = isCapital ? AppColors.alertAmber : AppColors.primaryTeal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isCapital ? 'CapEx' : 'OpEx',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add expense
// ---------------------------------------------------------------------------

class _ExpenseFormDialog extends ConsumerStatefulWidget {
  const _ExpenseFormDialog();

  @override
  ConsumerState<_ExpenseFormDialog> createState() =>
      _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends ConsumerState<_ExpenseFormDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _receiptController = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.other;
  DateTime _date = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    String? error;
    if (title.isEmpty) {
      error = context.tr(
        'Expense title is required.',
        'የወጪው ርዕስ ያስፈልጋል።',
      );
    } else if (amount == null || amount <= 0) {
      error = context.tr(
        'Enter an amount greater than zero.',
        'ከዜሮ በላይ የሆነ መጠን ያስገቡ።',
      );
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repository = await ref.read(expenseRepositoryProvider.future);
      final isRestock = _category == ExpenseCategory.restock;
      final receipt = _receiptController.text.trim();
      await repository.create(
        ExpenseModel(
          title: title,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          amount: amount!,
          category: _category,
          expenseDate: _date,
          createdAt: DateTime.now(),
          receiptImageUrl: receipt.isEmpty ? null : receipt,
          isRestockExpense: isRestock,
        ),
      );
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isRestock = _category == ExpenseCategory.restock;

    InputDecoration decoration(String label, {IconData? icon}) {
      return InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : Colors.white,
        prefixIcon: icon == null ? null : Icon(icon, size: 18),
      );
    }

    return AlertDialog(
      title: Text(
        context.tr('Record expense', 'ወጪ መዝግብ'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                autofocus: true,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: decoration(
                  context.tr('Title *', 'ርዕስ *'),
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: decoration(
                  context.tr('Description (optional)', 'መግለጫ (አማራጭ)'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: decoration(
                  context.tr('Amount *', 'መጠን *'),
                  icon: Icons.payments_outlined,
                ).copyWith(prefixText: 'ብር '),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _category,
                isExpanded: true,
                decoration: decoration(
                  context.tr('Category', 'ምድብ'),
                  icon: Icons.category_outlined,
                ),
                items: [
                  for (final category in ExpenseCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            categoryIcon(category),
                            size: 16,
                            color: expenseCategoryColor(category),
                          ),
                          const SizedBox(width: 8),
                          Text(_categoryLabel(context, category)),
                        ],
                      ),
                    ),
                ],
                onChanged: (category) {
                  if (category == null) return;
                  setState(() => _category = category);
                },
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _saving ? null : _pickDate,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: InputDecorator(
                  decoration: decoration(
                    context.tr('Date', 'ቀን'),
                    icon: Icons.calendar_today_outlined,
                  ),
                  child: Text(
                    DateHelper.formatDate(_date),
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _receiptController,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: decoration(
                  context.tr(
                    'Receipt image path or URL (optional)',
                    'የደረሰኝ ምስል አድራሻ (አማራጭ)',
                  ),
                  icon: Icons.image_outlined,
                ),
              ),
              if (isRestock) ...[
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    'Restock is recorded as CapEx and excluded from operating '
                    'spend and net profit.',
                    'እቃ መሙላት እንደ CapEx ተመዝግቦ ከስራ ወጪ እና ከተጣራ ትርፍ ይመነጫል።',
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
              : Text(context.tr('Save expense', 'ወጪ አስቀምጥ')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyExpenses extends StatelessWidget {
  const _EmptyExpenses({
    required this.hasFilters,
    required this.onAdd,
    required this.onReset,
  });

  final bool hasFilters;
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
                hasFilters ? Icons.filter_alt_off : Icons.receipt_long_outlined,
                size: 34,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              hasFilters
                  ? context.tr('No matching expenses', 'ተመሳሳይ ወጪ አልተገኘም')
                  : context.tr('No expenses yet', 'እስካሁን ወጪ የለም'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? context.tr(
                      'Adjust the category or view filter to see more.',
                      'ተጨማሪ ለማየት ምድብ ወይም ማጣሪያ ይቀይሩ።',
                    )
                  : context.tr(
                      'Record rent, salaries, transport and other spending '
                      'to keep profit accurate.',
                      'ትርፍ ትክክል እንዲሆን ኪራይ፣ ደሞዝ፣ መጓጓዣ እና ሌሎች ወጪዎችን ይመዝግቡ።',
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceM),
            if (hasFilters)
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(context.tr('Show all', 'ሁሉንም አሳይ')),
              )
            else
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text(context.tr('Record expense', 'ወጪ መዝግብ')),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared category presentation helpers
// ---------------------------------------------------------------------------

IconData categoryIcon(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.rent:
      return Icons.home_outlined;
    case ExpenseCategory.salary:
      return Icons.people_outline;
    case ExpenseCategory.transport:
      return Icons.local_shipping_outlined;
    case ExpenseCategory.utilities:
      return Icons.lightbulb_outline;
    case ExpenseCategory.airtime:
      return Icons.phone_iphone;
    case ExpenseCategory.supplies:
      return Icons.inventory_2_outlined;
    case ExpenseCategory.restock:
      return Icons.autorenew;
    case ExpenseCategory.other:
      return Icons.more_horiz;
  }
}

Color expenseCategoryColor(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.rent:
      return AppColors.primaryTeal;
    case ExpenseCategory.salary:
      return AppColors.infoBlue;
    case ExpenseCategory.transport:
      return AppColors.alertAmber;
    case ExpenseCategory.utilities:
      return const Color(0xFFD97706);
    case ExpenseCategory.airtime:
      return const Color(0xFF7C3AED);
    case ExpenseCategory.supplies:
      return AppColors.successGreen;
    case ExpenseCategory.restock:
      return AppColors.alertRed;
    case ExpenseCategory.other:
      return AppColors.textSecondary;
  }
}

String _categoryLabel(BuildContext context, ExpenseCategory category) {
  return context.isAmharic
      ? category.displayNameAmharic
      : category.displayName;
}
