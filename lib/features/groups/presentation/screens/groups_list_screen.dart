import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicksplit/core/router/router.dart';
import 'package:quicksplit/features/groups/presentation/providers/group_providers.dart';
import 'package:quicksplit/features/groups/presentation/providers/preselected_group_provider.dart';
import 'package:quicksplit/features/groups/presentation/widgets/group_card.dart';

/// Full-featured Groups List Screen for managing all groups
class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(groupsProvider);
    final groups = groupsState.groups;

    return Scaffold(
      appBar: AppBar(title: const Text('Groups'), centerTitle: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(RouteNames.groupCreate),
        backgroundColor: const Color(0xFF248CFF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Group'),
      ),
      body: groups.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Dismissible(
                    key: Key(group.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await _showDeleteConfirmation(context, group.name);
                    },
                    onDismissed: (direction) {
                      ref.read(groupsProvider.notifier).deleteGroup(group.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deleted ${group.name}'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              // TODO: Implement undo functionality
                            },
                          ),
                        ),
                      );
                    },
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, color: Colors.white, size: 28),
                          SizedBox(height: 4),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    child: GroupCard(
                      group: group,
                      isCompact: false,
                      onTap: () => _showGroupOptions(context, ref, group),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF248CFF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_rounded,
                size: 40,
                color: Color(0xFF248CFF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No groups yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first group to start splitting bills with friends',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.pushNamed(RouteNames.groupCreate),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF248CFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, size: 24),
              label: const Text(
                'Create Your First Group',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    String groupName,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group?'),
        content: Text(
          'Are you sure you want to delete "$groupName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showGroupOptions(BuildContext context, WidgetRef ref, group) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              Text(
                group.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF248CFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Color(0xFF248CFF),
                  ),
                ),
                title: const Text('Use for New Split'),
                subtitle: const Text('Start splitting with this group'),
                onTap: () {
                  Navigator.pop(context);
                  // Store the selected group for pre-selection
                  ref
                      .read(preselectedGroupIdProvider.notifier)
                      .setGroupId(group.id);
                  // Navigate to home and trigger add receipt flow
                  context.go('/${RouteNames.home}');
                  // Show add receipt bottom sheet
                  // Note: This will be triggered from home screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Starting split with ${group.name}...'),
                      duration: const Duration(milliseconds: 1500),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit, color: Color(0xFFFFA726)),
                ),
                title: const Text('Edit Group'),
                subtitle: const Text('Modify group details and members'),
                onTap: () {
                  Navigator.pop(context);
                  context.pushNamed(RouteNames.groupEdit, extra: group);
                },
              ),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.delete, color: Colors.red.shade400),
                ),
                title: Text(
                  'Delete Group',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                subtitle: const Text('This action cannot be undone'),
                onTap: () async {
                  final confirmed = await _showDeleteConfirmation(
                    context,
                    group.name,
                  );
                  if (confirmed == true && context.mounted) {
                    Navigator.pop(context);
                    ref.read(groupsProvider.notifier).deleteGroup(group.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deleted ${group.name}')),
                    );
                  } else if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
