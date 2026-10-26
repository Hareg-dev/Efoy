import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Theme and locale preferences.
///
/// Preferences are persisted with [FlutterSecureStorage] (already a project
/// dependency) instead of shared_preferences. Functionally equivalent for
/// this app and avoids an extra platform plugin.
const _storage = FlutterSecureStorage();

const _themeModeKey = 'theme_mode';
const _languageKey = 'language';

/// Preferences read once before `runApp`, so the very first frame already
/// uses the theme and language the user left the app in.
class PersistedPreferences {
  const PersistedPreferences({
    required this.themeMode,
    required this.locale,
  });

  static const PersistedPreferences defaults = PersistedPreferences(
    themeMode: ThemeMode.system,
    locale: Locale('en'),
  );

  final ThemeMode themeMode;
  final Locale locale;

  static Future<PersistedPreferences> load() async {
    try {
      final values = await Future.wait([
        _storage.read(key: _themeModeKey),
        _storage.read(key: _languageKey),
      ]);
      return PersistedPreferences(
        themeMode: themeModeFromName(values[0]),
        locale: Locale(values[1] == 'am' ? 'am' : 'en'),
      );
    } on Exception {
      // A broken platform keystore must not stop the app from starting.
      return defaults;
    }
  }
}

ThemeMode themeModeFromName(String? name) {
  switch (name) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

/// Light / dark / system theme selection.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier([super.initialMode = ThemeMode.system]);

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(key: _themeModeKey, value: mode.name);
  }
}

/// Persisted locale (English / Amharic).
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier([super.initialLocale = const Locale('en')]);

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _storage.write(key: _languageKey, value: locale.languageCode);
  }

  Future<void> setLanguage(String languageCode) {
    return setLocale(Locale(languageCode == 'am' ? 'am' : 'en'));
  }
}

/// Convenience provider for widgets that only need the language code.
final languageProvider = Provider<String>((ref) {
  return ref.watch(localeProvider).languageCode;
});

/// Accent color provider (optional customization).
final accentColorProvider = StateProvider<Color>(
  (ref) => const Color(0xFF0A6358),
);

/// Status bar icons that match the theme actually on screen.
///
/// Without this the status bar keeps the light-icon style hard-coded at
/// startup and becomes unreadable in light mode.
class SystemStyleForTheme extends StatelessWidget {
  const SystemStyleForTheme({
    super.key,
    required this.brightness,
    required this.child,
  });

  final Brightness brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final light = brightness == Brightness.light;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: light ? Brightness.dark : Brightness.light,
        statusBarBrightness: light ? Brightness.light : Brightness.dark,
      ),
      child: child,
    );
  }
}

