import 'package:isar/isar.dart';

part 'license_model.g.dart';

@collection
class LicenseModel {
  Id id = Isar.autoIncrement;

  // Device binding
  late String deviceId; // Hardware fingerprint
  
  // License details
  late String licenseKey; // Encrypted activation key
  
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
    this.isActive = true,
    this.isExpired = false,
    this.storeName,
    this.ownerPhone,
  });

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
  trial, // 7 or 14 days
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
