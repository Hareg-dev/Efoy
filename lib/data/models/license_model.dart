import 'package:isar/isar.dart';

part 'license_model.g.dart';

@collection
class LicenseModel {
  Id id = Isar.autoIncrement;

  // Installation binding (random installation identifier, not hardware).
  late String deviceId;

  // License details
  late String licenseKey; // Full signed activation code

  /// Unique id minted by the issuer (e.g. EFY-9F3A61C2-7B04).
  /// Nullable for records created by legacy versions.
  String? licenseId;

  /// When the issuer created this license (payload `iat`).
  /// Nullable for records created by legacy versions.
  DateTime? issuedAt;

  @Index()
  late DateTime activatedAt;
  late DateTime expiresAt;
  
  @enumerated
  late LicenseType licenseType;
  
  // Status
  @Index()
  bool isActive = true;
  bool isExpired = false;

  // Store metadata
  String? storeName;
  String? ownerPhone;

  LicenseModel({
    required this.deviceId,
    required this.licenseKey,
    required this.activatedAt,
    required this.expiresAt,
    required this.licenseType,
    this.licenseId,
    this.issuedAt,
    this.isActive = true,
    this.isExpired = false,
    this.storeName,
    this.ownerPhone,
  });

  /// Number of days left before expiry (0 when already expired).
  int get daysRemainingOrZero {
    final remaining = expiresAt.difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inDays;
  }

  /// True when the license expires within the next seven days.
  bool get isExpiringSoon {
    if (!isValid) return false;
    final days = daysRemainingOrZero;
    return days > 0 && days <= 7;
  }

  bool get isValid {
    if (!isActive || isExpired) return false;
    return DateTime.now().isBefore(expiresAt);
  }

  int get daysRemaining {
    if (!isValid) return 0;
    return expiresAt.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'licenseKey': licenseKey,
      'licenseId': licenseId,
      'issuedAt': issuedAt?.toIso8601String(),
      'activatedAt': activatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'licenseType': licenseType.name,
      'isActive': isActive,
      'isExpired': isExpired,
      'storeName': storeName,
      'ownerPhone': ownerPhone,
    };
  }

  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    return LicenseModel(
      deviceId: json['deviceId'] as String,
      licenseKey: json['licenseKey'] as String,
      licenseId: json['licenseId'] as String?,
      issuedAt: json['issuedAt'] != null
          ? DateTime.parse(json['issuedAt'] as String)
          : null,
      activatedAt: json['activatedAt'] != null ? DateTime.parse(json['activatedAt'] as String) : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : DateTime.now(),
      licenseType: LicenseType.values.byName(json['licenseType'] as String),
      isActive: json['isActive'] as bool? ?? true,
      isExpired: json['isExpired'] as bool? ?? false,
      storeName: json['storeName'] as String?,
      ownerPhone: json['ownerPhone'] as String?,
    )..id = json['id'] as int;
  }
}

enum LicenseType {
  trial,
  monthly,
  yearly,
  lifetime,
}

extension LicenseTypeExtension on LicenseType {
  String get displayName {
    switch (this) {
      case LicenseType.trial:
        return 'Trial';
      case LicenseType.monthly:
        return 'Monthly';
      case LicenseType.yearly:
        return 'Yearly';
      case LicenseType.lifetime:
        return 'Lifetime';
    }
  }
}
