import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicksplit/core/router/router.dart';
import 'package:quicksplit/features/assign/presentation/providers/assignment_providers.dart';
import 'package:quicksplit/features/assign/presentation/providers/session_provider.dart';
import 'package:quicksplit/features/assign/presentation/widgets/assignable_item_card.dart';
import 'package:quicksplit/features/assign/presentation/widgets/person_chip.dart';
import 'package:quicksplit/features/assign/presentation/widgets/person_selector_bottom_sheet.dart';

class AssignItemsScreen extends ConsumerStatefulWidget {
  const AssignItemsScreen({super.key});

  @override
  ConsumerState<AssignItemsScreen> createState() => _AssignItemsScreenState();
}

class _AssignItemsScreenState extends ConsumerState<AssignItemsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAssignments();
    });
  }

  void _initializeAssignments() {
    final session = ref.read(sessionProvider);
    if (session.currentReceipt != null) {
      ref
          .read(assignmentProvider.notifier)
          .initialize(
            session.currentReceipt!.items,
            session.participants.map((p) => p.id).toList(),
          );
    }
  }

  void _showPersonSelector(String itemId) {
    final session = ref.read(sessionProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => PersonSelectorBottomSheet(
        itemId: itemId,
        participants: session.participants,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final session = ref.watch(sessionProvider);
    final receipt = session.currentReceipt;
    final participants = session.participants;

    if (receipt == null || participants.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assign Items')),
        body: const Center(child: Text('No active session')),
      );
    }

    final unassignedCount = ref.watch(unassignedItemsCountProvider);
    final isFullyAssigned = ref.watch(isFullyAssignedProvider);

    final totalItems = receipt.items.length;
    final assignedItems = totalItems - unassignedCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assign Items'),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '$assignedItems/$totalItems assigned',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: totalItems > 0 ? assignedItems / totalItems : 0,
                    minHeight: 6,
                    backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Participants',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ...participants.map(
                                  (person) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: PersonChip(person: person),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Receipt Items',
                        style: textTheme.titleMedium?.copyWith(
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
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = receipt.items[index];
                        return AssignableItemCard(
                          item: item,
                          participants: participants,
                          onTap: () => _showPersonSelector(item.id),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$unassignedCount items unassigned',
                        style: textTheme.bodyMedium?.copyWith(
                          color: unassignedCount > 0
                              ? Colors.orange
                              : colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: isFullyAssigned
                        ? () {
                            context.pushNamed(RouteNames.summary);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Calculate'),
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
