import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/security/device_identity.dart';
import '../../core/security/license_verifier.dart';
import '../../core/security/password_hasher.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/l10n.dart';
import '../../data/local/app_database.dart';
import '../../data/models/license_model.dart';
import '../../data/models/user_profile.dart';
import '../../logic/providers/repository_providers.dart';
import '../../logic/providers/theme_provider.dart';

const _backupKeys = {
  'products',
  'sales',
  'expenses',
  'restockLogs',
  'licenses',
  'userProfiles',
  'heldOrders',
};

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const _prefs = FlutterSecureStorage();
  static const _lastBackupKey = 'efoy_last_backup_at';

  String? _deviceId;
  DateTime? _lastBackupAt;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadLocalState();
  }

  Future<void> _loadLocalState() async {
    String? deviceId;
    try {
      deviceId = await DeviceIdentity.getDeviceId();
    } catch (_) {
      // Device identity is unavailable on unsupported platforms.
    }
    DateTime? lastBackup;
    try {
      final raw = await _prefs.read(key: _lastBackupKey);
      lastBackup = raw == null ? null : DateTime.tryParse(raw);
    } catch (_) {
      // Ignore preference read failures.
    }
    if (!mounted) return;
    setState(() {
      _deviceId = deviceId;
      _lastBackupAt = lastBackup;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final profileAsync = ref.watch(userProfileProvider);
    final licenseAsync = ref.watch(latestLicenseProvider);
    final profile = profileAsync.valueOrNull;
    final license = licenseAsync.valueOrNull;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceM,
            AppTheme.spaceM,
            AppTheme.spaceM,
            AppTheme.spaceXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('PROFILE', 'መገለጫ'),
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
                  'Store, security and data settings',
                  'የሱቅ፣ የደህንነት እና የውሂብ ቅንብሮች',
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              _ProfileCard(
                profile: profile,
                onEdit:
                    profile == null ? null : () => _openProfileForm(profile),
              ),
              const SizedBox(height: AppTheme.spaceM),
              _PaymentCard(
                profile: profile,
                onEdit:
                    profile == null ? null : () => _openPaymentForm(profile),
              ),
              const SizedBox(height: AppTheme.spaceM),
              _PreferencesCard(
                themeMode: themeMode,
                locale: locale,
                onThemeChanged: (mode) =>
                    ref.read(themeModeProvider.notifier).setThemeMode(mode),
                onLanguageChanged: (code) =>
                    ref.read(localeProvider.notifier).setLanguage(code),
              ),
              const SizedBox(height: AppTheme.spaceM),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(context.tr('Security', 'ደህንነት')),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.lock_outline,
                      title: context.tr('Change password', 'የይለፍ ቃል ቀይር'),
                      subtitle: context.tr(
                        'Update the password used to sign in',
                        'ለመግቢያ የሚያገለግለውን የይለፍ ቃል ያድሱ',
                      ),
                      onTap: profile == null
                          ? null
                          : () => _openChangePassword(profile),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      context.tr('Data management', 'የውሂብ አስተዳደር'),
                    ),
                    const SizedBox(height: 10),
                    _ActionTile(
                      icon: Icons.cloud_download_outlined,
                      title: context.tr('Back up data', 'ውሂብ ያስቀምጡ'),
                      subtitle: _lastBackupAt == null
                          ? context.tr('Never backed up', 'አልተቀመጠም')
                          : context.tr(
                              'Last backup '
                              '${DateHelper.formatDateTime(_lastBackupAt!)}',
                              'የመጨረሻ ማስቀመጫ '
                              '${DateHelper.formatDateTime(_lastBackupAt!)}',
                            ),
                      trailing: _exporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.file_download_outlined, size: 20),
                      onTap: _exporting ? null : _exportData,
                    ),
                    const SizedBox(height: 8),
                    _ActionTile(
                      icon: Icons.restore_outlined,
                      title: context.tr('Restore data', 'ውሂብ መልስ'),
                      subtitle: context.tr(
                        'Restore from an exported JSON backup',
                        'ከተላከ JSON ምትኬ ወደነበረበት ይመልሱ',
                      ),
                      trailing: const Icon(Icons.upload_file_outlined, size: 20),
                      onTap: _restoreData,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              _LicenseCard(
                license: license,
                isLoading: licenseAsync.isLoading,
                deviceId: _deviceId,
                onCopyDeviceId: _copyDeviceId,
                onReactivate: _openReactivation,
              ),
              const SizedBox(height: AppTheme.spaceL),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _signOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.alertRed,
                    side: BorderSide(
                      color: AppColors.alertRed.withValues(alpha: 0.45),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text(
                    context.tr('Sign out', 'ውጣ'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Profile / payment editing
  // -------------------------------------------------------------------------

  Future<void> _openProfileForm(UserProfile profile) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ProfileFormDialog(profile: profile),
    );
    if (!mounted || saved != true) return;
    _showSnack(context.tr('Profile updated', 'መገለጫ ተስተካክሏል'));
  }

  Future<void> _openPaymentForm(UserProfile profile) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _PaymentFormDialog(profile: profile),
    );
    if (!mounted || saved != true) return;
    _showSnack(context.tr('Payment details updated', 'የክፍያ ዝርዝር ተስተካክሏል'));
  }

  Future<void> _openChangePassword(UserProfile profile) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _ChangePasswordDialog(profile: profile),
    );
    if (!mounted || changed != true) return;
    _showSnack(context.tr('Password changed', 'የይለፍ ቃል ተቀይሯል'));
  }

  // -------------------------------------------------------------------------
  // Backup / restore
  // -------------------------------------------------------------------------

  Future<void> _exportData() async {
    setState(() => _exporting = true);
    try {
      final database = AppDatabase();
      await database.init();
      final data = await database.exportToJson();
      final json = const JsonEncoder.withIndent('  ').convert(data);

      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final stamp = '${now.year}${_two(now.month)}${_two(now.day)}_'
          '${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
      final file = File(
        '${directory.path}${Platform.pathSeparator}efoy_backup_$stamp.json',
      );
      await file.writeAsString(json);

      await _prefs.write(key: _lastBackupKey, value: now.toIso8601String());
      if (!mounted) return;
      setState(() {
        _exporting = false;
        _lastBackupAt = now;
      });

      final copy = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.tr('Backup created', 'ምትኬ ተፈጥሯል')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  'Saved to your app documents folder:',
                  'ወደ መተግበሪያው ሰነዶች አቃፊ ተቀምጧል፦',
                ),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              SelectableText(
                file.path,
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr(
                  'Copy the JSON to move the backup somewhere safe.',
                  'ምትኬውን ደህንነቱ በተጠበቀ ቦታ ለማስቀመጥ JSON ኮፒ ያድርጉ።',
                ),
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.tr('Done', 'ጨርስ')),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.copy, size: 16),
              label: Text(context.tr('Copy JSON', 'JSON ኮፒ')),
            ),
          ],
        ),
      );

      if (copy == true && mounted) {
        await Clipboard.setData(ClipboardData(text: json));
        if (!mounted) return;
        _showSnack(
          context.tr('Backup copied to clipboard', 'ምትኬ ተኮርጅቷል'),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _exporting = false);
      _showSnack(error.toString(), isError: true);
    }
  }

  Future<void> _restoreData() async {
    final raw = await showDialog<String>(
      context: context,
      builder: (_) => const _RestoreDialog(),
    );
    if (!mounted || raw == null) return;

    final data = _tryParseBackup(raw);
    if (data == null) {
      _showSnack(
        context.tr(
          'That does not look like a valid Efoy backup.',
          'ይህ ትክክለኛ የኢፎይ ምትኬ አይመስልም።',
        ),
        isError: true,
      );
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

    try {
      final database = AppDatabase();
      await database.init();
      await database.importFromJson(data);
      ref.invalidate(activeLicenseProvider);
      ref.invalidate(latestLicenseProvider);
      if (!mounted) return;
      _showSnack(context.tr('Backup restored', 'ምትኬ ተመልሷል'));
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString(), isError: true);
    }
  }

  // -------------------------------------------------------------------------
  // License / session
  // -------------------------------------------------------------------------

  void _copyDeviceId() {
    final deviceId = _deviceId;
    if (deviceId == null) return;
    Clipboard.setData(ClipboardData(text: deviceId));
    _showSnack(context.tr('Device ID copied', 'የመሳሪያ መለያ ተኮርጅቷል'));
  }

  Future<void> _openReactivation() async {
    final activated = await showDialog<bool>(
      context: context,
      builder: (_) => _ReactivateDialog(deviceId: _deviceId),
    );
    if (!mounted || activated != true) return;
    ref.invalidate(activeLicenseProvider);
    ref.invalidate(latestLicenseProvider);
    _showSnack(context.tr('License activated', 'ፈቃድ ነቅቷል'));
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Sign out?', 'ውጣ?')),
        content: Text(
          context.tr(
            'You will need your password to sign back in.',
            'እንደገና ለመግባት የይለፍ ቃልዎ ያስፈልጋል።',
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
            child: Text(context.tr('Sign out', 'ውጣ')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.alertRed : AppColors.primaryTeal,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile card
// ---------------------------------------------------------------------------

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile, required this.onEdit});

  final UserProfile? profile;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final name = profile?.businessName?.trim();
    final owner = profile?.ownerName?.trim();

    return _SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: isDark
                  ? scheme.primary.withValues(alpha: 0.16)
                  : AppColors.tealTint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.storefront_outlined,
              size: 30,
              color: isDark ? scheme.primary : AppColors.primaryTeal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name == null || name.isEmpty
                            ? context.tr('Merchant', 'ነጋዴ')
                            : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ModeBadge(isDemo: profile?.isDemoMode ?? true),
                  ],
                ),
                if (owner != null && owner.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    owner,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        profile == null
                            ? context.tr(
                                'Profile unavailable',
                                'መገለጫ አልተገኘም',
                              )
                            : context.tr(
                                'Member since '
                                '${DateHelper.formatDate(profile!.createdAt)}',
                                'ከ${DateHelper.formatDate(profile!.createdAt)} '
                                    'ጀምሮ',
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              tooltip: context.tr('Edit profile', 'መገለጫ አስተካክል'),
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
        ],
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.isDemo});

  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final color = isDemo ? AppColors.alertAmber : AppColors.successGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isDemo ? 'Demo' : context.tr('Production', 'ምርት'),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payment card
// ---------------------------------------------------------------------------

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.profile, required this.onEdit});

  final UserProfile? profile;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phone = profile?.phoneNumber;
    final telebirr = profile?.telebirrAccount;
    final bank = profile?.bankAccount;
    final bankName = profile?.bankName;
    final hasAny =
        [phone, telebirr, bank].any((value) => value != null && value.isNotEmpty);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionTitle(
                  context.tr('Payment details', 'የክፍያ ዝርዝር'),
                ),
              ),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  child: Text(
                    hasAny
                        ? context.tr('Edit', 'አስተካክል')
                        : context.tr('Add', 'ጨምር'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (!hasAny)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr(
                        'No payment information yet. Add your phone, Telebirr '
                        'or bank account.',
                        'እስካሁን የክፍያ መረጃ የለም። ስልክ፣ ቴሌብር ወይም የባንክ ሂሳብ ያክሉ።',
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _PaymentRow(
              icon: Icons.phone_outlined,
              label: context.tr('Phone', 'ስልክ'),
              value: _displayValue(context, phone),
            ),
            const SizedBox(height: 10),
            _PaymentRow(
              icon: Icons.wallet_outlined,
              label: 'Telebirr',
              value: _displayValue(context, telebirr),
            ),
            const SizedBox(height: 10),
            _PaymentRow(
              icon: Icons.account_balance_outlined,
              label: context.tr('Bank', 'ባንክ'),
              value: bank == null || bank.isEmpty
                  ? context.tr('Not set', 'አልተዘጋጀም')
                  : bankName == null || bankName.isEmpty
                      ? bank
                      : '$bankName · $bank',
            ),
          ],
        ],
      ),
    );
  }

  String _displayValue(BuildContext context, String? value) {
    if (value == null || value.isEmpty) {
      return context.tr('Not set', 'አልተዘጋጀም');
    }
    return value;
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: scheme.primary),
        ),
        const SizedBox(width: 10),
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
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Preferences
// ---------------------------------------------------------------------------

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.themeMode,
    required this.locale,
    required this.onThemeChanged,
    required this.onLanguageChanged,
  });

  final ThemeMode themeMode;
  final Locale locale;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(context.tr('Appearance', 'አቀራረብ')),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ChoiceTile(
                  icon: Icons.light_mode_outlined,
                  label: context.tr('Light', 'ብርሃን'),
                  selected: themeMode == ThemeMode.light,
                  onTap: () => onThemeChanged(ThemeMode.light),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChoiceTile(
                  icon: Icons.dark_mode_outlined,
                  label: context.tr('Dark', 'ጨለማ'),
                  selected: themeMode == ThemeMode.dark,
                  onTap: () => onThemeChanged(ThemeMode.dark),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChoiceTile(
                  icon: Icons.brightness_auto_outlined,
                  label: context.tr('System', 'ስርዓት'),
                  selected: themeMode == ThemeMode.system,
                  onTap: () => onThemeChanged(ThemeMode.system),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionTitle(context.tr('Language', 'ቋንቋ')),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ChoiceTile(
                  icon: Icons.translate,
                  label: 'English',
                  selected: locale.languageCode == 'en',
                  onTap: () => onLanguageChanged('en'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ChoiceTile(
                  icon: Icons.translate,
                  label: 'አማርኛ',
                  selected: locale.languageCode == 'am',
                  onTap: () => onLanguageChanged('am'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.10)
              : scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.55)
                : scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(
              selected ? Icons.check_circle : icon,
              size: 19,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? scheme.primary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// License card
// ---------------------------------------------------------------------------

class _LicenseCard extends StatelessWidget {
  const _LicenseCard({
    required this.license,
    required this.isLoading,
    required this.deviceId,
    required this.onCopyDeviceId,
    required this.onReactivate,
  });

  final LicenseModel? license;
  final bool isLoading;
  final String? deviceId;
  final VoidCallback onCopyDeviceId;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final isActive = license?.isValid ?? false;
    final isExpired = license != null &&
        (license!.isExpired || !now.isBefore(license!.expiresAt));
    final statusColor = isActive
        ? AppColors.successGreen
        : isExpired
            ? AppColors.alertAmber
            : AppColors.alertRed;
    final statusLabel = isActive
        ? context.tr('Active', 'ንቁ')
        : isExpired
            ? context.tr('Expired', 'ጊዜው አልፎበታል')
            : context.tr('Invalid', 'ልክ ያልሆነ');

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  size: 21,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('License', 'ፈቃድ'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      license == null
                          ? context.tr(
                              'No license on this device',
                              'በዚህ መሳሪያ ፈቃድ የለም',
                            )
                          : '${license!.licenseType.displayName} · '
                              '${context.tr('activated', 'ተነቅቷል')} '
                              '${DateHelper.formatDate(license!.activatedAt)}',
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          _LicenseRow(
            label: context.tr('Expiry date', 'የማብቂያ ቀን'),
            value: license == null
                ? '—'
                : DateHelper.formatDate(license!.expiresAt),
          ),
          const SizedBox(height: 8),
          _LicenseRow(
            label: context.tr('Days remaining', 'ቀሪ ቀናት'),
            value: isActive ? '${license!.daysRemaining}' : '0',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Device ID', 'የመሳሪያ መለያ'),
                        style: TextStyle(
                          fontSize: 9.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        deviceId ?? context.tr('Loading…', 'በመጫን ላይ…'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: deviceId == null ? null : onCopyDeviceId,
                  tooltip: context.tr('Copy device ID', 'መለያ ኮፒ'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy, size: 16),
                ),
              ],
            ),
          ),
          if (!isActive) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onReactivate,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                ),
                icon: const Icon(Icons.key_outlined, size: 18),
                label: Text(
                  context.tr('Reactivate license', 'ፈቃድ እንደገና አንቃ'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LicenseRow extends StatelessWidget {
  const _LicenseRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared section widgets
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.25 : 0.5),
        ),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: scheme.primary),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
            const SizedBox(width: 8),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit profile dialog
// ---------------------------------------------------------------------------

class _ProfileFormDialog extends ConsumerStatefulWidget {
  const _ProfileFormDialog({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_ProfileFormDialog> createState() => _ProfileFormDialogState();
}

class _ProfileFormDialogState extends ConsumerState<_ProfileFormDialog> {
  late final TextEditingController _businessName;
  late final TextEditingController _businessNameAm;
  late final TextEditingController _ownerName;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _businessName =
        TextEditingController(text: widget.profile.businessName ?? '');
    _businessNameAm =
        TextEditingController(text: widget.profile.businessNameAm ?? '');
    _ownerName = TextEditingController(text: widget.profile.ownerName ?? '');
  }

  @override
  void dispose() {
    _businessName.dispose();
    _businessNameAm.dispose();
    _ownerName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _businessName.text.trim();
    if (name.isEmpty) {
      setState(() {
        _error = context.tr(
          'Business name is required.',
          'የንግድ ስም ያስፈልጋል።',
        );
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repository = await ref.read(userRepositoryProvider.future);
      final updated = _copyProfile(widget.profile)
        ..businessName = name
        ..businessNameAm = _blankToNull(_businessNameAm.text)
        ..ownerName = _blankToNull(_ownerName.text);
      await repository.saveProfile(updated);
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    InputDecoration decoration(String label) {
      return InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : Colors.white,
      );
    }

    return AlertDialog(
      title: Text(
        context.tr('Edit profile', 'መገለጫ አስተካክል'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _businessName,
                autofocus: true,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: decoration(
                  context.tr('Business name *', 'የንግድ ስም *'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _businessNameAm,
                decoration: decoration(
                  context.tr('Business name (Amharic)', 'የንግድ ስም (አማርኛ)'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ownerName,
                decoration: decoration(
                  context.tr('Owner name', 'የባለቤት ስም'),
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
              : Text(context.tr('Save', 'አስቀምጥ')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Edit payment dialog
// ---------------------------------------------------------------------------

class _PaymentFormDialog extends ConsumerStatefulWidget {
  const _PaymentFormDialog({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends ConsumerState<_PaymentFormDialog> {
  late final TextEditingController _phone;
  late final TextEditingController _telebirr;
  late final TextEditingController _bankName;
  late final TextEditingController _bankAccount;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.profile.phoneNumber ?? '');
    _telebirr =
        TextEditingController(text: widget.profile.telebirrAccount ?? '');
    _bankName = TextEditingController(text: widget.profile.bankName ?? '');
    _bankAccount =
        TextEditingController(text: widget.profile.bankAccount ?? '');
  }

  @override
  void dispose() {
    _phone.dispose();
    _telebirr.dispose();
    _bankName.dispose();
    _bankAccount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final phone = _phone.text.trim();
    final telebirr = _telebirr.text.trim();
    final bankName = _bankName.text.trim();
    final bankAccount = _bankAccount.text.trim();

    String? error;
    if (!widget.profile.isDemoMode) {
      if (phone.isEmpty) {
        error = context.tr(
          'Phone number is required in production mode.',
          'በምርት ሁነታ የስልክ ቁጥር ያስፈልጋል።',
        );
      } else if (telebirr.isEmpty && bankAccount.isEmpty) {
        error = context.tr(
          'Add a Telebirr or bank account.',
          'ቴሌብር ወይም የባንክ ሂሳብ ያክሉ።',
        );
      } else if (bankAccount.isNotEmpty && bankName.isEmpty) {
        error = context.tr(
          'Bank name is required when a bank account is set.',
          'የባንክ ሂሳብ ሲኖር የባንክ ስም ያስፈልጋል።',
        );
      }
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
      final repository = await ref.read(userRepositoryProvider.future);
      final updated = _copyProfile(widget.profile)
        ..phoneNumber = _blankToNull(phone)
        ..telebirrAccount = _blankToNull(telebirr)
        ..bankName = _blankToNull(bankName)
        ..bankAccount = _blankToNull(bankAccount);
      await repository.saveProfile(updated);
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    InputDecoration decoration(String label) {
      return InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : Colors.white,
      );
    }

    return AlertDialog(
      title: Text(
        context.tr('Payment details', 'የክፍያ ዝርዝር'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: decoration(
                  context.tr('Phone number', 'የስልክ ቁጥር'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _telebirr,
                keyboardType: TextInputType.phone,
                decoration: decoration('Telebirr'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bankName,
                decoration: decoration(context.tr('Bank name', 'የባንክ ስም')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bankAccount,
                keyboardType: TextInputType.number,
                decoration: decoration(
                  context.tr('Bank account number', 'የባንክ ሂሳብ ቁጥር'),
                ),
              ),
              if (widget.profile.isDemoMode) ...[
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    'Demo mode: payment fields are optional.',
                    'የሙከራ ሁነታ፦ የክፍያ መስኮች አማራጭ ናቸው።',
                  ),
                  style: TextStyle(
                    fontSize: 10,
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
              : Text(context.tr('Save', 'አስቀምጥ')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Change password dialog
// ---------------------------------------------------------------------------

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = _currentController.text;
    final next = _newController.text;
    final confirm = _confirmController.text;

    String? error;
    if (!PasswordHasher.verify(current, widget.profile.passwordHash)) {
      error = context.tr(
        'Current password is incorrect.',
        'የአሁኑ የይለፍ ቃል ትክክል አይደለም።',
      );
    } else if (next.length < 6) {
      error = context.tr(
        'Use at least 6 characters.',
        'ቢያንስ 6 ፊደሎችን ይጠቀሙ።',
      );
    } else if (!RegExp(r'[A-Za-z]').hasMatch(next) ||
        !RegExp(r'[0-9]').hasMatch(next)) {
      error = context.tr(
        'Include at least one letter and one number.',
        'ቢያንስ አንድ ፊደል እና አንድ ቁጥር ያካትቱ።',
      );
    } else if (next == current) {
      error = context.tr(
        'Choose a different password.',
        'የተለየ የይለፍ ቃል ይምረጡ።',
      );
    } else if (next != confirm) {
      error = context.tr(
        'Passwords do not match.',
        'የይለፍ ቃሎቹ አይመሳሰሉም።',
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
      final repository = await ref.read(userRepositoryProvider.future);
      final updated = _copyProfile(widget.profile)
        ..passwordHash = PasswordHasher.hash(next);
      await repository.saveProfile(updated);
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    InputDecoration decoration(String label) {
      return InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : Colors.white,
        prefixIcon: const Icon(Icons.lock_outline, size: 18),
      );
    }

    return AlertDialog(
      title: Text(
        context.tr('Change password', 'የይለፍ ቃል ቀይር'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _currentController,
                obscureText: true,
                autofocus: true,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: decoration(
                  context.tr('Current password', 'የአሁኑ የይለፍ ቃል'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _newController,
                obscureText: true,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: decoration(
                  context.tr('New password', 'አዲስ የይለፍ ቃል'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmController,
                obscureText: true,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: decoration(
                  context.tr('Confirm new password', 'አዲሱን የይለፍ ቃል ያረጋግጡ'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(
                  'Minimum 6 characters with at least one letter and number.',
                  'ቢያንስ 6 ፊደሎች ከአንድ ፊደል እና ቁጥር ጋር።',
                ),
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurfaceVariant,
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
              : Text(context.tr('Update password', 'የይለፍ ቃል አዘምን')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Restore dialog
// ---------------------------------------------------------------------------

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
    if (_tryParseBackup(raw) == null) {
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

// ---------------------------------------------------------------------------
// Reactivate license dialog
// ---------------------------------------------------------------------------

class _ReactivateDialog extends ConsumerStatefulWidget {
  const _ReactivateDialog({required this.deviceId});

  final String? deviceId;

  @override
  ConsumerState<_ReactivateDialog> createState() => _ReactivateDialogState();
}

class _ReactivateDialogState extends ConsumerState<_ReactivateDialog> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      setState(() {
        _error = context.tr('Enter a license key.', 'የፈቃድ ቁልፍ ያስገቡ።');
      });
      return;
    }
    final deviceId = widget.deviceId;
    if (deviceId == null) {
      setState(() {
        _error = context.tr(
          'Device ID is unavailable.',
          'የመሳሪያ መለያ አልተገኘም።',
        );
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final result = LicenseVerifier.verifyLicense(
        licenseKey: key,
        deviceId: deviceId,
      );
      if (!result.isValid ||
          result.expiryDate == null ||
          result.licenseType == null) {
        setState(() {
          _saving = false;
          _error = result.errorMessage ?? 'License verification failed';
        });
        return;
      }

      final repository = await ref.read(userRepositoryProvider.future);
      await repository.activateLicense(
        LicenseModel(
          deviceId: result.deviceId ?? deviceId,
          licenseKey: key,
          activatedAt: DateTime.now(),
          expiresAt: result.expiryDate!,
          licenseType: result.licenseType!,
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Text(
        context.tr('Reactivate license', 'ፈቃድ እንደገና አንቃ'),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  'Enter the license key issued for device '
                  '${widget.deviceId ?? '—'}.',
                  'ለመሳሪያ ${widget.deviceId ?? '—'} የተሰጠውን የፈቃድ ቁልፍ '
                  'ያስገቡ።',
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
                minLines: 1,
                maxLines: 3,
                autofocus: true,
                style: const TextStyle(fontSize: 12),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  labelText: context.tr('License key', 'የፈቃድ ቁልፍ'),
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
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: Text(context.tr('Cancel', 'ሰርዝ')),
        ),
        FilledButton(
          onPressed: _saving ? null : _activate,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('Activate', 'አንቃ')),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

UserProfile _copyProfile(UserProfile source) {
  final copy = UserProfile(
    passwordHash: source.passwordHash,
    lastLogin: source.lastLogin,
    businessName: source.businessName,
    businessNameAm: source.businessNameAm,
    ownerName: source.ownerName,
    phoneNumber: source.phoneNumber,
    telebirrAccount: source.telebirrAccount,
    bankAccount: source.bankAccount,
    bankName: source.bankName,
    isDemoMode: source.isDemoMode,
    isDarkMode: source.isDarkMode,
    language: source.language,
  )..id = source.id;
  copy
    ..createdAt = source.createdAt
    ..updatedAt = source.updatedAt;
  return copy;
}

String? _blankToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _two(int value) => value.toString().padLeft(2, '0');

Map<String, List<Map<String, dynamic>>>? _tryParseBackup(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    final data = <String, List<Map<String, dynamic>>>{};
    for (final entry in decoded.entries) {
      final key = entry.key.toString();
      if (!_backupKeys.contains(key)) continue;
      final value = entry.value;
      if (value is! List) return null;
      final items = <Map<String, dynamic>>[];
      for (final item in value) {
        if (item is! Map) return null;
        items.add(Map<String, dynamic>.from(item));
      }
      data[key] = items;
    }
    return data.isEmpty ? null : data;
  } catch (_) {
    return null;
  }
}
