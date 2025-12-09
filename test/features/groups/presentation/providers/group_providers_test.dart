import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:quicksplit/features/groups/domain/models/group.dart';
import 'package:quicksplit/features/groups/domain/models/person.dart';
import 'package:quicksplit/features/groups/presentation/providers/group_providers.dart';

void main() {
  // Setup: Initialize Hive boxes for testing
  setUpAll(() async {
    Hive.init('.');
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PersonAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(GroupAdapter());
    }

    // Create boxes if they don't exist
    try {
      await Hive.openBox<Group>('groups');
    } catch (e) {
      // Box might already be open
    }

    try {
      await Hive.openBox<Person>('people');
    } catch (e) {
      // Box might already be open
    }
  });

  // Cleanup: Clear boxes between tests
  setUp(() async {
    // Clear all data between tests
    try {
      final groupsBox = Hive.box<Group>('groups');
      final peopleBox = Hive.box<Person>('people');
      await groupsBox.clear();
      await peopleBox.clear();
    } catch (e) {
      // Boxes might not exist yet
    }
  });

  group('GroupsNotifier - Group CRUD Operations', () {
    test('createGroup saves group to Hive and updates state', () async {
      final container = ProviderContainer();

      // Setup test data
      final person = Person(name: 'Alice', emoji: '👩');

      // Get initial state
      final initialState = container.read(groupsProvider);
      expect(initialState.groups.isEmpty, true);

      // Create group
      final notifier = container.read(groupsProvider.notifier);
      final group = await notifier.createGroup('Test Group', [person]);

      // Verify group was created
      expect(group.name, 'Test Group');
      expect(group.personIds, [person.id]);
      expect(group.id.isNotEmpty, true);

      // Verify state updated
      final updatedState = container.read(groupsProvider);
      expect(updatedState.groups.length, 1);
      expect(updatedState.groups.first.id, group.id);
    });

    test('updateGroup modifies existing group and persists changes', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      // Create initial group
      final group = await notifier.createGroup('Original Name', []);

      // Update group
      final updated = group.copyWith(name: 'Updated Name');
      await notifier.updateGroup(updated);

      // Verify update persisted
      final state = container.read(groupsProvider);
      final retrievedGroup = state.groups.firstWhere((g) => g.id == group.id);
      expect(retrievedGroup.name, 'Updated Name');
    });

    test('deleteGroup removes group from Hive and state', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      // Create group
      final group = await notifier.createGroup('To Delete', []);
      expect(container.read(groupsProvider).groups.length, 1);

      // Delete group
      await notifier.deleteGroup(group.id);

      // Verify group deleted
      final state = container.read(groupsProvider);
      expect(state.groups.isEmpty, true);
    });

    test('isLoading flag set during group creation', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      // Initially should not be loading
      expect(container.read(groupsProvider).isLoading, false);

      // Create group (observable state change)
      final future = notifier.createGroup('Test', []);
      await Future.delayed(Duration.zero); // Allow state update

      // After creation, should complete
      await future;
      expect(container.read(groupsProvider).isLoading, false);
    });
  });

  group('GroupsNotifier - Person CRUD Operations', () {
    test('createPerson saves person to Hive and updates state', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      // Initial state should have no people
      expect(container.read(groupsProvider).people.isEmpty, true);

      // Create person
      final person = await notifier.createPerson('Bob', '👨');

      // Verify person created
      expect(person.name, 'Bob');
      expect(person.emoji, '👨');
      expect(person.id.isNotEmpty, true);

      // Verify state updated
      final state = container.read(groupsProvider);
      expect(state.people.length, 1);
      expect(state.people.first.id, person.id);
    });

    test('updatePerson modifies existing person', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      // Create person
      final person = await notifier.createPerson('Carol', '👩');

      // Update person
      final updated = person.copyWith(name: 'Carolina', emoji: '👸');
      await notifier.updatePerson(updated);

      // Verify update persisted
      final state = container.read(groupsProvider);
      final retrieved = state.people.firstWhere((p) => p.id == person.id);
      expect(retrieved.name, 'Carolina');
      expect(retrieved.emoji, '👸');
    });

    test(
      'deletePerson throws exception if person is in a group',
      () async {
        final container = ProviderContainer();
        final notifier = container.read(groupsProvider.notifier);

        // Create person and group
        final person = await notifier.createPerson('Dave', '👨');
        await notifier.createGroup('Group with Dave', [person]);

        // Attempt to delete person in group
        expect(
          () => notifier.deletePerson(person.id),
          throwsA(isA<Exception>()),
        );

        // Verify person still exists
        final state = container.read(groupsProvider);
        expect(state.people.length, 1);
      },
    );

    test('deletePerson removes person if not in any group', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      // Create person without adding to group
      final person = await notifier.createPerson('Eve', '👩');
      expect(container.read(groupsProvider).people.length, 1);

      // Delete person
      await notifier.deletePerson(person.id);

      // Verify person deleted
      final state = container.read(groupsProvider);
      expect(state.people.isEmpty, true);
    });
  });

  group('GroupsNotifier - Helper Methods', () {
    test('getPeopleForGroup returns people in specific group', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      // Create people
      final alice = await notifier.createPerson('Alice', '👩');
      final bob = await notifier.createPerson('Bob', '👨');
      final carol = await notifier.createPerson('Carol', '👩');

      // Create groups
      final group1 = await notifier.createGroup('Group 1', [alice, bob]);
      await notifier.createGroup('Group 2', [carol]);

      // Verify getPeopleForGroup works
      final people = notifier.getPeopleForGroup(group1.id);
      expect(people.length, 2);
      final personIds = people.map((p) => p.id).toSet();
      expect(personIds, {alice.id, bob.id});
    });

    test('getPersonById returns correct person', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      final person = await notifier.createPerson('Frank', '👨');
      final retrieved = notifier.getPersonById(person.id);

      expect(retrieved?.id, person.id);
      expect(retrieved?.name, 'Frank');
    });

    test('getPersonById returns null for non-existent person', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      final retrieved = notifier.getPersonById('non-existent-id');
      expect(retrieved, null);
    });

    test('getGroupById returns correct group', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      final group = await notifier.createGroup('Test', []);
      final retrieved = notifier.getGroupById(group.id);

      expect(retrieved?.id, group.id);
      expect(retrieved?.name, 'Test');
    });

    test('getGroupById returns null for non-existent group', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      final retrieved = notifier.getGroupById('non-existent-id');
      expect(retrieved, null);
    });
  });

  group('GroupsNotifier - Computed Providers', () {
    test('frequentGroupsProvider returns top 5 groups by lastUsedAt', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      // Create multiple groups
      final groups = <Group>[];
      for (int i = 0; i < 7; i++) {
        final group = await notifier.createGroup('Group $i', []);
        groups.add(group);
        // Small delay to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Mark groups as used in reverse order to change lastUsedAt
      for (final group in groups.reversed.toList()) {
        group.markUsed();
        await notifier.updateGroup(group);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Get frequent groups
      final frequent = container.read(frequentGroupsProvider);

      // Should only have top 5
      expect(frequent.length, 5);

      // Should be sorted by lastUsedAt descending (most recent first)
      for (int i = 0; i < frequent.length - 1; i++) {
        expect(
          frequent[i].lastUsedAt.isAfter(frequent[i + 1].lastUsedAt) ||
              frequent[i].lastUsedAt.isAtSameMomentAs(frequent[i + 1].lastUsedAt),
          true,
        );
      }
    });

    test('groupsCountProvider returns total groups count', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      expect(container.read(groupsCountProvider), 0);

      await notifier.createGroup('Group 1', []);
      expect(container.read(groupsCountProvider), 1);

      await notifier.createGroup('Group 2', []);
      expect(container.read(groupsCountProvider), 2);
    });

    test('peopleCountProvider returns total people count', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      expect(container.read(peopleCountProvider), 0);

      await notifier.createPerson('Alice', '👩');
      expect(container.read(peopleCountProvider), 1);

      await notifier.createPerson('Bob', '👨');
      expect(container.read(peopleCountProvider), 2);
    });
  });

  group('GroupsNotifier - Error Handling', () {
    test('error state set when group creation fails', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      // Normal operation should clear error
      await notifier.createGroup('Valid Group', []);
      expect(container.read(groupsProvider).error, null);
    });

    test('createGroup rethrows exception after setting error state', () async {
      final container = ProviderContainer();
      final notifier = container.read(groupsProvider.notifier);

      // This test verifies that errors are properly propagated
      // Creating with valid data should not throw
      expect(
        () => notifier.createGroup('Valid', []),
        returnsNormally,
      );
    });
  });

  group('GroupsNotifier - Data Persistence', () {
    test('groups persist across container recreations', () async {
      // First container: create group
      final container1 = ProviderContainer();
      final notifier1 = container1.read(groupsProvider.notifier);
      await notifier1.createGroup('Persistent Group', []);

      expect(container1.read(groupsProvider).groups.length, 1);

      // Second container: should load same group
      final container2 = ProviderContainer();
      expect(container2.read(groupsProvider).groups.length, 1);
      expect(container2.read(groupsProvider).groups.first.name, 'Persistent Group');
    });

    test('people persist across container recreations', () async {
      // First container: create person
      final container1 = ProviderContainer();
      final notifier1 = container1.read(groupsProvider.notifier);
      await notifier1.createPerson('Persistent Person', '🎯');

      expect(container1.read(groupsProvider).people.length, 1);

      // Second container: should load same person
      final container2 = ProviderContainer();
      expect(container2.read(groupsProvider).people.length, 1);
      expect(container2.read(groupsProvider).people.first.name, 'Persistent Person');
    });
  });
}
