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
}
