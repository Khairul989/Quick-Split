import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:quicksplit/features/assign/domain/models/split_session.dart';
import 'package:quicksplit/features/payments/domain/models/payment_status.dart';

class FinancialSummary {
  final double totalUnpaid;
  final double totalPaidThisMonth;

  const FinancialSummary({
    required this.totalUnpaid,
    required this.totalPaidThisMonth,
  });
}

final financialSummaryProvider = StreamProvider.autoDispose<FinancialSummary>((
  ref,
) async* {
  final historyBox = Hive.box<SplitSession>('history');

  final now = DateTime.now();
  final firstDayOfMonth = DateTime(now.year, now.month, 1);
  final firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);

  FinancialSummary computeSummary() {
    try {
      final sessions = historyBox.values.where((s) => s.isSaved).toList();

      double totalUnpaid = 0.0;
      double totalPaidThisMonth = 0.0;

      for (final session in sessions) {
        for (final share in session.calculatedShares) {
          // Calculate unpaid amount based on payment status
          if (share.paymentStatus == PaymentStatus.unpaid) {
            // Fully unpaid - add entire total
            totalUnpaid += share.total;
          } else if (share.paymentStatus == PaymentStatus.partial) {
            // Partially paid - add remaining amount
            final remaining = share.total - (share.amountPaid ?? 0);
            if (remaining > 0.01) {
              totalUnpaid += remaining;
            }
          }
          // If paid, don't add to unpaid

          // Calculate paid this month
          if (session.createdAt.isAfter(firstDayOfMonth) &&
              session.createdAt.isBefore(firstDayOfNextMonth) &&
              share.paymentStatus != PaymentStatus.unpaid &&
              share.amountPaid != null) {
            totalPaidThisMonth += share.amountPaid!;
          }
        }
      }

      return FinancialSummary(
        totalUnpaid: totalUnpaid,
        totalPaidThisMonth: totalPaidThisMonth,
      );
    } catch (e) {
      // Return zero values on error
      return const FinancialSummary(totalUnpaid: 0.0, totalPaidThisMonth: 0.0);
    }
  }

  final streamController = StreamController<FinancialSummary>();
  streamController.add(computeSummary());

  final listener = historyBox.watch().listen((_) {
    streamController.add(computeSummary());
  });

  ref.onDispose(() {
    listener.cancel();
    streamController.close();
  });

  yield* streamController.stream;
});
