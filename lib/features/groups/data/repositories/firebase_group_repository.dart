import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../domain/models/group.dart';
import '../../domain/models/person.dart';

class FirebaseGroupRepository {
  static final _logger = Logger();

  static const String _usersCollectionPath = 'users';
  static const String _groupsCollectionPath = 'groups';
  static const String _membersCollectionPath = 'members';

  final FirebaseFirestore _firestore;

  FirebaseGroupRepository(this._firestore);

  /// Create a new group in Firestore
  /// Path: users/{userId}/groups/{groupId}
  /// Also creates members subcollection
  Future<Group> createGroup(String userId, Group group) async {
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_groupsCollectionPath)
          .doc(group.id)
          .set(group.toFirestore());

      return group;
    } catch (e) {
      _logger.e('Error creating group: $e');
      rethrow;
    }
  }

  /// Update an existing group in Firestore
  Future<void> updateGroup(String userId, Group group) async {
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_groupsCollectionPath)
          .doc(group.id)
          .update(group.toFirestore());
    } catch (e) {
      _logger.e('Error updating group: $e');
      rethrow;
    }
  }

  /// Delete a group from Firestore (including members subcollection)
  Future<void> deleteGroup(String userId, String groupId) async {
    try {
      // Delete all members first
      final membersSnapshot = await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_groupsCollectionPath)
          .doc(groupId)
          .collection(_membersCollectionPath)
          .get();

      for (final doc in membersSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete group document
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_groupsCollectionPath)
          .doc(groupId)
          .delete();
    } catch (e) {
      _logger.e('Error deleting group: $e');
      rethrow;
    }
  }

  /// Get a single group from Firestore
  Future<Group?> getGroup(String userId, String groupId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_groupsCollectionPath)
          .doc(groupId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Group.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      _logger.e('Error fetching group: $e');
      rethrow;
    }
  }

  /// Watch groups in real-time from Firestore
  /// Returns stream of groups for a user
  Stream<List<Group>> watchGroups(String userId) {
    return _firestore
        .collection(_usersCollectionPath)
        .doc(userId)
        .collection(_groupsCollectionPath)
        .snapshots()
        .handleError((error) {
          _logger.e('Error watching groups: $error');
        })
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Group.fromFirestore(doc.data()))
              .toList();
        });
  }

  /// Add a member to a group
  /// Path: users/{userId}/groups/{groupId}/members/{personId}
  Future<void> addMember(String userId, String groupId, Person person) async {
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_groupsCollectionPath)
          .doc(groupId)
          .collection(_membersCollectionPath)
          .doc(person.id)
          .set(person.toFirestore());
    } catch (e) {
      _logger.e('Error adding member to group: $e');
      rethrow;
    }
  }

  /// Remove a member from a group
  Future<void> removeMember(
    String userId,
    String groupId,
    String personId,
  ) async {
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_groupsCollectionPath)
          .doc(groupId)
          .collection(_membersCollectionPath)
          .doc(personId)
          .delete();
    } catch (e) {
      _logger.e('Error removing member from group: $e');
      rethrow;
    }
  }

  /// Get all members of a group
  Future<List<Person>> getMembers(String userId, String groupId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_groupsCollectionPath)
          .doc(groupId)
          .collection(_membersCollectionPath)
          .get();

      return snapshot.docs
          .map((doc) => Person.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Error fetching group members: $e');
      rethrow;
    }
  }

  /// Watch group members in real-time
  Stream<List<Person>> watchMembers(String userId, String groupId) {
    return _firestore
        .collection(_usersCollectionPath)
        .doc(userId)
        .collection(_groupsCollectionPath)
        .doc(groupId)
        .collection(_membersCollectionPath)
        .snapshots()
        .handleError((error) {
          _logger.e('Error watching group members: $error');
        })
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Person.fromFirestore(doc.data()))
              .toList();
        });
  }

  /// Update a member in a group
  Future<void> updateMember(
    String userId,
    String groupId,
    Person person,
  ) async {
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_groupsCollectionPath)
          .doc(groupId)
          .collection(_membersCollectionPath)
          .doc(person.id)
          .update(person.toFirestore());
    } catch (e) {
      _logger.e('Error updating group member: $e');
      rethrow;
    }
  }
}
