import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_locales.dart';
import 'core/constants/app_theme.dart';
import 'data/local/app_database.dart';
import 'logic/providers/theme_provider.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/screens/debts_screen.dart';
import 'ui/screens/reports_screen.dart';
import 'ui/screens/main_layout.dart';
import 'ui/screens/session_guard.dart';
import 'ui/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preferences are read before the first frame so the app resumes in the
  // theme and language the user left it in.
  final preferences = await PersistedPreferences.load();
  final startDark = switch (preferences.themeMode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
  };

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: startDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: startDark ? Brightness.dark : Brightness.light,
    ),
  );

  // Initialize database (skip on web - Isar doesn't support web)
  if (!kIsWeb) {
    try {
      final db = AppDatabase();
      await db.init();
    } catch (e) {
      debugPrint('Database initialization failed: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(
          (ref) => ThemeModeNotifier(preferences.themeMode),
        ),
        localeProvider.overrideWith(
          (ref) => LocaleNotifier(preferences.locale),
        ),
        accentProvider.overrideWith(
          (ref) => AccentNotifier(preferences.accent),
        ),
      ],
      child: const EfoyApp(),
    ),
  );
}

class EfoyApp extends ConsumerWidget {
  const EfoyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final accent = ref.watch(accentProvider);

    return MaterialApp(
      title: 'Efoy - እፎይ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightThemeFor(accent),
      darkTheme: AppTheme.darkThemeFor(accent),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: appLocalizationsDelegates,
      builder: (context, child) {
        final brightness = switch (themeMode) {
          ThemeMode.light => Brightness.light,
          ThemeMode.dark => Brightness.dark,
          ThemeMode.system => MediaQuery.platformBrightnessOf(context),
        };
        return SystemStyleForTheme(brightness: brightness, child: child!);
      },
      supportedLocales: appSupportedLocales,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) =>
            const SessionGuard(child: MainLayout(initialIndex: 0)),
        '/sell': (context) =>
            const SessionGuard(child: MainLayout(initialIndex: 1)),
        '/inventory': (context) =>
            const SessionGuard(child: MainLayout(initialIndex: 2)),
        '/expenses': (context) =>
            const SessionGuard(child: MainLayout(initialIndex: 3)),
        '/profile': (context) =>
            const SessionGuard(child: MainLayout(initialIndex: 4)),
        '/debts': (context) => const SessionGuard(child: DebtsScreen()),
        '/reports': (context) => const SessionGuard(child: ReportsScreen()),
        '/settings': (context) => const SessionGuard(child: SettingsScreen()),
      },
    );
  }
}
