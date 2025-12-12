import 'package:flutter/material.dart';

import '../../domain/models/person_share.dart';

/// Widget displaying a person's share breakdown in an expandable card
/// Shows gradient emoji avatar, person name, and total amount
/// Expands to show itemized breakdown (subtotal, SST, service charge, rounding)
class PersonShareCard extends StatelessWidget {
  final PersonShare share;

  const PersonShareCard({required this.share, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        collapsedBackgroundColor: colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.7,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
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
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${share.total.toStringAsFixed(2)}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Trailing amount in primary color
            Text(
              'RM ${share.total.toStringAsFixed(2)}',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
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
                _BreakdownRow(
                  label: 'Items Subtotal',
                  amount: share.itemsSubtotal,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 8),
                _BreakdownRow(
                  label: 'SST',
                  amount: share.sst,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 8),
                _BreakdownRow(
                  label: 'Service Charge',
                  amount: share.serviceCharge,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 8),
                _BreakdownRow(
                  label: 'Rounding',
                  amount: share.rounding,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: 12),
                Divider(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  height: 16,
                ),
                const SizedBox(height: 4),
                _BreakdownRow(
                  label: 'Total',
                  amount: share.total,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper widget for displaying a single breakdown row
class _BreakdownRow extends StatelessWidget {
  final String label;
  final double amount;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isBold;

  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.colorScheme,
    required this.textTheme,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
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
