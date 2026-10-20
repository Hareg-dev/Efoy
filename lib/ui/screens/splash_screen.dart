import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isar/isar.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../data/local/app_database.dart';
import '../../data/models/license_model.dart';
import '../../data/models/user_profile.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _animationController.forward();

    // Navigate after delay
    _navigationTimer = Timer(const Duration(seconds: 2), _navigateToNextScreen);
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    final hasSession = await _hasActiveSession();
    if (!mounted) return;

    if (hasSession) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  /// Initializes the license/database layer in the background and checks
  /// whether a completed onboarding profile exists.
  Future<bool> _hasActiveSession() async {
    try {
      final database = AppDatabase();
      final isar = await database.init();

      // Refresh license expiry state in the background.
      final license = await isar.licenseModels
          .filter()
          .isActiveEqualTo(true)
          .findFirst();
      if (license != null && DateTime.now().isAfter(license.expiresAt)) {
        await isar.writeTxn(() async {
          license
            ..isExpired = true
            ..isActive = false;
          await isar.licenseModels.put(license);
        });
      }

      final profile = await isar.userProfiles.where().findFirst();
      return profile?.passwordHash != null;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // Logo Card with Animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildLogoCard(),
                ),
              ),
              
              const SizedBox(height: 56),
              
              // Brand Name in Amharic
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildBrandText(),
              ),
              
              const Spacer(flex: 2),
              
              // Animated Loading Dots
              _buildLoadingDots(),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoCard() {
    return Container(
      width: 218,
      height: 142,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Image.asset(
        'asset/efoy.jpg',
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildBrandText() {
    return Column(
      children: [
        // Amharic Brand Name
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFF75F0A0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            'እፎይ',
            style: GoogleFonts.notoSansEthiopic(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'በእፎይ እርፍ ይበሉ',
          style: GoogleFonts.notoSansEthiopic(
            fontSize: 16.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6BE39B),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingDots() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final delay = index * 0.3;
              final value = (_animationController.value - delay).clamp(0.0, 1.0);
              final opacity = (0.35 + (value * 0.65)).clamp(0.35, 1.0);
              final scale = 0.9 + (value * 0.2);

              final isCenter = index == 1;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: isCenter ? 5 : 4),
                width: isCenter ? 10 : 8,
                height: isCenter ? 10 : 8,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                  boxShadow: isCenter
                      ? [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                transform: Matrix4.identity()
                  ..scaleByDouble(scale, scale, scale, 1.0),
              );
            },
          );
        }),
      ),
    );
  }
}
