import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quicksplit/core/router/router.dart';
import 'package:quicksplit/core/utils/whatsapp_helper.dart';
import '../../../ocr/domain/models/receipt.dart';
import '../providers/calculator_provider.dart';
import '../providers/session_provider.dart';
import '../providers/assignment_providers.dart';
import '../widgets/person_share_card.dart';

/// Summary screen showing the calculated split for all participants
/// Displays receipt information, person-by-person breakdown, and action buttons
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCalculation();
    });
  }

  void _ensureCalculation() {
    final session = ref.read(sessionProvider);
    final receipt = session.currentReceipt;
    final participants = session.participants;
    final assignments = ref.read(calculatorProvider).shares.isEmpty
        ? ref.read(assignmentProvider)
        : null;

    if (receipt != null && participants.isNotEmpty && assignments != null) {
      ref
          .read(calculatorProvider.notifier)
          .calculate(
            receipt: receipt,
            participants: participants,
            assignments: assignments.assignments,
          );
    }
  }

  String _generateShareText(Receipt receipt) {
    final calculatorState = ref.read(calculatorProvider);
    final shares = calculatorState.shares;

    if (shares.isEmpty) {
      return 'Unable to generate share text';
    }

    final buffer = StringBuffer();
    buffer.writeln('Receipt 🍽️');
    buffer.writeln(receipt.merchantName);
    buffer.writeln('Total: RM ${receipt.total.toStringAsFixed(2)}');
    buffer.writeln();

    for (final share in shares) {
      buffer.writeln(
        '${share.personEmoji} ${share.personName}: RM ${share.total.toStringAsFixed(2)}',
      );
    }

    buffer.writeln();
    buffer.writeln('Split via QuickSplit');

    return buffer.toString();
  }

  Future<void> _handleSaveAndShare() async {
    final session = ref.read(sessionProvider);
    if (session.currentReceipt == null) return;

    try {
      await ref.read(sessionProvider.notifier).saveSession();

      if (!mounted) return;

      final shareText = _generateShareText(session.currentReceipt!);
      await Clipboard.setData(ClipboardData(text: shareText));
      await SharePlus.instance.share(
        ShareParams(text: shareText, subject: 'Receipt from QuickSplit'),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved, copied & shared!'),
          duration: Duration(milliseconds: 1200),
        ),
      );

      ref.read(sessionProvider.notifier).resetSession();
      context.go('/${RouteNames.home}');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleShareViaWhatsApp() async {
    final calculatorState = ref.read(calculatorProvider);
    final shares = calculatorState.shares;
    final receipt = ref.read(sessionProvider).currentReceipt;

    if (shares.isEmpty || receipt == null) return;

    // Show dialog to select which participant to share with
    final selectedShare = await showDialog<dynamic>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share via WhatsApp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a participant to share their breakdown:'),
            const SizedBox(height: 16),
            ...shares.map((share) => ListTile(
              leading: Text(share.personEmoji, style: const TextStyle(fontSize: 24)),
              title: Text(share.personName),
              subtitle: Text('RM ${share.total.toStringAsFixed(2)}'),
              onTap: () => Navigator.of(context).pop(share),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedShare == null || !mounted) return;

    try {
      await WhatsAppHelper.shareBillSummary(
        receipt: receipt,
        userShare: selectedShare,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shared ${selectedShare.personName}\'s breakdown via WhatsApp'),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share via WhatsApp: ${e.toString().contains('not installed') ? 'WhatsApp is not installed' : 'An error occurred'}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final session = ref.watch(sessionProvider);
    final receipt = session.currentReceipt;
    final calculatorState = ref.watch(calculatorProvider);

    if (receipt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Split Summary')),
        body: const Center(child: Text('No active session')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Summary'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receipt information card
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                      ),
                    ),
                    // Person shares section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Individual Shares',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (calculatorState.isCalculated &&
                        calculatorState.shares.isNotEmpty)
                      ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: calculatorState.shares.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return PersonShareCard(
                            share: calculatorState.shares[index],
                          );
                        },
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Calculating...',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Action buttons
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Edit Assignments'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleSaveAndShare,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.share_rounded, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Save & Share',
                                style: textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // NEW: WhatsApp share button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _handleShareViaWhatsApp,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF25D366)),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF25D366)),
                      label: const Text(
                        'Share via WhatsApp',
                        style: TextStyle(color: Color(0xFF25D366)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
