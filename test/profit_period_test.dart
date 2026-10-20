import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/logic/providers/profit_provider.dart';

void main() {
  group('periodBounds', () {
    final now = DateTime(2026, 10, 20, 15, 42); // Tuesday

    test('today covers the local calendar day', () {
      final (start, end) = periodBounds(now, ProfitPeriod.today);

      expect(start, DateTime(2026, 10, 20));
      expect(end, DateTime(2026, 10, 21));
      expect(end.difference(start), const Duration(days: 1));
    });

    test('week starts on Monday and covers seven days', () {
      final (start, end) = periodBounds(now, ProfitPeriod.week);

      expect(start, DateTime(2026, 10, 19));
      expect(end, DateTime(2026, 10, 26));
    });

    test('month covers the full calendar month, including year end', () {
      final (start, end) = periodBounds(now, ProfitPeriod.month);
      expect(start, DateTime(2026, 10));
      expect(end, DateTime(2026, 11));

      final (decemberStart, januaryEnd) = periodBounds(
        DateTime(2026, 12, 31, 23, 59),
        ProfitPeriod.month,
      );
      expect(decemberStart, DateTime(2026, 12));
      expect(januaryEnd, DateTime(2027));
    });

    test('week handles a Sunday correctly', () {
      final (start, end) = periodBounds(
        DateTime(2026, 10, 25, 8), // Sunday
        ProfitPeriod.week,
      );

      expect(start, DateTime(2026, 10, 19));
      expect(end, DateTime(2026, 10, 26));
    });
  });
}
