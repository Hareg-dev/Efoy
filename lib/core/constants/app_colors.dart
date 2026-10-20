import 'package:flutter/material.dart';

/// Application Color Palette
/// All colors extracted from HTML mockups (asset/*.html)
class AppColors {
  AppColors._();

  // ==================== PRIMARY BRAND GREENS ====================
  // Exact colors from HTML designs
  static const Color primaryDark   = Color(0xFF044A2B); // Logo container, headers
  static const Color primary       = Color(0xFF0A6358); // Main brand (profile, expenses)
  static const Color primaryMid    = Color(0xFF126857); // Inventory buttons
  static const Color primaryLight  = Color(0xFF1B635C); // Sell screen, cart
  
  // Aliases for backwards compatibility
  static const Color primaryTeal = primary;
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color mintGreen = Color(0xFF6EE7B7);

  // ==================== PROFIT CARD GRADIENT ====================
  static const Color profitGradStart = Color(0xFF15803D);
  static const Color profitGradMid   = Color(0xFF0D5C2E);
  static const Color profitGradEnd   = Color(0xFF053B1E);

  // ==================== BACKGROUNDS (PER SCREEN) ====================
  static const Color bgHome      = Color(0xFFF2F4F3);
  static const Color bgProfile   = Color(0xFFF7F8FA);
  static const Color bgInventory = Color(0xFFFAFAFA);
  static const Color bgExpenses  = Color(0xFFF6F8F8);
  static const Color bgCard      = Color(0xFFFFFFFF);

  // ==================== ALERT COLORS ====================
  static const Color alertRed      = Color(0xFFB91C24);
  static const Color alertRedDark  = Color(0xFF910D13);
  static const Color alertAmber    = Color(0xFFE6690B);
  static const Color warningAmber  = alertAmber;
  static const Color alertAmberBg  = Color(0xFFFFF9F0);
  static const Color alertAmberBorder = Color(0xFFFFECD1);

  // Splash screen gradient (matches HTML mockup)
  static const RadialGradient splashGradient = RadialGradient(
    center: Alignment(0.0, -0.35),
    radius: 1.0,
    colors: [
      Color(0xFF0E2039),
      Color(0xFF091322),
    ],
  );

  // ==================== STATUS INDICATORS ====================
  static const Color syncGreen = Color(0xFF34D399);
  static const Color successGreen = Color(0xFF10B981);
  static const Color emerald200   = Color(0xFFA7F3D0); // Labels on profit card
  static const Color rose300      = Color(0xFFFCA5A5); // Expenses on profit card

  // ==================== TEXT HIERARCHY ====================
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary  = Color(0xFF9CA3AF);

  // ==================== NEUTRAL UI ====================
  static const Color neutralBg    = Color(0xFFE5E9E6); // Settings button bg
  static const Color neutralGray  = Color(0xFF9CA3AF); // Inactive icons
  static const Color borderLight  = Color(0xFFF0F2F5);
  static const Color darkCard     = Color(0xFF1C1D1C); // "0 transactions" card
  static const Color darkCardInner = Color(0xFF2B2C2B);

  // ==================== DARK MODE COLORS ====================
  static const Color darkBg       = Color(0xFF0C1A2F);
  static const Color darkSurface  = Color(0xFF1C1D1C);
  static const Color textOnDark   = Color(0xFFE5E7EB);

  // ==================== MISC ====================
  static const Color infoBlue     = Color(0xFF0EA5E9);
  static const Color tealTint     = Color(0xFFD6EFE9);
}
