import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/backup/data_backup.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/export/excel_exporter.dart';
import '../../core/settings/data_deletion_service.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/l10n.dart';
import '../../logic/providers/cart_provider.dart';
import '../../logic/providers/database_provider.dart';
import '../../logic/providers/inventory_provider.dart';
import '../../logic/providers/license_provider.dart';
import '../../logic/providers/profit_provider.dart';
import '../../logic/providers/repository_providers.dart';
import '../../logic/providers/theme_provider.dart';
import '../widgets/screen_header.dart';
import '../widgets/settings_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _backup = DataBackup();

  DateTime? _lastBackupAt;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadBackupStamp();
  }

  Future<void> _loadBackupStamp() async {
    final at = await _backup.lastBackupAt();
    if (!mounted) return;
    setState(() => _lastBackupAt = at);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final hasPassword = profile?.passwordHash != null;

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
              _Header(onBack: () => Navigator.of(context).maybePop()),
              const SizedBox(height: AppTheme.spaceM),
              SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsSectionTitle(
                      context.tr('Appearance', 'አቀራረብ'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SettingsChoiceTile(
                            icon: Icons.light_mode_outlined,
                            label: context.tr('Light', 'ብርሃን'),
                            selected: themeMode == ThemeMode.light,
                            onTap: () => _setTheme(ThemeMode.light),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SettingsChoiceTile(
                            icon: Icons.dark_mode_outlined,
                            label: context.tr('Dark', 'ጨለማ'),
                            selected: themeMode == ThemeMode.dark,
                            onTap: () => _setTheme(ThemeMode.dark),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SettingsChoiceTile(
                            icon: Icons.brightness_auto_outlined,
                            label: context.tr('System', 'ስርዓት'),
                            selected: themeMode == ThemeMode.system,
                            onTap: () => _setTheme(ThemeMode.system),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SettingsSectionTitle(context.tr('Language', 'ቋንቋ')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SettingsChoiceTile(
                            icon: Icons.translate,
                            label: 'English',
                            selected: locale.languageCode == 'en',
                            onTap: () => ref
                                .read(localeProvider.notifier)
                                .setLanguage('en'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SettingsChoiceTile(
                            icon: Icons.translate,
                            label: 'አማርኛ',
                            selected: locale.languageCode == 'am',
                            onTap: () => ref
                                .read(localeProvider.notifier)
                                .setLanguage('am'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsSectionTitle(
                      context.tr('Reports & backup', 'ወረዳና ምትኬ'),
                    ),
                    const SizedBox(height: 10),
                    SettingsActionTile(
                      icon: Icons.grid_on_rounded,
                      title: context.tr('Export Excel report', 'ወደ ኤክሰል ላክ'),
                      subtitle: context.tr(
                        'Products, sales and expenses as .xlsx',
                        'እቃዎች፣ ሽያጮችና ወጪዎች እንደ ኤክሰል',
                      ),
                      trailing: _busy
                          ? const _Spinner()
                          : const Icon(Icons.description_outlined, size: 20),
                      onTap: _busy ? null : _exportExcel,
                    ),
                    const SizedBox(height: 8),
                    SettingsActionTile(
                      icon: Icons.cloud_download_outlined,
                      title: context.tr('Back up data', 'ውሂብ ያስቀምጡ'),
                      subtitle: _lastBackupAt == null
                          ? context.tr('Never backed up', 'አልተቀመጠም')
                          : context.tr(
                              'Last backup ${DateHelper.formatDateTime(_lastBackupAt!)}',
                              'የመጨረሻ ማስቀመጫ ${DateHelper.formatDateTime(_lastBackupAt!)}',
                            ),
                      trailing: _busy
                          ? const _Spinner()
                          : const Icon(Icons.file_download_outlined, size: 20),
                      onTap: _busy ? null : _backupJson,
                    ),
                    const SizedBox(height: 8),
                    SettingsActionTile(
                      icon: Icons.restore_outlined,
                      title: context.tr('Restore data', 'ውሂብ መልስ'),
                      subtitle: context.tr(
                        'Restore from an exported JSON backup',
                        'ከተላከ JSON ምትኬ ወደነበረበት ይመልሱ',
                      ),
                      trailing: const Icon(Icons.upload_file_outlined, size: 20),
                      onTap: _busy ? null : _restoreJson,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsSectionTitle(
                      context.tr('Delete data', 'ውሂብ ሰርዝ'),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPassword
                          ? context.tr(
                              'Every deletion asks for your account password.',
                              'እያንዳንዱ ማጥፋት የመግቢያ የይለፍ ቃልዎን ይጠይቃል።',
                            )
                          : context.tr(
                              'Set a password in Profile before deleting '
                              'anything.',
                              'ማጥፋት ከመፈጸሙ በፊት በመገለጫ የይለፍ ቃል ይስጡ።',
                            ),
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SettingsActionTile(
                      icon: Icons.cleaning_services_outlined,
                      danger: true,
                      title: context.tr(
                        'Clear sales & stock',
                        'ሽያጭና ክምችት አጽዳ',
                      ),
                      subtitle: context.tr(
                        'Products, sales, expenses. Keeps profile & license.',
                        'እቃዎች፣ ሽያጮች፣ ወጪዎች። መገለጫና ፈቃድ ይቆያሉ።',
                      ),
                      onTap: hasPassword
                          ? () => _startDeletion(DataDeletionScope.businessRecords)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    SettingsActionTile(
                      icon: Icons.delete_forever_outlined,
                      danger: true,
                      title: context.tr(
                        'Delete everything',
                        'ሁሉንም ሰርዝ',
                      ),
                      subtitle: context.tr(
                        'Wipes this device and signs you out',
                        'ዚህን መሣሪያ አጽድቶ ያስወጣል',
                      ),
                      onTap: hasPassword
                          ? () => _startDeletion(DataDeletionScope.entireAccount)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceL),
              Text(
                context.tr(
                  'Deleting is permanent. Make a backup first.',
                  'ማጥፋት ሊመለስ አይችልም። በፊት ምትኬ ያስቀምጡ።',
                ),
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setTheme(ThemeMode mode) async {
    try {
      await ref.read(themeModeProvider.notifier).setThemeMode(mode);
    } on Object catch (_) {
      // The screen already flipped to the new mode; without the write the next
      // cold start comes back in the old one, so say so instead of lying.
      if (!mounted) return;
      _showSnack(
        context.tr(
          'This choice could not be saved - the app may open in the old theme.',
          'ይህ ምርጫ ማስቀመጥ አልተቻለም - መተግበሪያው በድሮው ውስብስብ ሊከፈት ይችላል።',
        ),
        isError: true,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Reports & backup
  // -------------------------------------------------------------------------

  Future<void> _exportExcel() async {
    setState(() => _busy = true);
    try {
      final isar = await ref.read(databaseProvider.future);
      final profile = await ref.read(userProfileProvider.future);
      final file = await ExcelExporter(
        isar,
      ).export(businessName: profile?.businessName);
      await _shareFile(file, 'Efoy report');
      if (!mounted) return;
      _showSnack(context.tr('Report ready', 'ወረዳ ዝግጁ ነው'));
    } on Object catch (error) {
      if (!mounted) return;
      _showSnack(_describe(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _backupJson() async {
    setState(() => _busy = true);
    try {
      final file = await _backup.export();
      await _loadBackupStamp();
      await _shareFile(file, 'Efoy backup');
    } on Object catch (error) {
      if (!mounted) return;
      _showSnack(_describe(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreJson() async {
    final raw = await showDialog<String>(
      context: context,
      builder: (_) => const _RestoreDialog(),
    );
    if (!mounted || raw == null) return;

    Map<String, List<Map<String, dynamic>>> data;
    try {
      data = DataBackup.parse(raw);
    } on BackupFormatException catch (error) {
      _showSnack(error.message, isError: true);
      return;
    }

    final count = data.values.fold<int>(0, (sum, list) => sum + list.length);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Restore backup?', 'ምትኬ ወደነበረበት ይመለስ?')),
        content: Text(
          context.tr(
            'This will write $count records. Any existing records with the '
            'same IDs will be replaced. This cannot be undone.',
            'ይህ $count መዝገቦችን ይጽፋል። ተመሳሳይ መለያ ያላቸው ነባር መዝገቦች ይተካሉ። '
            'ይህ አይመለስም።',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('Cancel', 'ሰርዝ')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.tr('Restore', 'መልስ')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await _backup.restore(raw);
      _invalidateAll();
      if (!mounted) return;
      _showSnack(context.tr('Backup restored', 'ምትኬ ተመልሷል'));
    } on Object catch (error) {
      _showSnack(_describe(error), isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareFile(File file, String label) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: label),
    );
  }

  // -------------------------------------------------------------------------
  // Deletion
  // -------------------------------------------------------------------------

  Future<void> _startDeletion(DataDeletionScope scope) async {
    final isar = await ref.read(databaseProvider.future);
    final service = DataDeletionService(isar);
    final summary = await service.summarize();
    if (!mounted) return;

    final removed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _DeletionDialog(
        scope: scope,
        summary: summary,
        onSubmit: (password) async {
          try {
            await service.delete(scope: scope, password: password);
          } on DataDeletionDenied catch (error) {
            return error.message;
          }
          return null;
        },
      ),
    );
    if (removed != true || !mounted) return;

    _invalidateAll();
    if (scope == DataDeletionScope.entireAccount) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/auth', (route) => false);
      return;
    }
    _showSnack(context.tr('Records cleared', 'መዝገቦቹ ተሰርዘዋል'));
  }

  /// Streams refresh themselves from Isar; these are the cached ones.
  void _invalidateAll() {
    ref
      ..invalidate(dashboardSummaryProvider)
      ..invalidate(inventoryProvider)
      ..invalidate(activeLicenseProvider)
      ..invalidate(latestLicenseProvider)
      ..invalidate(licenseAccessProvider)
      ..invalidate(cartProvider);
  }

  String _describe(Object error) {
    if (error is ExcelExportException) return error.message;
    if (error is BackupFormatException) return error.message;
    return context.tr('Something went wrong: $error', 'ስህተት ተከሰተ፦ $error');
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.alertRed : AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ScreenHeader(
      leading: IconButton(
        onPressed: onBack,
        tooltip: context.tr('Back', 'ተመለስ'),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: scheme.onSurfaceVariant,
      ),
      title: context.tr('SETTINGS', 'ቅንብሮች'),
      subtitle: context.tr(
        'Appearance, reports and stored data',
        'አቀራረብ፣ ወረዳዎችና የተቀመጠ ውሂብ',
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
}

class _RestoreDialog extends StatefulWidget {
  const _RestoreDialog();

  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim();
    try {
      DataBackup.parse(raw);
    } on BackupFormatException {
      setState(() {
        _error = context.tr(
          'Paste a valid Efoy backup JSON.',
          'ትክክለኛ የኢፎይ ምትኬ JSON ይለጥፉ።',
        );
      });
      return;
    }
    Navigator.of(context).pop(raw);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(
        context.tr('Restore data', 'ውሂብ መልስ'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  'Open your exported backup file and paste its JSON here.',
                  'የተላከውን የምትኬ ፋይል ይክፈቱና JSON ይለጥፉ።',
                ),
                style: TextStyle(
                  fontSize: 11,
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                minLines: 5,
                maxLines: 8,
                autofocus: true,
                style: const TextStyle(fontSize: 11, height: 1.4),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  hintText: '{"products": [...], "sales": [...]}',
                  filled: true,
                  fillColor: isDark
                      ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
                      : Colors.white,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('Cancel', 'ሰርዝ')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(context.tr('Validate backup', 'ምትኬ አረጋግጥ')),
        ),
      ],
    );
  }
}

class _DeletionDialog extends ConsumerStatefulWidget {
  const _DeletionDialog({
    required this.scope,
    required this.summary,
    required this.onSubmit,
  });

  final DataDeletionScope scope;
  final DataDeletionSummary summary;

  /// Verifies the password and deletes. Returns an error message, or null when
  /// the deletion succeeded.
  final Future<String?> Function(String password) onSubmit;

  @override
  ConsumerState<_DeletionDialog> createState() => _DeletionDialogState();
}

class _DeletionDialogState extends ConsumerState<_DeletionDialog> {
  final _controller = TextEditingController();
  bool _obscured = true;
  bool _running = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _controller.text;
    if (password.isEmpty) {
      setState(() {
        _error = context.tr(
          'Enter your account password.',
          'የመግቢያ የይለፍ ቃልዎን ያስገቡ።',
        );
      });
      return;
    }
    setState(() {
      _running = true;
      _error = null;
    });
    final message = await widget.onSubmit(password);
    if (!mounted) return;
    if (message != null) {
      setState(() {
        _running = false;
        _error = message;
      });
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final full = widget.scope == DataDeletionScope.entireAccount;
    final summary = widget.summary;

    return AlertDialog(
      title: Text(
        full
            ? context.tr('Delete everything?', 'ሁሉንም ሰርዝ?')
            : context.tr('Clear sales & stock?', 'ሽያጭና ክምችት አጽዳ?'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              full
                  ? context.tr(
                      'This device will go back to first run. Nothing can be '
                      'recovered afterwards.',
                      'ይህ መሣሪያ ወደ መጀመሪያ ሁኔታ ይመለሳል። ከኋላ ምንም አይመለስም።',
                    )
                  : context.tr(
                      'Your shop starts from an empty book. The profile and '
                      'the license stay on this device.',
                      'ሱቅዎ ከባዶ መጽሐፍ ይጀምራል። መገለጫና ፈቃዱ በዚህ መሣሪያ ላይ ይቆያሉ።',
                    ),
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _CountRow(
              label: context.tr('Products', 'እቃዎች'),
              value: summary.products,
            ),
            _CountRow(
              label: context.tr('Sales', 'ሽያጮች'),
              value: summary.sales,
            ),
            _CountRow(
              label: context.tr('Expenses', 'ወጪዎች'),
              value: summary.expenses,
            ),
            _CountRow(
              label: context.tr('Restock logs', 'የእቃ መሙላት መዝገብ'),
              value: summary.restockLogs,
            ),
            _CountRow(
              label: context.tr('Held orders', 'የተያዙ ትዕዛዞች'),
              value: summary.heldOrders,
            ),
            if (full)
              _CountRow(
                label: context.tr('License records', 'የፈቃድ መዝገቦች'),
                value: summary.licenses,
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              obscureText: _obscured,
              enabled: !_running,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: context.tr(
                  'Account password',
                  'የመግቢያ የይለፍ ቃል',
                ),
                isDense: true,
                prefixIcon: const Icon(Icons.lock_outline, size: 18),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    _obscured ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.alertRed,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _running ? null : () => Navigator.of(context).pop(false),
          child: Text(context.tr('Cancel', 'ሰርዝ')),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.alertRed,
            foregroundColor: Colors.white,
          ),
          onPressed: _running ? null : _submit,
          icon:
              _running
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_forever, size: 16),
          label: Text(
            full
                ? context.tr('Delete all', 'ሁሉንም ሰርዝ')
                : context.tr('Clear records', 'መዝገቦቹን አጽዳ'),
          ),
        ),
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.alertRed,
            ),
          ),
        ],
      ),
    );
  }
}
