import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../domain/models/person.dart';

class FirebasePersonRepository {
  static final _logger = Logger();

  static const String _usersCollectionPath = 'users';
  static const String _peopleCollectionPath = 'people';

  final FirebaseFirestore _firestore;

  FirebasePersonRepository(this._firestore);

  /// Create a new person in Firestore (global people, reusable across groups)
  /// Path: users/{userId}/people/{personId}
  Future<Person> createPerson(String userId, Person person) async {
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_peopleCollectionPath)
          .doc(person.id)
          .set(person.toFirestore());

      return person;
    } catch (e) {
      _logger.e('Error creating person: $e');
      rethrow;
    }
  }

  /// Update an existing person in Firestore
  Future<void> updatePerson(String userId, Person person) async {
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_peopleCollectionPath)
          .doc(person.id)
          .update(person.toFirestore());
    } catch (e) {
      _logger.e('Error updating person: $e');
      rethrow;
    }
  }

  /// Delete a person from Firestore
  Future<void> deletePerson(String userId, String personId) async {
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_peopleCollectionPath)
          .doc(personId)
          .delete();
    } catch (e) {
      _logger.e('Error deleting person: $e');
      rethrow;
    }
  }

  /// Get a single person from Firestore
  Future<Person?> getPerson(String userId, String personId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_peopleCollectionPath)
          .doc(personId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Person.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      _logger.e('Error fetching person: $e');
      rethrow;
    }
  }

  /// Watch people in real-time from Firestore
  /// Returns stream of people for a user
  Stream<List<Person>> watchPeople(String userId) {
    return _firestore
        .collection(_usersCollectionPath)
        .doc(userId)
        .collection(_peopleCollectionPath)
        .snapshots()
        .handleError((error) {
          _logger.e('Error watching people: $error');
        })
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Person.fromFirestore(doc.data()))
              .toList();
        });
  }

  /// Get all people for a user (batch fetch, not real-time)
  Future<List<Person>> getPeople(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_peopleCollectionPath)
          .get();

      return snapshot.docs
          .map((doc) => Person.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Error fetching people: $e');
      rethrow;
    }
  }

  /// Search people by name (case-insensitive prefix search)
  /// Note: Firestore doesn't support regex, so this is a basic implementation
  /// For production, consider using a search service or Algolia
  Future<List<Person>> searchPeopleByName(String userId, String query) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_peopleCollectionPath)
          .get();

      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => Person.fromFirestore(doc.data()))
          .where(
            (person) =>
                person.name.toLowerCase().startsWith(lowerQuery) ||
                person.name.toLowerCase().contains(lowerQuery),
          )
          .toList();
    } catch (e) {
      _logger.e('Error searching people by name: $e');
      rethrow;
    }
  }

  /// Search people by email
  Future<Person?> searchPersonByEmail(String userId, String email) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_peopleCollectionPath)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return Person.fromFirestore(snapshot.docs.first.data());
    } catch (e) {
      _logger.e('Error searching person by email: $e');
      rethrow;
    }
  }

  /// Search people by phone number
  Future<Person?> searchPersonByPhone(String userId, String phone) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_peopleCollectionPath)
          .where('phoneNumber', isEqualTo: phone)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return Person.fromFirestore(snapshot.docs.first.data());
    } catch (e) {
      _logger.e('Error searching person by phone: $e');
      rethrow;
    }
  }
}
