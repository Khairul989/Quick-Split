import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../providers/recent_splits_provider.dart';

/// Card widget displaying a recent split entry
///
/// Shows merchant name, date, and total amount with Material Design icon.
/// Includes tap callback for navigation.
class RecentSplitCard extends StatelessWidget {
  final RecentSplitEntry entry;
  final VoidCallback onTap;

  const RecentSplitCard({required this.entry, required this.onTap, super.key});

  /// Format date to "MMM dd, yyyy" (e.g., "Dec 08, 2025")
  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Get Material Design icon based on merchant type
  IconData _getMerchantIcon(String merchantName) {
    final name = merchantName.toLowerCase();

    // Food & Restaurant
    if (name.contains('restaurant') || name.contains('food')) {
      return Icons.restaurant;
    }
    if (name.contains('coffee') || name.contains('cafe')) {
      return Icons.lunch_dining;
    }
    if (name.contains('pizza') || name.contains('burger')) {
      return Icons.local_pizza;
    }

    // Shopping
    if (name.contains('grocery') ||
        name.contains('market') ||
        name.contains('supermarket') ||
        name.contains('mall') ||
        name.contains('shop') ||
        name.contains('retail') ||
        name.contains('store')) {
      return Icons.shopping_cart;
    }

    // Drinks & Bars
    if (name.contains('drink') ||
        name.contains('bar') ||
        name.contains('pub')) {
      return Icons.local_bar;
    }

    // Accommodation
    if (name.contains('hotel') || name.contains('resort')) {
      return Icons.hotel;
    }

    // Default
    return Icons.receipt_long;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconData = _getMerchantIcon(entry.displayName);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Material icon in rounded background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(iconData, color: colorScheme.primary, size: 24),
                ),
              ),
              const SizedBox(width: 16),

              // Merchant name and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(entry.session.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Total amount
              Text(
                entry.formattedTotal,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
