import 'package:hive_ce/hive.dart';
import 'package:logger/logger.dart';

import '../../domain/models/group.dart';
import '../../domain/models/person.dart';
import '../repositories/firebase_group_repository.dart';
import '../repositories/firebase_person_repository.dart';

class GroupMigrationService {
  static final _logger = Logger();

  static const String _migrationFlagKey = 'hasCompletedGroupMigration';

  final FirebaseGroupRepository _firebaseGroupRepo;
  final FirebasePersonRepository _firebasePersonRepo;
  final HiveInterface _hive;

  GroupMigrationService(
    this._firebaseGroupRepo,
    this._firebasePersonRepo,
    this._hive,
  );

  /// Check if migration has already been completed
  Future<bool> isMigrationComplete() async {
    try {
      final preferencesBox = _hive.box('preferences');
      return preferencesBox.get(_migrationFlagKey, defaultValue: false) == true;
    } catch (e) {
      _logger.w('Error checking migration status: $e');
      return false;
    }
  }

  /// Migrate all local groups and people to Firestore
  /// Preserves existing UUIDs and data
  /// Only proceeds if migration hasn't been done before
  Future<void> migrateToFirestore(String userId) async {
    try {
      // Check if already migrated
      if (await isMigrationComplete()) {
        _logger.i('Migration already completed, skipping');
        return;
      }

      _logger.i('Starting group migration to Firestore');

      // Load all local groups
      final groupsBox = _hive.box<Group>('groups');
      final localGroups = groupsBox.values.toList();

      // Load all local people
      final peopleBox = _hive.box<Person>('people');
      final localPeople = peopleBox.values.toList();

      _logger.i(
        'Found ${localGroups.length} groups and ${localPeople.length} people to migrate',
      );

      // Step 1: Upload all groups
      for (final group in localGroups) {
        try {
          await _firebaseGroupRepo.createGroup(userId, group);
          _logger.d('Migrated group: ${group.name} (${group.id})');
        } catch (e) {
          _logger.e('Error migrating group ${group.name}: $e');
          // Continue with other groups instead of failing completely
        }
      }

      // Step 2: Upload group members (as subcollections)
      for (final group in localGroups) {
        try {
          final members = localPeople
              .where((p) => group.personIds.contains(p.id))
              .toList();

          for (final member in members) {
            try {
              await _firebaseGroupRepo.addMember(userId, group.id, member);
              _logger.d(
                'Migrated member: ${member.name} to group ${group.name}',
              );
            } catch (e) {
              _logger.e('Error migrating member ${member.name}: $e');
            }
          }
        } catch (e) {
          _logger.e('Error migrating members for group ${group.id}: $e');
        }
      }

      // Step 3: Upload global people (not in any group)
      final globalPeople = localPeople
          .where((p) => !localGroups.any((g) => g.personIds.contains(p.id)))
          .toList();

      for (final person in globalPeople) {
        try {
          await _firebasePersonRepo.createPerson(userId, person);
          _logger.d('Migrated global person: ${person.name} (${person.id})');
        } catch (e) {
          _logger.e('Error migrating global person ${person.name}: $e');
        }
      }

      // Step 4: Mark migration as complete
      await _setMigrationComplete();

      _logger.i(
        'Migration complete: ${localGroups.length} groups, '
        '${localPeople.length} people',
      );
    } catch (e) {
      _logger.e('Migration failed: $e');
      // Don't mark as complete, will retry on next app launch
      rethrow;
    }
  }

  /// Mark migration as complete
  Future<void> _setMigrationComplete() async {
    try {
      final preferencesBox = _hive.box('preferences');
      await preferencesBox.put(_migrationFlagKey, true);
      _logger.i('Migration flag set to complete');
    } catch (e) {
      _logger.e('Error setting migration flag: $e');
      rethrow;
    }
  }

  /// Reset migration flag (for testing or re-migration)
  /// WARNING: Use with caution - will cause re-migration on next app launch
  Future<void> resetMigrationFlag() async {
    try {
      final preferencesBox = _hive.box('preferences');
      await preferencesBox.put(_migrationFlagKey, false);
      _logger.w(
        'Migration flag reset - migration will run again on next launch',
      );
    } catch (e) {
      _logger.e('Error resetting migration flag: $e');
      rethrow;
    }
  }
}
