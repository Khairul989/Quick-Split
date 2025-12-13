import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce/hive.dart';
import 'package:logger/logger.dart';

import '../../../onboarding/data/models/user_profile.dart';

class UserProfileRepository {
  static final _logger = Logger();
  static const String _userProfileKey = 'userProfile';
  static const String _usersCollectionPath = 'users';
  static const String _profileSubcollectionPath = 'profile';
  static const String _profileDocId = 'data';

  final FirebaseFirestore _firestore;
  final Box<dynamic> _preferencesBox;

  UserProfileRepository(this._firestore, this._preferencesBox);

  /// Get user profile from Firestore with local Hive fallback
  /// Returns null if profile doesn't exist in either location
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      // Try to fetch from Firestore first (cloud source of truth)
      final doc = await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_profileSubcollectionPath)
          .doc(_profileDocId)
          .get();

      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromFirestore(doc.data()!);
        // Update local cache
        await _preferencesBox.put(_userProfileKey, profile.toJson());
        return profile;
      } else {
        throw Exception('Profile document does not exist in Firestore');
      }
    } catch (e) {
      _logger.w('Error fetching profile from Firestore: $e');
      // Continue to fallback
    }

    // Fallback to local Hive cache
    try {
      final localProfileJson = _preferencesBox.get(_userProfileKey);
      if (localProfileJson != null) {
        if (localProfileJson is String) {
          return UserProfile.fromJson(jsonDecode(localProfileJson));
        } else if (localProfileJson is Map) {
          return UserProfile.fromJson(
            Map<String, dynamic>.from(localProfileJson),
          );
        }
      }
    } catch (e) {
      _logger.w('Error reading profile from local storage: $e');
    }

    return null;
  }

  /// Check if user profile exists in Firestore (cloud only, no fallback)
  /// Returns true only if profile exists in Firestore, ignoring local cache
  /// Used by migration service to determine if migration is needed
  Future<bool> cloudProfileExists(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_profileSubcollectionPath)
          .doc(_profileDocId)
          .get();

      return doc.exists && doc.data() != null;
    } catch (e) {
      _logger.w('Error checking cloud profile existence: $e');
      return false;
    }
  }

  /// Save user profile to Firestore and cache locally in Hive
  /// Throws exception if both cloud and local saves fail
  Future<void> saveUserProfile(String userId, UserProfile profile) async {
    bool cloudSaveSuccess = false;
    bool localSaveSuccess = false;

    // Try to save to Firestore
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_profileSubcollectionPath)
          .doc(_profileDocId)
          .set(profile.toFirestore(), SetOptions(merge: true));
      cloudSaveSuccess = true;
    } catch (e) {
      _logger.w('Error saving profile to Firestore: $e');
    }

    // Always try to save locally as cache/offline support
    try {
      await _preferencesBox.put(_userProfileKey, profile.toJson());
      localSaveSuccess = true;
    } catch (e) {
      _logger.w('Error saving profile to local storage: $e');
    }

    // Throw if both saves failed
    if (!cloudSaveSuccess && !localSaveSuccess) {
      throw Exception(
        'Failed to save user profile to both cloud and local storage',
      );
    }
  }

  /// Watch user profile changes in real-time from Firestore
  /// Falls back to cached value if Firestore is unavailable
  /// Streams updates as they occur in Firestore
  Stream<UserProfile?> watchUserProfile(String userId) {
    return _firestore
        .collection(_usersCollectionPath)
        .doc(userId)
        .collection(_profileSubcollectionPath)
        .doc(_profileDocId)
        .snapshots()
        .handleError((error) {
          _logger.w('Error watching profile changes: $error');
          // On error, emit null to let listener know there's an issue
          // Listener should handle this and potentially use fallback data
        })
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final profile = UserProfile.fromFirestore(snapshot.data()!);
            // Update local cache whenever we get a successful update
            _preferencesBox
                .put(_userProfileKey, profile.toJson())
                .catchError(
                  (e) => _logger.w('Error caching profile during watch: $e'),
                );
            return profile;
          }
          return null;
        });
  }

  /// Delete user profile from both Firestore and local cache
  /// Succeeds if at least one location successfully deletes
  Future<void> deleteUserProfile(String userId) async {
    bool cloudDeleteSuccess = false;
    bool localDeleteSuccess = false;

    // Try to delete from Firestore
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_profileSubcollectionPath)
          .doc(_profileDocId)
          .delete();
      cloudDeleteSuccess = true;
    } catch (e) {
      _logger.w('Error deleting profile from Firestore: $e');
    }

    // Try to delete from local cache
    try {
      await _preferencesBox.delete(_userProfileKey);
      localDeleteSuccess = true;
    } catch (e) {
      _logger.w('Error deleting profile from local storage: $e');
    }

    // Throw if both deletes failed
    if (!cloudDeleteSuccess && !localDeleteSuccess) {
      throw Exception(
        'Failed to delete user profile from both cloud and local storage',
      );
    }
  }

  /// Clear all cached user profiles from local storage
  /// Useful for sign-out or factory reset scenarios
  Future<void> clearLocalCache() async {
    try {
      await _preferencesBox.delete(_userProfileKey);
    } catch (e) {
      _logger.w('Error clearing local profile cache: $e');
      rethrow;
    }
  }

  /// Add FCM token to user's fcmTokens array in Firestore
  /// Uses arrayUnion to add token only if not already present
  /// Succeeds if Firestore update is successful
  Future<void> addFcmToken(String userId, String token) async {
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_profileSubcollectionPath)
          .doc(_profileDocId)
          .update({
            'fcmTokens': FieldValue.arrayUnion([token]),
          });
      _logger.d('FCM token added to user profile: $token');
    } catch (e) {
      _logger.w('Error adding FCM token to user profile: $e');
      rethrow;
    }
  }

  /// Remove FCM token from user's fcmTokens array in Firestore
  /// Uses arrayRemove to remove token from array
  /// Succeeds if Firestore update is successful
  Future<void> removeFcmToken(String userId, String token) async {
    try {
      await _firestore
          .collection(_usersCollectionPath)
          .doc(userId)
          .collection(_profileSubcollectionPath)
          .doc(_profileDocId)
          .update({
            'fcmTokens': FieldValue.arrayRemove([token]),
          });
      _logger.d('FCM token removed from user profile: $token');
    } catch (e) {
      _logger.w('Error removing FCM token from user profile: $e');
      rethrow;
    }
  }
}
