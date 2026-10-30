import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/constants/app_accents.dart';
import 'package:efoy_retail_app/core/constants/app_colors.dart';
import 'package:efoy_retail_app/core/constants/app_theme.dart';
import 'package:efoy_retail_app/logic/providers/theme_provider.dart';
import 'package:efoy_retail_app/main.dart';

/// The bug this guards: the notifiers used to construct with
/// [ThemeMode.system] and read secure storage asynchronously, so a cold start
/// painted the wrong theme for the first frames. The persisted value must now
/// be the initial state, with no async correction at all.
void main() {
  _accentTests();
  group('themeModeFromName', () {
    test('maps stored names and falls back for anything unknown', () {
      expect(themeModeFromName('light'), ThemeMode.light);
      expect(themeModeFromName('dark'), ThemeMode.dark);
      expect(themeModeFromName('system'), ThemeMode.system);
      expect(themeModeFromName(null), ThemeMode.system);
      expect(themeModeFromName('garbage'), ThemeMode.system);
    });
  });

  group('PersistedPreferences', () {
    test('stays on defaults when the platform store is unavailable', () async {
      // In a unit test there is no secure-storage plugin, so reads throw.
      // A broken keystore must not stop the app from starting.
      final preferences = await PersistedPreferences.load();
      expect(preferences.themeMode, ThemeMode.system);
      expect(preferences.locale.languageCode, anyOf('en', 'am'));
    });
  });

  group('ThemeModeNotifier', () {
    test('is already correct before any frame is drawn', () {
      expect(ThemeModeNotifier(ThemeMode.dark).state, ThemeMode.dark);
      expect(ThemeModeNotifier(ThemeMode.light).state, ThemeMode.light);
      expect(ThemeModeNotifier().state, ThemeMode.system);
    });

    test('LocaleNotifier takes its stored locale as the initial value', () {
      expect(LocaleNotifier(const Locale('am')).state.languageCode, 'am');
      expect(LocaleNotifier().state.languageCode, 'en');
    });
  });

  testWidgets('the app paints with the theme restored at startup', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          themeModeProvider.overrideWith(
            (ref) => ThemeModeNotifier(ThemeMode.dark),
          ),
          localeProvider.overrideWith(
            (ref) => LocaleNotifier(const Locale('en')),
          ),
        ],
        child: const EfoyApp(),
      ),
    );

    // First frame, before any timer or async work settles.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme, isNotNull);

    await tester.pump();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });
}

/// The six palettes in Settings. Teal is the shipped look, so the other five
/// must actually change the theme - not just be painted swatches.
void _accentTests() {
  group('accent palettes', () {
    test('every palette is named, distinct and starts with its own hue', () {
      expect(AppAccent.values, hasLength(6));
      expect(AppAccent.fromName(null), AppAccent.teal);
      expect(AppAccent.fromName('garbage'), AppAccent.teal);

      final seeds = AppAccent.values.map((accent) => accent.seed).toSet();
      expect(seeds, hasLength(AppAccent.values.length));

      for (final accent in AppAccent.values) {
        expect(AppAccent.fromName(accent.name), accent);
        expect(accent.profitGradient, hasLength(3));
        expect(accent.label, isNotEmpty);
        expect(accent.labelAm, isNotEmpty);
      }
    });

    testWidgets('the default palette keeps the theme the shop shipped with', (
      tester,
    ) async {
      final teal = AppTheme.lightThemeFor(AppAccent.teal);
      expect(teal.colorScheme.primary, AppColors.primaryTeal);
      expect(teal.colorScheme.secondary, AppColors.primaryGreen);
      expect(teal.scaffoldBackgroundColor, AppColors.neutralBg);
    });

    testWidgets('another palette repaints the scheme and the money surfaces', (
      tester,
    ) async {
      final blue = AppTheme.lightThemeFor(AppAccent.oceanBlue);
      expect(blue.colorScheme.primary, AppAccent.oceanBlue.seed);
      expect(blue.colorScheme.primary, isNot(AppColors.primaryTeal));
      expect(blue.primaryColor, AppAccent.oceanBlue.seed);
      expect(blue.brightness, Brightness.light);

      final dark = AppTheme.darkThemeFor(AppAccent.crimson);
      expect(dark.brightness, Brightness.dark);
      expect(dark.colorScheme.surface, AppColors.darkSurface);
    });

    test('the notifier starts on the stored accent', () {
      expect(AccentNotifier(AppAccent.amber).state, AppAccent.amber);
      expect(AccentNotifier().state, AppAccent.teal);
    });

    test('look drops back to teal when the store is empty', () async {
      final preferences = await PersistedPreferences.load();
      expect(preferences.accent, AppAccent.teal);
    });
  });
}
