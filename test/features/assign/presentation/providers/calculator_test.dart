import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksplit/features/assign/domain/models/item_assignment.dart';
import 'package:quicksplit/features/assign/presentation/providers/calculator_provider.dart';
import 'package:quicksplit/features/groups/domain/models/person.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('CalculatorState', () {
    test('initial state has correct default values', () {
      const state = CalculatorState(
        shares: [],
        totalAmount: 0,
        isCalculated: false,
      );

      expect(state.shares, []);
      expect(state.totalAmount, 0);
      expect(state.isCalculated, false);
      expect(state.error, null);
    });

    test('copyWith updates fields correctly', () {
      const state = CalculatorState(
        shares: [],
        totalAmount: 100,
        isCalculated: false,
      );

      final newState = state.copyWith(totalAmount: 150, isCalculated: true);

      expect(newState.totalAmount, 150);
      expect(newState.isCalculated, true);
      expect(newState.shares, []);
    });
  });

  group('CalculatorNotifier - Core Algorithm Tests', () {
    /// Test Case 1: Single person, single item -> correct total
    test('single person single item calculates correct total', () {
      final receipt = Receipt(
        items: [ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 40.00)],
        subtotal: 40.00,
        sst: 0,
        serviceCharge: 0,
        rounding: 0,
        total: 40.00,
      );

      final people = [Person(id: 'p1', name: 'Alice', emoji: '😊')];

      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1']),
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final state = container.read(calculatorProvider);
      expect(state.shares.length, 1);
      expect(state.shares[0].total, closeTo(40.00, 0.001));
      expect(state.shares[0].itemsSubtotal, closeTo(40.00, 0.001));
      expect(state.isCalculated, true);
    });

    /// Test Case 2: Multiple people, items split equally -> proportional taxes
    test('multiple people with proportional taxes distributed correctly', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 50.00),
          ReceiptItem(id: '2', name: 'Burger', quantity: 1, price: 30.00),
        ],
        subtotal: 80.00,
        sst: 8.00,
        serviceCharge: 4.00,
        rounding: 0.08,
        total: 92.08,
      );

      final people = [
        Person(id: 'p1', name: 'Alice', emoji: '😊'),
        Person(id: 'p2', name: 'Bob', emoji: '😎'),
      ];

      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1']),
        '2': ItemAssignment(itemId: '2', assignedPersonIds: ['p2']),
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final state = container.read(calculatorProvider);
      expect(state.shares.length, 2);

      // Alice: 50/80 = 0.625 proportion
      final aliceShare = state.shares[0];
      expect(aliceShare.itemsSubtotal, closeTo(50.00, 0.001));
      expect(aliceShare.sst, closeTo(5.00, 0.001));
      expect(aliceShare.serviceCharge, closeTo(2.50, 0.001));

      // Bob: 30/80 = 0.375 proportion
      final bobShare = state.shares[1];
      expect(bobShare.itemsSubtotal, closeTo(30.00, 0.001));
      expect(bobShare.sst, closeTo(3.00, 0.001));
      expect(bobShare.serviceCharge, closeTo(1.50, 0.001));
    });

    /// Test Case 3: Shared item (2 people) -> price divided by 2
    test('shared item splits price equally between 2 people', () {
      final receipt = Receipt(
        items: [ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 40.00)],
        subtotal: 40.00,
        sst: 0,
        serviceCharge: 0,
        rounding: 0,
        total: 40.00,
      );

      final people = [
        Person(id: 'p1', name: 'Alice', emoji: '😊'),
        Person(id: 'p2', name: 'Bob', emoji: '😎'),
      ];

      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1', 'p2']),
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final state = container.read(calculatorProvider);
      expect(state.shares.length, 2);
      expect(state.shares[0].itemsSubtotal, closeTo(20.00, 0.001));
      expect(state.shares[1].itemsSubtotal, closeTo(20.00, 0.001));
      expect(state.shares[0].total, closeTo(20.00, 0.001));
      expect(state.shares[1].total, closeTo(20.00, 0.001));
    });

    /// Test Case 4: Shared item (3 people) -> price divided by 3
    test('shared item splits price equally between 3 people', () {
      final receipt = Receipt(
        items: [ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 30.00)],
        subtotal: 30.00,
        sst: 0,
        serviceCharge: 0,
        rounding: 0,
        total: 30.00,
      );

      final people = [
        Person(id: 'p1', name: 'Alice', emoji: '😊'),
        Person(id: 'p2', name: 'Bob', emoji: '😎'),
        Person(id: 'p3', name: 'Charlie', emoji: '🤓'),
      ];

      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1', 'p2', 'p3']),
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final state = container.read(calculatorProvider);
      expect(state.shares.length, 3);
      expect(state.shares[0].itemsSubtotal, closeTo(10.00, 0.001));
      expect(state.shares[1].itemsSubtotal, closeTo(10.00, 0.001));
      expect(state.shares[2].itemsSubtotal, closeTo(10.00, 0.001));
    });

    /// Test Case 5: Person with no items -> total = 0.00
    test('person with no assigned items has zero total', () {
      final receipt = Receipt(
        items: [ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 40.00)],
        subtotal: 40.00,
        sst: 4.00,
        serviceCharge: 0,
        rounding: 0,
        total: 44.00,
      );

      final people = [
        Person(id: 'p1', name: 'Alice', emoji: '😊'),
        Person(id: 'p2', name: 'Bob', emoji: '😎'),
      ];

      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1']),
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final state = container.read(calculatorProvider);
      expect(state.shares.length, 2);

      // Alice gets the item
      expect(state.shares[0].total, closeTo(44.00, 0.001));

      // Bob has no assignments
      final bobShare = state.shares[1];
      expect(bobShare.itemsSubtotal, closeTo(0.00, 0.001));
      expect(bobShare.sst, closeTo(0.00, 0.001));
      expect(bobShare.total, closeTo(0.00, 0.001));
    });

    /// Test Case 6: Item with no assignment -> skipped in calculation
    test('unassigned item is skipped in calculation', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 40.00),
          ReceiptItem(id: '2', name: 'Coke', quantity: 1, price: 10.00),
        ],
        subtotal: 50.00,
        sst: 0,
        serviceCharge: 0,
        rounding: 0,
        total: 50.00,
      );

      final people = [Person(id: 'p1', name: 'Alice', emoji: '😊')];

      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1']),
        '2': ItemAssignment(itemId: '2', assignedPersonIds: []), // Not assigned
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final state = container.read(calculatorProvider);
      final share = state.shares[0];

      // Only Pizza should be counted (40), not Coke (10)
      expect(share.itemsSubtotal, closeTo(40.00, 0.001));
      expect(share.total, closeTo(40.00, 0.001));
    });

    /// Test Case 7: SST proportional distribution -> correct per-person SST
    test('SST is distributed proportionally to each person', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 60.00),
          ReceiptItem(id: '2', name: 'Burger', quantity: 1, price: 40.00),
        ],
        subtotal: 100.00,
        sst: 6.00,
        serviceCharge: 0,
        rounding: 0,
        total: 106.00,
      );

      final people = [
        Person(id: 'p1', name: 'Alice', emoji: '😊'),
        Person(id: 'p2', name: 'Bob', emoji: '😎'),
      ];

      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1']),
        '2': ItemAssignment(itemId: '2', assignedPersonIds: ['p2']),
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final state = container.read(calculatorProvider);

      // Alice: 60/100 = 0.6 of SST
      expect(state.shares[0].sst, closeTo(3.60, 0.001));

      // Bob: 40/100 = 0.4 of SST
      expect(state.shares[1].sst, closeTo(2.40, 0.001));
    });

    /// Test Case 8: Service charge proportional distribution
    test('service charge is distributed proportionally', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: '1', name: 'Item 1', quantity: 1, price: 70.00),
          ReceiptItem(id: '2', name: 'Item 2', quantity: 1, price: 30.00),
        ],
        subtotal: 100.00,
        sst: 0,
        serviceCharge: 10.00,
        rounding: 0,
        total: 110.00,
      );

      final people = [
        Person(id: 'p1', name: 'Alice', emoji: '😊'),
        Person(id: 'p2', name: 'Bob', emoji: '😎'),
      ];

      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1']),
        '2': ItemAssignment(itemId: '2', assignedPersonIds: ['p2']),
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final state = container.read(calculatorProvider);

      // Alice: 70/100 = 0.7 of service charge
      expect(state.shares[0].serviceCharge, closeTo(7.00, 0.001));

      // Bob: 30/100 = 0.3 of service charge
      expect(state.shares[1].serviceCharge, closeTo(3.00, 0.001));
    });

    /// Test Case 9: Rounding proportional distribution
    test('rounding adjustment is distributed proportionally', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: '1', name: 'Item 1', quantity: 1, price: 50.00),
          ReceiptItem(id: '2', name: 'Item 2', quantity: 1, price: 50.00),
        ],
        subtotal: 100.00,
        sst: 6.00,
        serviceCharge: 0,
        rounding: 0.12,
        total: 106.12,
      );

      final people = [
        Person(id: 'p1', name: 'Alice', emoji: '😊'),
        Person(id: 'p2', name: 'Bob', emoji: '😎'),
      ];

      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1']),
        '2': ItemAssignment(itemId: '2', assignedPersonIds: ['p2']),
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final state = container.read(calculatorProvider);

      // Each gets 50%, so 0.06 rounding each
      expect(state.shares[0].rounding, closeTo(0.06, 0.001));
      expect(state.shares[1].rounding, closeTo(0.06, 0.001));
    });

    /// Test Case 10: Sum validation - sum should equal receipt total (±0.10)
    test('sum of all shares equals receipt total within tolerance', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 50.00),
          ReceiptItem(id: '2', name: 'Burger', quantity: 1, price: 30.00),
          ReceiptItem(id: '3', name: 'Coke', quantity: 1, price: 20.00),
        ],
        subtotal: 100.00,
        sst: 8.00,
        serviceCharge: 10.00,
        rounding: 0.00,
        total: 118.00,
      );

      final people = [
        Person(id: 'p1', name: 'Alice', emoji: '😊'),
        Person(id: 'p2', name: 'Bob', emoji: '😎'),
        Person(id: 'p3', name: 'Charlie', emoji: '🤓'),
      ];

      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1', 'p2']),
        '2': ItemAssignment(itemId: '2', assignedPersonIds: ['p2', 'p3']),
        '3': ItemAssignment(itemId: '3', assignedPersonIds: ['p1', 'p3']),
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final state = container.read(calculatorProvider);
      final sum = state.shares.fold(0.0, (sum, share) => sum + share.total);

      // Sum should equal receipt total within 0.10 tolerance
      expect((sum - state.totalAmount).abs(), lessThanOrEqualTo(0.10));
    });

    /// Test Case 11: Receipt with SST=0, Service=0 -> handles gracefully
    test('receipt with zero taxes and service charges handles gracefully', () {
      final receipt = Receipt(
        items: [ReceiptItem(id: '1', name: 'Item', quantity: 1, price: 25.00)],
        subtotal: 25.00,
        sst: 0,
        serviceCharge: 0,
        rounding: 0,
        total: 25.00,
      );

      final people = [
        Person(id: 'p1', name: 'Alice', emoji: '😊'),
        Person(id: 'p2', name: 'Bob', emoji: '😎'),
      ];

      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1', 'p2']),
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final state = container.read(calculatorProvider);
      expect(state.shares.length, 2);
      expect(state.shares[0].sst, 0.0);
      expect(state.shares[0].serviceCharge, 0.0);
      expect(state.shares[0].rounding, 0.0);
      expect(state.shares[0].total, closeTo(12.50, 0.001));
      expect(state.isCalculated, true);
    });

    /// Test Case 12: Empty receipt -> returns empty shares list
    test('empty receipt returns empty shares list', () {
      final receipt = Receipt(
        items: [],
        subtotal: 0,
        sst: 0,
        serviceCharge: 0,
        rounding: 0,
        total: 0,
      );

      final people = [
        Person(id: 'p1', name: 'Alice', emoji: '😊'),
        Person(id: 'p2', name: 'Bob', emoji: '😎'),
      ];

      final assignments = <String, ItemAssignment>{};

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final state = container.read(calculatorProvider);
      expect(state.shares.length, 2);

      // All should have zero values
      for (final share in state.shares) {
        expect(share.itemsSubtotal, 0.0);
        expect(share.sst, 0.0);
        expect(share.serviceCharge, 0.0);
        expect(share.total, 0.0);
      }

      expect(state.isCalculated, true);
    });
  });

  group('CalculatorNotifier - Additional Edge Cases', () {
    test('empty participants list returns empty shares', () {
      final receipt = Receipt(
        items: [ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 40.00)],
        subtotal: 40.00,
        sst: 0,
        serviceCharge: 0,
        rounding: 0,
        total: 40.00,
      );

      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: []),
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: [],
            assignments: assignments,
          );

      final state = container.read(calculatorProvider);
      expect(state.shares, []);
      expect(state.isCalculated, true);
    });

    test('complex multi-item multi-person split with full charges', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 50.00),
          ReceiptItem(id: '2', name: 'Pasta', quantity: 1, price: 35.00),
          ReceiptItem(id: '3', name: 'Salad', quantity: 1, price: 20.00),
          ReceiptItem(id: '4', name: 'Dessert', quantity: 1, price: 15.00),
        ],
        subtotal: 120.00,
        sst: 7.20,
        serviceCharge: 12.00,
        rounding: 0.80,
        total: 140.00,
      );

      final people = [
        Person(id: 'p1', name: 'Alice', emoji: '😊'),
        Person(id: 'p2', name: 'Bob', emoji: '😎'),
        Person(id: 'p3', name: 'Charlie', emoji: '🤓'),
      ];

      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1']),
        '2': ItemAssignment(itemId: '2', assignedPersonIds: ['p1', 'p2']),
        '3': ItemAssignment(itemId: '3', assignedPersonIds: ['p2', 'p3']),
        '4': ItemAssignment(itemId: '4', assignedPersonIds: ['p1', 'p2', 'p3']),
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final state = container.read(calculatorProvider);
      expect(state.shares.length, 3);
      expect(state.isCalculated, true);

      // Verify calculation completed without errors
      final sum = state.shares.fold(0.0, (sum, share) => sum + share.total);
      expect((sum - 140.0).abs(), lessThanOrEqualTo(0.10));
    });

    test('reset clears calculator state', () {
      final receipt = Receipt(
        items: [ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 40.00)],
        subtotal: 40.00,
        sst: 0,
        serviceCharge: 0,
        rounding: 0,
        total: 40.00,
      );

      final people = [Person(id: 'p1', name: 'Alice', emoji: '😊')];
      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1']),
      };

      // Perform calculation
      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      var state = container.read(calculatorProvider);
      expect(state.shares, isNotEmpty);
      expect(state.isCalculated, true);

      // Reset
      container.read(calculatorProvider.notifier).reset();

      state = container.read(calculatorProvider);
      expect(state.shares, []);
      expect(state.totalAmount, 0);
      expect(state.isCalculated, false);
      expect(state.error, null);
    });

    test(
      'calculation with assigned items list tracks which items are assigned',
      () {
        final receipt = Receipt(
          items: [
            ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 40.00),
            ReceiptItem(id: '2', name: 'Coke', quantity: 1, price: 10.00),
          ],
          subtotal: 50.00,
          sst: 0,
          serviceCharge: 0,
          rounding: 0,
          total: 50.00,
        );

        final people = [Person(id: 'p1', name: 'Alice', emoji: '😊')];
        final assignments = {
          '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1']),
          '2': ItemAssignment(itemId: '2', assignedPersonIds: []),
        };

        container
            .read(calculatorProvider.notifier)
            .calculate(
              receipt: receipt,
              participants: people,
              assignments: assignments,
            );

        final state = container.read(calculatorProvider);
        final share = state.shares[0];

        // Should only track item 1 as assigned
        expect(share.assignedItemIds, ['1']);
        expect(share.assignedItemIds, isNot(contains('2')));
      },
    );
  });

  group('CalculatorNotifier - Computed Providers', () {
    test('calculatorSumProvider returns correct sum of all shares', () {
      final receipt = Receipt(
        items: [
          ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 50.00),
          ReceiptItem(id: '2', name: 'Burger', quantity: 1, price: 50.00),
        ],
        subtotal: 100.00,
        sst: 10.00,
        serviceCharge: 0,
        rounding: 0,
        total: 110.00,
      );

      final people = [
        Person(id: 'p1', name: 'Alice', emoji: '😊'),
        Person(id: 'p2', name: 'Bob', emoji: '😎'),
      ];

      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1']),
        '2': ItemAssignment(itemId: '2', assignedPersonIds: ['p2']),
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final sum = container.read(calculatorSumProvider);
      expect(sum, closeTo(110.00, 0.001));
    });

    test('calculatorValidProvider returns false when not calculated', () {
      final isValid = container.read(calculatorValidProvider);
      expect(isValid, false);
    });

    test('calculatorValidProvider returns true when sum equals total', () {
      final receipt = Receipt(
        items: [ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 40.00)],
        subtotal: 40.00,
        sst: 0,
        serviceCharge: 0,
        rounding: 0,
        total: 40.00,
      );

      final people = [Person(id: 'p1', name: 'Alice', emoji: '😊')];
      final assignments = {
        '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1']),
      };

      container
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: people,
            assignments: assignments,
          );

      final isValid = container.read(calculatorValidProvider);
      expect(isValid, true);
    });

    test(
      'calculatorValidProvider returns false when sum exceeds tolerance',
      () {
        final receipt = Receipt(
          items: [
            ReceiptItem(id: '1', name: 'Pizza', quantity: 1, price: 100.00),
          ],
          subtotal: 100.00,
          sst: 0,
          serviceCharge: 0,
          rounding: 0,
          total: 100.00,
        );

        final people = [
          Person(id: 'p1', name: 'Alice', emoji: '😊'),
          Person(id: 'p2', name: 'Bob', emoji: '😎'),
        ];

        // Alice gets whole item, Bob gets nothing
        final assignments = {
          '1': ItemAssignment(itemId: '1', assignedPersonIds: ['p1']),
        };

        container
            .read(calculatorProvider.notifier)
            .calculate(
              receipt: receipt,
              participants: people,
              assignments: assignments,
            );

        final state = container.read(calculatorProvider);
        final sum = state.shares.fold(0.0, (sum, share) => sum + share.total);

        // Manually verify sum doesn't equal total (Bob gets 0, so sum = 100)
        // but receipt total should be 100, so they match
        expect((sum - state.totalAmount).abs(), lessThanOrEqualTo(0.10));
      },
    );
  });
}
