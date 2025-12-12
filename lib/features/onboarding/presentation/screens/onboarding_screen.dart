import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicksplit/features/auth/presentation/providers/auth_state_provider.dart';

import '../../utils/onboarding_content.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/feature_tutorial_page.dart';
import '../widgets/navigation_buttons.dart';
import '../widgets/page_indicator.dart';
import '../widgets/permissions_page.dart';
import '../widgets/profile_setup_page.dart';
import '../widgets/welcome_page.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;
  final Map<int, GlobalKey> _pageKeys = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Create key for profile page (page 4)
    _pageKeys[4] = GlobalKey();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _validateProfilePage() async {
    final profileKey = _pageKeys[4];
    if (profileKey?.currentState != null) {
      return await (profileKey!.currentState as dynamic).validateAndSave();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    final authState = ref.watch(authStateProvider);
    final isAuthenticated = authState.maybeWhen(
      data: (user) => user != null,
      orElse: () => false,
    );

    final pages = <Widget>[
      const WelcomePage(),
      const FeatureTutorialPage(feature: Feature.ocr),
      const FeatureTutorialPage(feature: Feature.groups),
      const FeatureTutorialPage(feature: Feature.payments),
      if (!isAuthenticated) ProfileSetupPage(key: _pageKeys[4]),
      const PermissionsPage(),
    ];

    // Keep provider's totalPages in sync with the actual pages list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expectedTotalPages = pages.length;
      if (ref.read(onboardingProvider).totalPages != expectedTotalPages) {
        ref
            .read(onboardingProvider.notifier)
            .updateTotalPages(expectedTotalPages);
      }
    });

    // Sync PageController with provider state
    if (_pageController.hasClients) {
      final currentPageInt = _pageController.page?.round() ?? 0;
      if (currentPageInt != state.currentPage) {
        _pageController.animateToPage(
          state.currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // PageView with all pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: pages,
              ),
            ),

            // Page indicator dots
            const OnboardingPageIndicator(),

            // Navigation buttons
            OnboardingNavigationButtons(
              pageController: _pageController,
              isAuthenticated: isAuthenticated,
              onValidatePage: () async {
                final currentPage = ref.read(onboardingProvider).currentPage;
                if (!isAuthenticated && currentPage == 4) {
                  return await _validateProfilePage();
                }
                return true;
              },
            ),
          ],
        ),
      ),
    );
  }
}
