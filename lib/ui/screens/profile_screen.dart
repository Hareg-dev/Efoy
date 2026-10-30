import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_theme.dart';
import '../../core/licensing/license_access_state.dart';
import '../../core/security/password_hasher.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/l10n.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/debt_model.dart';
import '../../data/models/user_profile.dart';
import '../../logic/providers/license_provider.dart';
import '../../logic/providers/repository_providers.dart';
import '../widgets/settings_widgets.dart';
import '../widgets/screen_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // A merchant's own record - legal names, licence terms, the support line -
    // reads better in one script, so this screen stays English whatever the
    // rest of the app speaks.
    return Localizations.override(
      context: context,
      locale: const Locale('en'),
      child: const _ProfileScreenBody(),
    );
  }
}

class _ProfileScreenBody extends ConsumerStatefulWidget {
  const _ProfileScreenBody();

  @override
  ConsumerState<_ProfileScreenBody> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<_ProfileScreenBody> {
  bool _savingPhoto = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final accessAsync = ref.watch(licenseAccessProvider);
    final profile = profileAsync.valueOrNull;
    final licenseAccess = accessAsync.valueOrNull;
    final openDebts =
        ref.watch(openDebtsProvider).valueOrNull ?? const <DebtModel>[];
    var outstanding = 0.0;
    for (final debt in openDebts) {
      outstanding += debt.balanceDue;
    }

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
              ScreenHeader(
                title: context.tr('PROFILE', 'መገለጫ'),
                subtitle: context.tr(
                  'Store, security and data settings',
                  'የሱቅ፣ የደህንነት እና የውሂብ ቅንብሮች',
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              _ProfileCard(
                profile: profile,
                onEdit: profile == null
                    ? null
                    : () => _openProfileForm(profile),
                onPhoto: _savingPhoto || profile == null
                    ? null
                    : () => _choosePhoto(profile),
              ),
              const SizedBox(height: AppTheme.spaceM),
              SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsSectionTitle(context.tr('Security', 'ደህንነት')),
                    const SizedBox(height: 10),
                    SettingsActionTile(
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
                    const SizedBox(height: 8),
                    SettingsActionTile(
                      icon: Icons.settings_outlined,
                      title: context.tr('Settings', 'ቅንብሮች'),
                      subtitle: context.tr(
                        'Colours, language, reports and stored data',
                        'ቀለሞች፣ ቋንቋ፣ ወረዳዎችና የተቀመጠ ውሂብ',
                      ),
                      onTap: () => Navigator.of(context).pushNamed('/settings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              _LicenseCard(
                access: licenseAccess,
                isLoading: accessAsync.isLoading,
                installationId: licenseAccess?.installationId,
                onCopyInstallationId: _copyInstallationId,
                onReactivate: _openReactivation,
              ),
              const SizedBox(height: AppTheme.spaceM),
              _DebtsTile(
                outstanding: outstanding,
                openCount: openDebts.length,
                onTap: () => Navigator.of(context).pushNamed('/debts'),
              ),
              const SizedBox(height: AppTheme.spaceM),
              SettingsCard(
                child: SettingsActionTile(
                  icon: Icons.insights_outlined,
                  title: 'Business report',
                  subtitle: 'Profit, trends, costs and restock',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).pushNamed('/reports'),
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              const _SupportCard(),
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
  // Profile photo
  // -------------------------------------------------------------------------

  /// Tap the avatar: choose a new picture, or clear the one already set.
  Future<void> _choosePhoto(UserProfile profile) async {
    final hasPhoto = profile.profilePhotoPath != null;
    final action = hasPhoto
        ? await showModalBottomSheet<_PhotoAction>(
            context: context,
            builder: (sheetContext) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('Choose another photo'),
                    onTap: () =>
                        Navigator.of(sheetContext).pop(_PhotoAction.replace),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Remove photo'),
                    onTap: () =>
                        Navigator.of(sheetContext).pop(_PhotoAction.remove),
                  ),
                ],
              ),
            ),
          )
        : _PhotoAction.replace;
    if (action == null) return;
    if (action == _PhotoAction.remove) {
      await _storePhoto(profile, null);
      return;
    }
    await _pickPhoto(profile);
  }

  Future<void> _pickPhoto(UserProfile profile) async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 720,
        imageQuality: 88,
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack('Camera roll is not available: $error', isError: true);
      return;
    }
    if (picked == null) return;

    setState(() => _savingPhoto = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final target = File(
        '${directory.path}${Platform.pathSeparator}profile_photo'
        '${_suffixOf(picked.path)}',
      );
      await target.writeAsBytes(await picked.readAsBytes());
      await _storePhoto(profile, target.path);
    } catch (error) {
      if (!mounted) return;
      _showSnack('Could not save the photo: $error', isError: true);
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  Future<void> _storePhoto(UserProfile profile, String? path) async {
    final previous = profile.profilePhotoPath;
    try {
      final repository = await ref.read(userRepositoryProvider.future);
      profile.profilePhotoPath = path;
      await repository.saveProfile(profile);
      // Only drop the superseded copy once the new path is safely stored.
      if (previous != null && previous != path) {
        final stale = File(previous);
        if (await stale.exists()) await stale.delete();
      }
      if (!mounted) return;
      ref.invalidate(userProfileProvider);
      _showSnack(path == null ? 'Photo removed' : 'Photo updated');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Could not save the photo: $error', isError: true);
    }
  }

  static String _suffixOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return '.jpg';
    final suffix = path.substring(dot).toLowerCase();
    return suffix.length > 5 ? '.jpg' : suffix;
  }

  // -------------------------------------------------------------------------
  // Profile / payment editing
  // -------------------------------------------------------------------------

  /// Routes live on the app Navigator, above this screen's English scope, so
  /// every dialog re-applies the override or it would answer in Amharic.
  Widget _english(BuildContext dialogContext, Widget child) {
    return Localizations.override(
      context: dialogContext,
      locale: const Locale('en'),
      child: child,
    );
  }

  Future<void> _openProfileForm(UserProfile profile) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          _english(dialogContext, _ProfileFormDialog(profile: profile)),
    );
    if (!mounted || saved != true) return;
    _showSnack(context.tr('Profile updated', 'መገለጫ ተስተካክሏል'));
  }

  Future<void> _openChangePassword(UserProfile profile) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          _english(dialogContext, _ChangePasswordDialog(profile: profile)),
    );
    if (!mounted || changed != true) return;
    _showSnack(context.tr('Password changed', 'የይለፍ ቃል ተቀይሯል'));
  }

  // -------------------------------------------------------------------------
  // License / session
  // -------------------------------------------------------------------------

  void _copyInstallationId() {
    final installationId = ref
        .read(licenseAccessProvider)
        .valueOrNull
        ?.installationId;
    if (installationId == null) return;
    Clipboard.setData(ClipboardData(text: installationId));
    _showSnack(context.tr('Installation ID copied', 'የተጫን መለያ ተኮርጅቷል'));
  }

  Future<void> _openReactivation() async {
    final installationId = ref
        .read(licenseAccessProvider)
        .valueOrNull
        ?.installationId;
    final activated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _english(
        dialogContext,
        _ReactivateDialog(installationId: installationId),
      ),
    );
    if (!mounted || activated != true) return;
    ref.invalidate(licenseAccessProvider);
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

enum _PhotoAction { replace, remove }

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onEdit,
    required this.onPhoto,
  });

  final UserProfile? profile;
  final VoidCallback? onEdit;
  final VoidCallback? onPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final business = profile?.businessName?.trim();
    final owner = profile?.ownerName?.trim();
    final hasBusiness = business != null && business.isNotEmpty;
    final hasOwner = owner != null && owner.isNotEmpty;
    final photoPath = profile?.profilePhotoPath;

    return SettingsCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PhotoAvatar(path: photoPath, isDark: isDark, onTap: onPhoto),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hasBusiness
                            ? business
                            : (hasOwner ? owner : 'Merchant'),
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasBusiness && hasOwner) ...[
                  const SizedBox(height: 4),
                  Text(
                    owner,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.25,
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
                            ? context.tr('Profile unavailable', 'መገለጫ አልተገኘም')
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

/// The merchant's own picture, with a camera badge. Tapping it opens the
/// gallery; the picked file is copied into the app documents folder so a
/// cache clear cannot blank the profile.
class _PhotoAvatar extends StatelessWidget {
  const _PhotoAvatar({
    required this.path,
    required this.isDark,
    required this.onTap,
  });

  final String? path;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final file = path == null ? null : File(path!);
    final hasPhoto = file != null && file.existsSync();

    final tile = Container(
      width: 66,
      height: 66,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark
            ? scheme.primary.withValues(alpha: 0.16)
            : AppColors.tealTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: hasPhoto
          ? Image.file(file, fit: BoxFit.cover)
          : Icon(
              Icons.storefront_outlined,
              size: 30,
              color: isDark ? scheme.primary : AppColors.primaryTeal,
            ),
    );

    return Tooltip(
      message: hasPhoto ? 'Change photo' : 'Add your photo',
      child: InkWell(
        onTap: onTap,
        customBorder: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            tile,
            if (onTap != null)
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.photo_camera_outlined,
                    size: 12,
                    color: Colors.white,
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
// Preferences
// ---------------------------------------------------------------------------

class _LicenseCard extends StatelessWidget {
  const _LicenseCard({
    required this.access,
    required this.isLoading,
    required this.installationId,
    required this.onCopyInstallationId,
    required this.onReactivate,
  });

  final LicenseAccessState? access;
  final bool isLoading;
  final String? installationId;
  final VoidCallback onCopyInstallationId;
  final VoidCallback onReactivate;

  String _planLabel(BuildContext context) {
    final plan = access?.plan;
    switch (plan) {
      case null:
        return context.tr('Free trial', 'ነጻ ሙከራ');
      case 'trial':
        return context.tr('Trial', 'ሙከራ');
      case 'monthly':
        return context.tr('Monthly', 'ወርሃዊ');
      case 'lifetime':
        return context.tr('Lifetime', 'ዘላለማዊ');
      default:
        return plan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = access?.canPerformPaidOperations ?? false;
    final status = access?.status;
    final isTrial = status == LicenseAccessStatus.trial;
    final isExpired =
        status == LicenseAccessStatus.expired ||
        status == LicenseAccessStatus.trialExpired;
    final statusColor = isActive
        ? AppColors.successGreen
        : isExpired
        ? AppColors.alertAmber
        : AppColors.alertRed;
    final statusLabel = isActive
        ? (isTrial ? context.tr('Trial', 'ሙከራ') : context.tr('Active', 'ንቁ'))
        : isExpired
        ? context.tr('Expired', 'ጊዜው አልፎበታል')
        : context.tr('Blocked', 'ታግዷል');

    return SettingsCard(
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
                      access == null
                          ? context.tr(
                              'Loading license status…',
                              'የፈቃድ ሁኔታ በመጫን ላይ…',
                            )
                          : _planLabel(context),
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
          if (access?.clockRollbackSuspected ?? false) ...[
            const SizedBox(height: 10),
            Text(
              context.tr(
                'Device clock appears set backwards. Set the correct date and time to continue.',
                'የመሣሪያ ሰዓቱ ወደኋላ ተቀይሯል ይመስላል። ለመቀጠል ትክክለኛውን ቀንና ሰዓት ያስተካክሉ።',
              ),
              style: TextStyle(fontSize: 10, color: AppColors.alertAmber),
            ),
          ],
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
            value: access == null
                ? '—'
                : access!.isLifetime
                ? context.tr('Never', 'መቸም አይሆንም')
                : (access!.expiresAt == null
                      ? '—'
                      : DateHelper.formatDate(access!.expiresAt!)),
          ),
          const SizedBox(height: 8),
          _LicenseRow(
            label: context.tr('Days remaining', 'ቀሪ ቀናት'),
            value: isActive ? '${access!.daysRemaining}' : '0',
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
                        context.tr('Installation ID', 'የተጫን መለያ'),
                        style: TextStyle(
                          fontSize: 9.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        installationId ?? context.tr('Loading…', 'በመጫን ላይ…'),
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
                  onPressed: installationId == null
                      ? null
                      : onCopyInstallationId,
                  tooltip: context.tr('Copy Installation ID', 'የተጫን መለያ ኮፒ'),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy, size: 16),
                ),
              ],
            ),
          ),
          if (!isActive) ...[
            const SizedBox(height: 12),
            Text(
              context.tr(
                'To renew: send your Installation ID and pay to Telebirr '
                    '${AppStrings.supportPhone}. The activation key comes back '
                    'from the same number. Your data stays available for viewing '
                    'and export.',
                'ለማደስ፦ የተጫን መለያዎን ይላኩና በቴሌብር '
                    '${AppStrings.supportPhone} ይክፈሉ። የማንቂያ ኮዱ ከዚያው ቁጥር '
                    'ይመለስልዎታል። መረጃዎ ለመመልከትና ለማውጣት መኖሩን ይቀጥላል።',
              ),
              style: TextStyle(
                fontSize: 10.5,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
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
                  access?.hasLicense ?? false
                      ? context.tr('Renew license', 'ፈቃድ አድስ')
                      : context.tr('Activate license', 'ፈቃድ አንቃ'),
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
            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
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
// Receivables
// ---------------------------------------------------------------------------

/// How much of today's selling is still sitting in customers' hands.
///
/// The number is deliberately on the profile as well as on the sell screen: a
/// balance that only ever shows at the counter is one nobody chases.
class _DebtsTile extends StatelessWidget {
  const _DebtsTile({
    required this.outstanding,
    required this.openCount,
    required this.onTap,
  });

  final double outstanding;
  final int openCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDebts = openCount > 0;
    return SettingsCard(
      child: SettingsActionTile(
        icon: Icons.handshake_outlined,
        title: 'Who owes me',
        subtitle: hasDebts
            ? '$openCount customer${openCount == 1 ? '' : 's'} · take a payment'
            : 'No open balances yet',
        trailing: hasDebts
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.alertAmber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  CurrencyFormatter.formatBirrWhole(outstanding),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.alertAmber,
                  ),
                ),
              )
            : const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Support
// ---------------------------------------------------------------------------

/// Always visible, whatever the licence state: a trial that is still running
/// needs the same line for a question or a renewal, and hiding it until
/// something expires left merchants hunting for a number on their own.
class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionTitle('Customer support'),
          const SizedBox(height: 6),
          Text(
            'Reach the Efoy team on Telegram at '
            '${AppStrings.supportTelegram} or call either number below. '
            '${AppStrings.supportPhone} is also the Telebirr account for a '
            'licence: copy the Installation ID above, pay it, and the '
            'activation key comes straight back. Nothing you already '
            'recorded is deleted while a licence is expired.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _SupportRow(
            icon: Icons.send_outlined,
            label: 'Telegram',
            value: AppStrings.supportTelegram,
          ),
          const SizedBox(height: 8),
          _SupportRow(
            icon: Icons.phone_outlined,
            label: 'Call or SMS',
            value: AppStrings.supportPhone,
          ),
          const SizedBox(height: 8),
          _SupportRow(
            icon: Icons.phone_outlined,
            label: 'Call or SMS',
            value: AppStrings.supportPhoneAlt,
          ),
          const SizedBox(height: 8),
          _SupportRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Telebirr account',
            value: '${AppStrings.supportPhone} · ${AppStrings.supportTeam}',
          ),
        ],
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow({
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
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: scheme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Copied for support')));
          },
          tooltip: 'Copy',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.copy, size: 15),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profile form
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
    _businessName = TextEditingController(
      text: widget.profile.businessName ?? '',
    );
    _businessNameAm = TextEditingController(
      text: widget.profile.businessNameAm ?? '',
    );
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
        _error = context.tr('Business name is required.', 'የንግድ ስም ያስፈልጋል።');
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
                  context.tr('Owner full name', 'የባለቤት ሙሉ ስም'),
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
      error = context.tr('Use at least 6 characters.', 'ቢያንስ 6 ፊደሎችን ይጠቀሙ።');
    } else if (!RegExp(r'[A-Za-z]').hasMatch(next) ||
        !RegExp(r'[0-9]').hasMatch(next)) {
      error = context.tr(
        'Include at least one letter and one number.',
        'ቢያንስ አንድ ፊደል እና አንድ ቁጥር ያካትቱ።',
      );
    } else if (next == current) {
      error = context.tr('Choose a different password.', 'የተለየ የይለፍ ቃል ይምረጡ።');
    } else if (next != confirm) {
      error = context.tr('Passwords do not match.', 'የይለፍ ቃሎቹ አይመሳሰሉም።');
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
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
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
// Reactivate license dialog
// ---------------------------------------------------------------------------

class _ReactivateDialog extends ConsumerStatefulWidget {
  const _ReactivateDialog({required this.installationId});

  final String? installationId;

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
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() {
        _error = context.tr('Enter an activation code.', 'የማንቂያ ኮድ ያስገቡ።');
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final service = await ref.read(licenseServiceProvider.future);
      final result = await service.activate(code);
      if (!mounted) return;

      if (!result.success) {
        setState(() {
          _saving = false;
          _error = result.storageFailure
              ? context.tr(
                  'Secure storage is unavailable on this device.',
                  'የደህንነት ማከማቻ በዚህ መሣሪያ አይገኝም።',
                )
              : context.tr(
                  'This code was rejected. Make sure it was issued for this '
                      'installation and has not expired.',
                  'ይህ ኮድ አልተቀበለም። ለዚህ ተጫን መለያ እንደተሰጠና ጊዜው እንዳልአለፈ ያረጋግጡ።',
                );
        });
        return;
      }

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
        context.tr('Renew or activate license', 'ፈቃድ አድስ ወይም አንቃ'),
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
                  'Send Installation ID '
                      '${widget.installationId ?? '—'} by call or SMS to '
                      '${AppStrings.supportPhone} (${AppStrings.supportTeam}), '
                      'pay with Telebirr to that number, then enter the '
                      'activation key you get back.',
                  'የተጫን መለያ '
                      '${widget.installationId ?? '—'} በስልክ ወይም SMS ለ'
                      '${AppStrings.supportPhone} (${AppStrings.supportTeam}) '
                      'ይላኩ፣ በዚያ ቁጥር በቴሌብር ይክፈሉ፣ ከዚያ የተሰጠዎትን የማንቂያ ኮድ '
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
                  labelText: context.tr('Activation code', 'የማንቂያ ኮድ'),
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
    profilePhotoPath: source.profilePhotoPath,
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
