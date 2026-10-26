import 'package:isar/isar.dart';

part 'user_profile.g.dart';

@collection
class UserProfile {
  Id id = Isar.autoIncrement;

  // Authentication
  String? passwordHash;
  DateTime? lastLogin;

  // Business Information
  String? businessName;
  String? businessNameAm;
  String? ownerName;

  /// Local file path of the merchant's own photo, copied into the app
  /// documents folder when picked. Null means the default store icon.
  String? profilePhotoPath;

  // Payment Information (for receiving payments from customers)
  String? phoneNumber;
  String? telebirrAccount;
  String? bankAccount;
  String? bankName;

  // App Settings
  bool isDemoMode;
  bool isDarkMode;
  String language; // 'en' or 'am'

  // Timestamps
  late DateTime createdAt;
  late DateTime updatedAt;

  UserProfile({
    this.passwordHash,
    this.lastLogin,
    this.businessName,
    this.businessNameAm,
    this.ownerName,
    this.profilePhotoPath,
    this.phoneNumber,
    this.telebirrAccount,
    this.bankAccount,
    this.bankName,
    this.isDemoMode = true,
    this.isDarkMode = false,
    this.language = 'en',
  }) {
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passwordHash': passwordHash,
      'lastLogin': lastLogin?.toIso8601String(),
      'businessName': businessName,
      'businessNameAm': businessNameAm,
      'ownerName': ownerName,
      'profilePhotoPath': profilePhotoPath,
      'phoneNumber': phoneNumber,
      'telebirrAccount': telebirrAccount,
      'bankAccount': bankAccount,
      'bankName': bankName,
      'isDemoMode': isDemoMode,
      'isDarkMode': isDarkMode,
      'language': language,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final profile = UserProfile(
      passwordHash: json['passwordHash'] as String?,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
      businessName: json['businessName'] as String?,
      businessNameAm: json['businessNameAm'] as String?,
      ownerName: json['ownerName'] as String?,
      profilePhotoPath: json['profilePhotoPath'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      telebirrAccount: json['telebirrAccount'] as String?,
      bankAccount: json['bankAccount'] as String?,
      bankName: json['bankName'] as String?,
      isDemoMode: json['isDemoMode'] as bool? ?? true,
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      language: json['language'] as String? ?? 'en',
    )..id = json['id'] as int? ?? Isar.autoIncrement;

    profile.createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now();
    profile.updatedAt = json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : DateTime.now();
    return profile;
  }
}
