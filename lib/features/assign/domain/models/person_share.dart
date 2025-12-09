import 'package:hive_ce/hive.dart';

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
  });
}
