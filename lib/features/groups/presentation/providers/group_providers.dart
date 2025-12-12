import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import '../../domain/models/person.dart';
import '../../domain/models/group.dart';

/// State class for groups feature
class GroupsState {
  final List<Group> groups;
  final List<Person> people;
  final bool isLoading;
  final String? error;

  const GroupsState({
    required this.groups,
    required this.people,
    this.isLoading = false,
    this.error,
  });

  GroupsState copyWith({
    List<Group>? groups,
    List<Person>? people,
    bool? isLoading,
    String? error,
  }) {
    return GroupsState(
      groups: groups ?? this.groups,
      people: people ?? this.people,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing groups and people
class GroupsNotifier extends Notifier<GroupsState> {
  late Box<Group> _groupsBox;
  late Box<Person> _peopleBox;

  @override
  GroupsState build() {
    _groupsBox = Hive.box<Group>('groups');
    _peopleBox = Hive.box<Person>('people');

    return GroupsState(
      groups: _groupsBox.values.toList(),
      people: _peopleBox.values.toList(),
    );
  }

  // ===== GROUP OPERATIONS =====

  /// Create a new group with given name and people
  Future<Group> createGroup(String name, List<Person> people, {String? imagePath}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Save each person to people box if they don't already exist
      for (final person in people) {
        if (!_peopleBox.containsKey(person.id)) {
          await _peopleBox.put(person.id, person);
        }
      }

      // Create group with person IDs
      final group = Group(
        name: name,
        personIds: people.map((p) => p.id).toList(),
        imagePath: imagePath,
      );

      // Save to Hive
      await _groupsBox.put(group.id, group);

      // Update state with both groups and people
      state = state.copyWith(
        groups: _groupsBox.values.toList(),
        people: _peopleBox.values.toList(),
        isLoading: false,
      );

      return group;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create group: $e',
      );
      rethrow;
    }
  }

  /// Update an existing group
  Future<void> updateGroup(Group group) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _groupsBox.put(group.id, group);

      state = state.copyWith(
        groups: _groupsBox.values.toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update group: $e',
      );
      rethrow;
    }
  }

  /// Delete a group by ID
  Future<void> deleteGroup(String groupId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _groupsBox.delete(groupId);

      state = state.copyWith(
        groups: _groupsBox.values.toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete group: $e',
      );
      rethrow;
    }
  }

  // ===== PERSON OPERATIONS =====

  /// Create a new person with name and emoji
  Future<Person> createPerson(String name, String emoji) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final person = Person(
        name: name,
        emoji: emoji,
      );

      await _peopleBox.put(person.id, person);

      state = state.copyWith(
        people: _peopleBox.values.toList(),
        isLoading: false,
      );

      return person;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create person: $e',
      );
      rethrow;
    }
  }

  /// Update an existing person
  Future<void> updatePerson(Person person) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _peopleBox.put(person.id, person);

      state = state.copyWith(
        people: _peopleBox.values.toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update person: $e',
      );
      rethrow;
    }
  }

  /// Delete a person by ID
  Future<void> deletePerson(String personId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check if person is used in any group
      final groupsUsingPerson = state.groups
          .where((group) => group.personIds.contains(personId))
          .toList();

      if (groupsUsingPerson.isNotEmpty) {
        throw Exception(
          'Cannot delete person: used in ${groupsUsingPerson.length} group(s)',
        );
      }

      await _peopleBox.delete(personId);

      state = state.copyWith(
        people: _peopleBox.values.toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete person: $e',
      );
      rethrow;
    }
  }

  // ===== HELPER METHODS =====

  /// Get all people for a specific group
  List<Person> getPeopleForGroup(String groupId) {
    final group = state.groups.firstWhere(
      (g) => g.id == groupId,
      orElse: () => throw Exception('Group not found'),
    );

    return state.people
        .where((person) => group.personIds.contains(person.id))
        .toList();
  }

  /// Get person by ID
  Person? getPersonById(String personId) {
    try {
      return state.people.firstWhere((p) => p.id == personId);
    } catch (e) {
      return null;
    }
  }

  /// Get group by ID
  Group? getGroupById(String groupId) {
    try {
      return state.groups.firstWhere((g) => g.id == groupId);
    } catch (e) {
      return null;
    }
  }
}

/// Main provider for groups state
final groupsProvider = NotifierProvider<GroupsNotifier, GroupsState>(
  GroupsNotifier.new,
);

/// Computed provider: Frequent groups (sorted by lastUsedAt descending)
final frequentGroupsProvider = Provider<List<Group>>((ref) {
  final groups = ref.watch(groupsProvider).groups;
  final sorted = [...groups];
  sorted.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
  return sorted.take(5).toList(); // Top 5 frequent groups
});

/// Computed provider: Total groups count
final groupsCountProvider = Provider<int>((ref) {
  return ref.watch(groupsProvider).groups.length;
});

/// Computed provider: Total people count
final peopleCountProvider = Provider<int>((ref) {
  return ref.watch(groupsProvider).people.length;
});
