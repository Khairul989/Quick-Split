import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksplit/features/assign/domain/models/item_assignment.dart';
import 'package:quicksplit/features/assign/presentation/providers/assignment_providers.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('AssignmentState', () {
    test('getUnassignedCount returns correct count of unassigned items', () {
      final assignment1 = ItemAssignment(itemId: '1', assignedPersonIds: []);
      final assignment2 = ItemAssignment(
        itemId: '2',
        assignedPersonIds: ['p1'],
      );
      final assignment3 = ItemAssignment(itemId: '3', assignedPersonIds: []);

      final state = AssignmentState(
        assignments: {'1': assignment1, '2': assignment2, '3': assignment3},
        participantPersonIds: ['p1', 'p2'],
      );

      expect(state.getUnassignedCount(), 2);
    });

    test('isFullyAssigned returns true when all items are assigned', () {
      final assignment1 = ItemAssignment(
        itemId: '1',
        assignedPersonIds: ['p1'],
      );
      final assignment2 = ItemAssignment(
        itemId: '2',
        assignedPersonIds: ['p2'],
      );

      final state = AssignmentState(
        assignments: {'1': assignment1, '2': assignment2},
        participantPersonIds: ['p1', 'p2'],
      );

      expect(state.isFullyAssigned(), true);
    });

    test('isFullyAssigned returns false when some items are unassigned', () {
      final assignment1 = ItemAssignment(
        itemId: '1',
        assignedPersonIds: ['p1'],
      );
      final assignment2 = ItemAssignment(itemId: '2', assignedPersonIds: []);

      final state = AssignmentState(
        assignments: {'1': assignment1, '2': assignment2},
        participantPersonIds: ['p1', 'p2'],
      );

      expect(state.isFullyAssigned(), false);
    });

    test('isFullyAssigned returns false when assignments are empty', () {
      final state = AssignmentState(
        assignments: {},
        participantPersonIds: ['p1', 'p2'],
      );

      expect(state.isFullyAssigned(), false);
    });

    test('getAssignment returns correct assignment for item', () {
      final assignment1 = ItemAssignment(
        itemId: '1',
        assignedPersonIds: ['p1'],
      );
      final assignment2 = ItemAssignment(itemId: '2', assignedPersonIds: []);

      final state = AssignmentState(
        assignments: {'1': assignment1, '2': assignment2},
        participantPersonIds: ['p1', 'p2'],
      );

      expect(state.getAssignment('1'), assignment1);
      expect(state.getAssignment('2'), assignment2);
      expect(state.getAssignment('3'), null);
    });

    test('isItemAssigned returns true only for assigned items', () {
      final assignment1 = ItemAssignment(
        itemId: '1',
        assignedPersonIds: ['p1'],
      );
      final assignment2 = ItemAssignment(itemId: '2', assignedPersonIds: []);

      final state = AssignmentState(
        assignments: {'1': assignment1, '2': assignment2},
        participantPersonIds: ['p1', 'p2'],
      );

      expect(state.isItemAssigned('1'), true);
      expect(state.isItemAssigned('2'), false);
      expect(state.isItemAssigned('3'), false);
    });

    test('getAssignedPersonIds returns correct person IDs for item', () {
      final assignment1 = ItemAssignment(
        itemId: '1',
        assignedPersonIds: ['p1', 'p2'],
      );
      final assignment2 = ItemAssignment(itemId: '2', assignedPersonIds: []);

      final state = AssignmentState(
        assignments: {'1': assignment1, '2': assignment2},
        participantPersonIds: ['p1', 'p2'],
      );

      expect(state.getAssignedPersonIds('1'), ['p1', 'p2']);
      expect(state.getAssignedPersonIds('2'), []);
      expect(state.getAssignedPersonIds('3'), []);
    });

    test('copyWith creates new state with updated fields', () {
      final assignment1 = ItemAssignment(
        itemId: '1',
        assignedPersonIds: ['p1'],
      );
      final assignment2 = ItemAssignment(itemId: '2', assignedPersonIds: []);
      final state = AssignmentState(
        assignments: {'1': assignment1, '2': assignment2},
        participantPersonIds: ['p1', 'p2'],
      );

      final newAssignment = ItemAssignment(
        itemId: '3',
        assignedPersonIds: ['p1'],
      );
      final newState = state.copyWith(
        assignments: {...state.assignments, '3': newAssignment},
        isLoading: true,
      );

      expect(newState.assignments.length, 3);
      expect(newState.isLoading, true);
      expect(newState.participantPersonIds, ['p1', 'p2']);
    });
  });

  group('AssignmentNotifier', () {
    test('initialize creates assignments for all items', () {
      final items = [
        ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
        ReceiptItem(id: '2', name: 'Coke', quantity: 2, price: 5.0),
      ];
      final personIds = ['p1', 'p2'];

      container.read(assignmentProvider.notifier).initialize(items, personIds);

      final state = container.read(assignmentProvider);
      expect(state.assignments.length, 2);
      expect(state.assignments['1'], isNotNull);
      expect(state.assignments['2'], isNotNull);
      expect(state.participantPersonIds, personIds);
      expect(state.assignments['1']?.assignedPersonIds, []);
      expect(state.assignments['2']?.assignedPersonIds, []);
    });

    test('togglePersonForItem adds person to item when not assigned', () {
      final items = [
        ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
      ];
      const personIds = ['p1', 'p2'];

      container.read(assignmentProvider.notifier).initialize(items, personIds);
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p1');

      final state = container.read(assignmentProvider);
      expect(state.assignments['1']?.assignedPersonIds, ['p1']);
    });

    test(
      'togglePersonForItem removes person from item when already assigned',
      () {
        final items = [
          ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
        ];
        const personIds = ['p1', 'p2'];

        container
            .read(assignmentProvider.notifier)
            .initialize(items, personIds);
        container
            .read(assignmentProvider.notifier)
            .togglePersonForItem('1', 'p1');
        container
            .read(assignmentProvider.notifier)
            .togglePersonForItem('1', 'p1');

        final state = container.read(assignmentProvider);
        expect(state.assignments['1']?.assignedPersonIds, []);
      },
    );

    test('togglePersonForItem handles multiple persons per item', () {
      final items = [
        ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
      ];
      const personIds = ['p1', 'p2', 'p3'];

      container.read(assignmentProvider.notifier).initialize(items, personIds);
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p1');
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p2');

      final state = container.read(assignmentProvider);
      expect(state.assignments['1']?.assignedPersonIds, ['p1', 'p2']);
    });

    test('unassignedItemsCountProvider returns correct count', () {
      final items = [
        ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
        ReceiptItem(id: '2', name: 'Coke', quantity: 2, price: 5.0),
        ReceiptItem(id: '3', name: 'Burger', quantity: 1, price: 15.0),
      ];
      const personIds = ['p1', 'p2'];

      container.read(assignmentProvider.notifier).initialize(items, personIds);
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p1');

      final count = container.read(unassignedItemsCountProvider);
      expect(count, 2);
    });

    test('isFullyAssignedProvider returns false when items are unassigned', () {
      final items = [
        ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
        ReceiptItem(id: '2', name: 'Coke', quantity: 2, price: 5.0),
      ];
      const personIds = ['p1', 'p2'];

      container.read(assignmentProvider.notifier).initialize(items, personIds);
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p1');

      final isFullyAssigned = container.read(isFullyAssignedProvider);
      expect(isFullyAssigned, false);
    });

    test('isFullyAssignedProvider returns true when all items assigned', () {
      final items = [
        ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
        ReceiptItem(id: '2', name: 'Coke', quantity: 2, price: 5.0),
      ];
      const personIds = ['p1', 'p2'];

      container.read(assignmentProvider.notifier).initialize(items, personIds);
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p1');
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('2', 'p2');

      final isFullyAssigned = container.read(isFullyAssignedProvider);
      expect(isFullyAssigned, true);
    });

    test('assignAllItemsToPerson assigns all items to one person', () {
      final items = [
        ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
        ReceiptItem(id: '2', name: 'Coke', quantity: 2, price: 5.0),
        ReceiptItem(id: '3', name: 'Burger', quantity: 1, price: 15.0),
      ];
      const personIds = ['p1', 'p2'];

      container.read(assignmentProvider.notifier).initialize(items, personIds);
      container.read(assignmentProvider.notifier).assignAllItemsToPerson('p1');

      final state = container.read(assignmentProvider);
      expect(state.assignments['1']?.assignedPersonIds, ['p1']);
      expect(state.assignments['2']?.assignedPersonIds, ['p1']);
      expect(state.assignments['3']?.assignedPersonIds, ['p1']);
    });

    test('assignAllItemsToPerson replaces existing assignments', () {
      final items = [
        ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
        ReceiptItem(id: '2', name: 'Coke', quantity: 2, price: 5.0),
      ];
      const personIds = ['p1', 'p2'];

      container.read(assignmentProvider.notifier).initialize(items, personIds);
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p1');
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p2');
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('2', 'p2');

      container.read(assignmentProvider.notifier).assignAllItemsToPerson('p1');

      final state = container.read(assignmentProvider);
      expect(state.assignments['1']?.assignedPersonIds, ['p1']);
      expect(state.assignments['2']?.assignedPersonIds, ['p1']);
    });

    test('clearAssignments resets all assignments to empty', () {
      final items = [
        ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
        ReceiptItem(id: '2', name: 'Coke', quantity: 2, price: 5.0),
      ];
      const personIds = ['p1', 'p2'];

      container.read(assignmentProvider.notifier).initialize(items, personIds);
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p1');
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p2');
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('2', 'p1');

      container.read(assignmentProvider.notifier).clearAssignments();

      final state = container.read(assignmentProvider);
      expect(state.assignments['1']?.assignedPersonIds, []);
      expect(state.assignments['2']?.assignedPersonIds, []);
    });

    test('clearItemAssignment clears assignment for specific item', () {
      final items = [
        ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
        ReceiptItem(id: '2', name: 'Coke', quantity: 2, price: 5.0),
      ];
      const personIds = ['p1', 'p2'];

      container.read(assignmentProvider.notifier).initialize(items, personIds);
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p1');
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('2', 'p2');

      container.read(assignmentProvider.notifier).clearItemAssignment('1');

      final state = container.read(assignmentProvider);
      expect(state.assignments['1']?.assignedPersonIds, []);
      expect(state.assignments['2']?.assignedPersonIds, ['p2']);
    });

    test('clearItemAssignment does nothing for non-existent item', () {
      final items = [
        ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
      ];
      const personIds = ['p1'];

      container.read(assignmentProvider.notifier).initialize(items, personIds);
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p1');

      container.read(assignmentProvider.notifier).clearItemAssignment('999');

      final state = container.read(assignmentProvider);
      expect(state.assignments['1']?.assignedPersonIds, ['p1']);
    });

    test('togglePersonForItem does nothing for non-existent item', () {
      final items = [
        ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
      ];
      const personIds = ['p1'];

      container.read(assignmentProvider.notifier).initialize(items, personIds);

      final stateBefore = container.read(assignmentProvider);
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('999', 'p1');
      final stateAfter = container.read(assignmentProvider);

      expect(stateBefore.assignments, stateAfter.assignments);
    });

    test('provider state updates propagate to computed providers', () {
      final items = [
        ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
        ReceiptItem(id: '2', name: 'Coke', quantity: 2, price: 5.0),
      ];
      const personIds = ['p1', 'p2'];

      container.read(assignmentProvider.notifier).initialize(items, personIds);
      expect(container.read(unassignedItemsCountProvider), 2);
      expect(container.read(isFullyAssignedProvider), false);

      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p1');
      expect(container.read(unassignedItemsCountProvider), 1);
      expect(container.read(isFullyAssignedProvider), false);

      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('2', 'p2');
      expect(container.read(unassignedItemsCountProvider), 0);
      expect(container.read(isFullyAssignedProvider), true);
    });

    test('complex workflow: initialize, assign, update, and clear', () {
      final items = [
        ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 20.0),
        ReceiptItem(id: '2', name: 'Coke', quantity: 2, price: 5.0),
        ReceiptItem(id: '3', name: 'Burger', quantity: 1, price: 15.0),
      ];
      const personIds = ['p1', 'p2', 'p3'];

      // Initialize
      container.read(assignmentProvider.notifier).initialize(items, personIds);
      var state = container.read(assignmentProvider);
      expect(state.assignments.length, 3);
      expect(state.getUnassignedCount(), 3);

      // Assign some items
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p1');
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('2', 'p2');
      state = container.read(assignmentProvider);
      expect(state.getUnassignedCount(), 1);

      // Add more persons to an item
      container
          .read(assignmentProvider.notifier)
          .togglePersonForItem('1', 'p3');
      state = container.read(assignmentProvider);
      expect(state.assignments['1']?.splitCount, 2);

      // Assign all to one person
      container.read(assignmentProvider.notifier).assignAllItemsToPerson('p1');
      state = container.read(assignmentProvider);
      expect(state.getUnassignedCount(), 0);
      expect(state.isFullyAssigned(), true);

      // Clear one item
      container.read(assignmentProvider.notifier).clearItemAssignment('1');
      state = container.read(assignmentProvider);
      expect(state.getUnassignedCount(), 1);
      expect(state.isFullyAssigned(), false);
    });
  });
}
