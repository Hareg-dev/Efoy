/// Plans supported by the Efoy offline licensing system.
///
/// The trial plan is a short evaluation window. Monthly is a rolling
/// subscription renewed by a new activation code. Lifetime never expires.
enum LicensePlan {
  /// Three-day evaluation license.
  trial('trial', Duration(days: 3)),

  /// Rolling subscription, renewed by a fresh activation code.
  monthly('monthly', Duration(days: 30)),

  /// Explicit lifetime license; never expires.
  lifetime('lifetime', null);

  const LicensePlan(this.wireName, this.defaultDuration);

  /// Stable identifier used inside the signed payload.
  final String wireName;

  /// Default validity window used by the issuer when no explicit duration is
  /// given. `null` means the plan never expires.
  final Duration? defaultDuration;

  /// Whether licenses of this plan carry a real expiry date.
  bool get expires => defaultDuration != null;

  static LicensePlan? tryFromWireName(String? name) {
    if (name == null) return null;
    for (final plan in LicensePlan.values) {
      if (plan.wireName == name) return plan;
    }
    return null;
  }

  /// Human-readable label.
  String get displayName {
    switch (this) {
      case LicensePlan.trial:
        return 'Trial';
      case LicensePlan.monthly:
        return 'Monthly';
      case LicensePlan.lifetime:
        return 'Lifetime';
    }
  }
}
