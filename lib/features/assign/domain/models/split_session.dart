import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../payments/domain/models/payment_status.dart';
import 'item_assignment.dart';
import 'person_share.dart';

part 'split_session.g.dart';

@HiveType(typeId: 5)
class SplitSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String receiptId;

  @HiveField(2)
  final String? groupId;

  @HiveField(3)
  final List<String> participantPersonIds;

  @HiveField(4)
  final List<ItemAssignment> assignments;

  @HiveField(5)
  final List<PersonShare> calculatedShares;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  late bool isSaved;

  SplitSession({
    String? id,
    required this.receiptId,
    this.groupId,
    required this.participantPersonIds,
    required this.assignments,
    required this.calculatedShares,
    DateTime? createdAt,
    this.isSaved = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  SplitSession copyWith({
    List<ItemAssignment>? assignments,
    List<PersonShare>? calculatedShares,
    bool? isSaved,
  }) {
    return SplitSession(
      id: id,
      receiptId: receiptId,
      groupId: groupId,
      participantPersonIds: participantPersonIds,
      assignments: assignments ?? this.assignments,
      calculatedShares: calculatedShares ?? this.calculatedShares,
      createdAt: createdAt,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  /// Convert SplitSession to Firestore format
  Map<String, dynamic> toFirestore() => {
    'receiptId': receiptId,
    'groupId': groupId,
    'participantPersonIds': participantPersonIds,
    'assignments': assignments.map((a) => {
      'itemId': a.itemId,
      'assignedPersonIds': a.assignedPersonIds,
    }).toList(),
    'calculatedShares': calculatedShares.map((s) => {
      'personId': s.personId,
      'personName': s.personName,
      'personEmoji': s.personEmoji,
      'itemsSubtotal': s.itemsSubtotal,
      'sst': s.sst,
      'serviceCharge': s.serviceCharge,
      'rounding': s.rounding,
      'total': s.total,
      'assignedItemIds': s.assignedItemIds,
      'paymentStatus': s.paymentStatus.index,
      'amountPaid': s.amountPaid,
      'lastPaidAt': s.lastPaidAt?.toIso8601String(),
      'paymentNotes': s.paymentNotes,
    }).toList(),
    'createdAt': createdAt.toIso8601String(),
    'isSaved': isSaved,
  };

  /// Create SplitSession from Firestore document data
  factory SplitSession.fromFirestore(Map<String, dynamic> data) {
    return SplitSession(
      id: data['id'] as String? ?? const Uuid().v4(),
      receiptId: data['receiptId'] as String? ?? '',
      groupId: data['groupId'] as String?,
      participantPersonIds: List<String>.from(data['participantPersonIds'] as List? ?? []),
      assignments: (data['assignments'] as List?)?.map((a) {
        final assignment = a as Map<String, dynamic>;
        return ItemAssignment(
          itemId: assignment['itemId'] as String? ?? '',
          assignedPersonIds: List<String>.from(assignment['assignedPersonIds'] as List? ?? []),
        );
      }).toList() ?? [],
      calculatedShares: (data['calculatedShares'] as List?)?.map((s) {
        final share = s as Map<String, dynamic>;
        return PersonShare(
          personId: share['personId'] as String? ?? '',
          personName: share['personName'] as String? ?? '',
          personEmoji: share['personEmoji'] as String? ?? '👤',
          itemsSubtotal: (share['itemsSubtotal'] as num?)?.toDouble() ?? 0.0,
          sst: (share['sst'] as num?)?.toDouble() ?? 0.0,
          serviceCharge: (share['serviceCharge'] as num?)?.toDouble() ?? 0.0,
          rounding: (share['rounding'] as num?)?.toDouble() ?? 0.0,
          total: (share['total'] as num?)?.toDouble() ?? 0.0,
          assignedItemIds: List<String>.from(share['assignedItemIds'] as List? ?? []),
          paymentStatus: _parsePaymentStatus(share['paymentStatus'] as int?),
          amountPaid: (share['amountPaid'] as num?)?.toDouble(),
          lastPaidAt: share['lastPaidAt'] != null ? DateTime.parse(share['lastPaidAt'] as String) : null,
          paymentNotes: share['paymentNotes'] as String?,
        );
      }).toList() ?? [],
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt'] as String) : DateTime.now(),
      isSaved: data['isSaved'] as bool? ?? false,
    );
  }

  static PaymentStatus _parsePaymentStatus(int? statusIndex) {
    if (statusIndex == null || statusIndex < 0 || statusIndex >= PaymentStatus.values.length) {
      return PaymentStatus.unpaid; // Default fallback
    }
    return PaymentStatus.values[statusIndex];
  }
}
