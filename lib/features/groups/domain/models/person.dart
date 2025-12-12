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

  @HiveField(4)
  String? phoneNumber;

  @HiveField(5)
  String? email;

  @HiveField(6)
  String? contactId;

  @HiveField(7)
  int usageCount;

  @HiveField(8)
  DateTime? lastUsedAt;

  Person({
    String? id,
    required this.name,
    required this.emoji,
    DateTime? createdAt,
    this.phoneNumber,
    this.email,
    this.contactId,
    this.usageCount = 0,
    this.lastUsedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Person copyWith({
    String? name,
    String? emoji,
    String? phoneNumber,
    String? email,
    String? contactId,
    int? usageCount,
    DateTime? lastUsedAt,
  }) {
    return Person(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      contactId: contactId ?? this.contactId,
      usageCount: usageCount ?? this.usageCount,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  /// Check if this person was imported from device contacts
  bool get isFromContacts => contactId != null;

  /// Format phone number for display (handles null and formatting)
  String? get formattedPhone {
    if (phoneNumber == null) return null;
    final clean = phoneNumber!.replaceAll(RegExp(r'[^\d+\-\s]'), '');
    if (clean.isEmpty) return null;
    return clean;
  }
}
