import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../../../core/utils/phone_utils.dart';
import '../models/person.dart';

/// Service for discovering and finding registered users by email or phone
/// Queries the Firestore users collection to find registered users
class UserDiscoveryService {
  static final _logger = Logger();

  static const String _usersCollectionPath = 'users';
  static const String _profileSubcollectionPath = 'profile';
  static const String _profileDocId = 'data';
  static const int _maxBatchSize = 30; // Firestore 'in' query limit

  final FirebaseFirestore _firestore;

  UserDiscoveryService(this._firestore);

  /// Find a registered user by email
  /// Returns the user ID if found, null otherwise
  /// Handles errors gracefully - returns null on any error
  Future<String?> findByEmail(String? email) async {
    if (email == null || email.trim().isEmpty) {
      return null;
    }

    try {
      final snapshot = await _firestore
          .collection(_usersCollectionPath)
          .where('profile.data.email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return snapshot.docs.first.id;
    } catch (e) {
      _logger.w('Error finding user by email: $e');
      return null;
    }
  }

  /// Find a registered user by phone number
  /// Phone number should be in E.164 format (e.g., +60123456789)
  /// Normalizes input to E.164 format before searching
  /// Returns the user ID if found, null otherwise
  /// Handles errors gracefully - returns null on any error
  Future<String?> findByPhone(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      return null;
    }

    try {
      // Normalize phone to E.164 format for consistent matching
      final normalized = normalizePhoneNumber(phone.trim());

      if (normalized.isEmpty) {
        return null;
      }

      final snapshot = await _firestore
          .collection(_usersCollectionPath)
          .where('profile.data.phoneNumber', isEqualTo: normalized)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return snapshot.docs.first.id;
    } catch (e) {
      _logger.w('Error finding user by phone: $e');
      return null;
    }
  }

  /// Find a registered user by email or phone
  /// Tries email first, then phone if email not found
  /// Returns the user ID if found, null otherwise
  Future<String?> findByEmailOrPhone(String? email, String? phone) async {
    // Try email first
    if (email != null && email.trim().isNotEmpty) {
      final userId = await findByEmail(email);
      if (userId != null) {
        return userId;
      }
    }

    // Try phone if email not found
    if (phone != null && phone.trim().isNotEmpty) {
      final userId = await findByPhone(phone);
      if (userId != null) {
        return userId;
      }
    }

    return null;
  }

  /// Find registered users from a batch of people
  /// Respects Firestore's 30-item limit for 'in' queries by batching requests
  /// Returns map of person ID to user ID for matched contacts
  /// Handles errors gracefully - skips failed queries and continues
  Future<Map<String, String>> findByContacts(List<Person> people) async {
    if (people.isEmpty) {
      return {};
    }

    final results = <String, String>{};

    // Collect emails and phones from people
    final emails = <String>{};
    final phones = <String>{};
    final personByEmail = <String, Person>{};
    final personByPhone = <String, Person>{};

    for (final person in people) {
      if (person.email != null && person.email!.isNotEmpty) {
        final normalizedEmail = person.email!.trim().toLowerCase();
        emails.add(normalizedEmail);
        personByEmail[normalizedEmail] = person;
      }

      if (person.phoneNumber != null && person.phoneNumber!.isNotEmpty) {
        try {
          final normalized = normalizePhoneNumber(person.phoneNumber!.trim());
          if (normalized.isNotEmpty) {
            phones.add(normalized);
            personByPhone[normalized] = person;
          }
        } catch (e) {
          _logger.w(
            'Error normalizing phone number: ${person.phoneNumber}: $e',
          );
        }
      }
    }

    // Query emails in batches
    await _queryEmailsBatch(emails, personByEmail, results);

    // Query phones in batches (for people not already matched by email)
    final unmatchedPhones = phones
        .where((phone) => !results.values.contains(personByPhone[phone]?.id))
        .toSet();
    await _queryPhonesBatch(unmatchedPhones, personByPhone, results);

    return results;
  }

  /// Query emails in batches (respecting 30-item Firestore limit)
  Future<void> _queryEmailsBatch(
    Set<String> emails,
    Map<String, Person> personByEmail,
    Map<String, String> results,
  ) async {
    final emailList = emails.toList();

    for (int i = 0; i < emailList.length; i += _maxBatchSize) {
      final batch = emailList.sublist(
        i,
        (i + _maxBatchSize).clamp(0, emailList.length),
      );

      try {
        final snapshot = await _firestore
            .collection(_usersCollectionPath)
            .where('profile.data.email', whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          final userData = doc.data();
          final profileData =
              userData['profile']?['data'] as Map<String, dynamic>?;
          final email = profileData?['email'] as String?;

          if (email != null && personByEmail.containsKey(email)) {
            final person = personByEmail[email]!;
            results[person.id] = doc.id;
          }
        }
      } catch (e) {
        _logger.w('Error querying emails batch: $e');
      }
    }
  }

  /// Query phones in batches (respecting 30-item Firestore limit)
  Future<void> _queryPhonesBatch(
    Set<String> phones,
    Map<String, Person> personByPhone,
    Map<String, String> results,
  ) async {
    final phoneList = phones.toList();

    for (int i = 0; i < phoneList.length; i += _maxBatchSize) {
      final batch = phoneList.sublist(
        i,
        (i + _maxBatchSize).clamp(0, phoneList.length),
      );

      try {
        final snapshot = await _firestore
            .collection(_usersCollectionPath)
            .where('profile.data.phoneNumber', whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          final userData = doc.data();
          final profileData =
              userData['profile']?['data'] as Map<String, dynamic>?;
          final phone = profileData?['phoneNumber'] as String?;

          if (phone != null && personByPhone.containsKey(phone)) {
            final person = personByPhone[phone]!;
            // Only add if not already matched by email
            if (!results.containsKey(person.id)) {
              results[person.id] = doc.id;
            }
          }
        }
      } catch (e) {
        _logger.w('Error querying phones batch: $e');
      }
    }
  }

  /// Get user profile data for a registered user
  /// Used after discovery to get user name/emoji for display
  /// Returns null if user not found or error occurs
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_profileSubcollectionPath)
          .doc(_profileDocId)
          .get();

      if (doc.exists) {
        return doc.data();
      }

      return null;
    } catch (e) {
      _logger.w('Error fetching user profile: $e');
      return null;
    }
  }
}
