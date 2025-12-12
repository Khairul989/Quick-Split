import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

part 'group.g.dart';

@HiveType(typeId: 3)
class Group extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late List<String> personIds;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  late DateTime lastUsedAt;

  @HiveField(5)
  late int usageCount;

  @HiveField(6)
  String? imagePath;

  Group({
    String? id,
    required this.name,
    required this.personIds,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    this.imagePath,
    this.usageCount = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastUsedAt = lastUsedAt ?? DateTime.now();

  void markUsed() {
    lastUsedAt = DateTime.now();
    usageCount++;
  }

  Group copyWith({
    String? name,
    List<String>? personIds,
    String? imagePath,
  }) {
    return Group(
      id: id,
      name: name ?? this.name,
      personIds: personIds ?? this.personIds,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt,
      imagePath: imagePath ?? this.imagePath,
      usageCount: usageCount,
    );
  }
}
