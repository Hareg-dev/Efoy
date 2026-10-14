import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_colors.dart';

// Storage instance
const _storage = FlutterSecureStorage();

// Dark mode provider (persisted)
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(false) {
    _loadDarkMode();
  }

  Future<void> _loadDarkMode() async {
    final value = await _storage.read(key: 'dark_mode');
    state = value == 'true';
  }

  Future<void> toggle() async {
    state = !state;
    await _storage.write(key: 'dark_mode', value: state.toString());
  }
}

// Language provider (persisted: 'en' or 'am')
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final value = await _storage.read(key: 'language');
    state = value ?? 'en';
  }

  Future<void> setLanguage(String lang) async {
    if (lang == 'en' || lang == 'am') {
      state = lang;
      await _storage.write(key: 'language', value: lang);
    }
  }
}

// Accent color provider (optional customization)
final accentColorProvider = StateProvider<Color>((ref) => AppColors.primaryTeal);
