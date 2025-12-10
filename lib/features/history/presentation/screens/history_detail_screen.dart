import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../assign/domain/models/split_session.dart';
import '../../../assign/domain/models/person_share.dart';
import '../../../ocr/domain/models/receipt.dart';

/// History detail screen showing complete split session details
/// Loads data from Hive and displays receipt summary and individual shares
class HistoryDetailScreen extends ConsumerStatefulWidget {
  final String splitId;

  const HistoryDetailScreen({required this.splitId, super.key});

  @override
  ConsumerState<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends ConsumerState<HistoryDetailScreen> {
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
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    try {
      // Load session from Hive
      final historyBox = Hive.box<SplitSession>('history');

      debugPrint('[HistoryDetail] splitId passed: ${widget.splitId}');
      debugPrint('[HistoryDetail] Available session IDs: ${historyBox.keys.toList()}');

      final session = historyBox.values.firstWhere(
        (s) => s.id == widget.splitId,
        orElse: () => throw Exception('Split session not found'),
      );

      debugPrint('[HistoryDetail] Session found: ${session.id}');
      debugPrint('[HistoryDetail] Session receiptId: ${session.receiptId}');

      // Load receipt from Hive
      final receiptsBox = Hive.box<Receipt>('receipts');
      debugPrint('[HistoryDetail] All receipt keys in box: ${receiptsBox.keys.toList()}');
      debugPrint('[HistoryDetail] Looking for receipt with ID: ${session.receiptId}');

      final receipt = receiptsBox.get(session.receiptId);

      debugPrint('[HistoryDetail] Receipt found: ${receipt != null}');
      if (receipt != null) {
        debugPrint('[HistoryDetail] Receipt details - merchant: ${receipt.merchantName}, items: ${receipt.items.length}, total: ${receipt.total}');
      }

      if (receipt == null) {
        return Center(
          child: Text(
            'Receipt not found',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }

      return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => _shareWholeReceipt(session, receipt),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.share_rounded, color: Colors.white),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Receipt information card
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildReceiptCard(receipt, session),
                ),

                // Items section
                if (receipt.items.isNotEmpty) ...[
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
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = receipt.items[index];
                      return _buildItemRow(item);
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Individual Shares section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Individual Shares',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                if (session.calculatedShares.isNotEmpty)
                  ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: session.calculatedShares.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final share = session.calculatedShares[index];
                      // Get assigned items for this person
                      final assignedItems = receipt.items
                          .where((item) =>
                              share.assignedItemIds.contains(item.id))
                          .toList();

                      return _buildPersonShareCard(share, assignedItems);
                    },
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'No shares calculated',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
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
              'Error loading split details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'The split session or receipt could not be found.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
  }

  Widget _buildReceiptCard(Receipt receipt, SplitSession session) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormatter = DateFormat('MMM d, yyyy');

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            receipt.merchantName,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
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
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      collapsedBackgroundColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.5),
      backgroundColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.7),
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                share.personEmoji,
                style: const TextStyle(fontSize: 24),
              ),
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
          IconButton(
            icon: const Icon(Icons.share_rounded),
            iconSize: 20,
            onPressed: () => _shareIndividualShare(share),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 8),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                  height: 16,
                ),
              ],
              const SizedBox(height: 4),
              _BreakdownRow(
                label: 'Items Subtotal',
                amount: share.itemsSubtotal,
              ),
              const SizedBox(height: 8),
              _BreakdownRow(
                label: 'SST',
                amount: share.sst,
              ),
              const SizedBox(height: 8),
              _BreakdownRow(
                label: 'Service Charge',
                amount: share.serviceCharge,
              ),
              const SizedBox(height: 8),
              _BreakdownRow(
                label: 'Rounding',
                amount: share.rounding,
              ),
              const SizedBox(height: 12),
              Divider(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.2),
                height: 16,
              ),
              const SizedBox(height: 4),
              _BreakdownRow(
                label: 'Total',
                amount: share.total,
                isBold: true,
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
      buffer.writeln('${share.personEmoji} ${share.personName}: RM ${share.total.toStringAsFixed(2)}');
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
    buffer.writeln('Items Subtotal: RM ${share.itemsSubtotal.toStringAsFixed(2)}');
    buffer.writeln('SST: RM ${share.sst.toStringAsFixed(2)}');
    buffer.writeln('Service Charge: RM ${share.serviceCharge.toStringAsFixed(2)}');
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
      ShareParams(
        text: text,
        subject: 'Receipt from QuickSplit',
      ),
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
              ? textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                )
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
