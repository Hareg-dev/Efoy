import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'data/local/app_database.dart';
import 'logic/providers/theme_provider.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/screens/main_layout.dart';
import 'ui/screens/session_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
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
    const ProviderScope(
      child: EfoyApp(),
    ),
  );
}

class EfoyApp extends ConsumerWidget {
  const EfoyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Efoy - እፎይ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('am'),
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const SessionGuard(
              child: MainLayout(initialIndex: 0),
            ),
        '/sell': (context) => const SessionGuard(
              child: MainLayout(initialIndex: 1),
            ),
        '/inventory': (context) => const SessionGuard(
              child: MainLayout(initialIndex: 2),
            ),
        '/expenses': (context) => const SessionGuard(
              child: MainLayout(initialIndex: 3),
            ),
        '/profile': (context) => const SessionGuard(
              child: MainLayout(initialIndex: 4),
            ),
      },
    );
  }
}
