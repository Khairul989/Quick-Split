import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../domain/models/split_session.dart';

/// Repository for managing SplitSession data in Firestore
/// Firestore path: users/{userId}/splitSessions/{splitSessionId}
class FirebaseSplitSessionRepository {
  static final _logger = Logger();

  static const String _usersCollectionPath = 'users';
  static const String _splitSessionsCollectionPath = 'splitSessions';

  final FirebaseFirestore _firestore;

  FirebaseSplitSessionRepository(this._firestore);

  /// Create a new split session in Firestore
  /// Path: users/{userId}/splitSessions/{splitSessionId}
  Future<SplitSession> createSplitSession(
    String userId,
    SplitSession session,
  ) async {
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_splitSessionsCollectionPath)
          .doc(session.id)
          .set(session.toFirestore());

      _logger.d('Split session created: ${session.id}');
      return session;
    } catch (e) {
      _logger.e('Error creating split session: $e');
      rethrow;
    }
  }

  /// Update an existing split session in Firestore
  Future<void> updateSplitSession(
    String userId,
    SplitSession session,
  ) async {
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_splitSessionsCollectionPath)
          .doc(session.id)
          .update(session.toFirestore());

      _logger.d('Split session updated: ${session.id}');
    } catch (e) {
      _logger.e('Error updating split session: $e');
      rethrow;
    }
  }

  /// Delete a split session from Firestore
  Future<void> deleteSplitSession(String userId, String sessionId) async {
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_splitSessionsCollectionPath)
          .doc(sessionId)
          .delete();

      _logger.d('Split session deleted: $sessionId');
    } catch (e) {
      _logger.e('Error deleting split session: $e');
      rethrow;
    }
  }

  /// Get a single split session from Firestore
  Future<SplitSession?> getSplitSession(
    String userId,
    String sessionId,
  ) async {
    try {
      final doc = await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_splitSessionsCollectionPath)
          .doc(sessionId)
          .get();

      if (doc.exists && doc.data() != null) {
        return SplitSession.fromFirestore({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      _logger.e('Error fetching split session: $e');
      rethrow;
    }
  }

  /// Watch a single split session in real-time from Firestore
  Stream<SplitSession?> watchSplitSession(String userId, String sessionId) {
    return _firestore
        .collection(_usersCollectionPath)
        .doc(userId)
        .collection(_splitSessionsCollectionPath)
        .doc(sessionId)
        .snapshots()
        .handleError((error) {
          _logger.e('Error watching split session: $error');
        })
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return SplitSession.fromFirestore({...snapshot.data()!, 'id': snapshot.id});
          }
          return null;
        });
  }

  /// Watch all split sessions for a user in real-time from Firestore
  /// Returns stream of split sessions sorted by createdAt (newest first)
  Stream<List<SplitSession>> watchAllSplitSessions(String userId) {
    return _firestore
        .collection(_usersCollectionPath)
        .doc(userId)
        .collection(_splitSessionsCollectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          _logger.e('Error watching split sessions: $error');
        })
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SplitSession.fromFirestore({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  /// Watch split sessions for a specific group
  Stream<List<SplitSession>> watchGroupSplitSessions(
    String userId,
    String groupId,
  ) {
    return _firestore
        .collection(_usersCollectionPath)
        .doc(userId)
        .collection(_splitSessionsCollectionPath)
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          _logger.e('Error watching group split sessions: $error');
        })
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SplitSession.fromFirestore({...doc.data(), 'id': doc.id}))
              .toList();
        });
  }

  /// Get all split sessions for a user (one-time fetch)
  Future<List<SplitSession>> getAllSplitSessions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_splitSessionsCollectionPath)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SplitSession.fromFirestore({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      _logger.e('Error fetching all split sessions: $e');
      rethrow;
    }
  }

  /// Get split sessions for a specific group (one-time fetch)
  Future<List<SplitSession>> getGroupSplitSessions(
    String userId,
    String groupId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_splitSessionsCollectionPath)
          .where('groupId', isEqualTo: groupId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SplitSession.fromFirestore({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      _logger.e('Error fetching group split sessions: $e');
      rethrow;
    }
  }

  /// Sync a local split session to Firestore
  /// Used for offline-first approach where session is saved locally first
  /// then synced to Firestore in the background
  Future<void> syncLocalSession(String userId, SplitSession session) async {
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_splitSessionsCollectionPath)
          .doc(session.id)
          .set(
            session.toFirestore(),
            SetOptions(merge: true),
          );

      _logger.d('Local split session synced to Firestore: ${session.id}');
    } catch (e) {
      _logger.e('Error syncing local split session: $e');
      rethrow;
    }
  }
}
