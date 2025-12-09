import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import '../../domain/models/split_session.dart';
import '../../../ocr/domain/models/receipt.dart';
import '../../../groups/domain/models/group.dart';
import '../../../groups/domain/models/person.dart';
import 'assignment_providers.dart';
import 'calculator_provider.dart';

/// Represents the state of the current split session.
///
/// This state object holds all information about an active split session,
/// including the receipt, selected group, participants, and save status.
class SessionState {
  /// The current active split session, null if no session is active
  final SplitSession? currentSession;

  /// The receipt being split in the current session
  final Receipt? currentReceipt;

  /// The group selected for the current session, null if no group
  final Group? selectedGroup;

  /// List of participants in the current session
  final List<Person> participants;

  /// Whether the session is currently being saved
  final bool isSaving;

  /// Error message if an operation failed, null if no error
  final String? error;

  const SessionState({
    this.currentSession,
    this.currentReceipt,
    this.selectedGroup,
    this.participants = const [],
    this.isSaving = false,
    this.error,
  });

  /// Create a copy of this state with optional field overrides.
  SessionState copyWith({
    SplitSession? currentSession,
    Receipt? currentReceipt,
    Group? selectedGroup,
    List<Person>? participants,
    bool? isSaving,
    String? error,
  }) {
    return SessionState(
      currentSession: currentSession ?? this.currentSession,
      currentReceipt: currentReceipt ?? this.currentReceipt,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      participants: participants ?? this.participants,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

/// Notifier that manages the split session lifecycle.
///
/// This notifier orchestrates the entire session, coordinating with
/// assignment and calculator providers to manage state across the split flow.
class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    return const SessionState();
  }

  /// Start a new split session with a receipt and participants.
  ///
  /// Initializes the session state and coordinates initialization of
  /// assignment and calculator providers. This method should be called
  /// when a user begins splitting a receipt.
  ///
  /// Parameters:
  /// - receipt: The receipt to split
  /// - group: Optional group containing the participants
  /// - participants: List of people participating in the split
  void startSession({
    required Receipt receipt,
    Group? group,
    required List<Person> participants,
  }) {
    final session = SplitSession(
      receiptId: receipt.id,
      groupId: group?.id,
      participantPersonIds: participants.map((p) => p.id).toList(),
      assignments: [],
      calculatedShares: [],
    );

    state = SessionState(
      currentSession: session,
      currentReceipt: receipt,
      selectedGroup: group,
      participants: participants,
    );

    // Initialize assignment provider with receipt items and participant IDs
    ref
        .read(assignmentProvider.notifier)
        .initialize(receipt.items, participants.map((p) => p.id).toList());
  }

  /// Save the current session to Hive history and update group usage.
  ///
  /// Performs the following operations:
  /// 1. Retrieves current assignments from assignment provider
  /// 2. Calculates final shares using calculator provider
  /// 3. Updates session with assignments and calculated shares
  /// 4. Saves session to Hive history box
  /// 5. Updates group lastUsedAt and usageCount if a group was used
  ///
  /// Throws an exception if save fails; the error is also stored in state.
  /// Sets isSaving to true during the operation.
  Future<void> saveSession() async {
    if (state.currentSession == null || state.currentReceipt == null) {
      state = state.copyWith(error: 'No active session');
      return;
    }

    state = state.copyWith(isSaving: true, error: null);

    try {
      // Get current assignments from assignment provider
      final assignments = ref
          .read(assignmentProvider)
          .assignments
          .values
          .toList();

      // Calculate shares based on current receipt and assignments
      ref
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: state.currentReceipt!,
            participants: state.participants,
            assignments: ref.read(assignmentProvider).assignments,
          );
      final shares = ref.read(calculatorProvider).shares;

      // Update session with completed assignments and calculated shares
      final updatedSession = state.currentSession!.copyWith(
        assignments: assignments,
        calculatedShares: shares,
        isSaved: true,
      );

      // Save session to Hive history box
      final historyBox = Hive.box<SplitSession>('history');
      await historyBox.put(updatedSession.id, updatedSession);

      // Save receipt to receipts box so recent splits can display it
      final receiptsBox = Hive.box<Receipt>('receipts');
      await receiptsBox.put(state.currentReceipt!.id, state.currentReceipt!);

      // Update group usage statistics if a group was selected
      if (state.selectedGroup != null) {
        state.selectedGroup!.markUsed();
        final groupsBox = Hive.box<Group>('groups');
        await groupsBox.put(state.selectedGroup!.id, state.selectedGroup!);
      }

      // Update state with saved session
      state = state.copyWith(currentSession: updatedSession, isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save session: $e',
      );
      rethrow;
    }
  }

  /// Reset the session after save or cancellation.
  ///
  /// Clears all session state and resets dependent providers
  /// (assignment and calculator). Call this after successfully saving
  /// or when canceling a session.
  void resetSession() {
    state = const SessionState();
    ref.read(assignmentProvider.notifier).clearAssignments();
    ref.read(calculatorProvider.notifier).reset();
  }
}

/// Provider for the session notifier and state.
///
/// This provider manages the lifecycle of a split session, including
/// initialization, assignment tracking, calculation, and persistence.
final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(
  SessionNotifier.new,
);

/// Computed provider indicating whether a session is currently active.
///
/// Returns true if currentSession is not null, indicating an ongoing split.
final isSessionActiveProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider).currentSession != null;
});
