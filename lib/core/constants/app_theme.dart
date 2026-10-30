import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_accents.dart';
import 'app_colors.dart';

/// Application Theme Configuration
class AppTheme {
  AppTheme._();

  // Border Radius Constants
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 24.0;

  // Spacing Constants
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 16.0;
  static const double spaceL = 24.0;
  static const double spaceXL = 32.0;

  /// Light Theme Data, in the brand teal.
  static ThemeData get lightTheme => lightThemeFor(AppAccent.teal);

  /// Light theme in the accent the merchant picked.
  ///
  /// Teal is built by hand rather than from a seed so the shop that never
  /// touches the setting keeps exactly the palette it shipped with.
  static ThemeData lightThemeFor(AppAccent accent) {
    final primary = accent == AppAccent.teal
        ? AppColors.primaryTeal
        : accent.seed;
    final scheme = accent == AppAccent.teal
        ? const ColorScheme.light(
            primary: AppColors.primaryTeal,
            secondary: AppColors.primaryGreen,
            tertiary: AppColors.mintGreen,
            error: AppColors.alertRed,
            surface: Colors.white,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: AppColors.textPrimary,
            onError: Colors.white,
          )
        : ColorScheme.fromSeed(
            seedColor: accent.seed,
            brightness: Brightness.light,
          ).copyWith(
            primary: accent.seed,
            secondary: accent.secondary,
            tertiary: accent.tertiary,
            error: AppColors.alertRed,
            surface: Colors.white,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
            onError: Colors.white,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: AppColors.neutralBg,
      colorScheme: scheme,

      // Typography
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 52,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLarge)),
        ),
        color: Colors.white,
        margin: EdgeInsets.symmetric(horizontal: spaceM, vertical: spaceS),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.neutralBg,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceL,
            vertical: spaceM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceL,
            vertical: spaceM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.alertRed),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceM,
          vertical: spaceM,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: AppColors.neutralGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: accent.tint,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? accent.deep
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Dark Theme Data, in the brand teal.
  static ThemeData get darkTheme => darkThemeFor(AppAccent.teal);

  /// Dark theme in the accent the merchant picked.
  static ThemeData darkThemeFor(AppAccent accent) {
    final primary = accent == AppAccent.teal
        ? AppColors.primaryTeal
        : accent.seed;
    final scheme = accent == AppAccent.teal
        ? const ColorScheme.dark(
            primary: AppColors.primaryTeal,
            secondary: AppColors.primaryGreen,
            tertiary: AppColors.mintGreen,
            error: AppColors.alertRed,
            surface: AppColors.darkSurface,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: AppColors.textOnDark,
            onError: Colors.white,
          )
        : ColorScheme.fromSeed(
            seedColor: accent.seed,
            brightness: Brightness.dark,
          ).copyWith(
            primary: Color.lerp(accent.seed, Colors.white, 0.35)!,
            secondary: accent.secondary,
            tertiary: accent.tertiary,
            error: AppColors.alertRed,
            surface: AppColors.darkSurface,
            onPrimary: Colors.white,
            onSurface: AppColors.textOnDark,
            onError: Colors.white,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: scheme,

      // Typography (same as light with adjusted colors)
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.inter(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: AppColors.textOnDark,
            ),
            headlineLarge: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnDark,
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textOnDark,
            ),
          ),

      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(radiusLarge)),
        ),
        color: AppColors.darkCard,
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.textOnDark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnDark,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: AppColors.neutralGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.primaryLight.withValues(alpha: 0.42),
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.emerald200
                : AppColors.textOnDark.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
