import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/providers/theme_provider.dart';
import 'core/router/router.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/theme.dart';
import 'features/assign/domain/models/split_session.dart';
import 'features/groups/domain/models/contact_match.dart';
import 'features/groups/domain/models/group.dart';
import 'features/groups/domain/models/group_invite.dart';
import 'features/groups/domain/models/person.dart';
import 'features/ocr/domain/models/receipt.dart';
import 'hive_registrar.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive before building the app
  await _initializeHive();

  // Initialize Firebase
  await FirebaseService.initialize();
  debugPrint('Firebase initialization successful');

  // Setup background message handler for Firebase Cloud Messaging
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    ProviderScope(child: QuickSplitApp(onInitialize: _initializeDeepLinks)),
  );
}

/// Initialize deep link handling
/// This is called after the app is built
Future<void> _initializeDeepLinks(GoRouter router) async {
  final deepLinkService = DeepLinkService();

  // Initialize deep link listener with a callback that navigates using GoRouter
  await deepLinkService.initialize((uri) async {
    final code = deepLinkService.extractInviteCode(uri);
    if (code != null) {
      // Navigate to invite acceptance screen
      router.go('/invite/$code');
    }
  });
}

/// Initialize Hive database and create boxes
/// Call this before building the app
Future<void> _initializeHive() async {
  try {
    // Initialize Hive for Flutter (handles platform-specific setup)
    await Hive.initFlutter();

    // Register all Hive type adapters using auto-generated registrar
    Hive.registerAdapters();

    // Create boxes for different data types
    // Each box is like a table in a database

    // Groups box: stores frequently used groups
    // Format: Map<String, Group> where key is groupId
    if (!Hive.isBoxOpen('groups')) {
      await Hive.openBox<Group>('groups');
    }

    // People box: stores person profiles
    if (!Hive.isBoxOpen('people')) {
      await Hive.openBox<Person>('people');
    }

    // History box: stores past split sessions
    // Format: List of SplitSession objects ordered by date
    if (!Hive.isBoxOpen('history')) {
      await Hive.openBox<SplitSession>('history');
    }

    // Receipts box: stores receipt data for split sessions
    // Format: Map<String, Receipt> where key is receiptId
    if (!Hive.isBoxOpen('receipts')) {
      await Hive.openBox<Receipt>('receipts');
    }

    // Preferences box: stores user preferences
    // Format: Map<String, dynamic> for app-wide settings
    if (!Hive.isBoxOpen('preferences')) {
      await Hive.openBox<dynamic>('preferences');
    }

    // Cache box: temporary OCR results, image paths
    // Format: Map<String, dynamic>
    if (!Hive.isBoxOpen('cache')) {
      await Hive.openBox<dynamic>('cache');
    }

    // Contact matches box: caches device contact to registered user matches
    // Format: Map<String, ContactMatch> where key is personId
    if (!Hive.isBoxOpen('contact_matches')) {
      await Hive.openBox<ContactMatch>('contact_matches');
    }

    // Group invites box: caches received invites
    // Format: Map<String, GroupInvite> where key is inviteId
    if (!Hive.isBoxOpen('group_invites')) {
      await Hive.openBox<GroupInvite>('group_invites');
    }

    debugPrint('Hive initialization successful');
  } catch (e) {
    debugPrint('Error initializing Hive: $e');
    rethrow;
  }
}

class QuickSplitApp extends ConsumerWidget {
  final Future<void> Function(GoRouter)? onInitialize;

  const QuickSplitApp({super.key, this.onInitialize});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider
    final router = ref.watch(goRouterProvider);
    // Watch the theme mode provider
    final themeMode = ref.watch(themeModeProvider);

    // Initialize deep link handler after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onInitialize != null) {
        onInitialize!(router);
      }
    });

    return MaterialApp.router(
      title: 'QuickSplit',
      theme: QuickSplitTheme.light,
      darkTheme: QuickSplitTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
