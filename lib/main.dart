import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'core/providers/theme_provider.dart';
import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'features/assign/domain/models/split_session.dart';
import 'features/groups/domain/models/group.dart';
import 'features/groups/domain/models/person.dart';
import 'features/ocr/domain/models/receipt.dart';
import 'hive_registrar.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive before building the app
  await _initializeHive();

  runApp(const ProviderScope(child: QuickSplitApp()));
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

    debugPrint('Hive initialization successful');
  } catch (e) {
    debugPrint('Error initializing Hive: $e');
    rethrow;
  }
}

class QuickSplitApp extends ConsumerWidget {
  const QuickSplitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider
    final router = ref.watch(goRouterProvider);
    // Watch the theme mode provider
    final themeMode = ref.watch(themeModeProvider);

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
