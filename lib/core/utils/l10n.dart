import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

/// Lightweight bilingual helper for inline UI strings.
extension L10nContext on BuildContext {
  String get languageCode => Localizations.localeOf(this).languageCode;

  bool get isAmharic => languageCode == 'am';

  String tr(String english, String amharic) {
    return isAmharic ? amharic : english;
  }

  /// Translates a stored product category; anything the merchant typed by
  /// hand is shown as saved.
  String categoryLabel(String category) =>
      AppStrings.productCategoryLabel(category, languageCode);
}
