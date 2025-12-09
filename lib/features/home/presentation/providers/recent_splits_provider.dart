import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:quicksplit/features/assign/domain/models/split_session.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';

/// Represents a recent split entry with both session and receipt data
class RecentSplitEntry {
  final SplitSession session;
  final Receipt? receipt;

  const RecentSplitEntry({
    required this.session,
    required this.receipt,
  });

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

/// Provider that fetches recent splits from Hive history box
///
/// Returns the 5 most recent splits sorted by creation date (newest first).
/// Automatically refreshes when the Hive box changes.
final recentSplitsProvider = FutureProvider<List<RecentSplitEntry>>((ref) async {
  try {
    // Open/get Hive boxes
    final historyBox = Hive.box<SplitSession>('history');
    final receiptsBox = Hive.box<Receipt>('receipts');

    // Get all sessions and sort by createdAt descending
    final sessions = historyBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Take the top 5 most recent splits
    final recentSessions = sessions.take(5).toList();

    // Map sessions to RecentSplitEntry by looking up receipts
    final entries = recentSessions.map((session) {
      final receipt = receiptsBox.get(session.receiptId);
      return RecentSplitEntry(
        session: session,
        receipt: receipt,
      );
    }).toList();

    return entries;
  } catch (e) {
    // Return empty list on error (box might not exist yet)
    return [];
  }
});
