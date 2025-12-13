import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:riverpod/riverpod.dart';

/// Immutable theme state
class ThemeState {
  final ThemeMode themeMode;
  final bool isLoading;

  const ThemeState({this.themeMode = ThemeMode.system, this.isLoading = false});

  ThemeState copyWith({ThemeMode? themeMode, bool? isLoading}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Theme notifier with Hive persistence
class ThemeNotifier extends Notifier<ThemeState> {
  static const String _themePreferenceKey = 'theme_mode';
  late Box<dynamic> _preferencesBox;

  @override
  ThemeState build() {
    _preferencesBox = Hive.box<dynamic>('preferences');

    // Load saved preference or default to system
    final savedMode = _loadThemePreference();
    return ThemeState(themeMode: savedMode);
  }

  ThemeMode _loadThemePreference() {
    try {
      final savedValue = _preferencesBox.get(_themePreferenceKey);
      if (savedValue == null) return ThemeMode.system;

      // Convert stored string to ThemeMode enum
      return ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedValue,
        orElse: () => ThemeMode.system,
      );
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(isLoading: true);

    try {
      // Save to Hive
      await _preferencesBox.put(_themePreferenceKey, mode.toString());

      // Update state (triggers UI rebuild)
      state = state.copyWith(themeMode: mode, isLoading: false);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
      state = state.copyWith(isLoading: false);
      // Don't rethrow - fail silently and keep current theme
    }
  }
}

/// Provider for theme state
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);

/// Convenience provider for just the ThemeMode
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider).themeMode;
});
