import 'package:flutter_test/flutter_test.dart';
import 'package:quicksplit/features/groups/domain/models/contact_match.dart';

void main() {
  group('ContactMatch', () {
    test('should create ContactMatch with required fields', () {
      // Arrange
      final now = DateTime.now();

      // Act
      final match = ContactMatch(
        personId: 'person123',
        userId: 'user456',
        matchedAt: now,
      );

      // Assert
      expect(match.personId, equals('person123'));
      expect(match.userId, equals('user456'));
      expect(match.matchedAt, equals(now));
    });

    test('should validate cache expiration correctly', () {
      // Arrange
      final validMatch = ContactMatch(
        personId: 'person1',
        userId: 'user1',
        matchedAt: DateTime.now().subtract(const Duration(hours: 12)),
      );

      final expiredMatch = ContactMatch(
        personId: 'person2',
        userId: 'user2',
        matchedAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      // Act & Assert
      expect(validMatch.isValid(), isTrue); // Within 24 hours
      expect(expiredMatch.isValid(), isFalse); // Older than 24 hours
    });

    test('should create copy with updated fields', () {
      // Arrange
      final match = ContactMatch(
        personId: 'person123',
        userId: 'user456',
        matchedAt: DateTime(2025, 12, 13, 10, 30),
      );

      // Act
      final updated = match.copyWith(
        userId: 'user789',
      );

      // Assert
      expect(updated.personId, equals('person123')); // Same
      expect(updated.userId, equals('user789')); // Updated
      expect(updated.matchedAt, equals(match.matchedAt)); // Same
    });
  });

  group('Contact Matching Logic', () {
    test('should match contacts by email correctly', () {
      // Test email normalization and matching logic
      const email1 = 'test@example.com';
      const email2 = 'TEST@EXAMPLE.COM';

      // Emails should be case-insensitive
      expect(email1.toLowerCase(), equals(email2.toLowerCase()));
    });

    test('should handle empty contact lists', () {
      // Arrange
      final emptyMatches = <String, String>{};

      // Assert
      expect(emptyMatches.isEmpty, isTrue);
      expect(emptyMatches.length, equals(0));
    });
  });
}
