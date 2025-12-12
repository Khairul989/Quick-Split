import 'package:flutter/material.dart';

import '../../../assign/domain/models/person_share.dart';
import '../../../assign/domain/models/split_session.dart';
import '../../domain/models/payment_status.dart';

/// Banner widget displaying payment status summary for a split session
class PaymentStatusBanner extends StatelessWidget {
  final SplitSession session;

  const PaymentStatusBanner({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final paymentSummary = _calculatePaymentSummary(session);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.95),
            colorScheme.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Payment Status',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Financial Summary
          _buildSummaryRow(
            context,
            label: 'Total Expected',
            amount: paymentSummary.totalExpected,
            isPrimary: true,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            context,
            label: 'Amount Paid',
            amount: paymentSummary.totalPaid,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            context,
            label: 'Remaining',
            amount: paymentSummary.remaining,
            color: paymentSummary.remaining > 0
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white,
          ),

          const SizedBox(height: 20),
          Divider(color: colorScheme.outline.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 16),

          // Progress Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // People count
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${paymentSummary.peoplePaid} of ${paymentSummary.totalPeople}',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  Text(
                    'people paid',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),

              // Progress indicator
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 6,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    // Progress circle
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: paymentSummary.paymentProgress,
                        strokeWidth: 6,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    // Percentage text
                    Text(
                      '${(paymentSummary.paymentProgress * 100).round()}%',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Status chips
          if (paymentSummary.unpaidPeople.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: paymentSummary.unpaidPeople.take(3).map((person) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        person.personEmoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        person.personName,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (paymentSummary.unpaidPeople.length > 3)
              Text(
                '+${paymentSummary.unpaidPeople.length - 3} more',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required double amount,
    Color? color,
    bool isPrimary = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onPrimary.withValues(alpha: 0.9),
          ),
        ),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: isPrimary
              ? textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color ?? colorScheme.onPrimary,
                )
              : textTheme.bodyMedium?.copyWith(
                  color: color ?? colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
        ),
      ],
    );
  }

  PaymentSummary _calculatePaymentSummary(SplitSession session) {
    double totalExpected = 0;
    double totalPaid = 0;
    int peoplePaid = 0;
    int totalPeople = session.calculatedShares.length;
    List<PersonShare> unpaidPeople = [];

    for (final share in session.calculatedShares) {
      totalExpected += share.total;

      if (share.paymentStatus == PaymentStatus.paid) {
        totalPaid += share.total;
        peoplePaid++;
      } else if (share.paymentStatus == PaymentStatus.partial &&
          share.amountPaid != null) {
        totalPaid += share.amountPaid!;
        if (share.amountPaid! >= share.total) {
          peoplePaid++;
        } else {
          unpaidPeople.add(share);
        }
      } else {
        unpaidPeople.add(share);
      }
    }

    return PaymentSummary(
      totalExpected: totalExpected,
      totalPaid: totalPaid,
      remaining: totalExpected - totalPaid,
      peoplePaid: peoplePaid,
      totalPeople: totalPeople,
      unpaidPeople: unpaidPeople,
      paymentProgress: totalExpected > 0 ? totalPaid / totalExpected : 0,
    );
  }
}

/// Immutable class containing payment summary data
@immutable
class PaymentSummary {
  final double totalExpected;
  final double totalPaid;
  final double remaining;
  final int peoplePaid;
  final int totalPeople;
  final List<PersonShare> unpaidPeople;
  final double paymentProgress;

  const PaymentSummary({
    required this.totalExpected,
    required this.totalPaid,
    required this.remaining,
    required this.peoplePaid,
    required this.totalPeople,
    required this.unpaidPeople,
    required this.paymentProgress,
  });

  /// Check if all payments are complete
  bool get isFullyPaid => remaining <= 0.01; // Account for floating point

  /// Get completion percentage as integer
  int get completionPercentage => (paymentProgress * 100).round();
}
