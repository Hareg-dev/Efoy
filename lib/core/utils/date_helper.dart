import 'package:intl/intl.dart';

/// Time period filter enum
enum Period { today, week, month, custom }

/// Date and time utility functions
class DateHelper {
  DateHelper._();

  /// Get start and end DateTime for period
  static Map<String, DateTime> getPeriodRange(Period period, {DateTime? customStart, DateTime? customEnd}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case Period.today:
        return {
          'start': today,
          'end': today.add(const Duration(days: 1)),
        };

      case Period.week:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return {
          'start': startOfWeek,
          'end': startOfWeek.add(const Duration(days: 7)),
        };

      case Period.month:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 1);
        return {
          'start': startOfMonth,
          'end': endOfMonth,
        };

      case Period.custom:
        return {
          'start': customStart ?? today,
          'end': customEnd ?? today.add(const Duration(days: 1)),
        };
    }
  }

  /// Get last N days range
  static Map<String, DateTime> getLastNDays(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(Duration(days: days - 1));

    return {
      'start': startDate,
      'end': today.add(const Duration(days: 1)),
    };
  }

  /// Format date as "MMM dd, yyyy" (e.g., "Oct 14, 2026")
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date as "dd/MM/yyyy"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format time as "hh:mm a" (e.g., "02:30 PM")
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  /// Format date and time as "MMM dd, yyyy • hh:mm a"
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} • ${formatTime(date)}';
  }

  /// Format relative time (e.g., "2 hours ago", "Just now")
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes != 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours != 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days != 1 ? 's' : ''} ago';
    } else {
      return formatDate(date);
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Check if date is within period
  static bool isDateInPeriod(DateTime date, Period period) {
    final range = getPeriodRange(period);
    return date.isAfter(range['start']!) && date.isBefore(range['end']!);
  }

  /// Get day name (e.g., "Monday")
  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  /// Get month name (e.g., "October")
  static String getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  /// Calculate days between two dates
  static int daysBetween(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return endDate.difference(startDate).inDays;
  }
}
