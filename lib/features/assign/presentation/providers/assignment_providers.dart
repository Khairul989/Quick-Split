import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/item_assignment.dart';
import '../../../ocr/domain/models/receipt.dart';

/// Represents the state of item-to-person assignments.
class AssignmentState {
  /// Map of itemId to ItemAssignment
  final Map<String, ItemAssignment> assignments;

  /// List of participant person IDs
  final List<String> participantPersonIds;

  /// Loading state indicator
  final bool isLoading;

  const AssignmentState({
    required this.assignments,
    required this.participantPersonIds,
    this.isLoading = false,
  });

  /// Create a copy of this state with optional field overrides.
  AssignmentState copyWith({
    Map<String, ItemAssignment>? assignments,
    List<String>? participantPersonIds,
    bool? isLoading,
  }) {
    return AssignmentState(
      assignments: assignments ?? this.assignments,
      participantPersonIds: participantPersonIds ?? this.participantPersonIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Get the assignment for a specific item.
  ItemAssignment? getAssignment(String itemId) => assignments[itemId];

  /// Check if an item has been assigned to at least one person.
  bool isItemAssigned(String itemId) {
    final assignment = assignments[itemId];
    return assignment != null && assignment.isAssigned;
  }

  /// Get the list of person IDs assigned to an item.
  List<String> getAssignedPersonIds(String itemId) {
    final assignment = assignments[itemId];
    return assignment?.assignedPersonIds ?? [];
  }

  /// Get the count of unassigned items.
  int getUnassignedCount() {
    return assignments.values.where((assignment) => !assignment.isAssigned).length;
  }

  /// Check if all items are assigned to at least one person.
  bool isFullyAssigned() => getUnassignedCount() == 0 && assignments.isNotEmpty;
}

/// Notifier that manages item-to-person assignments using Riverpod 3.0 pattern.
class AssignmentNotifier extends Notifier<AssignmentState> {
  @override
  AssignmentState build() {
    return const AssignmentState(
      assignments: {},
      participantPersonIds: [],
    );
  }

  /// Initialize assignments with items and participants.
  ///
  /// Creates a new ItemAssignment for each item with empty assignedPersonIds.
  void initialize(List<ReceiptItem> items, List<String> personIds) {
    final assignments = <String, ItemAssignment>{};
    for (final item in items) {
      assignments[item.id] = ItemAssignment(
        itemId: item.id,
        assignedPersonIds: [],
      );
    }

    state = AssignmentState(
      assignments: assignments,
      participantPersonIds: personIds,
    );
  }

  /// Toggle a person's assignment for an item.
  ///
  /// If the person is already assigned to the item, removes them.
  /// If the person is not assigned, adds them.
  void togglePersonForItem(String itemId, String personId) {
    final assignment = state.assignments[itemId];
    if (assignment == null) return;

    assignment.togglePerson(personId);

    state = state.copyWith(
      assignments: {...state.assignments},
    );
  }

  /// Assign all items to a single person.
  ///
  /// Clears existing assignments and assigns every item to the specified person.
  void assignAllItemsToPerson(String personId) {
    final assignments = <String, ItemAssignment>{};

    for (final entry in state.assignments.entries) {
      assignments[entry.key] = entry.value.copyWith(
        assignedPersonIds: [personId],
      );
    }

    state = state.copyWith(assignments: assignments);
  }

  /// Clear all item assignments.
  ///
  /// Resets all items to unassigned state.
  void clearAssignments() {
    final assignments = <String, ItemAssignment>{};

    for (final entry in state.assignments.entries) {
      assignments[entry.key] = entry.value.copyWith(
        assignedPersonIds: [],
      );
    }

    state = state.copyWith(assignments: assignments);
  }

  /// Clear the assignment for a specific item.
  ///
  /// Removes all person assignments from the specified item.
  void clearItemAssignment(String itemId) {
    final assignment = state.assignments[itemId];
    if (assignment == null) return;

    state = state.copyWith(
      assignments: {
        ...state.assignments,
        itemId: assignment.copyWith(assignedPersonIds: []),
      },
    );
  }
}

/// Provider for managing item-to-person assignments.
final assignmentProvider = NotifierProvider<AssignmentNotifier, AssignmentState>(
  () => AssignmentNotifier(),
);

/// Computed provider for the count of unassigned items.
final unassignedItemsCountProvider = Provider<int>((ref) {
  final state = ref.watch(assignmentProvider);
  return state.getUnassignedCount();
});

/// Computed provider indicating whether all items are fully assigned.
final isFullyAssignedProvider = Provider<bool>((ref) {
  final state = ref.watch(assignmentProvider);
  return state.isFullyAssigned();
});
