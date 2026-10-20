import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/l10n.dart';
import '../../data/models/product_model.dart';
import '../../logic/calculators/wac_calculator.dart';
import '../../logic/providers/repository_providers.dart';

/// Modal that previews the new weighted average cost before committing a
/// restock (stock + restock log + CapEx expense atomically).
class RestockModal extends ConsumerStatefulWidget {
  const RestockModal({super.key, required this.product});

  final ProductModel product;

  @override
  ConsumerState<RestockModal> createState() => _RestockModalState();
}

class _RestockModalState extends ConsumerState<RestockModal> {
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    super.dispose();
  }

  int? get _quantity => int.tryParse(_quantityController.text.trim());

  double? get _cost => double.tryParse(_costController.text.trim());

  double? get _newWac {
    final quantity = _quantity;
    final cost = _cost;
    if (quantity == null || quantity <= 0 || cost == null || cost < 0) {
      return null;
    }
    return WACCalculator.calculateNewWAC(
      currentStock: widget.product.currentStock,
      currentCost: widget.product.costPrice,
      addedQuantity: quantity,
      purchasePrice: cost,
    );
  }

  Future<void> _confirm() async {
    final quantity = _quantity;
    final cost = _cost;

    if (quantity == null || quantity <= 0) {
      setState(() => _error = 'Enter a quantity greater than zero.');
      return;
    }
    if (cost == null || cost < 0) {
      setState(() => _error = 'Enter a valid cost per unit.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repository = await ref.read(productRepositoryProvider.future);
      final result = await repository.restock(
        productId: widget.product.id,
        quantityAdded: quantity,
        costPerUnit: cost,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
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
    final scheme = Theme.of(context).colorScheme;
    final newWac = _newWac;
    final totalCost = ((_quantity ?? 0) * (_cost ?? 0)).toDouble();

    return AlertDialog(
      title: Text(
        context.tr('Restock product', 'እቃ እንደገና ሙላ'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${context.tr('Current stock', 'አሁን ያለ መጠን')}: '
                    '${widget.product.currentStock}',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${context.tr('Current WAC', 'የአሁኑ አማካይ ወጪ')}: '
                    '${CurrencyFormatter.formatBirr(widget.product.costPrice)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _quantityController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: context.tr('Quantity added', 'የተጨመረ ብዛት'),
                prefixIcon: const Icon(Icons.add_box_outlined),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: context.tr('Cost per unit', 'የአንድ አሃድ ወጪ'),
                prefixText: 'ብር ',
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _PreviewRow(
                    label: context.tr('New WAC', 'አዲስ አማካይ ወጪ'),
                    value: newWac == null
                        ? '—'
                        : CurrencyFormatter.formatBirr(newWac),
                    highlight: true,
                  ),
                  const SizedBox(height: 6),
                  _PreviewRow(
                    label: context.tr('Total cost', 'አጠቃላይ ወጪ'),
                    value: CurrencyFormatter.formatBirr(totalCost),
                  ),
                ],
              ),
            ),
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
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancel', 'ሰርዝ')),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _confirm,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(context.tr('Confirm', 'አረጋግጥ')),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: highlight ? AppColors.primaryTeal : scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
