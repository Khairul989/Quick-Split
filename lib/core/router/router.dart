import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:quicksplit/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:quicksplit/features/assign/presentation/screens/assign_items_screen.dart';
import 'package:quicksplit/features/assign/presentation/screens/summary_screen.dart';
import 'package:quicksplit/features/groups/presentation/screens/group_create_screen.dart';
import 'package:quicksplit/features/groups/presentation/screens/group_edit_screen.dart';
import 'package:quicksplit/features/groups/presentation/screens/group_select_screen.dart';
import 'package:quicksplit/features/groups/domain/models/group.dart';
import 'package:quicksplit/features/groups/presentation/providers/group_providers.dart';
import 'package:quicksplit/features/groups/presentation/providers/preselected_group_provider.dart';
import 'package:quicksplit/features/groups/presentation/widgets/group_card.dart';
import 'package:quicksplit/features/history/presentation/screens/history_detail_screen.dart';
import 'package:quicksplit/features/history/presentation/screens/history_screen.dart';
import 'package:quicksplit/features/home/presentation/screens/home_screen.dart';
import 'package:quicksplit/features/settings/presentation/screens/settings_screen.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';
import 'package:quicksplit/features/ocr/presentation/screens/item_editor_screen.dart';
import 'package:quicksplit/features/scan/presentation/screens/camera_screen.dart';

/// Route name constants - use these to navigate instead of hardcoded strings
abstract class RouteNames {
  // Main flow
  static const String home = 'home';
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';

  // Scan feature
  static const String scan = 'scan';
  static const String camera = 'camera';


  // Items feature
  static const String itemsEditor = 'itemsEditor';

  // Assign feature
  static const String groupSelect = 'groupSelect';
  static const String assignItems = 'assignItems';
  static const String summary = 'summary';

  // Groups feature
  static const String groupsList = 'groupsList';
  static const String groupCreate = 'groupCreate';
  static const String groupEdit = 'groupEdit';

  // History feature
  static const String history = 'history';
  static const String historyDetail = 'historyDetail';

  // Settings feature
  static const String settings = 'settings';
}

/// Router configuration using GoRouter
/// Centralize all navigation routes here
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    redirect: (context, state) {
      try {
        final preferencesBox = Hive.box('preferences');
        final hasCompleted = preferencesBox.get(
          'hasCompletedOnboarding',
          defaultValue: false,
        ) as bool;
        final isOnboardingRoute = state.matchedLocation == '/onboarding';

        // Redirect to onboarding if not completed
        if (!hasCompleted && !isOnboardingRoute) {
          return '/onboarding';
        }

        // Redirect to home if onboarding already completed
        if (hasCompleted && isOnboardingRoute) {
          return '/home';
        }

        return null;
      } catch (e) {
        // If Hive box not ready, allow navigation
        return null;
      }
    },
    initialLocation: '/${RouteNames.home}',
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Page not found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/${RouteNames.home}'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
    routes: <RouteBase>[
      // Onboarding route (top-level)
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Home/Root route
      GoRoute(
        path: '/${RouteNames.home}',
        name: RouteNames.home,
        builder: (BuildContext context, GoRouterState state) {
          return const HomeScreen();
        },
        routes: [
          // Scan flow
          GoRoute(
            path: RouteNames.scan,
            name: RouteNames.scan,
            builder: (context, state) => const CameraScreen(),
          ),

          // Items editor
          GoRoute(
            path: RouteNames.itemsEditor,
            name: RouteNames.itemsEditor,
            builder: (context, state) {
              final items = state.extra as List<ReceiptItem>?;
              return ItemEditorScreen(initialItems: items);
            },
          ),

          // Assignment flow
          GoRoute(
            path: RouteNames.groupSelect,
            name: RouteNames.groupSelect,
            builder: (context, state) {
              final receipt = state.extra as Receipt;
              return GroupSelectScreen(receipt: receipt);
            },
          ),

          GoRoute(
            path: RouteNames.assignItems,
            name: RouteNames.assignItems,
            builder: (context, state) => const AssignItemsScreen(),
          ),

          GoRoute(
            path: RouteNames.summary,
            name: RouteNames.summary,
            builder: (context, state) => const SummaryScreen(),
          ),

          // Groups management
          GoRoute(
            path: RouteNames.groupsList,
            name: RouteNames.groupsList,
            builder: (context, state) => const GroupsListScreen(),
          ),

          GoRoute(
            path: RouteNames.groupCreate,
            name: RouteNames.groupCreate,
            builder: (context, state) {
              final receipt = state.extra as Receipt?;
              return GroupCreateScreen(receipt: receipt);
            },
          ),

          GoRoute(
            path: RouteNames.groupEdit,
            name: RouteNames.groupEdit,
            builder: (context, state) {
              final group = state.extra as Group;
              return GroupEditScreen(group: group);
            },
          ),

          // History
          GoRoute(
            path: RouteNames.history,
            name: RouteNames.history,
            builder: (context, state) => const HistoryScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: RouteNames.historyDetail,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return HistoryDetailScreen(splitId: id);
                },
              ),
            ],
          ),

          // Settings
          GoRoute(
            path: RouteNames.settings,
            name: RouteNames.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

/// Full-featured Groups List Screen for managing all groups
class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(groupsProvider);
    final groups = groupsState.groups;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        centerTitle: false,
      ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                  ref.read(preselectedGroupIdProvider.notifier).setGroupId(group.id);
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
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFFFFA726),
                  ),
                ),
                title: const Text('Edit Group'),
                subtitle: const Text('Modify group details and members'),
                onTap: () {
                  Navigator.pop(context);
                  context.pushNamed(
                    RouteNames.groupEdit,
                    extra: group,
                  );
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
                  child: Icon(
                    Icons.delete,
                    color: Colors.red.shade400,
                  ),
                ),
                title: Text(
                  'Delete Group',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                subtitle: const Text('This action cannot be undone'),
                onTap: () async {
                  final confirmed =
                      await _showDeleteConfirmation(context, group.name);
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
