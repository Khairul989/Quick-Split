import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicksplit/features/assign/presentation/screens/assign_items_screen.dart';
import 'package:quicksplit/features/assign/presentation/screens/summary_screen.dart';
import 'package:quicksplit/features/groups/presentation/screens/group_create_screen.dart';
import 'package:quicksplit/features/groups/presentation/screens/group_select_screen.dart';
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
            routes: [
              GoRoute(
                path: RouteNames.groupCreate,
                name: RouteNames.groupCreate,
                builder: (context, state) {
                  final receipt = state.extra as Receipt;
                  return GroupCreateScreen(receipt: receipt);
                },
              ),
            ],
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

class GroupsListScreen extends StatelessWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context) => _PlaceholderScreen('Groups');
}

/// Simple placeholder widget for unimplemented screens
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
