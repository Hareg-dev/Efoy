import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_theme.dart';
import '../../core/security/device_identity.dart';
import '../../core/security/license_verifier.dart';
import '../../core/utils/test_helpers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _passwordController = TextEditingController();
  final _licenseKeyController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _telebirrController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankNameController = TextEditingController();
  
  String? _deviceId;
  DeviceInfo? _deviceInfo;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showOnboarding = false;
  bool _isDemoMode = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final info = await DeviceIdentity.getDeviceInfo();
    final id = await DeviceIdentity.getDeviceId();
    
    setState(() {
      _deviceInfo = info;
      _deviceId = id;
    });
  }

  Future<void> _generateTestKey() async {
    if (_deviceId == null) return;
    
    // Generate 30-day test license
    final testKey = LicenseVerifier.generateLicenseKey(
      deviceId: _deviceId!,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    setState(() {
      _licenseKeyController.text = testKey;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test license key generated (30 days)'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordController.dispose();
    _licenseKeyController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _telebirrController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _handleLicenseActivation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final licenseKey = _licenseKeyController.text.trim();
    
    if (licenseKey.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a license key';
        _isLoading = false;
      });
      return;
    }

    if (_deviceId == null) {
      setState(() {
        _errorMessage = 'Device ID not available';
        _isLoading = false;
      });
      return;
    }

    // Simulate activation delay
    await Future.delayed(const Duration(milliseconds: 500));

    final result = LicenseVerifier.verifyLicense(
      licenseKey: licenseKey,
      deviceId: _deviceId!,
    );

    setState(() {
      _isLoading = false;
      if (result.isValid) {
        _successMessage = 'License activated successfully!';
        _errorMessage = null;
        
        // Show onboarding for password setup
        _showOnboarding = true;
      } else {
        _errorMessage = result.errorMessage ?? 'License verification failed';
        _successMessage = null;
      }
    });
  }
  
  Future<void> _completeOnboarding() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    
    // Validate password
    if (newPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Password is required';
      });
      return;
    }
    
    if (newPassword.length < 4) {
      setState(() {
        _errorMessage = 'Password must be at least 4 characters';
      });
      return;
    }
    
    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }
    
    // Validate payment info (at least one method required if not demo mode)
    if (!_isDemoMode) {
      if (_phoneController.text.trim().isEmpty && 
          _telebirrController.text.trim().isEmpty && 
          _bankAccountController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please provide at least one payment method';
        });
        return;
      }
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // TODO: Save user profile to database
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _isLoading = false;
    });
    
    // Navigate to home
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _copyDeviceId() {
    if (_deviceId != null) {
      Clipboard.setData(ClipboardData(text: _deviceId!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device ID copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    color: AppColors.primaryTeal.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                'asset/efoy.jpg',
                fit: BoxFit.contain,
              ),
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
            
            const Text(
              'እፎይ',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
              decoration: BoxDecoration(
                color: AppColors.neutralBg,
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
                unselectedLabelColor: AppColors.textSecondary,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Login'),
                  Tab(text: 'Activate License'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginTab(),
                  _buildLicenseTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            'Enter your password to continue',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          
          const SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: () {
              // TODO: Implement login logic
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('Login'),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: () {
              _tabController.animateTo(1);
            },
            child: const Text('Need to activate? Go to License tab'),
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
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Activate Efoy',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          const Text(
            'Enter your license key to activate',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Device Info Card
          if (_deviceInfo != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              decoration: BoxDecoration(
                color: AppColors.neutralBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppColors.primaryTeal.withOpacity(0.2),
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
                      const Text(
                        'Device Information',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildInfoRow('Platform', _deviceInfo!.platform),
                  _buildInfoRow('Model', _deviceInfo!.model),
                  _buildInfoRow('Manufacturer', _deviceInfo!.manufacturer),
                  
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  const Text(
                    'Device ID',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.neutralGray.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _deviceId ?? 'Loading...',
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
                        onPressed: _copyDeviceId,
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy Device ID',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Share this Device ID to get your license key',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
          
          // License Key Input
          TextField(
            controller: _licenseKeyController,
            decoration: const InputDecoration(
              labelText: 'License Key',
              hintText: 'XXXX-XXXX-XXXX-XXXX',
              prefixIcon: Icon(Icons.vpn_key),
            ),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]')),
            ],
            maxLines: 3,
            minLines: 1,
          ),
          
          // Test Key Generator Button (only in debug mode)
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _generateTestKey,
              icon: const Icon(Icons.build, size: 18),
              label: const Text('Generate Test Key (30 Days)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.warningAmber,
                side: const BorderSide(color: AppColors.warningAmber),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '⚠️ Debug mode only - for testing',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Error Message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.alertRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.alertRed.withOpacity(0.3),
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
          
          // Success Message
          if (_successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.successGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.successGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(
                        color: AppColors.successGreen,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Activate License'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOnboardingFlow() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.successGreen, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'License Activated!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.successGreen,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Complete your setup to get started',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
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
          const Text(
            'Step 1: Create Password',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This password will be used to login to your account',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New Password',
              hintText: 'Enter password (min 4 characters)',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          
          const SizedBox(height: 12),
          
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              hintText: 'Re-enter password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          
          // Step 2: Demo Mode Toggle
          const Text(
            'Step 2: Choose Mode',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isDemoMode ? AppColors.warningAmber.withOpacity(0.1) : AppColors.primaryTeal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isDemoMode ? AppColors.warningAmber.withOpacity(0.3) : AppColors.primaryTeal.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isDemoMode ? Icons.visibility : Icons.store,
                  color: _isDemoMode ? AppColors.warningAmber : AppColors.primaryTeal,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isDemoMode ? 'Demo Mode' : 'Production Mode',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isDemoMode 
                            ? 'Testing with sample data (payment info optional)'
                            : 'Real business mode (payment info required)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: !_isDemoMode,
                  onChanged: (value) {
                    setState(() {
                      _isDemoMode = !value;
                    });
                  },
                  activeColor: AppColors.primaryTeal,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          
          // Step 3: Payment Information (optional in demo mode)
          Row(
            children: [
              const Text(
                'Step 3: Payment Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isDemoMode) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Optional',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isDemoMode 
                ? 'You can add this information later in Settings'
                : 'Required for accepting customer payments',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+251912345678',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          
          const SizedBox(height: 12),
          
          TextField(
            controller: _telebirrController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'TeleBirr Account',
              hintText: 'TeleBirr number',
              prefixIcon: Icon(Icons.payment),
            ),
          ),
          
          const SizedBox(height: 12),
          
          TextField(
            controller: _bankAccountController,
            decoration: const InputDecoration(
              labelText: 'Bank Account Number',
              hintText: 'Account number',
              prefixIcon: Icon(Icons.account_balance),
            ),
          ),
          
          const SizedBox(height: 12),
          
          TextField(
            controller: _bankNameController,
            decoration: const InputDecoration(
              labelText: 'Bank Name',
              hintText: 'e.g., Commercial Bank of Ethiopia',
              prefixIcon: Icon(Icons.business),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Error Message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.alertRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.alertRed.withOpacity(0.3),
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
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Complete Setup & Start'),
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
            child: const Text('← Back to License Entry'),
          ),
        ],
      ),
    );
  }
}
