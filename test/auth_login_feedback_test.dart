import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/constants/app_locales.dart';
import 'package:efoy_retail_app/ui/screens/auth_screen.dart';

/// The login tab used to set an error message and never render it, so a wrong
/// password looked like a dead button. Whatever went wrong must come back on
/// the screen, in the app's own alert styling.
void main() {
  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: locale,
          supportedLocales: appSupportedLocales,
          localizationsDelegates: appLocalizationsDelegates,
          home: const AuthScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder loginButton() => find.widgetWithText(ElevatedButton, 'Login');

  testWidgets('an empty password is answered on the login tab', (tester) async {
    await pump(tester);

    expect(find.text('Password is required'), findsNothing);

    await tester.tap(loginButton());
    await tester.pumpAndSettle();

    expect(find.text('Password is required'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('the notice disappears as soon as the merchant starts typing', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(loginButton());
    await tester.pumpAndSettle();
    expect(find.text('Password is required'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'hunter2');
    await tester.pump();

    expect(find.text('Password is required'), findsNothing);
  });

  testWidgets('the keyboard action submits the same way the button does', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField).first, '');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('the notice speaks Amharic when the app does', (tester) async {
    await pump(tester, locale: const Locale('am'));

    await tester.tap(find.widgetWithText(ElevatedButton, 'ግባ'));
    await tester.pumpAndSettle();

    expect(find.text('የይለፍ ቃል ያስፈልጋል'), findsOneWidget);
  });
}
