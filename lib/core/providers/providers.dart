import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state.dart';

/// Central export file for all core providers
/// Prevents circular imports and makes imports cleaner in features

export 'app_state.dart';

/// Loading state - used across features to show loading dialogs
class LoadingStateNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setLoading(bool value) {
    state = value;
  }
}

final loadingProvider = NotifierProvider<LoadingStateNotifier, bool>(
  LoadingStateNotifier.new,
);

/// Error message state - used to display snackbars or error dialogs
class ErrorStateNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null;
  }

  void setError(String? message) {
    state = message;
  }

  void clearError() {
    state = null;
  }
}

final errorMessageProvider = NotifierProvider<ErrorStateNotifier, String?>(
  ErrorStateNotifier.new,
);

/// Provides initialization status
/// Features can use this to gate their initialization
final isAppInitializedProvider = Provider(
  (ref) => ref.watch(appStateProvider).isInitialized,
);
