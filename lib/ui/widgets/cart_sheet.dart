import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/security/password_hasher.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/l10n.dart';
import '../../data/models/sale_model.dart';
import '../../logic/providers/cart_provider.dart';
import '../../logic/providers/repository_providers.dart';
import '../animations/pill_transition.dart';

/// Slide-up cart with quantity steppers, price override, payment selection,
/// change calculation and the complete-sale action.
class CartSheet extends ConsumerStatefulWidget {
  const CartSheet({super.key});

  @override
  ConsumerState<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends ConsumerState<CartSheet> {
  late final TextEditingController _amountController;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _editPrice(CartItem item) async {
    final repository = await ref.read(userRepositoryProvider.future);
    final profile = await repository.getProfile();
    if (!mounted) return;

    final newPrice = await showDialog<double>(
      context: context,
      builder: (_) => _PriceEditDialog(
        item: item,
        passwordHash: profile?.passwordHash,
      ),
    );
    if (newPrice == null) return;

    try {
      ref.read(cartProvider.notifier).updatePrice(item.productId, newPrice);
    } on CartException catch (error) {
      _showError(error.message);
    }
  }

  Future<void> _completeSale() async {
    setState(() => _processing = true);
    try {
      final repository = await ref.read(userRepositoryProvider.future);
      final profile = await repository.getProfile();
      await ref.read(cartProvider.notifier).completeSale(
            cashierName: profile?.ownerName ?? profile?.businessName,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CartException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.alertRed,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(
                            'Cart (${cart.itemCount})',
                            'ጋሪ (${cart.itemCount})',
                          ),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: cart.isEmpty
                            ? null
                            : () => ref.read(cartProvider.notifier).clearCart(),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text(context.tr('Clear', 'አጽዳ')),
                      ),
                    ],
                  ),
                ),
                if (cart.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceXL),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr(
                            'Your cart is empty',
                            'ጋሪዎ ባዶ ነው',
                          ),
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return _CartItemRow(
                          item: item,
                          onIncrement: () {
                            try {
                              ref
                                  .read(cartProvider.notifier)
                                  .incrementQuantity(item.productId);
                            } on CartException catch (error) {
                              _showError(error.message);
                            }
                          },
                          onDecrement: () => ref
                              .read(cartProvider.notifier)
                              .decrementQuantity(item.productId),
                          onRemove: () => ref
                              .read(cartProvider.notifier)
                              .removeItem(item.productId),
                          onEditPrice: () => _editPrice(item),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('PAYMENT METHOD', 'የክፍያ ዘዴ'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: PaymentMethod.values.map((method) {
                            return PillTransition(
                              selected: cart.paymentMethod == method,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              selectedColor:
                                  scheme.primary.withValues(alpha: 0.14),
                              onTap: () => ref
                                  .read(cartProvider.notifier)
                                  .setPaymentMethod(method),
                              child: Text(_paymentLabel(context, method)),
                            );
                          }).toList(),
                        ),
                        if (cart.requiresAmountReceived) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: context.tr(
                                'Amount received',
                                'የተቀበለው ገንዘብ',
                              ),
                              prefixIcon:
                                  const Icon(Icons.payments_outlined),
                            ),
                            onChanged: (value) {
                              ref
                                  .read(cartProvider.notifier)
                                  .setAmountReceived(double.tryParse(value));
                            },
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr('Total', 'ድምር'),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatBirr(cart.total),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        if (cart.change != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.tr('Change', 'ተመላሽ'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatBirr(cart.change!),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _processing ? null : _completeSale,
                            child: _processing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    context.tr(
                                      'Complete Sale',
                                      'ሽያጭ አጠናቅቅ',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _paymentLabel(BuildContext context, PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return context.tr('Cash', 'ጥሬ ገንዘብ');
      case PaymentMethod.telebirr:
        return 'Telebirr';
      case PaymentMethod.cbeBirr:
        return 'CBE Birr';
      case PaymentMethod.amharaBank:
        return 'Amhara Bank';
      case PaymentMethod.mixed:
        return context.tr('Mixed', 'ቅልቅል');
    }
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onEditPrice,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback onEditPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${CurrencyFormatter.formatBirr(item.unitPrice)} × ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StepButton(
                      icon: Icons.remove,
                      onTap: onDecrement,
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        item.quantity.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    _StepButton(
                      icon: Icons.add,
                      onTap: onIncrement,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Edit price',
                      onPressed: onEditPrice,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove',
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18),
              ),
              Text(
                CurrencyFormatter.formatBirr(item.lineTotal),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: scheme.onSurface),
      ),
    );
  }
}

class _PriceEditDialog extends StatefulWidget {
  const _PriceEditDialog({
    required this.item,
    this.passwordHash,
  });

  final CartItem item;
  final String? passwordHash;

  @override
  State<_PriceEditDialog> createState() => _PriceEditDialogState();
}

class _PriceEditDialogState extends State<_PriceEditDialog> {
  late final TextEditingController _priceController;
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.item.unitPrice.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      setState(() => _error = context.tr(
            'Enter a valid price greater than zero.',
            'ከዜሮ በላይ የሆነ ትክክለኛ ዋጋ ያስገቡ።',
          ));
      return;
    }
    if (widget.passwordHash != null &&
        !PasswordHasher.verify(
          _passwordController.text,
          widget.passwordHash,
        )) {
      setState(() => _error = context.tr(
            'Incorrect password.',
            'የተሳሳተ የይለፍ ቃል።',
          ));
      return;
    }
    Navigator.of(context).pop(price);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        context.tr(
          'Edit price · ${widget.item.productName}',
          'ዋጋ አስተካክል · ${widget.item.productName}',
        ),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _priceController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.tr('New price', 'አዲስ ዋጋ'),
              prefixText: 'ብር ',
            ),
          ),
          if (widget.passwordHash != null) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.tr('Password', 'የይለፍ ቃል'),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.alertRed,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancel', 'ሰርዝ')),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(context.tr('Save', 'አስቀምጥ')),
        ),
      ],
    );
  }
}
