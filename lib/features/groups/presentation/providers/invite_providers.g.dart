// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for GroupInviteRepository

@ProviderFor(groupInviteRepository)
const groupInviteRepositoryProvider = GroupInviteRepositoryProvider._();

/// Provider for GroupInviteRepository

final class GroupInviteRepositoryProvider
    extends
        $FunctionalProvider<
          GroupInviteRepository,
          GroupInviteRepository,
          GroupInviteRepository
        >
    with $Provider<GroupInviteRepository> {
  /// Provider for GroupInviteRepository
  const GroupInviteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupInviteRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupInviteRepositoryHash();

  @$internal
  @override
  $ProviderElement<GroupInviteRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GroupInviteRepository create(Ref ref) {
    return groupInviteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroupInviteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroupInviteRepository>(value),
    );
  }
}

String _$groupInviteRepositoryHash() =>
    r'6960e03784c88061a277576eba405626fda2568b';

/// Provider to create an invite for a group

@ProviderFor(createGroupInvite)
const createGroupInviteProvider = CreateGroupInviteFamily._();

/// Provider to create an invite for a group

final class CreateGroupInviteProvider
    extends
        $FunctionalProvider<
          AsyncValue<GroupInvite>,
          GroupInvite,
          FutureOr<GroupInvite>
        >
    with $FutureModifier<GroupInvite>, $FutureProvider<GroupInvite> {
  /// Provider to create an invite for a group
  const CreateGroupInviteProvider._({
    required CreateGroupInviteFamily super.from,
    required ({
      String groupId,
      String groupName,
      String invitedBy,
      String invitedByName,
      String? invitedEmail,
      String? invitedPhone,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'createGroupInviteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$createGroupInviteHash();

  @override
  String toString() {
    return r'createGroupInviteProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<GroupInvite> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GroupInvite> create(Ref ref) {
    final argument =
        this.argument
            as ({
              String groupId,
              String groupName,
              String invitedBy,
              String invitedByName,
              String? invitedEmail,
              String? invitedPhone,
            });
    return createGroupInvite(
      ref,
      groupId: argument.groupId,
      groupName: argument.groupName,
      invitedBy: argument.invitedBy,
      invitedByName: argument.invitedByName,
      invitedEmail: argument.invitedEmail,
      invitedPhone: argument.invitedPhone,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CreateGroupInviteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$createGroupInviteHash() => r'c5767233da001327b9f6a108389534ab37f019d0';

/// Provider to create an invite for a group

final class CreateGroupInviteFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<GroupInvite>,
          ({
            String groupId,
            String groupName,
            String invitedBy,
            String invitedByName,
            String? invitedEmail,
            String? invitedPhone,
          })
        > {
  const CreateGroupInviteFamily._()
    : super(
        retry: null,
        name: r'createGroupInviteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to create an invite for a group

  CreateGroupInviteProvider call({
    required String groupId,
    required String groupName,
    required String invitedBy,
    required String invitedByName,
    String? invitedEmail,
    String? invitedPhone,
  }) => CreateGroupInviteProvider._(
    argument: (
      groupId: groupId,
      groupName: groupName,
      invitedBy: invitedBy,
      invitedByName: invitedByName,
      invitedEmail: invitedEmail,
      invitedPhone: invitedPhone,
    ),
    from: this,
  );

  @override
  String toString() => r'createGroupInviteProvider';
}

/// Provider to get an invite by code

@ProviderFor(getInviteByCode)
const getInviteByCodeProvider = GetInviteByCodeFamily._();

/// Provider to get an invite by code

final class GetInviteByCodeProvider
    extends
        $FunctionalProvider<
          AsyncValue<GroupInvite?>,
          GroupInvite?,
          FutureOr<GroupInvite?>
        >
    with $FutureModifier<GroupInvite?>, $FutureProvider<GroupInvite?> {
  /// Provider to get an invite by code
  const GetInviteByCodeProvider._({
    required GetInviteByCodeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'getInviteByCodeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getInviteByCodeHash();

  @override
  String toString() {
    return r'getInviteByCodeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GroupInvite?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GroupInvite?> create(Ref ref) {
    final argument = this.argument as String;
    return getInviteByCode(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetInviteByCodeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getInviteByCodeHash() => r'9242d9806f89d56f7b23b6f0c29f5b177c5ca951';

/// Provider to get an invite by code

final class GetInviteByCodeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GroupInvite?>, String> {
  const GetInviteByCodeFamily._()
    : super(
        retry: null,
        name: r'getInviteByCodeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to get an invite by code

  GetInviteByCodeProvider call(String code) =>
      GetInviteByCodeProvider._(argument: code, from: this);

  @override
  String toString() => r'getInviteByCodeProvider';
}

/// Provider to get an invite by ID

@ProviderFor(getInviteById)
const getInviteByIdProvider = GetInviteByIdFamily._();

/// Provider to get an invite by ID

final class GetInviteByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<GroupInvite?>,
          GroupInvite?,
          FutureOr<GroupInvite?>
        >
    with $FutureModifier<GroupInvite?>, $FutureProvider<GroupInvite?> {
  /// Provider to get an invite by ID
  const GetInviteByIdProvider._({
    required GetInviteByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'getInviteByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getInviteByIdHash();

  @override
  String toString() {
    return r'getInviteByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GroupInvite?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GroupInvite?> create(Ref ref) {
    final argument = this.argument as String;
    return getInviteById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetInviteByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getInviteByIdHash() => r'64aad7d018949f9501ad51c1b433f87208f9e6bc';

/// Provider to get an invite by ID

final class GetInviteByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GroupInvite?>, String> {
  const GetInviteByIdFamily._()
    : super(
        retry: null,
        name: r'getInviteByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to get an invite by ID

  GetInviteByIdProvider call(String inviteId) =>
      GetInviteByIdProvider._(argument: inviteId, from: this);

  @override
  String toString() => r'getInviteByIdProvider';
}

/// Provider to get all invites for a group

@ProviderFor(getGroupInvites)
const getGroupInvitesProvider = GetGroupInvitesFamily._();

/// Provider to get all invites for a group

final class GetGroupInvitesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupInvite>>,
          List<GroupInvite>,
          FutureOr<List<GroupInvite>>
        >
    with
        $FutureModifier<List<GroupInvite>>,
        $FutureProvider<List<GroupInvite>> {
  /// Provider to get all invites for a group
  const GetGroupInvitesProvider._({
    required GetGroupInvitesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'getGroupInvitesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getGroupInvitesHash();

  @override
  String toString() {
    return r'getGroupInvitesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<GroupInvite>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GroupInvite>> create(Ref ref) {
    final argument = this.argument as String;
    return getGroupInvites(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetGroupInvitesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getGroupInvitesHash() => r'61cb42c9384b06446aaff0bca6fb596553a2e407';

/// Provider to get all invites for a group

final class GetGroupInvitesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<GroupInvite>>, String> {
  const GetGroupInvitesFamily._()
    : super(
        retry: null,
        name: r'getGroupInvitesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to get all invites for a group

  GetGroupInvitesProvider call(String groupId) =>
      GetGroupInvitesProvider._(argument: groupId, from: this);

  @override
  String toString() => r'getGroupInvitesProvider';
}

/// Provider to watch pending invites for a group in real-time

@ProviderFor(watchGroupInvites)
const watchGroupInvitesProvider = WatchGroupInvitesFamily._();

/// Provider to watch pending invites for a group in real-time

final class WatchGroupInvitesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupInvite>>,
          List<GroupInvite>,
          Stream<List<GroupInvite>>
        >
    with
        $FutureModifier<List<GroupInvite>>,
        $StreamProvider<List<GroupInvite>> {
  /// Provider to watch pending invites for a group in real-time
  const WatchGroupInvitesProvider._({
    required WatchGroupInvitesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'watchGroupInvitesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$watchGroupInvitesHash();

  @override
  String toString() {
    return r'watchGroupInvitesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<GroupInvite>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GroupInvite>> create(Ref ref) {
    final argument = this.argument as String;
    return watchGroupInvites(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WatchGroupInvitesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$watchGroupInvitesHash() => r'c048ded127f3f8f020ebb28286bcd4b60e32d481';

/// Provider to watch pending invites for a group in real-time

final class WatchGroupInvitesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<GroupInvite>>, String> {
  const WatchGroupInvitesFamily._()
    : super(
        retry: null,
        name: r'watchGroupInvitesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to watch pending invites for a group in real-time

  WatchGroupInvitesProvider call(String groupId) =>
      WatchGroupInvitesProvider._(argument: groupId, from: this);

  @override
  String toString() => r'watchGroupInvitesProvider';
}

/// Provider to accept an invite by code

@ProviderFor(acceptInvite)
const acceptInviteProvider = AcceptInviteFamily._();

/// Provider to accept an invite by code

final class AcceptInviteProvider
    extends
        $FunctionalProvider<
          AsyncValue<GroupInvite>,
          GroupInvite,
          FutureOr<GroupInvite>
        >
    with $FutureModifier<GroupInvite>, $FutureProvider<GroupInvite> {
  /// Provider to accept an invite by code
  const AcceptInviteProvider._({
    required AcceptInviteFamily super.from,
    required ({String code, String userId}) super.argument,
  }) : super(
         retry: null,
         name: r'acceptInviteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$acceptInviteHash();

  @override
  String toString() {
    return r'acceptInviteProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<GroupInvite> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GroupInvite> create(Ref ref) {
    final argument = this.argument as ({String code, String userId});
    return acceptInvite(ref, code: argument.code, userId: argument.userId);
  }

  @override
  bool operator ==(Object other) {
    return other is AcceptInviteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$acceptInviteHash() => r'41619242e738e85993c73226c68f6d3b4d926194';

/// Provider to accept an invite by code

final class AcceptInviteFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<GroupInvite>,
          ({String code, String userId})
        > {
  const AcceptInviteFamily._()
    : super(
        retry: null,
        name: r'acceptInviteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to accept an invite by code

  AcceptInviteProvider call({required String code, required String userId}) =>
      AcceptInviteProvider._(
        argument: (code: code, userId: userId),
        from: this,
      );

  @override
  String toString() => r'acceptInviteProvider';
}

/// Provider to get invites created by a user

@ProviderFor(getUserInvites)
const getUserInvitesProvider = GetUserInvitesFamily._();

/// Provider to get invites created by a user

final class GetUserInvitesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupInvite>>,
          List<GroupInvite>,
          FutureOr<List<GroupInvite>>
        >
    with
        $FutureModifier<List<GroupInvite>>,
        $FutureProvider<List<GroupInvite>> {
  /// Provider to get invites created by a user
  const GetUserInvitesProvider._({
    required GetUserInvitesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'getUserInvitesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getUserInvitesHash();

  @override
  String toString() {
    return r'getUserInvitesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<GroupInvite>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GroupInvite>> create(Ref ref) {
    final argument = this.argument as String;
    return getUserInvites(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GetUserInvitesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getUserInvitesHash() => r'eed7623cb693f1e4d4d0f48129c85ed0eb75279a';

/// Provider to get invites created by a user

final class GetUserInvitesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<GroupInvite>>, String> {
  const GetUserInvitesFamily._()
    : super(
        retry: null,
        name: r'getUserInvitesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to get invites created by a user

  GetUserInvitesProvider call(String userId) =>
      GetUserInvitesProvider._(argument: userId, from: this);

  @override
  String toString() => r'getUserInvitesProvider';
}

/// Provider to check if user has pending invite to group

@ProviderFor(hasPendingInvite)
const hasPendingInviteProvider = HasPendingInviteFamily._();

/// Provider to check if user has pending invite to group

final class HasPendingInviteProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Provider to check if user has pending invite to group
  const HasPendingInviteProvider._({
    required HasPendingInviteFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'hasPendingInviteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hasPendingInviteHash();

  @override
  String toString() {
    return r'hasPendingInviteProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as (String, String);
    return hasPendingInvite(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is HasPendingInviteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hasPendingInviteHash() => r'347bf90f7e2c36b799a27ac943f937600ed28264';

/// Provider to check if user has pending invite to group

final class HasPendingInviteFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, (String, String)> {
  const HasPendingInviteFamily._()
    : super(
        retry: null,
        name: r'hasPendingInviteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to check if user has pending invite to group

  HasPendingInviteProvider call(String userId, String groupId) =>
      HasPendingInviteProvider._(argument: (userId, groupId), from: this);

  @override
  String toString() => r'hasPendingInviteProvider';
}

/// Provider to cancel an invite

@ProviderFor(cancelInvite)
const cancelInviteProvider = CancelInviteFamily._();

/// Provider to cancel an invite

final class CancelInviteProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Provider to cancel an invite
  const CancelInviteProvider._({
    required CancelInviteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cancelInviteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cancelInviteHash();

  @override
  String toString() {
    return r'cancelInviteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return cancelInvite(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CancelInviteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cancelInviteHash() => r'a6d85778c61e3d7b1c6935070358fa7f99aec345';

/// Provider to cancel an invite

final class CancelInviteFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  const CancelInviteFamily._()
    : super(
        retry: null,
        name: r'cancelInviteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to cancel an invite

  CancelInviteProvider call(String inviteId) =>
      CancelInviteProvider._(argument: inviteId, from: this);

  @override
  String toString() => r'cancelInviteProvider';
}

/// Provider to expire an invite

@ProviderFor(expireInvite)
const expireInviteProvider = ExpireInviteFamily._();

/// Provider to expire an invite

final class ExpireInviteProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Provider to expire an invite
  const ExpireInviteProvider._({
    required ExpireInviteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'expireInviteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expireInviteHash();

  @override
  String toString() {
    return r'expireInviteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as String;
    return expireInvite(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExpireInviteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expireInviteHash() => r'59ff29b78339c815beed1cc3bb3894fae656b393';

/// Provider to expire an invite

final class ExpireInviteFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, String> {
  const ExpireInviteFamily._()
    : super(
        retry: null,
        name: r'expireInviteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to expire an invite

  ExpireInviteProvider call(String inviteId) =>
      ExpireInviteProvider._(argument: inviteId, from: this);

  @override
  String toString() => r'expireInviteProvider';
}
