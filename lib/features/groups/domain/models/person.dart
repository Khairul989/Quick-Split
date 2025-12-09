import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

part 'person.g.dart';

@HiveType(typeId: 2)
class Person extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String emoji;

  @HiveField(3)
  final DateTime createdAt;

  Person({
    String? id,
    required this.name,
    required this.emoji,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Person copyWith({String? name, String? emoji}) {
    return Person(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt,
    );
  }
}
