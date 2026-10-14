import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

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
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    // TODO: Check license status here
    // For now, navigate to auth screen
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  void dispose() {
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
            color: AppColors.primaryGreen.withOpacity(0.25),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
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
          child: const Text(
            'እፎይ',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Tagline in Amharic
        const Text(
          'በእፎይ እርፍ ይበሉ',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6BE39B),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_animationController.value - delay).clamp(0.0, 1.0);
            final opacity = (0.35 + (value * 0.65)).clamp(0.35, 1.0);
            final scale = 0.9 + (value * 0.2);

            return Container(
              margin: EdgeInsets.symmetric(
                horizontal: index == 1 ? 5 : 4,
              ),
              width: index == 1 ? 10 : 8,
              height: index == 1 ? 10 : 8,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(opacity),
                shape: BoxShape.circle,
                boxShadow: index == 1
                    ? [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              transform: Matrix4.identity()..scale(scale),
            );
          },
        );
      }),
    );
  }
}
