import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/group_invite_repository.dart';
import '../../domain/models/group_invite.dart';

part 'invite_providers.g.dart';

/// Provider for GroupInviteRepository
@riverpod
GroupInviteRepository groupInviteRepository(Ref ref) {
  return GroupInviteRepository(FirebaseFirestore.instance);
}

/// Provider to create an invite for a group
@riverpod
Future<GroupInvite> createGroupInvite(
  Ref ref, {
  required String groupId,
  required String groupName,
  required String invitedBy,
  required String invitedByName,
  String? invitedEmail,
  String? invitedPhone,
}) async {
  final repo = ref.watch(groupInviteRepositoryProvider);
  return repo.createInvite(
    groupId: groupId,
    groupName: groupName,
    invitedBy: invitedBy,
    invitedByName: invitedByName,
    invitedEmail: invitedEmail,
    invitedPhone: invitedPhone,
  );
}

/// Provider to get an invite by code
@riverpod
Future<GroupInvite?> getInviteByCode(Ref ref, String code) async {
  final repo = ref.watch(groupInviteRepositoryProvider);
  return repo.getInviteByCode(code);
}

/// Provider to get an invite by ID
@riverpod
Future<GroupInvite?> getInviteById(Ref ref, String inviteId) async {
  final repo = ref.watch(groupInviteRepositoryProvider);
  return repo.getInvite(inviteId);
}

/// Provider to get all invites for a group
@riverpod
Future<List<GroupInvite>> getGroupInvites(Ref ref, String groupId) async {
  final repo = ref.watch(groupInviteRepositoryProvider);
  return repo.getGroupInvites(groupId);
}

/// Provider to watch pending invites for a group in real-time
@riverpod
Stream<List<GroupInvite>> watchGroupInvites(Ref ref, String groupId) {
  final repo = ref.watch(groupInviteRepositoryProvider);
  return repo.watchGroupInvites(groupId);
}

/// Provider to accept an invite by code
@riverpod
Future<GroupInvite> acceptInvite(
  Ref ref, {
  required String code,
  required String userId,
}) async {
  final repo = ref.watch(groupInviteRepositoryProvider);
  return repo.acceptInviteByCode(code, userId);
}

/// Provider to get invites created by a user
@riverpod
Future<List<GroupInvite>> getUserInvites(Ref ref, String userId) async {
  final repo = ref.watch(groupInviteRepositoryProvider);
  return repo.getInvitesByCreator(userId);
}

/// Provider to check if user has pending invite to group
@riverpod
Future<bool> hasPendingInvite(Ref ref, String userId, String groupId) async {
  final repo = ref.watch(groupInviteRepositoryProvider);
  return repo.hasPendingInvite(userId, groupId);
}

/// Provider to cancel an invite
@riverpod
Future<void> cancelInvite(Ref ref, String inviteId) async {
  final repo = ref.watch(groupInviteRepositoryProvider);
  return repo.cancelInvite(inviteId);
}

/// Provider to expire an invite
@riverpod
Future<void> expireInvite(Ref ref, String inviteId) async {
  final repo = ref.watch(groupInviteRepositoryProvider);
  return repo.expireInvite(inviteId);
}
