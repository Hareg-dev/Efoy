import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/constants/app_colors.dart';
import 'package:efoy_retail_app/core/constants/app_theme.dart';
import 'package:efoy_retail_app/ui/screens/splash_screen.dart';

/// The splash used to paint the brand's dark opening gradient whatever the
/// merchant's theme, so a light-mode start looked like a black screen.
void main() {
  Future<RadialGradient> pumpSplash(WidgetTester tester, ThemeMode mode) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        routes: {
          '/home': (_) => const Scaffold(body: Text('home')),
          '/auth': (_) => const Scaffold(body: Text('auth')),
        },
        home: const SplashScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final backdrop = tester.widget<Container>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).gradient != null &&
            widget.child is SafeArea,
      ),
    );
    return (backdrop.decoration! as BoxDecoration).gradient! as RadialGradient;
  }

  testWidgets('a light start opens on a light backdrop', (tester) async {
    final gradient = await pumpSplash(tester, ThemeMode.light);

    expect(gradient.colors, isNot(AppColors.splashGradient.colors));
    for (final color in gradient.colors) {
      // A pale wash over the surface, not the near-black brand gradient.
      expect(color.computeLuminance(), greaterThan(0.6));
    }
  });

  testWidgets('a dark start keeps the brand gradient', (tester) async {
    final gradient = await pumpSplash(tester, ThemeMode.dark);

    expect(gradient.colors, AppColors.splashGradient.colors);
  });
}
