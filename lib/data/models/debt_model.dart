import 'package:isar/isar.dart';

part 'debt_model.g.dart';

/// Money a customer still owes for a sale that was not paid for in full.
///
/// The sale itself is never edited: profit is counted on the whole invoice the
/// day it leaves the shop, and this row tracks only the cash that has not
/// arrived yet. Each settle-up adds one [DebtPayment] and raises [paidAmount].
@collection
class DebtModel {
  Id id = Isar.autoIncrement;

  /// The sale this receivable came from, by its transaction id.
  @Index()
  late String saleTransactionId;

  late String customerName;
  String? customerPhone;

  /// The invoice the debt came from.
  late double totalAmount;

  /// Everything received against this invoice: the part payment taken at the
  /// counter plus every later settle-up.
  late double paidAmount;

  @Index()
  late bool isOpen;

  @Index()
  late DateTime openedAt;

  DateTime? lastPaymentAt;

  String? note;

  List<DebtPayment> payments = [];

  DebtModel({
    required this.saleTransactionId,
    required this.customerName,
    this.customerPhone,
    required this.totalAmount,
    required this.paidAmount,
    required this.openedAt,
    this.lastPaymentAt,
    this.note,
    this.payments = const [],
  }) {
    isOpen = balanceDue > tolerance;
  }

  /// Half a cent. Money is stored as double, so a settle-up that clears the
  /// debt can land a few floating-point units short of the invoice.
  static const double tolerance = 0.005;

  double get balanceDue {
    final remaining = totalAmount - paidAmount;
    return remaining > tolerance ? remaining : 0;
  }

  double get paidProportion {
    if (totalAmount <= 0) return 1;
    return (paidAmount / totalAmount).clamp(0.0, 1.0);
  }

  /// Take money against this receivable. Throws when the amount does not make
  /// sense so a mis-typed settle-up cannot silently corrupt the balance.
  void recordPayment(double amount, {DateTime? at, String? note}) {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Must be greater than zero.');
    }
    if (!isOpen) {
      throw StateError('$customerName has no balance left to settle.');
    }
    final when = at ?? DateTime.now();
    paidAmount += amount;
    lastPaymentAt = when;
    payments = [
      ...payments,
      DebtPayment()
        ..amount = amount
        ..at = when
        ..note = note,
    ];
    isOpen = balanceDue > tolerance;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleTransactionId': saleTransactionId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'isOpen': isOpen,
      'openedAt': openedAt.toIso8601String(),
      'lastPaymentAt': lastPaymentAt?.toIso8601String(),
      'note': note,
      'payments': payments.map((payment) => payment.toJson()).toList(),
    };
  }

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    final debt = DebtModel(
      saleTransactionId: json['saleTransactionId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      openedAt: json['openedAt'] != null
          ? DateTime.parse(json['openedAt'] as String)
          : DateTime.now(),
      lastPaymentAt: json['lastPaymentAt'] != null
          ? DateTime.parse(json['lastPaymentAt'] as String)
          : null,
      note: json['note'] as String?,
      payments: (json['payments'] as List? ?? const [])
          .map(
            (payment) => DebtPayment.fromJson(payment as Map<String, dynamic>),
          )
          .toList(),
    )..id = json['id'] as int? ?? Isar.autoIncrement;
    return debt;
  }
}

/// One settle-up against a [DebtModel], kept so the merchant can see when the
/// money actually came in.
@embedded
class DebtPayment {
  double amount = 0;
  late DateTime at;
  String? note;

  DebtPayment();

  Map<String, dynamic> toJson() {
    return {'amount': amount, 'at': at.toIso8601String(), 'note': note};
  }

  factory DebtPayment.fromJson(Map<String, dynamic> json) {
    return DebtPayment()
      ..amount = (json['amount'] as num?)?.toDouble() ?? 0
      ..at = json['at'] != null
          ? DateTime.parse(json['at'] as String)
          : DateTime.now()
      ..note = json['note'] as String?;
  }
}
