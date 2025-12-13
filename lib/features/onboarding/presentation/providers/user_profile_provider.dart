import 'package:riverpod/riverpod.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/onboarding_repository.dart';

/// Notifier for managing user profile
class UserProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    final repository = ref.read(onboardingRepositoryProvider);
    return repository.getUserProfile();
  }

  /// Save user profile with provided data
  Future<bool> saveProfile({
    required String name,
    String? email,
    String? emoji,
    String? phoneNumber,
  }) async {
    try {
      final now = DateTime.now();
      final profile = UserProfile(
        name: name,
        email: email,
        emoji: emoji ?? '😊',
        createdAt: now,
        phoneNumber: phoneNumber,
        updatedAt: now,
      );

      final repository = ref.read(onboardingRepositoryProvider);
      final success = await repository.saveUserProfile(profile);

      if (success) {
        state = profile;
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  /// Update existing user profile
  Future<bool> updateProfile(UserProfile profile) async {
    try {
      final repository = ref.read(onboardingRepositoryProvider);
      final success = await repository.saveUserProfile(profile);

      if (success) {
        state = profile;
      }

      return success;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for user profile state
final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);
