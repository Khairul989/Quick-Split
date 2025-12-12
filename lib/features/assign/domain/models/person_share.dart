import 'package:hive_ce/hive.dart';
import '../../../payments/domain/models/payment_status.dart';

part 'person_share.g.dart';

@HiveType(typeId: 6)
class PersonShare extends HiveObject {
  @HiveField(0)
  final String personId;

  @HiveField(1)
  final String personName;

  @HiveField(2)
  final String personEmoji;

  @HiveField(3)
  final double itemsSubtotal;

  @HiveField(4)
  final double sst;

  @HiveField(5)
  final double serviceCharge;

  @HiveField(6)
  final double rounding;

  @HiveField(7)
  final double total;

  @HiveField(8)
  final List<String> assignedItemIds;

  // NEW: Payment tracking fields
  @HiveField(9)
  final PaymentStatus paymentStatus;

  @HiveField(10)
  final double? amountPaid;

  @HiveField(11)
  final DateTime? lastPaidAt;

  @HiveField(12)
  final String? paymentNotes;

  PersonShare({
    required this.personId,
    required this.personName,
    required this.personEmoji,
    required this.itemsSubtotal,
    required this.sst,
    required this.serviceCharge,
    required this.rounding,
    required this.total,
    required this.assignedItemIds,
    this.paymentStatus = PaymentStatus.unpaid,
    this.amountPaid,
    this.lastPaidAt,
    this.paymentNotes,
  });

  /// Create a copy with updated payment fields
  PersonShare copyWithPayment({
    PaymentStatus? paymentStatus,
    double? amountPaid,
    DateTime? lastPaidAt,
    String? paymentNotes,
  }) {
    return PersonShare(
      personId: personId,
      personName: personName,
      personEmoji: personEmoji,
      itemsSubtotal: itemsSubtotal,
      sst: sst,
      serviceCharge: serviceCharge,
      rounding: rounding,
      total: total,
      assignedItemIds: assignedItemIds,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amountPaid: amountPaid ?? this.amountPaid,
      lastPaidAt: lastPaidAt ?? this.lastPaidAt,
      paymentNotes: paymentNotes ?? this.paymentNotes,
    );
  }

  /// Get remaining amount to be paid
  double get remainingAmount {
    if (paymentStatus == PaymentStatus.paid) return 0;
    if (amountPaid == null) return total;
    return (total - (amountPaid ?? 0)).clamp(0.0, total);
  }

  /// Check if payment is overdue (for future features)
  bool get isOverdue => false; // TODO: Implement due date logic

  /// Get payment percentage
  double get paymentPercentage {
    if (total == 0) return 1.0;
    final paid = amountPaid ?? (paymentStatus == PaymentStatus.paid ? total : 0);
    return (paid / total).clamp(0.0, 1.0);
  }
}
