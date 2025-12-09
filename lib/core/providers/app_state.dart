import 'package:riverpod/riverpod.dart';

/// Global app state that persists across navigation
/// Example: current user, app settings, theme preferences
///
/// In Phase 3+, expand this to include:
/// - Current group ID
/// - Current split session
/// - User preferences from Hive
class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    return const AppState();
  }

  /// Initialize app state from Hive on startup
  Future<void> initialize() async {
    state = const AppState(isInitialized: true);
  }

  /// Reset app state (e.g., when creating new split)
  void reset() {
    state = const AppState(isInitialized: true);
  }
}

/// Immutable app state
class AppState {
  final bool isInitialized;
  // Future fields:
  // final String? currentGroupId;
  // final String? currentSessionId;
  // final UserPreferences? preferences;

  const AppState({this.isInitialized = false});
}

/// Global provider for app state
final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);
