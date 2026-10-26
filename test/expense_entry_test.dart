import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/core/constants/app_locales.dart';
import 'package:efoy_retail_app/data/models/expense_model.dart';
import 'package:efoy_retail_app/logic/providers/repository_providers.dart';
import 'package:efoy_retail_app/ui/screens/expenses_screen.dart';

/// Every case here stops before a save, so the repository is a tripwire: if it
/// is ever read, an invalid expense got through.
Future<void> pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWith(
          (ref) async => throw StateError(
            'an invalid expense must not reach the repository',
          ),
        ),
        expenseListProvider.overrideWith(
          (ref) => Stream<List<ExpenseModel>>.value(const []),
        ),
      ],
      child: MaterialApp(
        supportedLocales: appSupportedLocales,
        localizationsDelegates: appLocalizationsDelegates,
        home: const ExpensesScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// The screen's filter row names the same categories, so taps must be scoped
/// to the sheet itself.
Finder categoryChip(String label) =>
    find.descendant(of: find.byType(BottomSheet), matching: find.text(label));

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Add'));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('Expense entry sheet', () {
    testWidgets('the header opens a category-first sheet', (tester) async {
      await pumpScreen(tester);

      expect(find.text('0 expenses recorded'), findsOneWidget);
      await openSheet(tester);

      expect(find.text('Where did it go?'), findsOneWidget);
      expect(find.text('Choose a category to open the form'), findsOneWidget);
      expect(categoryChip('Rent'), findsOneWidget);
      // Nothing to type until a category is picked, and only one submit.
      expect(find.text('Amount *'), findsNothing);
      expect(find.text('Save expense'), findsOneWidget);
    });

    testWidgets('saving without a category is refused inline', (tester) async {
      await pumpScreen(tester);
      await openSheet(tester);

      await tester.tap(find.text('Save expense'));
      await tester.pump();

      expect(find.text('Pick a category first.'), findsOneWidget);
      expect(find.text('Where did it go?'), findsOneWidget);
    });

    testWidgets('a category reveals the form and names the note', (
      tester,
    ) async {
      await pumpScreen(tester);
      await openSheet(tester);
      await tester.tap(categoryChip('Rent'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Amount *'), findsOneWidget);
      expect(find.text('What was it for?'), findsOneWidget);
      final note = tester.widgetList<TextField>(find.byType(TextField)).last;
      expect(note.controller?.text, 'Rent');
    });

    testWidgets('a zero amount is refused before anything is stored', (
      tester,
    ) async {
      await pumpScreen(tester);
      await openSheet(tester);
      await tester.tap(categoryChip('Rent'));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.enterText(find.byType(TextField).first, '0');
      await tester.tap(find.text('Save expense'));
      await tester.pump();

      expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
      expect(find.text('Where did it go?'), findsOneWidget);
    });

    testWidgets('switching category re-labels an untouched note', (
      tester,
    ) async {
      await pumpScreen(tester);
      await openSheet(tester);
      await tester.tap(categoryChip('Rent'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(categoryChip('Salary'));
      await tester.pump(const Duration(milliseconds: 400));

      final note = tester.widgetList<TextField>(find.byType(TextField)).last;
      expect(note.controller?.text, 'Salary');
    });
  });
}
