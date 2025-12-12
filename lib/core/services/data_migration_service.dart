import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:quicksplit/features/auth/data/repositories/user_profile_repository.dart';
import 'package:quicksplit/features/onboarding/data/models/user_profile.dart';

class DataMigrationService {
  final UserProfileRepository _profileRepository;

  DataMigrationService(this._profileRepository);

  /// Migrate local Hive profile to Firestore for first-time authenticated user
  Future<void> migrateLocalProfileToFirestore(String userId) async {
    try {
      final preferencesBox = Hive.box('preferences');

      // Check if local profile exists
      if (!preferencesBox.containsKey('userProfile')) {
        debugPrint('DataMigration: No local profile found to migrate');
        return;
      }

      // Get local profile from Hive
      final localProfileJson =
          preferencesBox.get('userProfile') as Map<dynamic, dynamic>?;
      if (localProfileJson == null) {
        debugPrint('DataMigration: Local profile is null');
        return;
      }

      // Convert to UserProfile
      final localProfile = UserProfile.fromJson(
        Map<String, dynamic>.from(localProfileJson),
      );

      debugPrint(
        'DataMigration: Found local profile - ${localProfile.name} (${localProfile.emoji})',
      );

      // Check if cloud profile already exists (cloud only, not local cache)
      final cloudProfileExists = await _profileRepository.cloudProfileExists(
        userId,
      );

      if (cloudProfileExists) {
        // Cloud profile exists - prefer cloud data but log the merge
        debugPrint(
          'DataMigration: Cloud profile exists, skipping migration (preferring cloud data)',
        );
        return;
      }

      // Save local profile to Firestore
      await _profileRepository.saveUserProfile(userId, localProfile);
      debugPrint('DataMigration: Successfully migrated profile to Firestore');

      // Optionally: Mark migration as completed in preferences
      await preferencesBox.put('hasCompletedProfileMigration', true);
    } catch (e) {
      debugPrint('DataMigration: Error during profile migration - $e');
      // Don't rethrow - migration failure shouldn't block authentication
    }
  }

  /// Check if local profile exists in Hive
  bool hasLocalProfile() {
    try {
      final preferencesBox = Hive.box('preferences');
      return preferencesBox.containsKey('userProfile');
    } catch (e) {
      debugPrint('DataMigration: Error checking local profile - $e');
      return false;
    }
  }

  /// Get local profile from Hive
  UserProfile? getLocalProfile() {
    try {
      final preferencesBox = Hive.box('preferences');

      if (!preferencesBox.containsKey('userProfile')) {
        return null;
      }

      final profileJson =
          preferencesBox.get('userProfile') as Map<dynamic, dynamic>?;
      if (profileJson == null) {
        return null;
      }

      return UserProfile.fromJson(Map<String, dynamic>.from(profileJson));
    } catch (e) {
      debugPrint('DataMigration: Error getting local profile - $e');
      return null;
    }
  }
}
