import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/logic/providers/theme_provider.dart';
import 'package:efoy_retail_app/main.dart';

/// The bug this guards: the notifiers used to construct with
/// [ThemeMode.system] and read secure storage asynchronously, so a cold start
/// painted the wrong theme for the first frames. The persisted value must now
/// be the initial state, with no async correction at all.
void main() {
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
          themeModeProvider.overrideWith((ref) => ThemeModeNotifier(ThemeMode.dark)),
          localeProvider.overrideWith((ref) => LocaleNotifier(const Locale('en'))),
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
