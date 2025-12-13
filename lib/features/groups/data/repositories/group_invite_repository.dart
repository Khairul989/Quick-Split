import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../../domain/exceptions/invite_exceptions.dart';
import '../../domain/models/group_invite.dart';

class GroupInviteRepository {
  static final _logger = Logger();

  static const String _invitesCollectionPath = 'groupInvites';
  static const String _inviteCodeChars =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No confusing chars (I, O, 0, 1, L)

  final FirebaseFirestore _firestore;

  GroupInviteRepository(this._firestore);

  /// Generate a 6-character alphanumeric invite code
  /// Uses characters that are not easily confused (no I, O, 0, 1, L)
  String _generateInviteCode() {
    final random = Random.secure();
    return List.generate(
      6,
      (_) => _inviteCodeChars[random.nextInt(_inviteCodeChars.length)],
    ).join();
  }

  /// Create a new invite for a group
  Future<GroupInvite> createInvite({
    required String groupId,
    required String groupName,
    required String invitedBy,
    required String invitedByName,
    String? invitedEmail,
    String? invitedPhone,
  }) async {
    try {
      final inviteCode = _generateInviteCode();
      final now = DateTime.now();

      final invite = GroupInvite(
        groupId: groupId,
        groupName: groupName,
        invitedBy: invitedBy,
        invitedByName: invitedByName,
        inviteCode: inviteCode,
        status: 'pending',
        createdAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        invitedEmail: invitedEmail,
        invitedPhone: invitedPhone,
      );

      await _firestore
          .collection(_invitesCollectionPath)
          .doc(invite.id)
          .set(invite.toFirestore());

      _logger.d('Created invite: ${invite.id} for group: $groupId');
      return invite;
    } catch (e) {
      _logger.e('Error creating invite: $e');
      rethrow;
    }
  }

  /// Get invite by code
  Future<GroupInvite?> getInviteByCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection(_invitesCollectionPath)
          .where('inviteCode', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      final invite = GroupInvite.fromFirestore({...doc.data(), 'id': doc.id});

      return invite;
    } catch (e) {
      _logger.e('Error fetching invite by code: $e');
      rethrow;
    }
  }

  /// Get invite by ID
  Future<GroupInvite?> getInvite(String inviteId) async {
    try {
      final doc = await _firestore
          .collection(_invitesCollectionPath)
          .doc(inviteId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return GroupInvite.fromFirestore({...doc.data()!, 'id': doc.id});
    } catch (e) {
      _logger.e('Error fetching invite: $e');
      rethrow;
    }
  }

  /// Get all invites for a group
  Future<List<GroupInvite>> getGroupInvites(String groupId) async {
    try {
      final snapshot = await _firestore
          .collection(_invitesCollectionPath)
          .where('groupId', isEqualTo: groupId)
          .get();

      return snapshot.docs
          .map(
            (doc) => GroupInvite.fromFirestore({...doc.data(), 'id': doc.id}),
          )
          .toList();
    } catch (e) {
      _logger.e('Error fetching group invites: $e');
      rethrow;
    }
  }

  /// Watch pending invites for a group in real-time
  Stream<List<GroupInvite>> watchGroupInvites(String groupId) {
    return _firestore
        .collection(_invitesCollectionPath)
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .handleError((error) {
          _logger.e('Error watching group invites: $error');
        })
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    GroupInvite.fromFirestore({...doc.data(), 'id': doc.id}),
              )
              .toList();
        });
  }

  /// Accept an invite by code
  /// Returns the updated GroupInvite
  Future<GroupInvite> acceptInviteByCode(String code, String userId) async {
    try {
      final invite = await getInviteByCode(code);

      if (invite == null) {
        throw InviteNotFoundException();
      }

      if (invite.isExpired) {
        // Mark as expired in Firestore
        await _updateInviteStatus(invite.id, 'expired');
        throw InviteExpiredException();
      }

      if (invite.invitedBy == userId) {
        throw SelfInviteException();
      }

      if (invite.isAccepted) {
        throw InviteAlreadyAcceptedException();
      }

      // Update invite status to accepted
      final updatedInvite = invite.copyWith(
        status: 'accepted',
        acceptedBy: userId,
        acceptedAt: DateTime.now(),
      );

      await _firestore
          .collection(_invitesCollectionPath)
          .doc(invite.id)
          .update(updatedInvite.toFirestore());

      _logger.d('Accepted invite: ${invite.id} by user: $userId');
      return updatedInvite;
    } catch (e) {
      _logger.e('Error accepting invite: $e');
      rethrow;
    }
  }

  /// Update invite status
  Future<void> _updateInviteStatus(String inviteId, String status) async {
    try {
      await _firestore.collection(_invitesCollectionPath).doc(inviteId).update({
        'status': status,
      });

      _logger.d('Updated invite status: $inviteId -> $status');
    } catch (e) {
      _logger.e('Error updating invite status: $e');
      rethrow;
    }
  }

  /// Cancel an invite
  Future<void> cancelInvite(String inviteId) async {
    try {
      await _updateInviteStatus(inviteId, 'cancelled');
      _logger.d('Cancelled invite: $inviteId');
    } catch (e) {
      _logger.e('Error cancelling invite: $e');
      rethrow;
    }
  }

  /// Expire an invite
  Future<void> expireInvite(String inviteId) async {
    try {
      await _updateInviteStatus(inviteId, 'expired');
      _logger.d('Expired invite: $inviteId');
    } catch (e) {
      _logger.e('Error expiring invite: $e');
      rethrow;
    }
  }

  /// Delete an invite (hard delete from Firestore)
  /// Use with caution - only for cleanup
  Future<void> deleteInvite(String inviteId) async {
    try {
      await _firestore
          .collection(_invitesCollectionPath)
          .doc(inviteId)
          .delete();
      _logger.d('Deleted invite: $inviteId');
    } catch (e) {
      _logger.e('Error deleting invite: $e');
      rethrow;
    }
  }

  /// Get invites created by a user
  Future<List<GroupInvite>> getInvitesByCreator(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_invitesCollectionPath)
          .where('invitedBy', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map(
            (doc) => GroupInvite.fromFirestore({...doc.data(), 'id': doc.id}),
          )
          .toList();
    } catch (e) {
      _logger.e('Error fetching invites by creator: $e');
      rethrow;
    }
  }

  /// Check if a user has pending invites to a group
  Future<bool> hasPendingInvite(String userId, String groupId) async {
    try {
      final snapshot = await _firestore
          .collection(_invitesCollectionPath)
          .where('invitedBy', isEqualTo: userId)
          .where('groupId', isEqualTo: groupId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking pending invite: $e');
      rethrow;
    }
  }
}
