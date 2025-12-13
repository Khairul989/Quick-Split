import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:quicksplit/features/assign/domain/models/split_session.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';

/// Represents a recent split entry with both session and receipt data
class RecentSplitEntry {
  final SplitSession session;
  final Receipt? receipt;

  const RecentSplitEntry({required this.session, required this.receipt});

  /// Get emoji representation based on merchant name
  String get emoji {
    if (receipt == null) return '📄';
    final merchantName = receipt!.merchantName.toLowerCase();

    // Map common merchant types to emojis
    if (merchantName.contains('restaurant') ||
        merchantName.contains('food') ||
        merchantName.contains('cafe') ||
        merchantName.contains('pizza') ||
        merchantName.contains('burger') ||
        merchantName.contains('sushi') ||
        merchantName.contains('noodle')) {
      return '🍽️';
    }
    if (merchantName.contains('coffee') || merchantName.contains('tea')) {
      return '☕';
    }
    if (merchantName.contains('grocery') ||
        merchantName.contains('market') ||
        merchantName.contains('supermarket') ||
        merchantName.contains('mall')) {
      return '🛒';
    }
    if (merchantName.contains('drink') ||
        merchantName.contains('bar') ||
        merchantName.contains('pub')) {
      return '🍻';
    }
    if (merchantName.contains('hotel') || merchantName.contains('resort')) {
      return '🏨';
    }
    if (merchantName.contains('shop') ||
        merchantName.contains('retail') ||
        merchantName.contains('store')) {
      return '🏪';
    }

    // Default: use first letter as emoji fallback
    final firstChar = merchantName.isNotEmpty
        ? merchantName[0].toUpperCase()
        : '?';
    return firstChar;
  }

  /// Get formatted display name (merchant name or fallback)
  String get displayName {
    return receipt?.merchantName ?? 'Unknown';
  }

  /// Get formatted total amount
  String get formattedTotal {
    final amount = receipt?.total ?? 0.0;
    return 'RM ${amount.toStringAsFixed(2)}';
  }
}

/// Stream provider that fetches recent splits from Hive history box
///
/// Returns the 5 most recent splits sorted by creation date (newest first).
/// Automatically refreshes when either the history or receipts Hive boxes change.
final recentSplitsProvider = StreamProvider.autoDispose<List<RecentSplitEntry>>(
  (ref) async* {
    // Get the Hive boxes
    final historyBox = Hive.box<SplitSession>('history');
    final receiptsBox = Hive.box<Receipt>('receipts');

    // Helper function to compute recent splits
    List<RecentSplitEntry> computeRecentSplits() {
      try {
        // Get all sessions and sort by createdAt descending
        final sessions = historyBox.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Take the top 5 most recent splits
        final recentSessions = sessions.take(5).toList();

        // Map sessions to RecentSplitEntry by looking up receipts
        return recentSessions.map((session) {
          final receipt = receiptsBox.get(session.receiptId);
          return RecentSplitEntry(session: session, receipt: receipt);
        }).toList();
      } catch (e) {
        // Return empty list on error
        return <RecentSplitEntry>[];
      }
    }

    // Create a completer to handle async callbacks from Hive listeners
    final streamController = StreamController<List<RecentSplitEntry>>();

    // Add initial data
    streamController.add(computeRecentSplits());

    // Set up listeners for both Hive boxes
    final historyListener = historyBox.watch().listen((_) {
      streamController.add(computeRecentSplits());
    });

    final receiptsListener = receiptsBox.watch().listen((_) {
      streamController.add(computeRecentSplits());
    });

    // Clean up subscriptions when provider is disposed
    ref.onDispose(() {
      historyListener.cancel();
      receiptsListener.cancel();
      streamController.close();
    });

    // Return the stream
    yield* streamController.stream;
  },
);
