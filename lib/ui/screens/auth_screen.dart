import 'package:flutter/material.dart';
import 'package:efoy_licensing/efoy_licensing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_theme.dart';
import '../../core/licensing/installation_identity.dart';
import '../../core/licensing/license_service.dart';
import '../../core/security/password_hasher.dart';
import '../../core/utils/l10n.dart';
import '../../data/local/app_database.dart';
import '../../data/repositories/user_repository.dart';
import '../../logic/providers/license_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _passwordController = TextEditingController();
  final _licenseKeyController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _installationId;
  InstallationDeviceInfo? _deviceInfo;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInstallationInfo();
  }

  Future<void> _loadInstallationInfo() async {
    final info = await InstallationIdentity.getDeviceInfo();
    String? installationId;
    try {
      final service = await ref.read(licenseServiceProvider.future);
      final access = await service.currentAccess();
      installationId = access.installationId;
    } catch (_) {
      // Database unavailable (e.g. web); activation cannot proceed but the
      // rest of the screen still renders.
    }

    if (!mounted) return;
    setState(() {
      _deviceInfo = info;
      _installationId = installationId;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordController.dispose();
    _licenseKeyController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLicenseActivation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final activationCode = _licenseKeyController.text.trim();

    if (activationCode.isEmpty) {
      setState(() {
        _errorMessage = context.tr(
          'Please enter an activation code',
          'እባክዎ የማንቂያ ኮድ ያስገቡ',
        );
        _isLoading = false;
      });
      return;
    }

    if (_installationId == null) {
      setState(() {
        _errorMessage = context.tr(
          'Installation ID not available yet. Please wait a moment.',
          'የተጫን መለያ አልተገኘም። እባክዎ ትንሽ ይጠብቁ።',
        );
        _isLoading = false;
      });
      return;
    }

    try {
      final service = await ref.read(licenseServiceProvider.future);
      final result = await service.activate(activationCode);

      if (!mounted) return;

      if (!result.success) {
        setState(() {
          _isLoading = false;
          _errorMessage = _activationError(result);
          _successMessage = null;
        });
        return;
      }

      ref.invalidate(licenseAccessProvider);
      setState(() {
        _isLoading = false;
        _successMessage = context.tr(
          'License activated successfully!',
          'ፈቃዱ በተሳካ ሁኔታ ተስካለ!',
        );
        _errorMessage = null;
        _showOnboarding = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = context.tr(
          'License is valid but could not be saved. Please try again.',
          'ፈቃዱ ትክክል ነው ግን ማስቀመጥ አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
        );
        _successMessage = null;
      });
    }
  }

  /// Continue into the app on the free evaluation window. No license is
  /// activated; the trial is enforced by the licensing service.
  Future<void> _startTrial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final service = await ref.read(licenseServiceProvider.future);
      final access = await service.currentAccess();
      if (!mounted) return;
      if (access.canPerformPaidOperations) {
        setState(() {
          _isLoading = false;
          _showOnboarding = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = context.tr(
            'The trial period on this device has already ended. Please activate a license.',
            'በዚህ መሣሪያ የሙከራ ጊዜው አልፎበታል። እባክዎ ፈቃድ ያንቁ።',
          );
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = context.tr(
          'Could not start the trial. Please try again.',
          'ሙከራውን መጀመር አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
        );
      });
    }
  }

  String _activationError(ActivationResult result) {
    if (result.storageFailure) {
      return context.tr(
        'Secure storage is unavailable on this device. License state cannot be saved.',
        'የደህንነት ማከማቻ በዚህ መሣሪያ አይገኝም። የፈቃድ ሁኔታ ማስቀመጥ አይቻልም።',
      );
    }
    switch (result.rejection) {
      case LicenseRejectionReason.malformedCode:
        return context.tr(
          'This activation code is malformed. Check for missing characters.',
          'የማንቂያ ኮዱ አይገባም። የጎደሉ ፊደላት መኖራቸውን ይመልከቱ።',
        );
      case LicenseRejectionReason.unsupportedVersion:
        return context.tr(
          'This code was issued for a newer app version. Please update the app.',
          'ይህ ኮድ ለአዲስ የመተግበሪያ ቅጭ ተሰጥቷል። እባክዎ መተግበሪያውን ያዘምኑ።',
        );
      case LicenseRejectionReason.unsupportedPlan:
        return context.tr(
          'This license plan is not supported by this app.',
          'ይህ የፈቃድ ዓይነት በዚህ መተግበሪያ አይደገፍም።',
        );
      case LicenseRejectionReason.invalidPayload:
        return context.tr(
          'This activation code contains invalid license data.',
          'የማንቂያ ኮዱ የተሳሳተ የፈቃድ መረጃ ይዟል።',
        );
      case LicenseRejectionReason.invalidSignature:
        return context.tr(
          'Activation code signature verification failed.',
          'የማንቂያ ኮድ ፊርማ ማረጋገጫ አልተሳካም።',
        );
      case LicenseRejectionReason.installationMismatch:
        return context.tr(
          'This code is not valid for this device. Share your Installation ID to get your own code.',
          'ይህ ኮድ ለዚህ መሣሪያ ትክክል አይደለም። የመለያዎን ያጋሩ የራስዎን ኮድ ለማግኘት።',
        );
      case LicenseRejectionReason.expired:
        return context.tr(
          'This license has expired. Please renew it.',
          'ይህ ፈቃድ ጊዜው አልፎበታል። እባክዎ ያድሱት።',
        );
      case LicenseRejectionReason.notYetValid:
        return context.tr(
          'This license is not valid yet. Check your device date and time.',
          'ይህ ፈቃድ ገና አልተጀመረም። የመሣሪያዎን ቀንና ሰዓት ይመልከቱ።',
        );
      case null:
        return context.tr('License verification failed', 'የፈቃድ ማረጋገጫ አልተሳካም');
    }
  }

  String _hashPassword(String password) {
    return PasswordHasher.hash(password);
  }

  Future<void> _handleLogin() async {
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      setState(() {
        _errorMessage = context.tr('Password is required', 'የይለፍ ቃል ያስፈልጋል');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final db = AppDatabase();
      await db.init();
      final users = UserRepository(db.instance);
      final resolvedProfile = await users.getProfile();

      if (resolvedProfile == null || resolvedProfile.passwordHash == null) {
        setState(() {
          _errorMessage = context.tr(
            'No account found. Activate your license and create a password first.',
            'አካውንት አልተገኘም። መጀመሪያ ፈቃድዎን አስጀምረው የይለፍ ቃል ይፍጠሩ።',
          );
          _isLoading = false;
        });
        return;
      }

      final enteredHash = _hashPassword(password);
      if (resolvedProfile.passwordHash != enteredHash) {
        setState(() {
          _errorMessage = context.tr('Incorrect password', 'የተሳሳተ የይለፍ ቃል');
          _isLoading = false;
        });
        return;
      }

      await users.saveProfile(resolvedProfile..lastLogin = DateTime.now());

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = context.tr(
            'Unable to sign in. Please try again.',
            'መግባት አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty) {
      setState(() {
        _errorMessage = context.tr('Password is required', 'የይለፍ ቃል ያስፈልጋል');
      });
      return;
    }

    if (newPassword.length < 4) {
      setState(() {
        _errorMessage = context.tr(
          'Password must be at least 4 characters',
          'የይለፍ ቃል ቢያንስ 4 ፊደሎች መሆን አለበት',
        );
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = context.tr('Passwords do not match', 'የይለፍ ቃሎቹ አይጣጣሙም');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = AppDatabase();
      await db.init();
      // Onboarding owns the password and nothing else: the store names, photo
      // and language stay exactly as the merchant left them.
      await UserRepository(
        db.instance,
      ).savePassword(_hashPassword(newPassword));

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = context.tr(
            'Unable to save profile. Please try again.',
            'መገለጫ ማስቀመጥ አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _copyInstallationId() {
    if (_installationId != null) {
      Clipboard.setData(ClipboardData(text: _installationId!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'Installation ID copied to clipboard',
              'የተጫን መለያ ወደ ቅንጥብ ተቀድቷል',
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copySupportNumber() {
    Clipboard.setData(const ClipboardData(text: AppStrings.supportPhone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.tr(
            'Support number copied to clipboard',
            'የድጋፍ ቁጥር ወደ ቅንጥብ ተቀድቷል',
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Image.asset('asset/efoy.jpg', fit: BoxFit.contain),
            ),

            const SizedBox(height: 16),

            // Brand Name
            const Text(
              'Efoy',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryTeal,
              ),
            ),

            Text(
              'እፎይ',
              style: TextStyle(fontSize: 20, color: scheme.onSurfaceVariant),
            ),

            const SizedBox(height: 32),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: scheme.onSurfaceVariant,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: context.tr('Login', 'ግባ')),
                  Tab(text: context.tr('Activate License', 'ፈቃድ አስጀምር')),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildLoginTab(), _buildLicenseTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('Welcome Back', 'እንኳን ደህና መጡ'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            context.tr(
              'Enter your password to continue',
              'ለመቀጠል የይለፍ ቃልዎን ያስገቡ',
            ),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),

          const SizedBox(height: 32),

          TextField(
            controller: _passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
            onChanged: (_) {
              // The banner belongs to the attempt that failed; once the
              // merchant starts correcting the password it should go away.
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
            decoration: InputDecoration(
              labelText: context.tr('Password', 'የይለፍ ቃል'),
              hintText: context.tr('Enter your password', 'የይለፍ ቃልዎን ያስገቡ'),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _FeedbackBanner(message: _errorMessage!, isError: true),
          ],

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(context.tr('Login', 'ግባ')),
                  ),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () {
              _tabController.animateTo(1);
            },
            child: Text(
              context.tr(
                'Need to activate? Go to License tab',
                'ማስጀመር ይፈልጋሉ? ወደ ፈቃድ ገጽ ይሂዱ',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseTab() {
    // If activation successful, show onboarding
    if (_showOnboarding) {
      return _buildOnboardingFlow();
    }

    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('Activate Efoy', 'እፎይን አስጀምር'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text(
            context.tr(
              'Enter your license key to activate',
              'ለማስጀመር የፈቃድ ቁልፍዎን ያስገቡ',
            ),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),

          const SizedBox(height: 24),

          // Device Info Card
          if (_deviceInfo != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppColors.primaryTeal.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.smartphone,
                        color: AppColors.primaryTeal,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('Device Information', 'የመሣሪያ መረጃ'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _buildInfoRow(
                    context.tr('Platform', 'መድረክ'),
                    _deviceInfo!.platform,
                  ),
                  _buildInfoRow(context.tr('Model', 'ሞዴል'), _deviceInfo!.model),
                  _buildInfoRow(
                    context.tr('Manufacturer', 'አምራች'),
                    _deviceInfo!.manufacturer,
                  ),

                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),

                  Text(
                    context.tr('Installation ID', 'የተጫን መለያ'),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Text(
                            _installationId ??
                                context.tr('Loading...', 'በመጫን ላይ...'),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      IconButton(
                        onPressed: _copyInstallationId,
                        icon: const Icon(Icons.copy),
                        tooltip: context.tr(
                          'Copy Installation ID',
                          'የተጫን መለያ ቅዳ',
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    context.tr(
                      'Share this Installation ID to receive your activation code',
                      'የማንቂያ ኮድዎን ለማግኘት ይህን የተጫን መለያ ያጋሩ',
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],

          // Activation Code Input
          TextField(
            controller: _licenseKeyController,
            decoration: InputDecoration(
              labelText: context.tr('Activation Code', 'የማንቂያ ኮድ'),
              hintText: context.tr(
                'Paste the code you received',
                'የተሰጠዎትን ኮድ ይለጥፉ',
              ),
              prefixIcon: const Icon(Icons.vpn_key),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_\-=\s]')),
            ],
            maxLines: 3,
            minLines: 1,
          ),

          const SizedBox(height: 12),

          // One number, one path: the merchant calls or SMSes the Installation
          // ID, pays it on Telebirr, and the key comes back on the same line.
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: AppColors.primaryTeal,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.tr('How to get a code', 'ኮድ እንዴት እናገኛለን'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _copySupportNumber,
                      tooltip: context.tr('Copy the number', 'ቁጥሩን ቅዳ'),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.copy, size: 16),
                    ),
                  ],
                ),
                Text(
                  context.tr(
                    '1. Call or SMS your Installation ID to '
                        '${AppStrings.supportPhone} ${AppStrings.supportTeam}\n'
                        '2. Pay with Telebirr to that same number\n'
                        '3. The activation key comes back to you on it',
                    '1. የተጫን መለያዎን በስልክ ወይም SMS ለ${AppStrings.supportPhone} '
                        '${AppStrings.supportTeam} ይላኩ\n'
                        '2. በዚሁ ቁጥር በቴሌብር ይክፈሉ\n'
                        '3. የማንቂያ ኮዱ በዚሁ ቁጥር ይመለስልዎታል',
                  ),
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.6,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 15,
                      color: AppColors.primaryTeal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      context.tr('Telebirr & support', 'ቴሌብርና ድጋፍ'),
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${AppStrings.supportPhone} · ${AppStrings.supportTeam}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Error Message
          if (_errorMessage != null) ...[
            _FeedbackBanner(message: _errorMessage!, isError: true),
            const SizedBox(height: 16),
          ],

          // Success Message
          if (_successMessage != null) ...[
            _FeedbackBanner(message: _successMessage!, isError: false),
            const SizedBox(height: 16),
          ],

          // Activate Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleLicenseActivation,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(context.tr('Activate License', 'ፈቃድ አስጀምር')),
                  ),
          ),

          const SizedBox(height: 12),

          // Trial entry: use the app free for three days, no code needed.
          TextButton.icon(
            onPressed: _isLoading ? null : _startTrial,
            icon: const Icon(Icons.hourglass_top_outlined, size: 16),
            label: Text(context.tr('Try free for 3 days', 'ለ3 ቀናት በነጻ ይሞክሩ')),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingFlow() {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.successGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.successGreen,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('License Activated!', 'ፈቃዱ ተስካለ!'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.successGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr(
                          'Complete your setup to get started',
                          'ለመጀመር ማዋቀርዎን ያጠናቅቁ',
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Step 1: Set Password
          Text(
            context.tr('Create your password', 'የይለፍ ቃልዎን ይፍጠሩ'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'This password will be used to login to your account',
              'ይህ የይለፍ ቃል ለመግቢያነት ይጠቅማል',
            ),
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: context.tr('New Password', 'አዲስ የይለፍ ቃል'),
              hintText: context.tr(
                'Enter password (min 4 characters)',
                'የይለፍ ቃል ያስገቡ (ቢያንስ 4 ፊደሎች)',
              ),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: context.tr('Confirm Password', 'የይለፍ ቃል አረጋግጥ'),
              hintText: context.tr('Re-enter password', 'የይለፍ ቃል እንደገና ያስገቡ'),
              prefixIcon: const Icon(Icons.lock_outline),
            ),
          ),

          const SizedBox(height: 24),

          // Error Message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.alertRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.alertRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.alertRed,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.alertRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Complete Setup Button
          ElevatedButton(
            onPressed: _isLoading ? null : _completeOnboarding,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      context.tr('Complete Setup & Start', 'ማዋቀር ጨርስ እና ጀምር'),
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () {
              setState(() {
                _showOnboarding = false;
                _successMessage = null;
              });
            },
            child: Text(
              context.tr('← Back to License Entry', '← ወደ ፈቃድ ማስገቢያ ተመለስ'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline answer to whatever the merchant just tried: a wrong password, a
/// rejected code, a successful activation.
///
/// One component for both tabs so a failure never looks different depending on
/// which half of the screen it came from.
class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.alertRed : AppColors.successGreen;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
