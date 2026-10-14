import 'package:flutter/material.dart';

/// Efoy Brand Color Palette
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primaryTeal = Color(0xFF007A60);
  static const Color primaryGreen = Color(0xFF0EC254);
  static const Color mintGreen = Color(0xFF5BE48F);
  static const Color softGreen = Color(0xFF61E095);

  // Navy Background Colors
  static const Color brandNavy = Color(0xFF0C1A2F);
  static const Color darkNavy = Color(0xFF081323);
  static const Color circleNavy = Color(0xFF0B203C);

  // Neutral Colors
  static const Color neutralBg = Color(0xFFF8F9FA);
  static const Color neutralLight = Color(0xFFF5F6F7);
  static const Color neutralGray = Color(0xFF6C757D);
  static const Color neutralDark = Color(0xFF212529);

  // Status & Alert Colors
  static const Color alertRed = Color(0xFFD92D20);
  static const Color warningAmber = Color(0xFFFDB022);
  static const Color successGreen = Color(0xFF12B76A);
  static const Color infoBlue = Color(0xFF0BA5EC);

  // Text Colors
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF475467);
  static const Color textTertiary = Color(0xFF98A2B3);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFF9FAFB);

  // Currency Birr Green
  static const Color birrGreen = Color(0xFF10B981);

  // Gradient Colors
  static LinearGradient get profitGradient => const LinearGradient(
        colors: [Color(0xFF12B76A), Color(0xFF0EC254)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get splashGradient => const LinearGradient(
        colors: [Color(0xFF0E2039), Color(0xFF091322)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get cardGradient => LinearGradient(
        colors: [
          Colors.white,
          Colors.white.withOpacity(0.95),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF0A0E14);
  static const Color darkSurface = Color(0xFF1A1F2E);
  static const Color darkCard = Color(0xFF252B3A);
  static const Color darkBorder = Color(0xFF2D3548);

  // Accent Theme Swatches
  static const Map<String, Color> accentSwatches = {
    'Forest Green': Color(0xFF047857),
    'Ocean Blue': Color(0xFF0284C7),
    'Deep Purple': Color(0xFF7C3AED),
    'Crimson': Color(0xFFDC2626),
    'Teal': Color(0xFF007A60),
    'Amber': Color(0xFFD97706),
  };
}
