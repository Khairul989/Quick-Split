import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicksplit/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:quicksplit/features/onboarding/data/models/user_profile.dart';

import '../../../../core/router/router.dart';
import '../providers/onboarding_provider.dart';

class OnboardingNavigationButtons extends ConsumerWidget {
  final PageController pageController;
  final bool isAuthenticated;
  final Future<bool> Function()? onValidatePage;

  const OnboardingNavigationButtons({
    super.key,
    required this.pageController,
    required this.isAuthenticated,
    this.onValidatePage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final isLastPage = state.currentPage == state.totalPages - 1;
    final isFirstPage = state.currentPage == 0;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (hidden on first page)
          if (!isFirstPage)
            TextButton(
              onPressed: state.isLoading
                  ? null
                  : () {
                      ref.read(onboardingProvider.notifier).previousPage();
                      pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
              child: const Text('Back'),
            )
          else
            const SizedBox(width: 80),

          // Next/Finish button
          ElevatedButton(
            onPressed: state.isLoading
                ? null
                : () async {
                    // Validate current page if validator provided
                    if (onValidatePage != null) {
                      final isValid = await onValidatePage!();
                      if (!isValid) return;
                    }

                    if (isLastPage) {
                      // Complete onboarding
                      await ref
                          .read(onboardingProvider.notifier)
                          .completeOnboarding();

                      // If authenticated, create a default profile from auth
                      // provider data and persist it immediately.
                      if (isAuthenticated) {
                        final firebaseUser =
                            firebase_auth.FirebaseAuth.instance.currentUser;
                        if (firebaseUser != null) {
                          final derivedName =
                              firebaseUser.displayName ??
                              (firebaseUser.email?.split('@').first ?? 'User');

                          final profile = UserProfile(
                            name: derivedName,
                            email: firebaseUser.email,
                            emoji: '👤',
                            createdAt: DateTime.now(),
                          );

                          // Saves to Firestore and also caches to Hive
                          // (UserProfileRepository.saveUserProfile does both).
                          await ref
                              .read(userProfileRepositoryProvider)
                              .saveUserProfile(firebaseUser.uid, profile);
                        }
                      }

                      if (context.mounted) {
                        context.go('/${RouteNames.home}');
                      }
                    } else {
                      // Go to next page
                      ref.read(onboardingProvider.notifier).nextPage();
                      pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF248CFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: state.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(isLastPage ? 'Finish' : 'Next'),
          ),
        ],
      ),
    );
  }
}
