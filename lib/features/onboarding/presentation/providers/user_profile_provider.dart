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
  }) async {
    try {
      final profile = UserProfile(
        name: name,
        email: email,
        emoji: emoji ?? '😊',
        createdAt: DateTime.now(),
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
}

/// Provider for user profile state
final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);
