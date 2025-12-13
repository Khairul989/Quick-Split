import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:logger/logger.dart';

import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../data/repositories/firebase_group_repository.dart';
import '../../data/repositories/firebase_person_repository.dart';
import '../../data/services/group_migration_service.dart';
import '../../domain/models/person.dart';
import '../../domain/models/group.dart';
import '../../domain/services/user_discovery_service.dart';

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
/// Implements offline-first pattern: Hive for immediate UI updates, Firestore for cloud sync
class GroupsNotifier extends Notifier<GroupsState> {
  static final _logger = Logger();

  late Box<Group> _groupsBox;
  late Box<Person> _peopleBox;
  late FirebaseGroupRepository _firebaseGroupRepo;
  late FirebasePersonRepository _firebasePersonRepo;
  late UserDiscoveryService _userDiscoveryService;

  @override
  GroupsState build() {
    _groupsBox = Hive.box<Group>('groups');
    _peopleBox = Hive.box<Person>('people');

    // Initialize Firebase repositories and services
    _firebaseGroupRepo = FirebaseGroupRepository(FirebaseFirestore.instance);
    _firebasePersonRepo = FirebasePersonRepository(FirebaseFirestore.instance);
    _userDiscoveryService = UserDiscoveryService(FirebaseFirestore.instance);

    // Subscribe to Firestore streams for real-time updates
    // Only subscribe if user is authenticated
    ref.listen(currentUserProvider, (previous, current) {
      if (current != null) {
        _subscribeToFirestoreUpdates(current.uid);
      }
    });

    return GroupsState(
      groups: _groupsBox.values.toList(),
      people: _peopleBox.values.toList(),
    );
  }

  /// Subscribe to real-time Firestore streams
  /// Updates local Hive cache when Firestore data changes
  void _subscribeToFirestoreUpdates(String userId) {
    _logger.d('Setting up Firestore streams for user: $userId');

    // Trigger one-time migration from Hive to Firestore (if not already done)
    final migrationService = GroupMigrationService(
      _firebaseGroupRepo,
      _firebasePersonRepo,
      Hive,
    );

    migrationService.migrateToFirestore(userId).catchError((error) {
      _logger.w('Group migration failed (non-fatal): $error');
      // Migration failure doesn't prevent app from working
    });

    // Subscribe to groups stream
    _firebaseGroupRepo
        .watchGroups(userId)
        .listen(
          (firebaseGroups) {
            try {
              // Update Hive with Firestore data
              for (final group in firebaseGroups) {
                _groupsBox.put(group.id, group);
              }

              // Remove groups that were deleted in Firestore
              final firebaseIds = firebaseGroups.map((g) => g.id).toSet();
              final hiveIds = _groupsBox.keys.cast<String>().toSet();
              for (final id in hiveIds.difference(firebaseIds)) {
                _groupsBox.delete(id);
              }

              // Update state with synced data
              state = state.copyWith(groups: _groupsBox.values.toList());
              _logger.d(
                'Synced ${firebaseGroups.length} groups from Firestore',
              );
            } catch (e) {
              _logger.e('Error syncing groups from Firestore: $e');
            }
          },
          onError: (error) {
            _logger.w('Error watching groups stream: $error');
            // Continue with local data on stream error
          },
        );

    // Subscribe to people stream
    _firebasePersonRepo
        .watchPeople(userId)
        .listen(
          (firebasePeople) {
            try {
              // Update Hive with Firestore data
              for (final person in firebasePeople) {
                _peopleBox.put(person.id, person);
              }

              // Remove people that were deleted in Firestore
              final firebaseIds = firebasePeople.map((p) => p.id).toSet();
              final hiveIds = _peopleBox.keys.cast<String>().toSet();
              for (final id in hiveIds.difference(firebaseIds)) {
                _peopleBox.delete(id);
              }

              // Update state with synced data
              state = state.copyWith(people: _peopleBox.values.toList());
              _logger.d(
                'Synced ${firebasePeople.length} people from Firestore',
              );
            } catch (e) {
              _logger.e('Error syncing people from Firestore: $e');
            }
          },
          onError: (error) {
            _logger.w('Error watching people stream: $error');
            // Continue with local data on stream error
          },
        );
  }

  /// Get current user ID from auth state
  String? _getCurrentUserId() {
    final authState = ref.read(currentUserProvider);
    return authState?.uid;
  }

  // ===== GROUP OPERATIONS =====

  /// Create a new group with given name and people
  /// Offline-first: saves to Hive immediately, syncs to Firestore in background
  Future<Group> createGroup(
    String name,
    List<Person> people, {
    String? imagePath,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Step 1: Save people to Hive (immediate)
      for (final person in people) {
        if (!_peopleBox.containsKey(person.id)) {
          await _peopleBox.put(person.id, person);
        }
      }

      // Step 2: Create group with person IDs
      final group = Group(
        name: name,
        personIds: people.map((p) => p.id).toList(),
        imagePath: imagePath,
      );

      // Step 3: Save to Hive (immediate UI update)
      await _groupsBox.put(group.id, group);

      // Step 4: Update state immediately
      state = state.copyWith(
        groups: _groupsBox.values.toList(),
        people: _peopleBox.values.toList(),
        isLoading: false,
      );

      // Step 5: Sync to Firestore in background (don't await)
      final userId = _getCurrentUserId();
      if (userId != null) {
        _syncCreateGroupToFirebase(userId, group, people).catchError((e) {
          _logger.w('Failed to sync group to Firestore: $e');
          // Don't fail the operation - offline mode gracefully degraded
        });
      }

      return group;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create group: $e',
      );
      rethrow;
    }
  }

  /// Background sync: upload group and members to Firestore
  Future<void> _syncCreateGroupToFirebase(
    String userId,
    Group group,
    List<Person> people,
  ) async {
    try {
      // Create group in Firestore
      await _firebaseGroupRepo.createGroup(userId, group);
      _logger.d('Synced group to Firestore: ${group.name}');

      // Add members to group in Firestore
      for (final person in people) {
        await _firebaseGroupRepo.addMember(userId, group.id, person);
      }
      _logger.d('Synced ${people.length} members to Firestore');
    } catch (e) {
      _logger.e('Error syncing group to Firestore: $e');
      rethrow;
    }
  }

  /// Update an existing group
  /// Offline-first: saves to Hive immediately, syncs to Firestore in background
  Future<void> updateGroup(Group group) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Step 1: Update Hive (immediate)
      await _groupsBox.put(group.id, group);

      // Step 2: Update state immediately
      state = state.copyWith(
        groups: _groupsBox.values.toList(),
        isLoading: false,
      );

      // Step 3: Sync to Firestore in background
      final userId = _getCurrentUserId();
      if (userId != null) {
        _firebaseGroupRepo.updateGroup(userId, group).catchError((e) {
          _logger.w('Failed to sync group update to Firestore: $e');
          // Don't fail the operation - offline mode gracefully degraded
        });
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update group: $e',
      );
      rethrow;
    }
  }

  /// Delete a group by ID
  /// Offline-first: deletes from Hive immediately, syncs to Firestore in background
  Future<void> deleteGroup(String groupId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Step 1: Delete from Hive (immediate)
      await _groupsBox.delete(groupId);

      // Step 2: Update state immediately
      state = state.copyWith(
        groups: _groupsBox.values.toList(),
        isLoading: false,
      );

      // Step 3: Sync deletion to Firestore in background
      final userId = _getCurrentUserId();
      if (userId != null) {
        _firebaseGroupRepo.deleteGroup(userId, groupId).catchError((e) {
          _logger.w('Failed to sync group deletion to Firestore: $e');
          // Don't fail the operation - offline mode gracefully degraded
        });
      }
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
  /// Offline-first: saves to Hive immediately, syncs to Firestore in background
  /// Attempts to auto-link to registered user if email/phone provided
  Future<Person> createPerson(
    String name,
    String emoji, {
    String? email,
    String? phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      var person = Person(
        name: name,
        emoji: emoji,
        email: email,
        phoneNumber: phone,
      );

      // Step 1: Try to link to registered user (async, don't block)
      _attemptAutoLink(person)
          .then((linkedPerson) {
            if (linkedPerson != null && linkedPerson.linkedUserId != null) {
              person = linkedPerson;
              _peopleBox.put(person.id, person);
              state = state.copyWith(people: _peopleBox.values.toList());

              // Sync updated person to Firestore
              final userId = _getCurrentUserId();
              if (userId != null) {
                _firebasePersonRepo.updatePerson(userId, person).catchError((
                  e,
                ) {
                  _logger.w('Failed to sync linked person to Firestore: $e');
                });
              }

              _logger.d('Auto-linked person ${person.name} to registered user');
            }
          })
          .catchError((e) {
            _logger.w('Auto-linking failed (non-fatal): $e');
          });

      // Step 2: Save to Hive (immediate)
      await _peopleBox.put(person.id, person);

      // Step 3: Update state immediately
      state = state.copyWith(
        people: _peopleBox.values.toList(),
        isLoading: false,
      );

      // Step 4: Sync to Firestore in background
      final userId = _getCurrentUserId();
      if (userId != null) {
        _firebasePersonRepo.createPerson(userId, person).catchError((e) {
          _logger.w('Failed to sync person to Firestore: $e');
          // Don't fail the operation - offline mode gracefully degraded
          return person;
        });
      }

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
  /// Offline-first: saves to Hive immediately, syncs to Firestore in background
  /// Re-attempts auto-link if email/phone changed and link was previously missing
  Future<void> updatePerson(Person person) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      var updatedPerson = person;

      // Step 1: Check if we should re-attempt linking (if email/phone changed or not yet linked)
      if (!updatedPerson.isRegisteredUser &&
          (updatedPerson.email != null || updatedPerson.phoneNumber != null)) {
        final linkedPerson = await _attemptAutoLink(updatedPerson);
        if (linkedPerson != null && linkedPerson.linkedUserId != null) {
          updatedPerson = linkedPerson;
          _logger.d(
            'Auto-linked person ${updatedPerson.name} to registered user during update',
          );
        }
      }

      // Step 2: Update Hive (immediate)
      await _peopleBox.put(updatedPerson.id, updatedPerson);

      // Step 3: Update state immediately
      state = state.copyWith(
        people: _peopleBox.values.toList(),
        isLoading: false,
      );

      // Step 4: Sync to Firestore in background
      final userId = _getCurrentUserId();
      if (userId != null) {
        _firebasePersonRepo.updatePerson(userId, updatedPerson).catchError((e) {
          _logger.w('Failed to sync person update to Firestore: $e');
          // Don't fail the operation - offline mode gracefully degraded
        });
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update person: $e',
      );
      rethrow;
    }
  }

  /// Delete a person by ID
  /// Offline-first: deletes from Hive immediately, syncs to Firestore in background
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

      // Step 1: Delete from Hive (immediate)
      await _peopleBox.delete(personId);

      // Step 2: Update state immediately
      state = state.copyWith(
        people: _peopleBox.values.toList(),
        isLoading: false,
      );

      // Step 3: Sync deletion to Firestore in background
      final userId = _getCurrentUserId();
      if (userId != null) {
        _firebasePersonRepo.deletePerson(userId, personId).catchError((e) {
          _logger.w('Failed to sync person deletion to Firestore: $e');
          // Don't fail the operation - offline mode gracefully degraded
        });
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete person: $e',
      );
      rethrow;
    }
  }

  // ===== HELPER METHODS =====

  /// Attempt to auto-link a person to a registered user
  /// Returns the person with linkedUserId and linkedAt set if match found
  /// Returns the original person if no match found or error occurs
  Future<Person?> _attemptAutoLink(Person person) async {
    try {
      final userId = await _userDiscoveryService.findByEmailOrPhone(
        person.email,
        person.phoneNumber,
      );

      if (userId != null && userId.isNotEmpty) {
        return person.copyWith(linkedUserId: userId, linkedAt: DateTime.now());
      }

      return person;
    } catch (e) {
      _logger.w('Error during auto-linking: $e');
      return person;
    }
  }

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

  /// Increment usage count for a person
  /// Offline-first: updates Hive immediately, syncs to Firestore in background
  Future<void> incrementPersonUsage(String personId) async {
    try {
      final person = state.people.firstWhere(
        (p) => p.id == personId,
        orElse: () => throw Exception('Person not found'),
      );

      final updated = person.copyWith(
        usageCount: person.usageCount + 1,
        lastUsedAt: DateTime.now(),
      );

      // Step 1: Update Hive (immediate)
      await _peopleBox.put(personId, updated);

      // Step 2: Update state immediately
      state = state.copyWith(people: _peopleBox.values.toList());

      // Step 3: Sync to Firestore in background
      final userId = _getCurrentUserId();
      if (userId != null) {
        _firebasePersonRepo.updatePerson(userId, updated).catchError((e) {
          _logger.w('Failed to sync person usage update to Firestore: $e');
          // Don't fail the operation - offline mode gracefully degraded
        });
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update person usage: $e');
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
