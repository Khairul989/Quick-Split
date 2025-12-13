import 'package:flutter_test/flutter_test.dart';
import 'package:quicksplit/features/groups/domain/models/group.dart';
import 'package:quicksplit/features/groups/domain/models/person.dart';

void main() {
  group('Group Model', () {
    test('should create Group with required fields', () {
      // Arrange
      final now = DateTime.now();

      // Act
      final group = Group(
        id: 'group123',
        name: 'Test Group',
        personIds: ['person1', 'person2'],
        createdAt: now,
        lastUsedAt: now,
        usageCount: 0,
      );

      // Assert
      expect(group.id, equals('group123'));
      expect(group.name, equals('Test Group'));
      expect(group.personIds.length, equals(2));
      expect(group.usageCount, equals(0));
    });

    test('should convert Group to and from Firestore format', () {
      // Arrange
      final group = Group(
        id: 'group456',
        name: 'Family Budget',
        personIds: ['person1', 'person2', 'person3'],
        createdAt: DateTime(2025, 12, 13),
        lastUsedAt: DateTime(2025, 12, 13, 10, 30),
        usageCount: 5,
      );

      // Act
      final firestoreData = group.toFirestore();
      firestoreData['id'] = group.id; // Add ID to data
      final reconstructed = Group.fromFirestore(firestoreData);

      // Assert
      expect(reconstructed.id, equals(group.id));
      expect(reconstructed.name, equals(group.name));
      expect(reconstructed.personIds, equals(group.personIds));
      expect(reconstructed.usageCount, equals(group.usageCount));
    });

    test('should update usage count correctly', () {
      // Arrange
      final group = Group(
        id: 'group789',
        name: 'Office Lunch',
        personIds: [],
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
        usageCount: 0,
      );

      // Act
      group.usageCount = 1;
      group.usageCount = 2;

      // Assert
      expect(group.usageCount, equals(2));
    });
  });

  group('Person Model', () {
    test('should create Person with required fields', () {
      // Act
      final person = Person(
        id: 'person123',
        name: 'John Doe',
        phoneNumber: '+60123456789',
        emoji: '👤',
      );

      // Assert
      expect(person.id, equals('person123'));
      expect(person.name, equals('John Doe'));
      expect(person.phoneNumber, equals('+60123456789'));
      expect(person.emoji, equals('👤'));
    });

    test('should convert Person to and from Firestore format', () {
      // Arrange
      final person = Person(
        id: 'person456',
        name: 'Jane Smith',
        phoneNumber: '+1234567890',
        emoji: '👩',
        linkedUserId: 'user789',
        linkedAt: DateTime(2025, 12, 13),
      );

      // Act
      final firestoreData = person.toFirestore();
      firestoreData['id'] = person.id; // Add ID to data
      final reconstructed = Person.fromFirestore(firestoreData);

      // Assert
      expect(reconstructed.id, equals(person.id));
      expect(reconstructed.name, equals(person.name));
      expect(reconstructed.phoneNumber, equals(person.phoneNumber));
      expect(reconstructed.linkedUserId, equals(person.linkedUserId));
      expect(reconstructed.isRegisteredUser, isTrue);
    });

    test('should identify registered users correctly', () {
      // Arrange
      final linkedPerson = Person(
        id: 'person1',
        name: 'Linked User',
        emoji: '👤',
        linkedUserId: 'user123',
      );

      final unlinkedPerson = Person(
        id: 'person2',
        name: 'Unlinked User',
        emoji: '👤',
      );

      // Assert
      expect(linkedPerson.isRegisteredUser, isTrue);
      expect(unlinkedPerson.isRegisteredUser, isFalse);
    });
  });
}
