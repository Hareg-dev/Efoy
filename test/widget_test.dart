import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/main.dart';

void main() {
  testWidgets('Efoy app renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: EfoyApp(),
      ),
    );

    expect(find.text('እፎይ'), findsOneWidget);
    expect(find.text('በእፎይ እርፍ ይበሉ'), findsOneWidget);

    // Dispose the splash screen so its navigation timer is cancelled; the
    // test must not reach the auth flow, which needs platform plugins.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
