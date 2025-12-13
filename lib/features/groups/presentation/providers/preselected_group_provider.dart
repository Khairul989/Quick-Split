import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier for managing pre-selected group state
class PreselectedGroupNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Set the pre-selected group ID
  void setGroupId(String? groupId) {
    state = groupId;
  }

  /// Clear the pre-selected group ID
  void clear() {
    state = null;
  }
}

/// Provider that holds the ID of a pre-selected group for the next split session.
/// Used when user taps "Use for New Split" from home screen.
///
/// The provider is automatically cleared after the group is used in GroupSelectScreen.
final preselectedGroupIdProvider =
    NotifierProvider<PreselectedGroupNotifier, String?>(
      PreselectedGroupNotifier.new,
    );
