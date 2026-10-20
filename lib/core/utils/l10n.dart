import 'package:flutter/material.dart';

/// Lightweight bilingual helper for inline UI strings.
extension L10nContext on BuildContext {
  String get languageCode => Localizations.localeOf(this).languageCode;

  bool get isAmharic => languageCode == 'am';

  String tr(String english, String amharic) {
    return isAmharic ? amharic : english;
  }
}
