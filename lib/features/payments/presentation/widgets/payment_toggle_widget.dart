import 'package:flutter/material.dart';

import '../../../assign/domain/models/person_share.dart';
import '../../domain/models/payment_status.dart';

/// Widget for toggling and displaying payment status for a person
class PaymentToggleWidget extends StatelessWidget {
  final PersonShare share;
  final Function(PersonShare) onPaymentChanged;

  const PaymentToggleWidget({
    super.key,
    required this.share,
    required this.onPaymentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: share.paymentStatus == PaymentStatus.paid
            ? colorScheme.primaryContainer.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleToggle(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Compact checkbox
                _buildStatusCheckbox(context),
                const SizedBox(width: 12),

                // Payment status text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        share.paymentStatus == PaymentStatus.unpaid
                            ? 'Mark as paid'
                            : share.paymentStatus == PaymentStatus.paid
                            ? 'Paid'
                            : 'Partially paid',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: share.paymentStatus == PaymentStatus.paid
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (share.paymentStatus == PaymentStatus.partial &&
                          share.amountPaid != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'RM ${share.amountPaid!.toStringAsFixed(2)} of RM ${share.total.toStringAsFixed(2)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (share.lastPaidAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Last updated: ${_formatDate(share.lastPaidAt!)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Status icon
                Icon(
                  share.paymentStatus.icon,
                  size: 20,
                  color: share.paymentStatus.getColor(context),
                ),

                // Edit button for paid/partial
                if (share.paymentStatus != PaymentStatus.unpaid) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => _showPaymentOptions(context),
                    tooltip: 'Edit payment',
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildStatusCheckbox(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getCheckboxColor(context),
        border: Border.all(color: _getBorderColor(context), width: 2),
      ),
      child: share.paymentStatus.isFullyPaid
          ? Icon(Icons.check_rounded, color: colorScheme.onPrimary, size: 14)
          : share.paymentStatus == PaymentStatus.partial
          ? Icon(Icons.remove_rounded, color: colorScheme.onSecondary, size: 14)
          : null,
    );
  }

  Color _getBorderColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (share.paymentStatus) {
      case PaymentStatus.unpaid:
        return colorScheme.outline.withValues(alpha: 0.2);
      case PaymentStatus.partial:
        return colorScheme.secondary.withValues(alpha: 0.5);
      case PaymentStatus.paid:
        return colorScheme.primary;
    }
  }

  Color _getCheckboxColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (share.paymentStatus) {
      case PaymentStatus.unpaid:
        return Colors.transparent;
      case PaymentStatus.partial:
        return colorScheme.secondaryContainer;
      case PaymentStatus.paid:
        return colorScheme.primary;
    }
  }

  void _handleToggle(BuildContext context) {
    PersonShare updatedShare;

    switch (share.paymentStatus) {
      case PaymentStatus.unpaid:
        updatedShare = share.copyWithPayment(
          paymentStatus: PaymentStatus.paid,
          amountPaid: share.total,
          lastPaidAt: DateTime.now(),
        );
        break;
      case PaymentStatus.partial:
      case PaymentStatus.paid:
        updatedShare = share.copyWithPayment(
          paymentStatus: PaymentStatus.unpaid,
          amountPaid: null,
          lastPaidAt: null,
          paymentNotes: null,
        );
        break;
    }

    onPaymentChanged(updatedShare);
  }

  void _showPaymentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          PaymentOptionsSheet(share: share, onPaymentChanged: onPaymentChanged),
    );
  }
}

/// Bottom sheet for editing payment options
class PaymentOptionsSheet extends StatefulWidget {
  final PersonShare share;
  final Function(PersonShare) onPaymentChanged;

  const PaymentOptionsSheet({
    super.key,
    required this.share,
    required this.onPaymentChanged,
  });

  @override
  State<PaymentOptionsSheet> createState() => _PaymentOptionsSheetState();
}

class _PaymentOptionsSheetState extends State<PaymentOptionsSheet> {
  late PaymentStatus _selectedStatus;
  late double? _amountPaid;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.share.paymentStatus;
    _amountPaid = widget.share.amountPaid;
    if (widget.share.paymentNotes != null) {
      _notesController.text = widget.share.paymentNotes!;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Update Payment',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Person info
          Row(
            children: [
              Text(
                widget.share.personEmoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.share.personName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Amount due: RM ${widget.share.total.toStringAsFixed(2)}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Status selection
          Text(
            'Payment Status',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusOption(PaymentStatus.unpaid, 'Unpaid'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusOption(PaymentStatus.partial, 'Partial'),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildStatusOption(PaymentStatus.paid, 'Paid')),
            ],
          ),

          // Amount input for partial payment
          if (_selectedStatus == PaymentStatus.partial) ...[
            const SizedBox(height: 24),
            Text(
              'Amount Paid',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(
                text: _amountPaid?.toStringAsFixed(2) ?? '',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                prefixText: 'RM ',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _amountPaid = double.tryParse(value);
                });
              },
            ),
          ],

          // Notes
          const SizedBox(height: 24),
          Text(
            'Notes (Optional)',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add payment notes...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _savePaymentStatus,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOption(PaymentStatus status, String label) {
    final isSelected = _selectedStatus == status;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
          if (status == PaymentStatus.paid) {
            _amountPaid = widget.share.total;
          } else if (status == PaymentStatus.unpaid) {
            _amountPaid = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? status.getColor(context).withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? status.getColor(context)
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              status.icon,
              color: isSelected
                  ? status.getColor(context)
                  : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? status.getColor(context)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savePaymentStatus() {
    final updatedShare = widget.share.copyWithPayment(
      paymentStatus: _selectedStatus,
      amountPaid: _amountPaid,
      lastPaidAt: _selectedStatus != PaymentStatus.unpaid
          ? DateTime.now()
          : null,
      paymentNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    widget.onPaymentChanged(updatedShare);
    Navigator.of(context).pop();
  }
}
