import 'package:flutter/material.dart';
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

/// Light / dark / system theme selection.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final value = await _storage.read(key: _themeModeKey);
    switch (value) {
      case 'light':
        state = ThemeMode.light;
      case 'dark':
        state = ThemeMode.dark;
      case 'system':
      default:
        state = ThemeMode.system;
    }
  }

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
  LocaleNotifier() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final value = await _storage.read(key: _languageKey);
    state = Locale(value == 'am' ? 'am' : 'en');
  }

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
final accentColorProvider = StateProvider<Color>((ref) => const Color(0xFF0A6358));
