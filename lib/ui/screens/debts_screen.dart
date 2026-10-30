import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/licensing/license_gate.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/l10n.dart';
import '../../data/models/debt_model.dart';
import '../../data/repositories/debt_repository.dart';
import '../../data/repositories/repository_exceptions.dart';
import '../../logic/providers/repository_providers.dart';
import '../widgets/screen_header.dart';

/// Who owes the shop money.
///
/// A credit sale is never rewritten when the customer comes back: the invoice
/// keeps its full value so profit stays on the day the goods left, and only the
/// balance on this screen moves.
class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  bool _showSettled = false;

  Future<void> _takePayment(DebtModel debt) async {
    // Built before the awaits: this screen's own context is what the messages
    // need, and after the dialog and the write the widget may be gone.
    final licenseLostMessage = context.tr(
      'Your license or trial has ended. Renew in Profile to record a payment. '
          'Existing records stay available.',
      'ፈቃድዎ ወይም ሙከራዎ አብቋል። ክፍያ ለመመዝገብ በመገለጫ ውስጥ ያድሱ። '
          'ያሉት መዛግብቶች ይገኛሉ።',
    );
    final repository = await ref.read(debtRepositoryProvider.future);
    if (!mounted) return;

    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _PaymentDialog(debt: debt),
    );
    if (amount == null || !mounted) return;

    try {
      final updated = await repository.recordPayment(
        debtId: debt.id,
        amount: amount,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              updated.isOpen
                  ? context.tr(
                      'Taken. ${CurrencyFormatter.formatBirr(updated.balanceDue)} '
                          'still owed by ${updated.customerName}.',
                      'ተቀብሏል። ${CurrencyFormatter.formatBirr(updated.balanceDue)} '
                          'ገና በ${updated.customerName} ላይ ቀርቷል።',
                    )
                  : context.tr(
                      '${updated.customerName} has settled up. Nothing owed.',
                      '${updated.customerName} ሚዛኑን አጠናቀቀ። ምንም አልቀረም።',
                    ),
            ),
            backgroundColor: updated.isOpen
                ? AppColors.alertAmber
                : AppColors.primaryTeal,
          ),
        );
    } on LicenseRequiredException {
      _showError(licenseLostMessage);
    } catch (error) {
      _showError(error is RepositoryException ? error.message : '$error');
    }
  }

  Future<void> _editContact(DebtModel debt) async {
    final repository = await ref.read(debtRepositoryProvider.future);
    if (!mounted) return;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactSheet(debt: debt, repository: repository),
    );
    if (!mounted || saved != true) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.tr('Balance updated', 'ሚዛን ተስተካክሏል')),
          backgroundColor: AppColors.primaryTeal,
        ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final openAsync = ref.watch(openDebtsProvider);
    final open = openAsync.valueOrNull ?? const <DebtModel>[];

    var outstanding = 0.0;
    for (final debt in open) {
      outstanding += debt.balanceDue;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceM,
                AppTheme.spaceS,
                AppTheme.spaceM,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: ScreenHeader(
                  leading: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: context.tr('Back', 'ተመለስ'),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: context.tr('WHO OWES ME', 'ማን ይዳናል'),
                  subtitle: context.tr(
                    'Credit sales stay on the sale; only the balance moves here.',
                    'እዳ የሽያጩ ላይ ይቆያል፤ እዚህ የሚቀየረው ቀሪው ብቻ ነው።',
                  ),
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
                child: _OutstandingCard(
                  outstanding: outstanding,
                  openCount: open.length,
                ),
              ),
            ),
            if (openAsync.isLoading && open.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (open.isEmpty)
              SliverToBoxAdapter(
                child: const Padding(
                  padding: EdgeInsets.only(top: AppTheme.spaceXL),
                  child: _EmptyDebts(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceM,
                  AppTheme.spaceL,
                  AppTheme.spaceM,
                  0,
                ),
                sliver: SliverList.separated(
                  itemCount: open.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTheme.spaceS),
                  itemBuilder: (context, index) {
                    final debt = open[index];
                    return _DebtTile(
                      debt: debt,
                      onTakePayment: () => _takePayment(debt),
                      onEditContact: () => _editContact(debt),
                    );
                  },
                ),
              ),
            // Always rendered: a shop with nothing open still has a record of
            // who paid up, and that is the history a merchant comes to check.
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceM,
                AppTheme.spaceL,
                AppTheme.spaceM,
                AppTheme.spaceXL,
              ),
              sliver: SliverToBoxAdapter(
                child: _SettledSection(
                  expanded: _showSettled,
                  onToggle: () => setState(() => _showSettled = !_showSettled),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Outstanding total
// ---------------------------------------------------------------------------

class _OutstandingCard extends StatelessWidget {
  const _OutstandingCard({required this.outstanding, required this.openCount});

  final double outstanding;
  final int openCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8A5A00), AppColors.alertAmber],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.alertAmber.withValues(alpha: 0.26),
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
                context.tr('STILL TO COME IN', 'ገና የማይገባ'),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const Spacer(),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.handshake_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.formatBirrWhole(outstanding),
            style: const TextStyle(
              fontSize: 32,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            openCount == 0
                ? context.tr('Nobody owes anything', 'ማንም አልተዳነም')
                : context.tr(
                    '$openCount customer${openCount == 1 ? '' : 's'} on the list, '
                        'oldest first',
                    '$openCount ደንበኞች በዝርዝሩ ላይ፣ የቆየው በፊት',
                  ),
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// One debtor
// ---------------------------------------------------------------------------

class _DebtTile extends StatelessWidget {
  const _DebtTile({
    required this.debt,
    required this.onTakePayment,
    required this.onEditContact,
  });

  final DebtModel debt;
  final VoidCallback onTakePayment;
  final VoidCallback onEditContact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final days = DateHelper.daysBetween(debt.openedAt, DateTime.now());

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.alertAmber.withValues(
                    alpha: isDark ? 0.2 : 0.13,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 20,
                  color: AppColors.alertAmber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _openedLine(context, debt, days),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (debt.customerPhone != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        debt.customerPhone!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatBirr(debt.balanceDue),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.alertAmber,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr(
                      'of ${CurrencyFormatter.formatBirrWhole(debt.totalAmount)}',
                      'ከ${CurrencyFormatter.formatBirrWhole(debt.totalAmount)}',
                    ),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Progress(proportion: debt.paidProportion),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onTakePayment,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  icon: const Icon(Icons.payments_outlined, size: 17),
                  label: Text(
                    context.tr('Take payment', 'ክፍያ ተቀበል'),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: onEditContact,
                tooltip: context.tr(
                  'Correct name or phone',
                  'ስም ወይም ስልክ አስተካክል',
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ],
          ),
          if (debt.payments.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PaymentHistory(payments: debt.payments),
          ],
        ],
      ),
    );
  }

  static String _openedLine(BuildContext context, DebtModel debt, int days) {
    final when = DateHelper.formatDate(debt.openedAt);
    if (days <= 0) {
      return context.tr('Opened today · $when', 'ዛሬ ተከፈተ · $when');
    }
    return context.tr(
      '$days day${days == 1 ? '' : 's'} ago · $when',
      '$days ቀን በፊት · $when',
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.proportion});

  final double proportion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: proportion,
        minHeight: 6,
        backgroundColor: scheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation(AppColors.primaryTeal),
      ),
    );
  }
}

class _PaymentHistory extends StatelessWidget {
  const _PaymentHistory({required this.payments});

  final List<DebtPayment> payments;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Payments received', 'የተቀበሉ ክፍያዎች'),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        for (final payment in payments)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 13,
                  color: AppColors.primaryTeal,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    DateHelper.formatDate(payment.at),
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  CurrencyFormatter.formatBirr(payment.amount),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Settled, folded away until asked for
// ---------------------------------------------------------------------------

class _SettledSection extends ConsumerWidget {
  const _SettledSection({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final settled = ref.watch(settledDebtsProvider).valueOrNull ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: settled.isEmpty ? null : onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: Row(
              children: [
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  context.tr('Settled up', 'የተከፈሉ'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  settled.isEmpty
                      ? context.tr('none yet', 'እስካሁን የለም')
                      : context.tr(
                          '${settled.length} shown',
                          '${settled.length} ታይተዋል',
                        ),
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          for (final debt in settled)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spaceS),
              child: _SettledTile(debt: debt),
            ),
      ],
    );
  }
}

class _SettledTile extends StatelessWidget {
  const _SettledTile({required this.debt});

  final DebtModel debt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final settledAt = debt.lastPaymentAt ?? debt.openedAt;

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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.done_all_rounded,
              size: 18,
              color: AppColors.successGreen,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr(
                    'Cleared on ${DateHelper.formatDate(settledAt)}',
                    'በ${DateHelper.formatDate(settledAt)} ተገድሏል',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.formatBirrWhole(debt.totalAmount),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
              decorationColor: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyDebts extends StatelessWidget {
  const _EmptyDebts();

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
                color: AppColors.successGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.verified_outlined,
                size: 34,
                color: AppColors.successGreen,
              ),
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              context.tr('Nobody owes you', 'ማንም አልተዳነዎትም'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(
                'When a sale is recorded on credit or with a part payment the '
                    'customer appears here with what is still owed.',
                'ሽያጭ በእዳ ወይም በከፊል ክፍያ ሲመዝገብ ደንበኛው የቀረው ገንዘብ እዚህ ይታያል።',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Take a payment
// ---------------------------------------------------------------------------

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({required this.debt});

  final DebtModel debt;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.debt.balanceDue.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_controller.text.trim());
    if (amount == null || amount <= 0) {
      setState(
        () => _error = context.tr(
          'Enter an amount greater than zero.',
          'ከዜሮ በላይ የሆነ መጠን ያስገቡ።',
        ),
      );
      return;
    }
    if (amount > widget.debt.balanceDue + DebtModel.tolerance) {
      setState(
        () => _error = context.tr(
          'That is more than the ${CurrencyFormatter.formatBirr(widget.debt.balanceDue)} still owed.',
          'ይህ ከ${CurrencyFormatter.formatBirr(widget.debt.balanceDue)} ቀሪው በላይ ነው።',
        ),
      );
      return;
    }
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(
        context.tr(
          'Payment from ${widget.debt.customerName}',
          '${widget.debt.customerName} ክፍያ',
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              'Still owed: ${CurrencyFormatter.formatBirr(widget.debt.balanceDue)}',
              'ቀሪ፡ ${CurrencyFormatter.formatBirr(widget.debt.balanceDue)}',
            ),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.alertAmber,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            decoration: InputDecoration(
              labelText: context.tr('Amount received', 'የተቀበሉት'),
              isDense: true,
              prefixText: 'ብር ',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'The invoice keeps its full value; only this balance changes.',
              'የሽያጩ ዋጋ አልቀየረም፤ የሚቀየረው ይህ ቀሪ ብቻ ነው።',
            ),
            style: TextStyle(
              fontSize: 10.5,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancel', 'ተሰርዝ')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.tr('Record', 'መዝግብ')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Correct who the balance is on
// ---------------------------------------------------------------------------

class _ContactSheet extends ConsumerStatefulWidget {
  const _ContactSheet({required this.debt, required this.repository});

  final DebtModel debt;
  final DebtRepository repository;

  @override
  ConsumerState<_ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<_ContactSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.debt.customerName,
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.debt.customerPhone ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.setContact(
        debtId: widget.debt.id,
        customerName: _name.text,
        customerPhone: _phone.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXLarge),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceM,
                    16,
                    AppTheme.spaceM,
                    0,
                  ),
                  child: Text(
                    context.tr('Who is this balance on?', 'ይህ ቀሪ የማን ነው?'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceM,
                    14,
                    AppTheme.spaceM,
                    0,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        decoration: InputDecoration(
                          labelText: context.tr('Customer name', 'የደንበኛ ስም'),
                          isDense: true,
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        decoration: InputDecoration(
                          labelText: context.tr(
                            'Phone (optional)',
                            'ስልክ (አማራጭ)',
                          ),
                          isDense: true,
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceM,
                    14,
                    AppTheme.spaceM,
                    AppTheme.spaceM,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              context.tr('Save', 'አስቀምጥ'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
