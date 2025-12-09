import 'package:hive_ce/hive.dart';

part 'item_assignment.g.dart';

@HiveType(typeId: 4)
class ItemAssignment extends HiveObject {
  @HiveField(0)
  final String itemId;

  @HiveField(1)
  late List<String> assignedPersonIds;

  ItemAssignment({
    required this.itemId,
    required this.assignedPersonIds,
  });

  bool get isAssigned => assignedPersonIds.isNotEmpty;
  bool get isShared => assignedPersonIds.length > 1;
  int get splitCount => assignedPersonIds.length;

  void assignPerson(String personId) {
    if (!assignedPersonIds.contains(personId)) {
      assignedPersonIds.add(personId);
    }
  }

  void unassignPerson(String personId) {
    assignedPersonIds.remove(personId);
  }

  void togglePerson(String personId) {
    if (assignedPersonIds.contains(personId)) {
      unassignPerson(personId);
    } else {
      assignPerson(personId);
    }
  }

  ItemAssignment copyWith({List<String>? assignedPersonIds}) {
    return ItemAssignment(
      itemId: itemId,
      assignedPersonIds: assignedPersonIds ?? this.assignedPersonIds,
    );
  }
}
