import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/contact_matching_provider.dart';

/// Widget showing suggested friends from device contacts who are registered on QuickSplit
/// Displays first 3 matches from cache with a button to see all matches
/// Uses ContactMatchingProvider for automatic caching (no network calls)
class SuggestedFriendsCard extends ConsumerWidget {
  final VoidCallback onViewAll;

  const SuggestedFriendsCard({required this.onViewAll, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get suggested friends from cache (first 3)
    final suggestions = ref.watch(suggestedContactsProvider);

    // Only show if we have suggestions
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.people_outline, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggested Friends',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${suggestions.length} friends on QuickSplit',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List of suggestions
            ...List.generate(suggestions.length, (index) {
              final (person, _) = suggestions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(person.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          if (person.email != null)
                            Text(
                              person.email!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),

            // View all button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onViewAll,
                child: const Text('See all matches'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
