/// Exception thrown when an invite is not found
class InviteNotFoundException implements Exception {
  final String message;

  InviteNotFoundException({this.message = 'Invite not found'}) : assert(true);

  @override
  String toString() => message;
}

/// Exception thrown when an invite has expired
class InviteExpiredException implements Exception {
  final String message;

  InviteExpiredException({this.message = 'Invite has expired'}) : assert(true);

  @override
  String toString() => message;
}

/// Exception thrown when user tries to accept their own invite
class SelfInviteException implements Exception {
  final String message;

  SelfInviteException({this.message = 'Cannot accept your own invite'})
    : assert(true);

  @override
  String toString() => message;
}

/// Exception thrown when invite is already accepted
class InviteAlreadyAcceptedException implements Exception {
  final String message;

  InviteAlreadyAcceptedException({
    this.message = 'Invite has already been accepted',
  }) : assert(true);

  @override
  String toString() => message;
}

/// Exception thrown when group for invite is not found
class InviteGroupNotFoundException implements Exception {
  final String message;

  InviteGroupNotFoundException({this.message = 'Group not found'})
    : assert(true);

  @override
  String toString() => message;
}

/// Exception thrown when user is already a member of the group
class AlreadyGroupMemberException implements Exception {
  final String message;

  AlreadyGroupMemberException({
    this.message = 'You are already a member of this group',
  }) : assert(true);

  @override
  String toString() => message;
}
