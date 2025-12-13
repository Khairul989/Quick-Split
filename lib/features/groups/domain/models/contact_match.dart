import 'package:hive_ce/hive.dart';

part 'contact_match.g.dart';

@HiveType(typeId: 11)
class ContactMatch extends HiveObject {
  @HiveField(0)
  final String personId;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final DateTime matchedAt;

  ContactMatch({
    required this.personId,
    required this.userId,
    required this.matchedAt,
  });

  /// Check if cache is still valid (not expired)
  /// Default cache duration is 24 hours
  bool isValid({Duration cacheDuration = const Duration(hours: 24)}) {
    final now = DateTime.now();
    return now.difference(matchedAt) < cacheDuration;
  }

  /// Create a copy with updated fields
  ContactMatch copyWith({
    String? personId,
    String? userId,
    DateTime? matchedAt,
  }) {
    return ContactMatch(
      personId: personId ?? this.personId,
      userId: userId ?? this.userId,
      matchedAt: matchedAt ?? this.matchedAt,
    );
  }
}
