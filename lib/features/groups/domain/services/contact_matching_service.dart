import 'package:hive_ce/hive.dart';
import 'package:logger/logger.dart';

import '../models/contact_match.dart';
import 'contact_service.dart';
import 'user_discovery_service.dart';

/// Service for automatically matching device contacts with registered QuickSplit users
/// Caches results locally in Hive for fast access and reduces Firestore queries
class ContactMatchingService {
  static final _logger = Logger();

  static const String _cacheBoxName = 'contact_matches';
  static const Duration _defaultCacheDuration = Duration(hours: 24);

  final UserDiscoveryService _userDiscoveryService;
  late Box<ContactMatch> _cacheBox;

  /// Initialize with required services
  /// The Hive box for contact matches should already be registered
  ContactMatchingService({required UserDiscoveryService userDiscoveryService})
    : _userDiscoveryService = userDiscoveryService {
    _initializeCache();
  }

  /// Initialize cache box (ensure it exists)
  void _initializeCache() {
    try {
      if (!Hive.isBoxOpen(_cacheBoxName)) {
        _logger.d('Opening contact matches cache box');
      }
      _cacheBox = Hive.box<ContactMatch>(_cacheBoxName);
    } catch (e) {
      _logger.e('Failed to initialize contact matches cache: $e');
      rethrow;
    }
  }

  /// Automatically match device contacts with registered users
  /// - Fetches device contacts via ContactService
  /// - Queries Firestore via UserDiscoveryService
  /// - Caches results in Hive
  /// - Returns map of person ID to matched user ID
  /// Handles errors gracefully - returns empty map on failure
  Future<Map<String, String>> matchContacts() async {
    try {
      _logger.d('Starting automatic contact matching');

      // Check permission first
      final hasPermission = await ContactService.hasPermission();
      if (!hasPermission) {
        _logger.w('Contact permission not granted, skipping matching');
        return {};
      }

      // Fetch device contacts
      final contacts = await ContactService.fetchContacts();
      if (contacts.isEmpty) {
        _logger.i('No contacts found on device');
        return {};
      }

      // Convert to Person models
      final people = contacts
          .map((contact) => ContactService.contactToPerson(contact))
          .toList();

      _logger.d('Fetched ${people.length} device contacts for matching');

      // Query Firestore for registered users
      final matches = await _userDiscoveryService.findByContacts(people);

      // Cache the matches
      await _cacheMatches(matches);

      _logger.i('Contact matching completed: ${matches.length} matches found');
      return matches;
    } catch (e) {
      _logger.e('Error during contact matching: $e');
      return {};
    }
  }

  /// Cache matching results in Hive
  /// Stores personId -> userId mappings with timestamp for expiration
  Future<void> _cacheMatches(Map<String, String> matches) async {
    try {
      final now = DateTime.now();
      final cacheEntries = matches.entries.map((entry) {
        return ContactMatch(
          personId: entry.key,
          userId: entry.value,
          matchedAt: now,
        );
      }).toList();

      // Clear old cache
      await _cacheBox.clear();

      // Add new matches
      for (final match in cacheEntries) {
        await _cacheBox.put(match.personId, match);
      }

      _logger.d('Cached ${cacheEntries.length} contact matches');
    } catch (e) {
      _logger.e('Error caching contact matches: $e');
      rethrow;
    }
  }

  /// Get cached matches (instant retrieval, no network call)
  /// Returns map of person ID to matched user ID
  /// Only returns valid (non-expired) matches
  Map<String, String> getCachedMatches({
    Duration cacheDuration = _defaultCacheDuration,
  }) {
    try {
      final result = <String, String>{};

      for (final match in _cacheBox.values) {
        if (match.isValid(cacheDuration: cacheDuration)) {
          result[match.personId] = match.userId;
        }
      }

      _logger.d('Retrieved ${result.length} valid cached matches');
      return result;
    } catch (e) {
      _logger.e('Error retrieving cached matches: $e');
      return {};
    }
  }

  /// Refresh matches by re-querying Firestore
  /// Bypasses cache and updates with fresh results
  /// Returns map of person ID to matched user ID
  Future<Map<String, String>> refreshMatches() async {
    try {
      _logger.d('Refreshing contact matches from Firestore');
      return await matchContacts();
    } catch (e) {
      _logger.e('Error refreshing contact matches: $e');
      return {};
    }
  }

  /// Clear cache manually
  /// Useful for logout or explicit cache invalidation
  Future<void> clearCache() async {
    try {
      _logger.d('Clearing contact matches cache');
      await _cacheBox.clear();
    } catch (e) {
      _logger.e('Error clearing cache: $e');
      rethrow;
    }
  }

  /// Get cache metadata
  /// Returns last match timestamp and cache size
  ContactMatchCacheInfo getCacheInfo() {
    try {
      final matches = _cacheBox.values.toList();
      DateTime? lastMatchedAt;

      if (matches.isNotEmpty) {
        matches.sort((a, b) => b.matchedAt.compareTo(a.matchedAt));
        lastMatchedAt = matches.first.matchedAt;
      }

      return ContactMatchCacheInfo(
        cacheSize: matches.length,
        lastMatchedAt: lastMatchedAt,
      );
    } catch (e) {
      _logger.e('Error getting cache info: $e');
      return ContactMatchCacheInfo(cacheSize: 0);
    }
  }
}

/// Information about contact matching cache state
class ContactMatchCacheInfo {
  final int cacheSize;
  final DateTime? lastMatchedAt;

  ContactMatchCacheInfo({required this.cacheSize, this.lastMatchedAt});

  /// Check if cache is empty
  bool get isEmpty => cacheSize == 0;

  /// Format last matched time for display
  String? get formattedLastMatchedAt {
    if (lastMatchedAt == null) return null;

    final now = DateTime.now();
    final difference = now.difference(lastMatchedAt!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return lastMatchedAt!.toString().split(' ')[0];
    }
  }
}
