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
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       lastUsedAt = lastUsedAt ?? DateTime.now();

  void markUsed() {
    lastUsedAt = DateTime.now();
    usageCount++;
  }

  Group copyWith({String? name, List<String>? personIds, String? imagePath}) {
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

  /// Convert Group to Firestore format
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'personIds': personIds,
    'imagePath': imagePath,
    'createdAt': createdAt.toIso8601String(),
    'lastUsedAt': lastUsedAt.toIso8601String(),
    'usageCount': usageCount,
  };

  /// Create Group from Firestore document data
  factory Group.fromFirestore(Map<String, dynamic> data) {
    return Group(
      id: data['id'] as String? ?? const Uuid().v4(),
      name: data['name'] as String? ?? '',
      personIds: List<String>.from(data['personIds'] as List? ?? []),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      lastUsedAt: data['lastUsedAt'] != null
          ? DateTime.parse(data['lastUsedAt'] as String)
          : DateTime.now(),
      imagePath: data['imagePath'] as String?,
      usageCount: data['usageCount'] as int? ?? 0,
    );
  }
}
