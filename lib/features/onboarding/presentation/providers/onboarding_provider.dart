import 'package:riverpod/riverpod.dart';
import '../../data/repositories/onboarding_repository.dart';

/// Immutable onboarding state
class OnboardingState {
  final int currentPage;
  final int totalPages;
  final bool isLoading;

  const OnboardingState({
    this.currentPage = 0,
    this.totalPages = 6,
    this.isLoading = false,
  });

  OnboardingState copyWith({
    int? currentPage,
    int? totalPages,
    bool? isLoading,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier for managing onboarding flow
class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  /// Move to the next page if available
  void nextPage() {
    if (state.currentPage < state.totalPages - 1) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  /// Move to the previous page if available
  void previousPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  /// Go to a specific page if it's valid
  void goToPage(int page) {
    if (page >= 0 && page < state.totalPages) {
      state = state.copyWith(currentPage: page);
    }
  }

  /// Complete onboarding and mark it in the repository
  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true);

    try {
      final repository = ref.read(onboardingRepositoryProvider);
      await repository.markOnboardingComplete();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

/// Provider for onboarding state
final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
