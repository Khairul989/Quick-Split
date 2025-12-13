import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../onboarding/data/models/user_profile.dart';

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

  @HiveField(9)
  String? linkedUserId;

  @HiveField(10)
  DateTime? linkedAt;

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
    this.linkedUserId,
    this.linkedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Person copyWith({
    String? name,
    String? emoji,
    String? phoneNumber,
    String? email,
    String? contactId,
    int? usageCount,
    DateTime? lastUsedAt,
    String? linkedUserId,
    DateTime? linkedAt,
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
      linkedUserId: linkedUserId ?? this.linkedUserId,
      linkedAt: linkedAt ?? this.linkedAt,
    );
  }

  /// Check if this person was imported from device contacts
  bool get isFromContacts => contactId != null;

  /// Check if this person is linked to a registered user
  bool get isRegisteredUser => linkedUserId != null;

  /// Format phone number for display (handles null and formatting)
  String? get formattedPhone {
    if (phoneNumber == null) return null;
    final clean = phoneNumber!.replaceAll(RegExp(r'[^\d+\-\s]'), '');
    if (clean.isEmpty) return null;
    return clean;
  }

  /// Convert Person to Firestore format
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'emoji': emoji,
    'phoneNumber': phoneNumber,
    'email': email,
    'contactId': contactId,
    'usageCount': usageCount,
    'lastUsedAt': lastUsedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'linkedUserId': linkedUserId,
    'linkedAt': linkedAt?.toIso8601String(),
  };

  /// Create Person from Firestore document data
  factory Person.fromFirestore(Map<String, dynamic> data) {
    return Person(
      id: data['id'] as String? ?? const Uuid().v4(),
      name: data['name'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '👤',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      phoneNumber: data['phoneNumber'] as String?,
      email: data['email'] as String?,
      contactId: data['contactId'] as String?,
      usageCount: data['usageCount'] as int? ?? 0,
      lastUsedAt: data['lastUsedAt'] != null
          ? DateTime.parse(data['lastUsedAt'] as String)
          : null,
      linkedUserId: data['linkedUserId'] as String?,
      linkedAt: data['linkedAt'] != null
          ? DateTime.parse(data['linkedAt'] as String)
          : null,
    );
  }
}

/// Extension for converting UserProfile to Person
extension PersonFromProfile on UserProfile {
  /// Creates a Person from the current user's profile
  /// Returns null if profile is incomplete (no name)
  Person? toPerson() {
    if (name.trim().isEmpty) return null;

    return Person(
      name: name,
      emoji: emoji,
      phoneNumber: null,
      email: email,
      contactId: null,
      usageCount: 0,
      lastUsedAt: null,
    );
  }
}
