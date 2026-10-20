import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Application Typography System
/// Matches HTML mockup text styles exactly
class AppTextStyles {
  AppTextStyles._();

  // ==================== DISPLAY (48sp+) ====================
  /// Used for: Profit amount on home screen
  /// HTML: 48px, font-black, tracking-tight
  static TextStyle display = GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w900, // black
    letterSpacing: -1.0,
    color: AppColors.textPrimary,
    height: 1.0,
  );

  // ==================== HEADER (20-24sp) ====================
  /// Used for: Screen titles
  /// HTML: 20-24px, font-black, uppercase
  static TextStyle header = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w900, // black
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  // ==================== SUBHEADER (12sp) ====================
  /// Used for: Section headers like "CRITICAL ALERTS"
  /// HTML: 12px, font-black, uppercase, tracking-wider (1px)
  static TextStyle subheader = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w900, // black
    letterSpacing: 1.0,
    color: AppColors.textPrimary,
  );

  // ==================== BODY (14sp) ====================
  /// Used for: Primary content
  /// HTML: 14px, font-semibold
  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600, // semibold
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // ==================== CAPTION (11sp) ====================
  /// Used for: Labels, badges
  /// HTML: 11px, font-bold, uppercase
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w700, // bold
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  // ==================== MICRO (9sp) ====================
  /// Used for: Navigation labels, smallest text
  /// HTML: 9px, font-black, uppercase, tracking-wider (0.8px)
  static TextStyle micro = GoogleFonts.inter(
    fontSize: 9,
    fontWeight: FontWeight.w900, // black
    letterSpacing: 0.8,
    color: AppColors.textTertiary,
  );

  // ==================== NUMBER STYLES ====================
  /// Tabular figures for consistent number alignment
  static TextStyle number = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w900, // black
    fontFeatures: const [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  static TextStyle numberLarge = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: AppColors.textPrimary,
  );

  // ==================== AMHARIC TEXT ====================
  /// For Amharic brand name and content
  static TextStyle amharic = GoogleFonts.notoSansEthiopic(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle amharicLarge = GoogleFonts.notoSansEthiopic(
    fontSize: 52,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
  );
}
