import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/router.dart';
import '../providers/onboarding_provider.dart';

class OnboardingNavigationButtons extends ConsumerWidget {
  final PageController pageController;
  final Future<bool> Function()? onValidatePage;

  const OnboardingNavigationButtons({
    super.key,
    required this.pageController,
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
