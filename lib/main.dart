import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'data/local/app_database.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/auth_screen.dart';
import 'ui/screens/main_layout.dart';

// TESTING: Uncomment to generate license keys on startup
// import 'core/utils/test_helpers.dart';

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
      print('Database initialization skipped (web platform)');
    }
  }
  
  // TESTING: Uncomment to print test license keys to console
  // await TestHelpers.generateTestLicenses();
  
  runApp(
    const ProviderScope(
      child: EfoyApp(),
    ),
  );
}

class EfoyApp extends StatelessWidget {
  const EfoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Efoy - እፎይ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/home': (context) => const MainLayout(),
      },
    );
  }
}
