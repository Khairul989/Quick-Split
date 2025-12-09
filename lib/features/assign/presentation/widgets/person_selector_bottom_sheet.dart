import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicksplit/features/assign/presentation/providers/assignment_providers.dart';
import 'package:quicksplit/features/groups/domain/models/person.dart';

class PersonSelectorBottomSheet extends ConsumerWidget {
  final String itemId;
  final List<Person> participants;

  const PersonSelectorBottomSheet({
    required this.itemId,
    required this.participants,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final assignmentState = ref.watch(assignmentProvider);
    final assignedPersonIds = assignmentState.getAssignedPersonIds(itemId);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who had this item?',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select all people who shared this item',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: participants.length,
              itemBuilder: (context, index) {
                final person = participants[index];
                final isChecked = assignedPersonIds.contains(person.id);

                return CheckboxListTile(
                  value: isChecked,
                  onChanged: (_) {
                    ref
                        .read(assignmentProvider.notifier)
                        .togglePersonForItem(itemId, person.id);
                  },
                  secondary: CircleAvatar(
                    backgroundColor: colorScheme.primary,
                    child: Text(
                      person.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  title: Text(
                    person.name,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  activeColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
