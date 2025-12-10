import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:quicksplit/features/assign/domain/models/split_session.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';

/// Represents monthly statistics data
class MonthlyStats {
  final double totalSpent;
  final int splitCount;

  const MonthlyStats({
    required this.totalSpent,
    required this.splitCount,
  });
}

/// Stream provider that calculates monthly statistics from Hive boxes
///
/// Returns the total amount spent and number of splits for the current month.
/// Automatically refreshes when either the history or receipts Hive boxes change.
final monthlyStatsProvider = StreamProvider.autoDispose<MonthlyStats>((ref) async* {
  // Get the Hive boxes
  final historyBox = Hive.box<SplitSession>('history');
  final receiptsBox = Hive.box<Receipt>('receipts');

  // Get current month boundaries
  final now = DateTime.now();
  final firstDayOfMonth = DateTime(now.year, now.month, 1);
  final firstDayOfNextMonth = DateTime(now.year, now.month + 1, 1);

  // Helper function to compute monthly stats
  MonthlyStats computeMonthlyStats() {
    try {
      // Filter sessions by current month and that are saved
      final sessions = historyBox.values.where((session) {
        return session.createdAt.isAfter(firstDayOfMonth) &&
               session.createdAt.isBefore(firstDayOfNextMonth) &&
               session.isSaved;
      }).toList();

      // Calculate total spent by summing receipt totals
      double totalSpent = 0.0;
      for (final session in sessions) {
        final receipt = receiptsBox.get(session.receiptId);
        if (receipt != null) {
          totalSpent += receipt.total;
        }
      }

      return MonthlyStats(
        totalSpent: totalSpent,
        splitCount: sessions.length,
      );
    } catch (e) {
      // Return zero values on error
      return const MonthlyStats(totalSpent: 0.0, splitCount: 0);
    }
  }

  // Create a stream controller to handle updates
  final streamController = StreamController<MonthlyStats>();

  // Add initial data
  streamController.add(computeMonthlyStats());

  // Set up listeners for both Hive boxes
  final historyListener = historyBox.watch().listen((_) {
    streamController.add(computeMonthlyStats());
  });

  final receiptsListener = receiptsBox.watch().listen((_) {
    streamController.add(computeMonthlyStats());
  });

  // Clean up subscriptions when provider is disposed
  ref.onDispose(() {
    historyListener.cancel();
    receiptsListener.cancel();
    streamController.close();
  });

  // Return the stream
  yield* streamController.stream;
});
