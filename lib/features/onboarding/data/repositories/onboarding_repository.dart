import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:riverpod/riverpod.dart';

import '../models/user_profile.dart';

class OnboardingRepository {
  static const String _hasCompletedOnboardingKey = 'hasCompletedOnboarding';
  static const String _userProfileKey = 'userProfile';

  final Box<dynamic> _preferencesBox;

  OnboardingRepository(this._preferencesBox);

  /// Check if user has completed onboarding
  bool hasCompletedOnboarding() {
    try {
      return _preferencesBox.get(
            _hasCompletedOnboardingKey,
            defaultValue: false,
          )
          as bool;
    } catch (e) {
      return false;
    }
  }

  /// Mark onboarding as complete
  Future<void> markOnboardingComplete() async {
    try {
      await _preferencesBox.put(_hasCompletedOnboardingKey, true);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user profile from storage
  UserProfile? getUserProfile() {
    try {
      final profileData = _preferencesBox.get(_userProfileKey);
      if (profileData == null) return null;

      if (profileData is Map) {
        final jsonMap = Map<String, dynamic>.from(profileData);
        return UserProfile.fromJson(jsonMap);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save user profile to storage
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      await _preferencesBox.put(_userProfileKey, profile.toJson());
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Riverpod provider for OnboardingRepository
final onboardingRepositoryProvider = Provider((ref) {
  final preferencesBox = Hive.box<dynamic>('preferences');
  return OnboardingRepository(preferencesBox);
});
