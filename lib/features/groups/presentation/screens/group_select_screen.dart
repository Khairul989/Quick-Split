import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicksplit/core/router/router.dart';
import 'package:quicksplit/features/assign/presentation/providers/session_provider.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';
import '../providers/group_providers.dart';
import '../widgets/group_card.dart';

class GroupSelectScreen extends ConsumerWidget {
  final Receipt receipt;
  const GroupSelectScreen({required this.receipt, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(groupsProvider);
    final frequentGroups = ref.watch(frequentGroupsProvider);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Group'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: groupsState.groups.isEmpty
            ? _EmptyState(
                colorScheme: colorScheme,
                textTheme: textTheme,
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: CustomScrollView(
                  slivers: [
                    // Frequent groups section
                    if (frequentGroups.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24.0, bottom: 12),
                          child: Text(
                            'Frequent Groups',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: frequentGroups.length,
                            itemBuilder: (context, index) {
                              final group = frequentGroups[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index == frequentGroups.length - 1
                                      ? 0
                                      : 12,
                                ),
                                child: SizedBox(
                                  width: 140,
                                  child: GroupCard(
                                    group: group,
                                    onTap: () {
                                      final groupsState = ref.read(groupsProvider);
                                      final people = groupsState.people
                                          .where((p) => group.personIds.contains(p.id))
                                          .toList();
                                      group.markUsed();
                                      ref
                                          .read(groupsProvider.notifier)
                                          .updateGroup(group);

                                      ref.read(sessionProvider.notifier).startSession(
                                        receipt: receipt,
                                        group: group,
                                        participants: people,
                                      );

                                      context.pushNamed(RouteNames.assignItems);
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 24),
                      ),
                    ],

                    // All groups section
                    SliverToBoxAdapter(
                      child: Text(
                        'All Groups',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 12),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final group = groupsState.groups[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GroupCard(
                              group: group,
                              isCompact: false,
                              onTap: () {
                                final groupsState = ref.read(groupsProvider);
                                final people = groupsState.people
                                    .where((p) => group.personIds.contains(p.id))
                                    .toList();
                                group.markUsed();
                                ref
                                    .read(groupsProvider.notifier)
                                    .updateGroup(group);

                                ref.read(sessionProvider.notifier).startSession(
                                  receipt: receipt,
                                  group: group,
                                  participants: people,
                                );

                                context.pushNamed(RouteNames.assignItems);
                              },
                            ),
                          );
                        },
                        childCount: groupsState.groups.length,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.pushNamed(
            RouteNames.groupCreate,
            extra: receipt,
          );
        },
        tooltip: 'Create New Group',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _EmptyState({
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty state icon
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Empty state title
          Text(
            'No Groups Yet',
            style: textTheme.displayLarge?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // Empty state subtitle
          Text(
            'Create a group to get started splitting bills',
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // CTA Button
          ElevatedButton(
            onPressed: () => context.pushNamed(RouteNames.groupCreate),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_add_outlined, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Create Your First Group',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
