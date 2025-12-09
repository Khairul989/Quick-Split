import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/person_share.dart';
import '../../domain/models/item_assignment.dart';
import '../../../ocr/domain/models/receipt.dart';
import '../../../groups/domain/models/person.dart';

/// Represents the state of the split calculation.
class CalculatorState {
  /// List of calculated shares for each participant.
  final List<PersonShare> shares;

  /// The total amount from the receipt.
  final double totalAmount;

  /// Whether calculation has been completed successfully.
  final bool isCalculated;

  /// Error message if calculation failed, null otherwise.
  final String? error;

  const CalculatorState({
    required this.shares,
    required this.totalAmount,
    this.isCalculated = false,
    this.error,
  });

  /// Create a copy of this state with optional field overrides.
  CalculatorState copyWith({
    List<PersonShare>? shares,
    double? totalAmount,
    bool? isCalculated,
    String? error,
  }) {
    return CalculatorState(
      shares: shares ?? this.shares,
      totalAmount: totalAmount ?? this.totalAmount,
      isCalculated: isCalculated ?? this.isCalculated,
      error: error,
    );
  }
}

/// Notifier that manages the calculation of expense splits.
class CalculatorNotifier extends Notifier<CalculatorState> {
  @override
  CalculatorState build() {
    return const CalculatorState(
      shares: [],
      totalAmount: 0,
      isCalculated: false,
    );
  }

  /// Calculates the split for all participants based on item assignments.
  ///
  /// Implements the split algorithm:
  /// 1. For each participant, calculate their item subtotal
  /// 2. Calculate their proportion of the receipt
  /// 3. Apply proportional taxes, service charges, and rounding
  /// 4. Create PersonShare with final total
  ///
  /// Handles edge cases:
  /// - Items with no assignments are skipped
  /// - Items assigned to multiple people split cost equally
  /// - Participants with no items get 0.00 total
  /// - Division by zero is prevented
  void calculate({
    required Receipt receipt,
    required List<Person> participants,
    required Map<String, ItemAssignment> assignments,
  }) {
    try {
      // Handle empty participants
      if (participants.isEmpty) {
        state = state.copyWith(
          shares: [],
          totalAmount: receipt.total,
          isCalculated: true,
          error: null,
        );
        return;
      }

      // Handle empty receipt
      if (receipt.items.isEmpty) {
        final shares = participants
            .map((person) => PersonShare(
                  personId: person.id,
                  personName: person.name,
                  personEmoji: person.emoji,
                  itemsSubtotal: 0.0,
                  sst: 0.0,
                  serviceCharge: 0.0,
                  rounding: 0.0,
                  total: 0.0,
                  assignedItemIds: [],
                ))
            .toList();

        state = state.copyWith(
          shares: shares,
          totalAmount: receipt.total,
          isCalculated: true,
          error: null,
        );
        return;
      }

      final calculatedSubtotal = receipt.calculatedSubtotal;

      // Calculate shares for each participant
      final shares = <PersonShare>[];
      for (final person in participants) {
        final personShare = _calculatePersonShare(
          person: person,
          receipt: receipt,
          assignments: assignments,
          calculatedSubtotal: calculatedSubtotal,
        );
        shares.add(personShare);
      }

      // Update state with calculated shares
      state = state.copyWith(
        shares: shares,
        totalAmount: receipt.total,
        isCalculated: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        shares: [],
        isCalculated: false,
        error: 'Calculation error: $e',
      );
    }
  }

  /// Calculates the split share for a single person.
  ///
  /// Algorithm:
  /// 1. Calculate person's item subtotal from assigned items
  /// 2. Calculate proportion: itemsSubtotal / calculatedSubtotal
  /// 3. Apply proportional taxes, service charges, rounding
  /// 4. Sum to get person's total
  ///
  /// Handles shared items by dividing price equally among assignees.
  PersonShare _calculatePersonShare({
    required Person person,
    required Receipt receipt,
    required Map<String, ItemAssignment> assignments,
    required double calculatedSubtotal,
  }) {
    double itemsSubtotal = 0.0;
    final assignedItemIds = <String>[];

    // Calculate this person's item subtotal
    for (final item in receipt.items) {
      final assignment = assignments[item.id];

      // Skip items with no assignment
      if (assignment == null || !assignment.isAssigned) {
        continue;
      }

      // Check if person is assigned to this item
      if (assignment.assignedPersonIds.contains(person.id)) {
        assignedItemIds.add(item.id);

        // Split price equally among all people assigned to this item
        final splitCount = assignment.splitCount;
        final itemSplitPrice = item.subtotal / splitCount;
        itemsSubtotal += itemSplitPrice;
      }
    }

    // Calculate proportion of receipt (handle division by zero)
    final proportion = calculatedSubtotal > 0 ? itemsSubtotal / calculatedSubtotal : 0.0;

    // Apply proportional taxes and charges
    final personSst = receipt.sst * proportion;
    final personServiceCharge = receipt.serviceCharge * proportion;
    final personRounding = receipt.rounding * proportion;

    // Calculate final total
    final personTotal = itemsSubtotal + personSst + personServiceCharge + personRounding;

    return PersonShare(
      personId: person.id,
      personName: person.name,
      personEmoji: person.emoji,
      itemsSubtotal: itemsSubtotal,
      sst: personSst,
      serviceCharge: personServiceCharge,
      rounding: personRounding,
      total: personTotal,
      assignedItemIds: assignedItemIds,
    );
  }

  /// Resets the calculator state to its initial empty state.
  void reset() {
    state = const CalculatorState(
      shares: [],
      totalAmount: 0,
      isCalculated: false,
    );
  }
}

/// Provider for the calculator notifier and state.
final calculatorProvider = NotifierProvider<CalculatorNotifier, CalculatorState>(
  CalculatorNotifier.new,
);

/// Computed provider for sum of all calculated shares.
/// Used to validate that sum equals receipt total (within tolerance).
final calculatorSumProvider = Provider<double>((ref) {
  final state = ref.watch(calculatorProvider);
  return state.shares.fold(0.0, (sum, share) => sum + share.total);
});

/// Computed provider indicating if calculation is valid.
/// Sum should equal receipt total within 0.10 tolerance.
final calculatorValidProvider = Provider<bool>((ref) {
  final state = ref.watch(calculatorProvider);
  if (!state.isCalculated || state.shares.isEmpty) {
    return false;
  }

  final sum = state.shares.fold(0.0, (sum, share) => sum + share.total);
  const tolerance = 0.10;

  return (sum - state.totalAmount).abs() <= tolerance;
});
