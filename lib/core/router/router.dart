import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:quicksplit/features/assign/presentation/screens/assign_items_screen.dart';
import 'package:quicksplit/features/assign/presentation/screens/summary_screen.dart';
import 'package:quicksplit/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:quicksplit/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:quicksplit/features/auth/presentation/screens/login_screen.dart';
import 'package:quicksplit/features/auth/presentation/screens/signup_screen.dart';
import 'package:quicksplit/features/auth/presentation/screens/welcome_screen.dart';
import 'package:quicksplit/features/groups/domain/models/group.dart';
import 'package:quicksplit/features/groups/presentation/screens/group_create_screen.dart';
import 'package:quicksplit/features/groups/presentation/screens/group_edit_screen.dart';
import 'package:quicksplit/features/groups/presentation/screens/group_select_screen.dart';
import 'package:quicksplit/features/groups/presentation/screens/groups_list_screen.dart';
import 'package:quicksplit/features/history/presentation/screens/history_detail_screen.dart';
import 'package:quicksplit/features/history/presentation/screens/history_screen.dart';
import 'package:quicksplit/features/home/presentation/screens/home_screen.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';
import 'package:quicksplit/features/ocr/presentation/screens/item_editor_screen.dart';
import 'package:quicksplit/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:quicksplit/features/scan/presentation/screens/camera_screen.dart';
import 'package:quicksplit/features/settings/presentation/screens/edit_profile_screen.dart';
import 'package:quicksplit/features/settings/presentation/screens/settings_screen.dart';
import 'package:quicksplit/features/groups/presentation/screens/find_friends_screen.dart';
import 'package:quicksplit/features/groups/presentation/screens/invite_screen.dart';
import 'package:quicksplit/features/groups/presentation/screens/accept_invite_screen.dart';

/// Route name constants - use these to navigate instead of hardcoded strings
abstract class RouteNames {
  // Main flow
  static const String home = 'home';
  static const String splash = 'splash';
  static const String onboarding = 'onboarding';
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String signup = 'signup';
  static const String forgotPassword = 'forgotPassword';

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
  static const String findFriends = 'findFriends';
  static const String invite = 'invite';
  static const String acceptInvite = 'acceptInvite';

  // History feature
  static const String history = 'history';
  static const String historyDetail = 'historyDetail';

  // Settings feature
  static const String settings = 'settings';
  static const String editProfile = 'editProfile';
}

/// Router configuration using GoRouter
/// Centralize all navigation routes here
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    redirect: (context, state) {
      try {
        final preferencesBox = Hive.box('preferences');
        final hasCompletedOnboarding =
            preferencesBox.get('hasCompletedOnboarding', defaultValue: false)
                as bool;

        final currentLocation = state.matchedLocation;
        final isOnboardingRoute = currentLocation == '/onboarding';
        final isAuthRoute =
            currentLocation == '/welcome' ||
            currentLocation == '/login' ||
            currentLocation == '/signup' ||
            currentLocation == '/forgotPassword';
        final isInviteRoute = currentLocation.startsWith('/invite/');

        // Check if user is authenticated via Firebase
        final isAuthenticated = authState.value != null;

        // 1. Allow invite routes regardless of auth state
        if (isInviteRoute) {
          return null;
        }

        // 2. If not authenticated and not on auth/onboarding routes, go to welcome
        if (!isAuthenticated && !isAuthRoute && !isOnboardingRoute) {
          return '/welcome';
        }

        // 3. If authenticated but hasn't completed onboarding, go to onboarding
        if (isAuthenticated && !hasCompletedOnboarding && !isOnboardingRoute) {
          return '/onboarding';
        }

        // 4. If authenticated and completed onboarding, redirect from auth/onboarding to home
        if (isAuthenticated &&
            hasCompletedOnboarding &&
            (isAuthRoute || isOnboardingRoute)) {
          return '/home';
        }

        // 5. Allow navigation to auth routes when not authenticated
        if (!isAuthenticated && isAuthRoute) {
          return null;
        }

        // 6. Allow onboarding route when authenticated but not completed
        if (isAuthenticated && !hasCompletedOnboarding && isOnboardingRoute) {
          return null;
        }

        return null;
      } catch (e) {
        // If any error (e.g., Hive box not ready), allow navigation
        return null;
      }
    },
    initialLocation: '/welcome',
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
      // Auth routes (top-level)
      GoRoute(
        path: '/welcome',
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: RouteNames.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgotPassword',
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

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

          GoRoute(
            path: RouteNames.findFriends,
            name: RouteNames.findFriends,
            builder: (context, state) => const FindFriendsScreen(),
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
            routes: [
              GoRoute(
                path: RouteNames.editProfile,
                name: RouteNames.editProfile,
                builder: (context, state) => const EditProfileScreen(),
              ),
            ],
          ),

          // Invite screen - show invite code and share options
          GoRoute(
            path: RouteNames.invite,
            name: RouteNames.invite,
            builder: (context, state) {
              final Map<String, dynamic> data =
                  state.extra as Map<String, dynamic>? ?? {};
              final group = data['group'] as Group?;
              final userId = data['userId'] as String? ?? '';
              final userName = data['userName'] as String? ?? '';

              if (group == null) {
                return const Scaffold(
                  body: Center(child: Text('Group not found')),
                );
              }

              return InviteScreen(
                group: group,
                currentUserId: userId,
                currentUserName: userName,
              );
            },
          ),
        ],
      ),

      // Accept invite route (top-level for deep links)
      GoRoute(
        path: '/invite/:code',
        name: RouteNames.acceptInvite,
        builder: (context, state) {
          final code = state.pathParameters['code'] ?? '';
          return AcceptInviteScreen(inviteCode: code);
        },
      ),
    ],
  );
});
