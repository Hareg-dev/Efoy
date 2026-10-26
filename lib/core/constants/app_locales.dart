import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Locales the app ships with.
const List<Locale> appSupportedLocales = [Locale('en'), Locale('am')];

/// Delegates that give Amharic (and English) its Material date pickers,
/// navigation semantics and gesture labels. Without these, the M3 widgets
/// throw on the first Amharic frame.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
