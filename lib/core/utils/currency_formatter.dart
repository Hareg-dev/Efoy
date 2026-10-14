import 'package:intl/intl.dart';

/// Currency formatting utilities for Ethiopian Birr
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _birrFormat = NumberFormat('#,##0.00', 'en_US');

  /// Format amount as Birr with symbol
  /// Example: 21000.50 -> "21,000.50 ብር"
  static String formatBirr(double amount, {bool showSymbol = true}) {
    final formatted = _birrFormat.format(amount);
    return showSymbol ? '$formatted ብር' : formatted;
  }

  /// Format amount as Birr for English display
  /// Example: 21000.50 -> "Birr 21,000.50"
  static String formatBirrEnglish(double amount) {
    return 'Birr ${_birrFormat.format(amount)}';
  }

  /// Parse formatted birr string back to double
  /// Example: "21,000.50 ብር" -> 21000.50
  static double parseBirr(String formattedAmount) {
    final cleaned = formattedAmount.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Format compact notation for large amounts
  /// Example: 1500000 -> "1.5M ብር"
  static String formatCompactBirr(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M ብር';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K ብር';
    }
    return formatBirr(amount);
  }

  /// Format amount without decimal places
  /// Example: 21000.50 -> "21,001 ብር"
  static String formatBirrWhole(double amount) {
    final wholeAmount = amount.round();
    final formatted = NumberFormat('#,##0', 'en_US').format(wholeAmount);
    return '$formatted ብር';
  }

  /// Format percentage
  /// Example: 0.1575 -> "15.75%"
  static String formatPercentage(double ratio) {
    return '${(ratio * 100).toStringAsFixed(2)}%';
  }

  /// Format percentage with one decimal
  /// Example: 0.1575 -> "15.8%"
  static String formatPercentageSimple(double ratio) {
    return '${(ratio * 100).toStringAsFixed(1)}%';
  }

  /// Validate if string is valid Birr amount
  static bool isValidAmount(String amount) {
    final cleaned = amount.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) != null;
  }
}
