import 'package:flutter/material.dart';

/// The colour a shop dresses in.
///
/// [seed] feeds the Material colour scheme, so buttons, focus rings and chips
/// follow it. [profitGradient] paints the profit window and the cart total; a
/// merchant who reads the green card as "money" every day can pick another hue
/// and still recognise the same card.
enum AppAccent {
  teal(
    label: 'Teal',
    labelAm: 'ቀላል አረንጓዴ',
    seed: Color(0xFF0A6358),
    profitGradient: [Color(0xFF15803D), Color(0xFF0D5C2E), Color(0xFF053B1E)],
  ),
  forestGreen(
    label: 'Forest Green',
    labelAm: 'ጨለማ አረንጓዴ',
    seed: Color(0xFF166534),
    profitGradient: [Color(0xFF22A34A), Color(0xFF15803D), Color(0xFF0A3D1E)],
  ),
  oceanBlue(
    label: 'Ocean Blue',
    labelAm: 'የባህር ሰማያዊ',
    seed: Color(0xFF0B5FA5),
    profitGradient: [Color(0xFF1D7BD6), Color(0xFF0B5FA5), Color(0xFF062E52)],
  ),
  deepPurple(
    label: 'Deep Purple',
    labelAm: 'ወይን ጠጅ',
    seed: Color(0xFF5B21B6),
    profitGradient: [Color(0xFF7C3AED), Color(0xFF5B21B6), Color(0xFF2E1065)],
  ),
  crimson(
    label: 'Crimson',
    labelAm: 'ቀይ',
    seed: Color(0xFF9F1239),
    profitGradient: [Color(0xFFE11D48), Color(0xFF9F1239), Color(0xFF4C0519)],
  ),
  amber(
    label: 'Amber',
    labelAm: 'ወርቃማ',
    seed: Color(0xFFB45309),
    profitGradient: [Color(0xFFF59E0B), Color(0xFFB45309), Color(0xFF5C2E05)],
  );

  const AppAccent({
    required this.label,
    required this.labelAm,
    required this.seed,
    required this.profitGradient,
  });

  final String label;
  final String labelAm;
  final Color seed;

  /// Start, middle and end of every money surface that used to be green.
  final List<Color> profitGradient;

  Color get profitStart => profitGradient.first;
  Color get profitEnd => profitGradient.last;

  /// Header and indicator text: the seed darkened enough to read on white.
  Color get deep => this == AppAccent.teal
      ? const Color(0xFF044A2B)
      : Color.lerp(seed, Colors.black, 0.32)!;

  /// Wash used behind selected pills and icons.
  Color get tint => this == AppAccent.teal
      ? const Color(0xFFD6EFE9)
      : Color.lerp(seed, Colors.white, 0.86)!;

  /// Brighter companion for secondary actions; the legacy green for teal.
  Color get secondary => this == AppAccent.teal
      ? const Color(0xFF10B981)
      : Color.lerp(seed, Colors.white, 0.28)!;

  /// Softest companion, used for tertiary accents and mint highlights.
  Color get tertiary => this == AppAccent.teal
      ? const Color(0xFF6EE7B7)
      : Color.lerp(seed, Colors.white, 0.55)!;

  /// Label text that stays readable on [profitGradient] in either theme.
  Color get onGradient => Colors.white;

  /// Stable name for storage. Never renumber this list - names, not indexes,
  /// are written to the keystore.
  String get storageKey => name;

  static AppAccent fromName(String? name) {
    for (final accent in AppAccent.values) {
      if (accent.name == name) return accent;
    }
    return AppAccent.teal;
  }
}
