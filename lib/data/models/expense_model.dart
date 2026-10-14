import 'package:isar/isar.dart';

part 'expense_model.g.dart';

@collection
class ExpenseModel {
  Id id = Isar.autoIncrement;

  // Expense details
  late String title;
  String? description;

  late double amount;

  @Index()
  @enumerated
  late ExpenseCategory category;

  // Timestamp
  @Index()
  late DateTime expenseDate;
  late DateTime createdAt;

  // Optional metadata
  String? receiptImageUrl;
  String? notes;

  // Flag to differentiate Restock vs. Operating Expense
  // Restock expenses are tracked but don't reduce daily net profit
  bool isRestockExpense = false;

  // Soft delete
  bool isDeleted = false;

  ExpenseModel({
    required this.title,
    this.description,
    required this.amount,
    required this.category,
    required this.expenseDate,
    required this.createdAt,
    this.receiptImageUrl,
    this.notes,
    this.isRestockExpense = false,
    this.isDeleted = false,
  });

  ExpenseModel copyWith({
    String? title,
    String? description,
    double? amount,
    ExpenseCategory? category,
    DateTime? expenseDate,
    String? receiptImageUrl,
    String? notes,
    bool? isRestockExpense,
    bool? isDeleted,
  }) {
    return ExpenseModel(
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      notes: notes ?? this.notes,
      isRestockExpense: isRestockExpense ?? this.isRestockExpense,
      isDeleted: isDeleted ?? this.isDeleted,
    )..id = id;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category.name,
      'expenseDate': expenseDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'receiptImageUrl': receiptImageUrl,
      'notes': notes,
      'isRestockExpense': isRestockExpense,
      'isDeleted': isDeleted,
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      category: ExpenseCategory.values.byName(json['category'] as String),
      expenseDate: json['expenseDate'] != null ? DateTime.parse(json['expenseDate'] as String) : DateTime.now(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      receiptImageUrl: json['receiptImageUrl'] as String?,
      notes: json['notes'] as String?,
      isRestockExpense: json['isRestockExpense'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
    )..id = json['id'] as int;
  }
}

enum ExpenseCategory {
  rent,
  salary,
  transport,
  utilities,
  airtime,
  supplies,
  restock,
  other,
}

// Category display helper
extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.salary:
        return 'Salary';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.airtime:
        return 'Airtime';
      case ExpenseCategory.supplies:
        return 'Supplies';
      case ExpenseCategory.restock:
        return 'Restock';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get displayNameAmharic {
    switch (this) {
      case ExpenseCategory.rent:
        return 'ኪራይ';
      case ExpenseCategory.salary:
        return 'ደሞዝ';
      case ExpenseCategory.transport:
        return 'መጓጓዣ';
      case ExpenseCategory.utilities:
        return 'መገልገያዎች';
      case ExpenseCategory.airtime:
        return 'ኤርታይም';
      case ExpenseCategory.supplies:
        return 'መሳሪያዎች';
      case ExpenseCategory.restock:
        return 'እቃ መሙላት';
      case ExpenseCategory.other:
        return 'ሌላ';
    }
  }
}
