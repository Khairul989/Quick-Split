import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
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
  })  : id = id ?? const Uuid().v4(),
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
}
