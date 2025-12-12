import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/person.dart';
import '../../domain/services/contact_service.dart';

/// State class for contacts feature
class ContactsState {
  final List<Person> contacts;
  final bool isLoading;
  final String? error;

  const ContactsState({
    required this.contacts,
    this.isLoading = false,
    this.error,
  });

  ContactsState copyWith({
    List<Person>? contacts,
    bool? isLoading,
    String? error,
  }) {
    return ContactsState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing contacts state
class ContactsNotifier extends Notifier<ContactsState> {
  @override
  ContactsState build() {
    return const ContactsState(contacts: []);
  }

  /// Load contacts from device
  Future<void> loadContacts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final contacts = await ContactService.fetchContacts();

      // Convert to Person models and sort by recent/frequent
      final people = contacts
          .map((contact) => ContactService.contactToPerson(contact))
          .toList();

      final sorted = ContactSorter.sortByRecentAndFrequent(people);

      state = state.copyWith(
        contacts: sorted,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load contacts: $e',
      );
    }
  }

  /// Clear contacts state
  void clearContacts() {
    state = const ContactsState(contacts: []);
  }
}

/// Provider for contacts state
final contactsProvider = NotifierProvider<ContactsNotifier, ContactsState>(
  ContactsNotifier.new,
);

/// Duplicate detection utility class
class ContactDuplicateDetector {
  /// Check if a person already exists in the system (by phone)
  static bool existsInSystem(Person person, List<Person> systemPeople) {
    if (person.phoneNumber == null) return false;
    return findByPhone(person.phoneNumber!, systemPeople) != null;
  }

  /// Check if a person is already in the current group
  static bool existsInGroup(Person person, List<Person> groupPeople) {
    // Match by ID first (most reliable)
    if (groupPeople.any((p) => p.id == person.id)) return true;

    // Then by phone number (for duplicates)
    if (person.phoneNumber != null) {
      return groupPeople.any((p) => _normalizePhone(p.phoneNumber) == _normalizePhone(person.phoneNumber));
    }

    return false;
  }

  /// Find person by phone number
  static Person? findByPhone(String phone, List<Person> people) {
    final normalized = _normalizePhone(phone);
    try {
      return people.firstWhere(
        (person) => _normalizePhone(person.phoneNumber) == normalized,
      );
    } catch (e) {
      return null;
    }
  }

  /// Normalize phone number for comparison (remove all non-digits)
  static String _normalizePhone(String? phone) {
    if (phone == null) return '';
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }
}

/// Contact sorting utility class
class ContactSorter {
  static const Duration _recentDuration = Duration(days: 30);
  static const int _frequentThreshold = 3;

  /// Sort contacts by recent first, then frequent, then alphabetical
  static List<Person> sortByRecentAndFrequent(List<Person> contacts) {
    final now = DateTime.now();

    contacts.sort((a, b) {
      // First: by recency (used in last 30 days)
      final aIsRecent = a.lastUsedAt != null &&
          a.lastUsedAt!.isAfter(now.subtract(_recentDuration));
      final bIsRecent = b.lastUsedAt != null &&
          b.lastUsedAt!.isAfter(now.subtract(_recentDuration));

      if (aIsRecent && !bIsRecent) return -1;
      if (!aIsRecent && bIsRecent) return 1;

      // Second: by frequency (if both recent or both not recent)
      if (aIsRecent == bIsRecent) {
        final aIsFrequent = a.usageCount >= _frequentThreshold;
        final bIsFrequent = b.usageCount >= _frequentThreshold;

        if (aIsFrequent && !bIsFrequent) return -1;
        if (!aIsFrequent && bIsFrequent) return 1;

        // Third: by usage count
        if (a.usageCount != b.usageCount) {
          return b.usageCount.compareTo(a.usageCount);
        }
      }

      // Finally: alphabetical by name
      return a.name.compareTo(b.name);
    });

    return contacts;
  }

  /// Categorize contacts into 'recent' and 'all' sections
  static Map<String, List<Person>> categorizeContacts(List<Person> contacts) {
    final now = DateTime.now();
    final recentThreshold = now.subtract(_recentDuration);

    final recent = contacts
        .where((p) =>
            p.lastUsedAt != null &&
            p.lastUsedAt!.isAfter(recentThreshold))
        .toList();

    final all = contacts;

    return {
      'recent': recent,
      'all': all,
    };
  }
}
