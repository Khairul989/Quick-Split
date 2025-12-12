import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

part 'payment_status.g.dart';

/// Payment status enumeration for tracking individual payments
@HiveType(typeId: 7)
enum PaymentStatus {
  @HiveField(0)
  unpaid,

  @HiveField(1)
  partial,

  @HiveField(2)
  paid,
}

/// Extension methods for payment status
extension PaymentStatusExtensions on PaymentStatus {
  /// Get human-readable display name
  String get displayName {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.partial:
        return 'Partial';
      case PaymentStatus.paid:
        return 'Paid';
    }
  }

  /// Get associated color for UI
  Color getColor(BuildContext context) {
    switch (this) {
      case PaymentStatus.unpaid:
        return Theme.of(context).colorScheme.outline;
      case PaymentStatus.partial:
        return Theme.of(context).colorScheme.secondary;
      case PaymentStatus.paid:
        return Theme.of(context).colorScheme.primary;
    }
  }

  /// Get associated icon
  IconData get icon {
    switch (this) {
      case PaymentStatus.unpaid:
        return Icons.hourglass_empty_rounded;
      case PaymentStatus.partial:
        return Icons.timelapse_rounded;
      case PaymentStatus.paid:
        return Icons.check_circle_rounded;
    }
  }

  /// Check if status indicates payment has been made
  bool get hasPaid => this == PaymentStatus.partial || this == PaymentStatus.paid;

  /// Check if status is fully paid
  bool get isFullyPaid => this == PaymentStatus.paid;
}