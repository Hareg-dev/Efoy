import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/constants/app_accents.dart';
import 'package:efoy_retail_app/core/security/password_hasher.dart';
import 'package:efoy_retail_app/data/models/user_profile.dart';
import 'package:efoy_retail_app/logic/providers/repository_providers.dart';
import 'package:efoy_retail_app/logic/providers/theme_provider.dart';
import 'package:efoy_retail_app/ui/screens/settings_screen.dart';

/// The screen only reads the profile, so the whole test can run against an
/// in-memory stream instead of opening a database inside the fake-async zone.
final UserProfile _profileWithPassword = UserProfile(
  businessName: 'Suq Kona',
  passwordHash: PasswordHasher.hash('hunter2'),
);

Future<void> pump(
  WidgetTester tester, {
  ThemeMode theme = ThemeMode.dark,
  UserProfile? profile,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith((ref) => ThemeModeNotifier(theme)),
        userProfileProvider.overrideWith(
          (ref) => Stream<UserProfile?>.value(profile),
        ),
      ],
      child: MaterialApp(
        home: const SettingsScreen(),
        supportedLocales: const [Locale('en'), Locale('am')],
      ),
    ),
  );
  // The profile arrives on a stream, so it takes one extra frame before the
  // screen knows whether a password exists.
  await tester.pump();
  await tester.pump();
}

void main() {
  _accentPickerTests();
  testWidgets('settings owns appearance, reports and deletion', (tester) async {
    await pump(tester, profile: _profileWithPassword);

    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('አማርኛ'), findsOneWidget);
    expect(find.text('Export Excel report'), findsOneWidget);
    expect(find.text('Back up data'), findsOneWidget);
    expect(find.text('Restore data'), findsOneWidget);
    expect(find.text('Clear sales & stock'), findsOneWidget);
    expect(find.text('Delete everything'), findsOneWidget);
  });

  testWidgets('the stored theme is selected on the first frame', (
    tester,
  ) async {
    await pump(tester, profile: _profileWithPassword);

    // A selected option swaps its icon for a tick, so the missing dark icon
    // proves the stored mode won the very first frame.
    expect(find.byIcon(Icons.dark_mode_outlined), findsNothing);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(find.byIcon(Icons.brightness_auto_outlined), findsOneWidget);
  });

  testWidgets('deletion is blocked without a password', (tester) async {
    await pump(tester);
    expect(
      find.text('Set a password in Profile before deleting anything.'),
      findsOneWidget,
    );
    expect(
      find.text('Every deletion asks for your account password.'),
      findsNothing,
    );
  });

  testWidgets('deletion asks for the merchant password once it exists', (
    tester,
  ) async {
    await pump(tester, profile: _profileWithPassword);
    expect(
      find.text('Every deletion asks for your account password.'),
      findsOneWidget,
    );
  });

  testWidgets('the home settings icon routes to the settings screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/settings'),
              child: const Text('open settings'),
            ),
          ),
          '/settings': (context) => ProviderScope(
            overrides: [
              userProfileProvider.overrideWith(
                (ref) => Stream<UserProfile?>.value(_profileWithPassword),
              ),
            ],
            child: const SettingsScreen(),
          ),
        },
      ),
    );
    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS'), findsOneWidget);
  });
}

/// The six palettes the merchant can pick, added because the profit window used
/// to be green whatever the rest of the app looked like.
void _accentPickerTests() {
  testWidgets('offers all six palettes and marks the current one', (
    tester,
  ) async {
    await pump(tester, profile: _profileWithPassword);

    expect(find.text('Accent colour'), findsOneWidget);
    for (final accent in AppAccent.values) {
      expect(find.text(accent.label), findsOneWidget);
    }
  });

  testWidgets('tapping a palette selects it and keeps the others unselected', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        themeModeProvider.overrideWith(
          (ref) => ThemeModeNotifier(ThemeMode.dark),
        ),
        userProfileProvider.overrideWith(
          (ref) => Stream<UserProfile?>.value(_profileWithPassword),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pump();

    expect(container.read(accentProvider), AppAccent.teal);

    await tester.tap(find.text('Crimson'));
    await tester.pumpAndSettle();

    expect(container.read(accentProvider), AppAccent.crimson);
    expect(container.read(accentProvider), isNot(AppAccent.teal));
  });
}
