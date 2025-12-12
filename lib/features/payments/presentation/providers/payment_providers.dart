import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import '../../../assign/domain/models/split_session.dart';
import '../../../assign/domain/models/person_share.dart';
import '../../domain/models/payment_status.dart';

/// Provider for accessing the history box
final paymentHistoryBoxProvider = Provider<Box<SplitSession>>((ref) {
  return Hive.box<SplitSession>('history');
});

/// Async provider for loading a specific split session with payment data
final splitSessionProvider = FutureProvider.family<SplitSession, String>((ref, splitId) async {
  final box = ref.read(paymentHistoryBoxProvider);
  final session = box.get(splitId);

  if (session == null) {
    throw Exception('Split session not found');
  }

  return session;
});

/// Stream provider for watching changes to a specific split session
final splitSessionStreamProvider = StreamProvider.family<SplitSession?, String>((ref, splitId) {
  final box = ref.read(paymentHistoryBoxProvider);
  return box.watch(key: splitId).map((event) => event.value);
});

/// Provider for payment management state
final paymentNotifierProvider = AsyncNotifierProvider<PaymentNotifier, PaymentState>(() {
  return PaymentNotifier();
});

/// Provider for payment statistics
final paymentStatsProvider = Provider.family<PaymentStats, String>((ref, splitId) {
  final session = ref.watch(splitSessionStreamProvider(splitId)).value;

  if (session == null) {
    return const PaymentStats(
      totalAmount: 0,
      totalPaid: 0,
      peoplePaid: 0,
      totalPeople: 0,
      isFullyPaid: false,
    );
  }

  double totalAmount = 0;
  double totalPaid = 0;
  int peoplePaid = 0;

  for (final share in session.calculatedShares) {
    totalAmount += share.total;

    if (share.paymentStatus == PaymentStatus.paid) {
      totalPaid += share.total;
      peoplePaid++;
    } else if (share.paymentStatus == PaymentStatus.partial && share.amountPaid != null) {
      totalPaid += share.amountPaid!;
      if (share.amountPaid! >= share.total) {
        peoplePaid++;
      }
    }
  }

  return PaymentStats(
    totalAmount: totalAmount,
    totalPaid: totalPaid,
    peoplePaid: peoplePaid,
    totalPeople: session.calculatedShares.length,
    isFullyPaid: totalPaid >= totalAmount - 0.01, // Account for floating point
  );
});

/// State for payment management
class PaymentState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const PaymentState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  PaymentState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// Statistics for payment tracking
class PaymentStats {
  final double totalAmount;
  final double totalPaid;
  final int peoplePaid;
  final int totalPeople;
  final bool isFullyPaid;

  const PaymentStats({
    required this.totalAmount,
    required this.totalPaid,
    required this.peoplePaid,
    required this.totalPeople,
    required this.isFullyPaid,
  });

  /// Get remaining amount
  double get remainingAmount => totalAmount - totalPaid;

  /// Get payment progress as percentage
  double get progressPercentage {
    if (totalAmount == 0) return 1.0;
    return (totalPaid / totalAmount).clamp(0.0, 1.0);
  }

  /// Get progress percentage as integer
  int get progressPercentageInt => (progressPercentage * 100).round();
}

/// Notifier for managing payment operations
class PaymentNotifier extends AsyncNotifier<PaymentState> {
  @override
  PaymentState build() => const PaymentState();

  /// Update payment status for a person
  Future<void> updatePaymentStatus(
    String splitId,
    PersonShare updatedShare,
  ) async {
    state = const AsyncValue.loading();

    try {
      final box = Hive.box<SplitSession>('history');
      final session = box.get(splitId);

      if (session == null) {
        throw Exception('Session not found');
      }

      // Update the share in the calculatedShares list
      final updatedShares = session.calculatedShares.map((share) {
        return share.personId == updatedShare.personId ? updatedShare : share;
      }).toList();

      // Create updated session
      final updatedSession = session.copyWith(
        calculatedShares: updatedShares,
      );

      // Save to Hive
      await box.put(splitId, updatedSession);

      state = AsyncValue.data(PaymentState(
        successMessage: '${updatedShare.personName} marked as ${updatedShare.paymentStatus.displayName}',
      ));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Bulk update payment status for all shares
  Future<void> bulkUpdatePaymentStatus(
    String splitId,
    PaymentStatus status,
  ) async {
    state = const AsyncValue.loading();

    try {
      final box = Hive.box<SplitSession>('history');
      final session = box.get(splitId);

      if (session == null) {
        throw Exception('Session not found');
      }

      // Update all shares
      final updatedShares = session.calculatedShares.map((share) {
        return share.copyWithPayment(
          paymentStatus: status,
          amountPaid: status == PaymentStatus.paid ? share.total : null,
          lastPaidAt: status != PaymentStatus.unpaid ? DateTime.now() : null,
          paymentNotes: null,
        );
      }).toList();

      // Create updated session
      final updatedSession = session.copyWith(
        calculatedShares: updatedShares,
      );

      // Save to Hive
      await box.put(splitId, updatedSession);

      final actionText = status == PaymentStatus.paid ? 'marked as paid' : 'marked as unpaid';
      state = AsyncValue.data(PaymentState(
        successMessage: 'All people $actionText',
      ));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Mark partial payment for a specific person
  Future<void> markPartialPayment(
    String splitId,
    PersonShare share,
    double amountPaid,
    String? notes,
  ) async {
    state = const AsyncValue.loading();

    try {
      final box = Hive.box<SplitSession>('history');
      final session = box.get(splitId);

      if (session == null) {
        throw Exception('Session not found');
      }

      // Determine payment status based on amount
      final paymentStatus = amountPaid >= share.total
          ? PaymentStatus.paid
          : PaymentStatus.partial;

      // Update the share
      final updatedShare = share.copyWithPayment(
        paymentStatus: paymentStatus,
        amountPaid: amountPaid,
        lastPaidAt: DateTime.now(),
        paymentNotes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      );

      // Update the shares list
      final updatedShares = session.calculatedShares.map((s) {
        return s.personId == share.personId ? updatedShare : s;
      }).toList();

      // Create updated session
      final updatedSession = session.copyWith(
        calculatedShares: updatedShares,
      );

      // Save to Hive
      await box.put(splitId, updatedSession);

      state = AsyncValue.data(PaymentState(
        successMessage: 'Payment of RM ${amountPaid.toStringAsFixed(2)} recorded for ${share.personName}',
      ));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Reset all payment status to unpaid
  Future<void> resetAllPayments(String splitId) async {
    state = const AsyncValue.loading();

    try {
      final box = Hive.box<SplitSession>('history');
      final session = box.get(splitId);

      if (session == null) {
        throw Exception('Session not found');
      }

      // Reset all shares to unpaid
      final updatedShares = session.calculatedShares.map((share) {
        return share.copyWithPayment(
          paymentStatus: PaymentStatus.unpaid,
          amountPaid: null,
          lastPaidAt: null,
          paymentNotes: null,
        );
      }).toList();

      // Create updated session
      final updatedSession = session.copyWith(
        calculatedShares: updatedShares,
      );

      // Save to Hive
      await box.put(splitId, updatedSession);

      state = AsyncValue.data(const PaymentState(
        successMessage: 'All payments have been reset',
      ));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}