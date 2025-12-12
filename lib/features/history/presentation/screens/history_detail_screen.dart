import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../assign/domain/models/person_share.dart';
import '../../../assign/domain/models/split_session.dart';
import '../../../ocr/domain/models/receipt.dart';
import '../../../payments/domain/models/payment_status.dart';
import '../../../payments/presentation/providers/payment_providers.dart';
import '../../../payments/presentation/widgets/payment_status_banner.dart';
import '../../../payments/presentation/widgets/payment_toggle_widget.dart';

/// History detail screen showing complete split session details
/// Loads data from Hive and displays receipt summary and individual shares
class HistoryDetailScreen extends ConsumerStatefulWidget {
  final String splitId;

  const HistoryDetailScreen({required this.splitId, super.key});

  @override
  ConsumerState<HistoryDetailScreen> createState() =>
      _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends ConsumerState<HistoryDetailScreen> {
  // Helper method to show snackbars without BuildContext across async gaps
  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Provider for the specific split session
  late final splitSessionProvider = FutureProvider<SplitSession?>((ref) {
    return Future(() async {
      final box = Hive.box<SplitSession>('history');
      return box.get(widget.splitId);
    });
  });

  // Reactive provider that watches for changes to the specific session
  late final reactiveSessionProvider = StreamProvider<SplitSession?>((ref) {
    final box = Hive.box<SplitSession>('history');
    final streamController = StreamController<SplitSession?>();

    // Emit initial value immediately to prevent infinite loading
    streamController.add(box.get(widget.splitId));

    // Watch for changes to the specific key
    final subscription = box.watch(key: widget.splitId).listen((event) {
      streamController.add(event.value);
    });

    // Cleanup on provider dispose
    ref.onDispose(() {
      subscription.cancel();
      streamController.close();
    });

    return streamController.stream;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Detail'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              final sessionAsync = ref.read(reactiveSessionProvider);
              if (sessionAsync.hasValue && sessionAsync.requireValue != null) {
                final session = sessionAsync.requireValue!;
                final receiptsBox = Hive.box<Receipt>('receipts');
                final receipt = receiptsBox.get(session.receiptId);
                if (receipt != null) {
                  _shareWholeReceipt(session, receipt);
                }
              }
            },
          ),
          // Bulk actions button
          Consumer(
            builder: (context, ref, child) {
              final session = ref.watch(reactiveSessionProvider);

              if (session.hasError) return const SizedBox.shrink();
              if (!session.hasValue) return const SizedBox.shrink();

              final data = session.requireValue;
              if (data == null) return const SizedBox.shrink();

              final hasUnpaid = data.calculatedShares.any(
                (share) => share.paymentStatus != PaymentStatus.paid,
              );
              final hasPaid = data.calculatedShares.any(
                (share) => share.paymentStatus == PaymentStatus.paid,
              );

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'use_for_new_split') {
                    _useForNewSplit(context, data);
                  } else if (value == 'mark_all_paid') {
                    _markAllAsPaid(context, data);
                  } else if (value == 'mark_all_unpaid') {
                    _markAllAsUnpaid(context, data);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'use_for_new_split',
                    child: Text('Use for New Split'),
                  ),
                  if (hasUnpaid)
                    const PopupMenuItem(
                      value: 'mark_all_paid',
                      child: Text('Mark All as Paid'),
                    ),
                  if (hasPaid)
                    const PopupMenuItem(
                      value: 'mark_all_unpaid',
                      child: Text('Reset All Payments'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    // Watch the specific split session with real-time updates
    return Consumer(
      builder: (context, ref, child) {
        final session = ref.watch(reactiveSessionProvider);

        if (session.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading split',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          );
        }

        if (!session.hasValue) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = session.requireValue;
        if (data == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Split session not found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Could not find split with ID: ${widget.splitId}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          );
        }

        // Load receipt
        final receiptsBox = Hive.box<Receipt>('receipts');
        final receipt = receiptsBox.get(data.receiptId);

        if (receipt == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Receipt not found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          );
        }

        // Check if shares need migration (missing payment fields)
        bool needsMigration = false;
        try {
          needsMigration = data.calculatedShares.isEmpty;
        } catch (e) {
          // If we can't access calculatedShares, it needs migration
          needsMigration = true;
        }

        if (needsMigration) {
          return _buildMigrationView(data, receipt);
        }

        return _buildSplitDetailView(data, receipt);
      },
    );
  }

  Widget _buildMigrationView(SplitSession session, Receipt receipt) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.update_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Data Update Required',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This split needs to be updated to the new payment tracking format.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Option 1: Create a new split with this receipt\nOption 2: Continue without payment tracking',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Go Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitDetailView(SplitSession session, Receipt receipt) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment Status Banner (NEW)
              Padding(
                padding: const EdgeInsets.all(24),
                child: PaymentStatusBanner(session: session),
              ),

              // Receipt information card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildReceiptCard(receipt, session),
              ),

              // Items section
              if (receipt.items.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: receipt.items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = receipt.items[index];
                    return _buildItemRow(item);
                  },
                ),
              ],

              // Individual Shares section with payment tracking
              if (session.calculatedShares.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'Individual Shares',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        'Tap to view details',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: session.calculatedShares.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final share = session.calculatedShares[index];
                    // Get assigned items for this person
                    final assignedItems = receipt.items
                        .where(
                          (item) => share.assignedItemIds.contains(item.id),
                        )
                        .toList();

                    return _buildPersonShareCard(share, assignedItems);
                  },
                ),
              ] else ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'No shares calculated',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptCard(Receipt receipt, SplitSession session) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormatter = DateFormat('MMM d, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            receipt.merchantName,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            dateFormatter.format(session.createdAt),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'RM ${receipt.subtotal.toStringAsFixed(2)}',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (receipt.sst > 0)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SST',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'RM ${receipt.sst.toStringAsFixed(2)}',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          if (receipt.serviceCharge > 0)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Service Charge',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'RM ${receipt.serviceCharge.toStringAsFixed(2)}',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          Divider(
            color: colorScheme.outline.withValues(alpha: 0.2),
            height: 16,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'RM ${receipt.total.toStringAsFixed(2)}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(ReceiptItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity}x RM ${item.price.toStringAsFixed(2)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'RM ${item.subtotal.toStringAsFixed(2)}',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonShareCard(
    PersonShare share,
    List<ReceiptItem> assignedItems,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      collapsedBackgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      title: Row(
        children: [
          // Gradient emoji avatar
          Container(
            width: 48,
            height: 48,
            margin: EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(Icons.person, color: colorScheme.primary, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          // Person name and total amount
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share.personName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RM ${share.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Trailing amount in primary color
          Text(
            'RM ${share.total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (assignedItems.isNotEmpty) ...[
                Text(
                  'Assigned Items',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: assignedItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = assignedItems[index];
                    return Text(
                      '${item.name} (${item.quantity}x)',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Divider(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                  height: 16,
                ),
              ],
              const SizedBox(height: 4),
              _BreakdownRow(
                label: 'Items Subtotal',
                amount: share.itemsSubtotal,
              ),
              const SizedBox(height: 8),
              _BreakdownRow(label: 'SST', amount: share.sst),
              const SizedBox(height: 8),
              _BreakdownRow(
                label: 'Service Charge',
                amount: share.serviceCharge,
              ),
              const SizedBox(height: 8),
              _BreakdownRow(label: 'Rounding', amount: share.rounding),
              const SizedBox(height: 12),
              Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
                height: 16,
              ),
              const SizedBox(height: 4),
              _BreakdownRow(label: 'Total', amount: share.total, isBold: true),
              const SizedBox(height: 16),

              // Payment Status Section
              PaymentToggleWidget(
                share: share,
                onPaymentChanged: (updatedShare) {
                  _handlePaymentUpdate(updatedShare);
                },
              ),

              const SizedBox(height: 12),

              // Share Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _shareIndividualShare(share),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share Details'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _generateWholeReceiptShareText(SplitSession session, Receipt receipt) {
    final buffer = StringBuffer();
    final dateFormatter = DateFormat('MMM d, yyyy');

    buffer.writeln('Receipt 🍽️');
    buffer.writeln(receipt.merchantName);
    buffer.writeln(dateFormatter.format(session.createdAt));
    buffer.writeln('Total: RM ${receipt.total.toStringAsFixed(2)}');
    buffer.writeln();

    for (final share in session.calculatedShares) {
      buffer.writeln(
        '${share.personEmoji} ${share.personName}: RM ${share.total.toStringAsFixed(2)}',
      );
    }

    buffer.writeln();
    buffer.writeln('Split via QuickSplit');

    return buffer.toString();
  }

  String _generateIndividualShareText(PersonShare share) {
    final buffer = StringBuffer();

    buffer.writeln('Your Share 💰');
    buffer.writeln('${share.personName} ${share.personEmoji}');
    buffer.writeln();
    buffer.writeln(
      'Items Subtotal: RM ${share.itemsSubtotal.toStringAsFixed(2)}',
    );
    buffer.writeln('SST: RM ${share.sst.toStringAsFixed(2)}');
    buffer.writeln(
      'Service Charge: RM ${share.serviceCharge.toStringAsFixed(2)}',
    );
    buffer.writeln('Rounding: RM ${share.rounding.toStringAsFixed(2)}');
    buffer.writeln();
    buffer.writeln('Total: RM ${share.total.toStringAsFixed(2)}');
    buffer.writeln();
    buffer.writeln('Split via QuickSplit');

    return buffer.toString();
  }

  Future<void> _shareWholeReceipt(SplitSession session, Receipt receipt) async {
    final text = _generateWholeReceiptShareText(session, receipt);
    await SharePlus.instance.share(
      ShareParams(text: text, subject: 'Receipt from QuickSplit'),
    );
  }

  Future<void> _shareIndividualShare(PersonShare share) async {
    final text = _generateIndividualShareText(share);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: '${share.personName} Share from QuickSplit',
      ),
    );
  }

  // NEW: Payment update handler
  Future<void> _handlePaymentUpdate(PersonShare updatedShare) async {
    try {
      // Update directly in Hive for immediate UI response
      final historyBox = Hive.box<SplitSession>('history');
      final session = historyBox.get(widget.splitId);

      if (session != null) {
        // Update the share in the calculatedShares list
        final updatedShares = session.calculatedShares.map((share) {
          return share.personId == updatedShare.personId ? updatedShare : share;
        }).toList();

        // Create updated session
        final updatedSession = session.copyWith(
          calculatedShares: updatedShares,
        );

        // Save to Hive
        await historyBox.put(widget.splitId, updatedSession);

        // Also update via provider for consistency
        await ref
            .read(paymentNotifierProvider.notifier)
            .updatePaymentStatus(widget.splitId, updatedShare);
      }

      // Show success message
      if (mounted) {
        _showSnackBar(
          '${updatedShare.personName} marked as ${updatedShare.paymentStatus.displayName}',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Failed to update payment: $e',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
  }

  // NEW: Use receipt for new split
  void _useForNewSplit(BuildContext context, SplitSession session) {
    // Get the receipt from Hive
    final receiptsBox = Hive.box<Receipt>('receipts');
    final receipt = receiptsBox.get(session.receiptId);

    if (receipt == null) {
      _showSnackBar(
        'Receipt not found',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
      return;
    }

    // Navigate to group select with the receipt to start a new split
    context.pushNamed('groupSelect', extra: receipt);
  }

  // NEW: Bulk action handlers
  Future<void> _markAllAsPaid(
    BuildContext context,
    SplitSession session,
  ) async {
    final errorColor = Theme.of(context).colorScheme.error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark All as Paid?'),
        content: const Text(
          'This will mark all shares as paid. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Mark All as Paid'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Update directly in Hive for immediate UI response
        final historyBox = Hive.box<SplitSession>('history');

        // Update all shares
        final updatedShares = session.calculatedShares.map((share) {
          return share.copyWithPayment(
            paymentStatus: PaymentStatus.paid,
            amountPaid: share.total,
            lastPaidAt: DateTime.now(),
            paymentNotes: null,
          );
        }).toList();

        // Create updated session
        final updatedSession = session.copyWith(
          calculatedShares: updatedShares,
        );

        // Save to Hive
        await historyBox.put(session.id, updatedSession);

        // Show success message
        _showSnackBar('All payments marked as paid');
      } catch (e) {
        if (mounted) {
          _showSnackBar(
            'Failed to update payments: $e',
            backgroundColor: errorColor,
          );
        }
      }
    }
  }

  Future<void> _markAllAsUnpaid(
    BuildContext context,
    SplitSession session,
  ) async {
    final errorColor = Theme.of(context).colorScheme.error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Payments?'),
        content: const Text('This will reset all payment statuses to unpaid.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Update directly in Hive for immediate UI response
        final historyBox = Hive.box<SplitSession>('history');

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
        await historyBox.put(session.id, updatedSession);

        // Show success message
        if (mounted) {
          _showSnackBar('All payments have been reset');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar(
            'Failed to reset payments: $e',
            backgroundColor: errorColor,
          );
        }
      }
    }
  }
}

/// Helper widget for displaying a single breakdown row
class _BreakdownRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;

  const _BreakdownRow({
    required this.label,
    required this.amount,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)
              : textTheme.bodySmall,
        ),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: isBold
              ? textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                )
              : textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
        ),
      ],
    );
  }
}
