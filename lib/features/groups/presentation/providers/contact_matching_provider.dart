import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/person.dart';
import '../../domain/services/contact_matching_service.dart';
import '../../domain/services/user_discovery_service.dart';
import '../../../groups/presentation/providers/group_providers.dart';

/// Provider for ContactMatchingService instance
/// Singleton that manages automatic contact matching and caching
final contactMatchingServiceProvider = Provider((ref) {
  return ContactMatchingService(
    userDiscoveryService: UserDiscoveryService(FirebaseFirestore.instance),
  );
});

/// State for contact matching feature
class ContactMatchingState {
  final Map<String, String> matches; // personId -> userId
  final bool isLoading;
  final String? error;
  final DateTime? lastRefreshedAt;

  const ContactMatchingState({
    this.matches = const {},
    this.isLoading = false,
    this.error,
    this.lastRefreshedAt,
  });

  ContactMatchingState copyWith({
    Map<String, String>? matches,
    bool? isLoading,
    String? error,
    DateTime? lastRefreshedAt,
  }) {
    return ContactMatchingState(
      matches: matches ?? this.matches,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
    );
  }
}

/// Notifier for managing contact matching state
class ContactMatchingNotifier extends Notifier<ContactMatchingState> {
  @override
  ContactMatchingState build() {
    // Load cached matches on initialization
    _loadCachedMatches();
    return const ContactMatchingState();
  }

  /// Load cached matches from Hive (instant, no network)
  void _loadCachedMatches() {
    try {
      final service = ref.read(contactMatchingServiceProvider);
      final cached = service.getCachedMatches();
      state = state.copyWith(matches: cached);
    } catch (e) {
      // Silently ignore cache errors
    }
  }

  /// Automatically match device contacts with registered users
  /// Runs in background, caches results
  Future<void> matchContacts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(contactMatchingServiceProvider);
      final matches = await service.matchContacts();

      state = state.copyWith(
        matches: matches,
        isLoading: false,
        lastRefreshedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to match contacts: $e',
      );
    }
  }

  /// Refresh matches by re-querying Firestore
  /// Bypasses cache and gets fresh results
  Future<void> refreshMatches() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final service = ref.read(contactMatchingServiceProvider);
      final matches = await service.refreshMatches();

      state = state.copyWith(
        matches: matches,
        isLoading: false,
        lastRefreshedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh matches: $e',
      );
    }
  }

  /// Clear cached matches
  /// Useful for logout or explicit cache invalidation
  Future<void> clearMatches() async {
    try {
      final service = ref.read(contactMatchingServiceProvider);
      await service.clearCache();
      state = state.copyWith(matches: {});
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear matches: $e');
    }
  }
}

/// Provider for contact matching state
final contactMatchingProvider =
    NotifierProvider<ContactMatchingNotifier, ContactMatchingState>(
      ContactMatchingNotifier.new,
    );

/// Compute matched contact list (person + userId pairs) from state
/// Combines groupsProvider people with contactMatchingProvider matches
final matchedContactsProvider = Provider<List<(Person, String)>>((ref) {
  final groupsState = ref.watch(groupsProvider);
  final matchingState = ref.watch(contactMatchingProvider);

  final result = <(Person, String)>[];

  for (final entry in matchingState.matches.entries) {
    final personId = entry.key;
    final userId = entry.value;

    final person = groupsState.people.firstWhere(
      (p) => p.id == personId,
      orElse: () => Person(name: '', emoji: ''),
    );

    if (person.name.isNotEmpty) {
      result.add((person, userId));
    }
  }

  // Sort by name for consistent display
  result.sort((a, b) => a.$1.name.compareTo(b.$1.name));

  return result;
});

/// Compute first 3 suggested matches
final suggestedContactsProvider = Provider<List<(Person, String)>>((ref) {
  final matched = ref.watch(matchedContactsProvider);
  return matched.take(3).toList();
});

/// Cache info provider for UI display
final contactMatchCacheInfoProvider = Provider<ContactMatchCacheInfo>((ref) {
  final service = ref.watch(contactMatchingServiceProvider);
  return service.getCacheInfo();
});
