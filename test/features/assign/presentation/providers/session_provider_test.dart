import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:quicksplit/features/assign/domain/models/item_assignment.dart';
import 'package:quicksplit/features/assign/domain/models/person_share.dart';
import 'package:quicksplit/features/assign/domain/models/split_session.dart';
import 'package:quicksplit/features/assign/presentation/providers/assignment_providers.dart';
import 'package:quicksplit/features/assign/presentation/providers/calculator_provider.dart';
import 'package:quicksplit/features/assign/presentation/providers/session_provider.dart';
import 'package:quicksplit/features/groups/domain/models/group.dart';
import 'package:quicksplit/features/groups/domain/models/person.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';

void main() {
  late ProviderContainer container;

  setUpAll(() async {
    Hive.init('.');

    // Register all required adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ReceiptAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ReceiptItemAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(PersonAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(GroupAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ItemAssignmentAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(SplitSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(PersonShareAdapter());
    }
  });

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('SessionState', () {
    test('constructor creates state with default values', () {
      const state = SessionState();

      expect(state.currentSession, isNull);
      expect(state.currentReceipt, isNull);
      expect(state.selectedGroup, isNull);
      expect(state.participants, isEmpty);
      expect(state.isSaving, isFalse);
      expect(state.error, isNull);
    });

    test('copyWith creates new instance with specified fields', () {
      const state = SessionState(
        isSaving: true,
        error: 'Test error',
        participants: [],
      );

      final updated = state.copyWith(isSaving: false, error: null);

      expect(updated.isSaving, isFalse);
      expect(updated.error, isNull);
      expect(updated.participants, isEmpty);
    });

    test('copyWith preserves unspecified fields', () {
      const state = SessionState(participants: [], isSaving: false);

      final updated = state.copyWith(isSaving: true);

      expect(updated.participants, isEmpty);
      expect(updated.isSaving, isTrue);
    });
  });

  group('SessionNotifier.startSession', () {
    test('startSession initializes state correctly', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: 'item1', name: 'Item 1', quantity: 1, price: 50.0),
        ],
        subtotal: 50.0,
        total: 50.0,
      );

      final person1 = Person(id: 'p1', name: 'Alice', emoji: '👩');
      final person2 = Person(id: 'p2', name: 'Bob', emoji: '👨');
      final participants = [person1, person2];

      container
          .read(sessionProvider.notifier)
          .startSession(
            receipt: receipt,
            group: null,
            participants: participants,
          );

      final state = container.read(sessionProvider);

      expect(state.currentSession, isNotNull);
      expect(state.currentSession!.receiptId, equals(receipt.id));
      expect(state.currentSession!.groupId, isNull);
      expect(state.currentSession!.participantPersonIds, equals(['p1', 'p2']));
      expect(state.currentReceipt, equals(receipt));
      expect(state.selectedGroup, isNull);
      expect(state.participants, equals(participants));
    });

    test('startSession includes group when provided', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: 'item1', name: 'Item 1', quantity: 1, price: 50.0),
        ],
        subtotal: 50.0,
        total: 50.0,
      );

      final group = Group(
        id: 'group1',
        name: 'Friends',
        personIds: ['p1', 'p2'],
      );

      final person1 = Person(id: 'p1', name: 'Alice', emoji: '👩');
      final person2 = Person(id: 'p2', name: 'Bob', emoji: '👨');
      final participants = [person1, person2];

      container
          .read(sessionProvider.notifier)
          .startSession(
            receipt: receipt,
            group: group,
            participants: participants,
          );

      final state = container.read(sessionProvider);

      expect(state.currentSession!.groupId, equals('group1'));
      expect(state.selectedGroup, equals(group));
    });

    test('startSession initializes assignment provider', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: 'item1', name: 'Item 1', quantity: 1, price: 50.0),
          ReceiptItem(id: 'item2', name: 'Item 2', quantity: 1, price: 30.0),
        ],
        subtotal: 80.0,
        total: 80.0,
      );

      final person1 = Person(id: 'p1', name: 'Alice', emoji: '👩');
      final person2 = Person(id: 'p2', name: 'Bob', emoji: '👨');
      final participants = [person1, person2];

      container
          .read(sessionProvider.notifier)
          .startSession(
            receipt: receipt,
            group: null,
            participants: participants,
          );

      final assignmentState = container.read(assignmentProvider);

      expect(assignmentState.assignments.length, equals(2));
      expect(assignmentState.assignments.containsKey('item1'), isTrue);
      expect(assignmentState.assignments.containsKey('item2'), isTrue);
      expect(assignmentState.participantPersonIds, equals(['p1', 'p2']));
    });
  });

  group('SessionNotifier.saveSession', () {
    test('saveSession saves to Hive history box', () async {
      // Setup Hive boxes
      try {
        await Hive.openBox<SplitSession>('history');
      } catch (e) {
        // Box might already exist
      }

      final receipt = Receipt(
        items: [
          ReceiptItem(id: 'item1', name: 'Item 1', quantity: 1, price: 50.0),
        ],
        subtotal: 50.0,
        total: 50.0,
      );

      final person1 = Person(id: 'p1', name: 'Alice', emoji: '👩');
      final participants = [person1];

      container
          .read(sessionProvider.notifier)
          .startSession(
            receipt: receipt,
            group: null,
            participants: participants,
          );

      // Assign the item to the person
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('item1', 'p1');

      await container.read(sessionProvider.notifier).saveSession();

      final historyBox = Hive.box<SplitSession>('history');
      final savedSessions = historyBox.values.toList();

      expect(savedSessions.length, equals(1));
      expect(savedSessions.first.receiptId, equals(receipt.id));
      expect(savedSessions.first.isSaved, isTrue);

      await Hive.deleteBoxFromDisk('history');
    });

    test('saveSession updates group lastUsedAt and usageCount', () async {
      // Setup Hive boxes
      try {
        await Hive.openBox<SplitSession>('history');
        await Hive.openBox<Group>('groups');
      } catch (e) {
        // Boxes might already exist
      }

      final receipt = Receipt(
        items: [
          ReceiptItem(id: 'item1', name: 'Item 1', quantity: 1, price: 50.0),
        ],
        subtotal: 50.0,
        total: 50.0,
      );

      final group = Group(id: 'group1', name: 'Friends', personIds: ['p1']);

      final groupsBox = Hive.box<Group>('groups');
      await groupsBox.put('group1', group);

      final initialUsageCount = group.usageCount;
      final initialLastUsedAt = group.lastUsedAt;

      final person1 = Person(id: 'p1', name: 'Alice', emoji: '👩');
      final participants = [person1];

      container
          .read(sessionProvider.notifier)
          .startSession(
            receipt: receipt,
            group: group,
            participants: participants,
          );

      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('item1', 'p1');

      await container.read(sessionProvider.notifier).saveSession();

      final updatedGroup = groupsBox.get('group1');

      expect(updatedGroup!.usageCount, equals(initialUsageCount + 1));
      expect(updatedGroup.lastUsedAt.isAfter(initialLastUsedAt), isTrue);

      await Hive.deleteBoxFromDisk('history');
      await Hive.deleteBoxFromDisk('groups');
    });

    test('saveSession calculates and stores shares', () async {
      // Setup Hive boxes
      try {
        await Hive.openBox<SplitSession>('history');
      } catch (e) {
        // Box might already exist
      }

      final receipt = Receipt(
        items: [
          ReceiptItem(id: 'item1', name: 'Item 1', quantity: 1, price: 50.0),
          ReceiptItem(id: 'item2', name: 'Item 2', quantity: 1, price: 30.0),
        ],
        subtotal: 80.0,
        sst: 0.0,
        serviceCharge: 0.0,
        rounding: 0.0,
        total: 80.0,
      );

      final person1 = Person(id: 'p1', name: 'Alice', emoji: '👩');
      final person2 = Person(id: 'p2', name: 'Bob', emoji: '👨');
      final participants = [person1, person2];

      container
          .read(sessionProvider.notifier)
          .startSession(
            receipt: receipt,
            group: null,
            participants: participants,
          );

      // Assign items: item1 to p1, item2 to p2
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('item1', 'p1');
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('item2', 'p2');

      await container.read(sessionProvider.notifier).saveSession();

      final savedState = container.read(sessionProvider);
      final savedSession = savedState.currentSession;

      expect(savedSession!.calculatedShares.length, equals(2));
      expect(
        savedSession.calculatedShares.any((s) => s.personId == 'p1'),
        isTrue,
      );
      expect(
        savedSession.calculatedShares.any((s) => s.personId == 'p2'),
        isTrue,
      );

      await Hive.deleteBoxFromDisk('history');
    });

    test('saveSession sets isSaving to true during save', () async {
      // Setup Hive boxes
      try {
        await Hive.openBox<SplitSession>('history');
      } catch (e) {
        // Box might already exist
      }

      final receipt = Receipt(
        items: [
          ReceiptItem(id: 'item1', name: 'Item 1', quantity: 1, price: 50.0),
        ],
        subtotal: 50.0,
        total: 50.0,
      );

      final person1 = Person(id: 'p1', name: 'Alice', emoji: '👩');

      container
          .read(sessionProvider.notifier)
          .startSession(receipt: receipt, group: null, participants: [person1]);

      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('item1', 'p1');

      final saveFuture = container.read(sessionProvider.notifier).saveSession();

      // At some point during save, isSaving should be true
      await saveFuture;

      // After save completes, isSaving should be false
      final state = container.read(sessionProvider);
      expect(state.isSaving, isFalse);

      await Hive.deleteBoxFromDisk('history');
    });

    test('saveSession with no active session sets error', () async {
      final state = container.read(sessionProvider);
      expect(state.currentSession, isNull);

      await container.read(sessionProvider.notifier).saveSession();

      final errorState = container.read(sessionProvider);
      expect(errorState.error, equals('No active session'));
    });

    test('saveSession clears error on successful save', () async {
      // Setup Hive boxes
      try {
        await Hive.openBox<SplitSession>('history');
      } catch (e) {
        // Box might already exist
      }

      final receipt = Receipt(
        items: [
          ReceiptItem(id: 'item1', name: 'Item 1', quantity: 1, price: 50.0),
        ],
        subtotal: 50.0,
        total: 50.0,
      );

      final person1 = Person(id: 'p1', name: 'Alice', emoji: '👩');

      container
          .read(sessionProvider.notifier)
          .startSession(receipt: receipt, group: null, participants: [person1]);

      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('item1', 'p1');

      await container.read(sessionProvider.notifier).saveSession();

      final state = container.read(sessionProvider);
      expect(state.error, isNull);

      await Hive.deleteBoxFromDisk('history');
    });
  });

  group('SessionNotifier.resetSession', () {
    test('resetSession clears all session state', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: 'item1', name: 'Item 1', quantity: 1, price: 50.0),
        ],
        subtotal: 50.0,
        total: 50.0,
      );

      final person1 = Person(id: 'p1', name: 'Alice', emoji: '👩');

      container
          .read(sessionProvider.notifier)
          .startSession(receipt: receipt, group: null, participants: [person1]);

      // Verify session is active
      expect(container.read(sessionProvider).currentSession, isNotNull);

      container.read(sessionProvider.notifier).resetSession();

      final state = container.read(sessionProvider);
      expect(state.currentSession, isNull);
      expect(state.currentReceipt, isNull);
      expect(state.selectedGroup, isNull);
      expect(state.participants, isEmpty);
    });

    test('resetSession clears assignment provider', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: 'item1', name: 'Item 1', quantity: 1, price: 50.0),
          ReceiptItem(id: 'item2', name: 'Item 2', quantity: 1, price: 30.0),
        ],
        subtotal: 80.0,
        total: 80.0,
      );

      final person1 = Person(id: 'p1', name: 'Alice', emoji: '👩');

      container
          .read(sessionProvider.notifier)
          .startSession(receipt: receipt, group: null, participants: [person1]);

      // Assign items
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('item1', 'p1');
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('item2', 'p1');

      // Verify items are assigned
      expect(container.read(assignmentProvider).isFullyAssigned(), isTrue);

      container.read(sessionProvider.notifier).resetSession();

      final assignmentState = container.read(assignmentProvider);
      expect(assignmentState.getUnassignedCount(), equals(2));
    });

    test('resetSession resets calculator provider', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: 'item1', name: 'Item 1', quantity: 1, price: 50.0),
        ],
        subtotal: 50.0,
        total: 50.0,
      );

      final person1 = Person(id: 'p1', name: 'Alice', emoji: '👩');

      container
          .read(sessionProvider.notifier)
          .startSession(receipt: receipt, group: null, participants: [person1]);

      // Trigger calculation
      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: [person1],
            assignments: container.read(assignmentProvider).assignments,
          );

      // Verify calculation state is not empty
      expect(container.read(calculatorProvider).shares, isNotEmpty);

      container.read(sessionProvider.notifier).resetSession();

      final calculatorState = container.read(calculatorProvider);
      expect(calculatorState.shares, isEmpty);
      expect(calculatorState.isCalculated, isFalse);
    });
  });

  group('isSessionActiveProvider', () {
    test('isSessionActiveProvider returns false when no session active', () {
      final isActive = container.read(isSessionActiveProvider);
      expect(isActive, isFalse);
    });

    test('isSessionActiveProvider returns true when session active', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: 'item1', name: 'Item 1', quantity: 1, price: 50.0),
        ],
        subtotal: 50.0,
        total: 50.0,
      );

      final person1 = Person(id: 'p1', name: 'Alice', emoji: '👩');

      container
          .read(sessionProvider.notifier)
          .startSession(receipt: receipt, group: null, participants: [person1]);

      final isActive = container.read(isSessionActiveProvider);
      expect(isActive, isTrue);
    });

    test('isSessionActiveProvider returns false after reset', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: 'item1', name: 'Item 1', quantity: 1, price: 50.0),
        ],
        subtotal: 50.0,
        total: 50.0,
      );

      final person1 = Person(id: 'p1', name: 'Alice', emoji: '👩');

      container
          .read(sessionProvider.notifier)
          .startSession(receipt: receipt, group: null, participants: [person1]);

      expect(container.read(isSessionActiveProvider), isTrue);

      container.read(sessionProvider.notifier).resetSession();

      expect(container.read(isSessionActiveProvider), isFalse);
    });
  });
}
