import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App initialization provider
/// Returns true when app is fully initialized
final appInitProvider = FutureProvider<bool>((ref) async {
  // Simulate initialization tasks
  // In real app, would initialize Hive, load preferences, etc.
  await Future.delayed(const Duration(milliseconds: 500));
  return true;
});

/// Example: User preference for default currency
final preferredCurrencyProvider = NotifierProvider<CurrencyNotifier, String>(
  CurrencyNotifier.new,
);

class CurrencyNotifier extends Notifier<String> {
  @override
  String build() {
    return 'RM'; // Default: Malaysian Ringgit
  }

  void setCurrency(String currency) {
    state = currency;
  }
}

/// Example: App version
final appVersionProvider = Provider<String>((ref) {
  return '1.0.0';
});
