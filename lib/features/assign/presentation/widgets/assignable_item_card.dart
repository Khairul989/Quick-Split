import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicksplit/features/assign/presentation/providers/assignment_providers.dart';
import 'package:quicksplit/features/groups/domain/models/person.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';

class AssignableItemCard extends ConsumerWidget {
  final ReceiptItem item;
  final List<Person> participants;
  final VoidCallback onTap;

  const AssignableItemCard({
    required this.item,
    required this.participants,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final assignment = ref.watch(assignmentProvider).getAssignment(item.id);
    // final isAssigned = assignment?.isAssigned ?? false;
    // final isShared = assignment?.isShared ?? false;
    final assignedPersonIds = assignment?.assignedPersonIds ?? [];

    final assignedPeople = participants
        .where((person) => assignedPersonIds.contains(person.id))
        .toList();

    // Color borderColor;
    // if (!isAssigned) {
    //   borderColor = colorScheme.outline.withValues(alpha: 0.5);
    // } else if (isShared) {
    //   borderColor = Colors.purple;
    // } else {
    //   borderColor = colorScheme.primary;
    // }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.quantity}x @ RM${item.price.toStringAsFixed(2)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (assignedPeople.isNotEmpty)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primary,
                      child: Icon(
                        assignedPeople.length > 1
                            ? Icons.people_rounded
                            : Icons.person_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                Icon(Icons.chevron_right_rounded, color: colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
