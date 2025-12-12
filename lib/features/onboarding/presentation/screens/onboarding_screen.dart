import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/welcome_page.dart';
import '../widgets/feature_tutorial_page.dart';
import '../widgets/profile_setup_page.dart';
import '../widgets/permissions_page.dart';
import '../widgets/page_indicator.dart';
import '../widgets/navigation_buttons.dart';
import '../../utils/onboarding_content.dart';

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
                children: [
                  const WelcomePage(),
                  const FeatureTutorialPage(feature: Feature.ocr),
                  const FeatureTutorialPage(feature: Feature.groups),
                  const FeatureTutorialPage(feature: Feature.payments),
                  ProfileSetupPage(key: _pageKeys[4]),
                  const PermissionsPage(),
                ],
              ),
            ),

            // Page indicator dots
            const OnboardingPageIndicator(),

            // Navigation buttons
            OnboardingNavigationButtons(
              pageController: _pageController,
              onValidatePage: () async {
                final currentPage = ref.read(onboardingProvider).currentPage;
                if (currentPage == 4) {
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
