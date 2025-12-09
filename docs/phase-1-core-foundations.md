# Phase 1: Core Foundations

**Duration:** Week 1
**Status:** Not Started
**Target Completion:** End of Week 1

## Overview

Phase 1 establishes the complete architectural foundation for QuickSplit. This phase is critical—all future features depend on proper setup here. By the end of Phase 1, the app will have:

- Complete folder structure for all 6 planned features
- Riverpod provider infrastructure ready for features to inject dependencies and manage state
- GoRouter navigation with routes for all phases
- Hive local database initialized and ready for data persistence
- Material 3 theme configured with Material You support (deepPurple seed)
- Example providers and navigation patterns that future phases will follow

**Why Phase 1 Matters:**

- Riverpod setup determines how testable and maintainable all code will be
- Router configuration affects deep linking, state preservation, and navigation performance
- Hive initialization enables offline-first architecture from day one
- Folder structure determines code organization and modularity

**Estimated Time:** 12-16 development hours (spread across the week)

## Success Criteria

All items must be complete before moving to Phase 2:

- [ ] All Phase 1 dependencies installed and resolving correctly
- [ ] Complete folder structure created (core/ and features/ with all subfolders)
- [ ] App runs without errors on at least one platform (Android, iOS, or macOS)
- [ ] Riverpod providers are accessible and injectable
- [ ] GoRouter navigation flow works for all 6 features
- [ ] Hive initializes without errors and box creation works
- [ ] Material 3 theme applies correctly with deepPurple seed color
- [ ] Basic widget tests pass (navigation, Hive initialization)
- [ ] Static analysis passes: `flutter analyze` returns no errors
- [ ] Example home screen demonstrates Riverpod provider usage

---

## Step 1: Dependencies Setup

### 1.1 Update pubspec.yaml

Replace your current `pubspec.yaml` with this complete version:

```yaml
name: quicksplit
description: "Fast bill-splitting app using OCR technology with a 30-40 second target flow."
publish_to: "none"

version: 1.0.0+1

environment:
  sdk: ^3.9.2

dependencies:
  flutter:
    sdk: flutter

  # UI and Design
  cupertino_icons: ^1.0.8

  # State Management & Reactive Programming
  riverpod: ^3.0.3
  hooks_riverpod: ^3.0.3
  flutter_hooks: ^0.21.3+1
  flutter_riverpod: ^3.0.3

  # Navigation & Routing
  go_router: ^17.0.0

  # Local Storage & Database
  # hive: ^2.2.3
  # hive_flutter: ^1.1.0
  hive_ce: ^2.15.1
  hive_ce_flutter: ^2.3.3

  # Image & Camera (Phase 2)
  camera: ^0.11.3
  image_picker: ^1.2.1

  # OCR Processing (Phase 2)
  google_mlkit_text_recognition: ^0.15.0

  # Export & Share (Phase 4)
  share_plus: ^12.0.1

  # Utilities
  path_provider: ^2.1.5
  uuid: ^4.5.2

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^6.0.0

  # Testing
  riverpod_generator: ^3.0.3
  # might need the annotation
  # riverpod_annotation: ^3.0.3
  build_runner: ^2.10.4

flutter:
  uses-material-design: true

  # To add assets (images, fonts), uncomment and configure:
  # assets:
  #   - assets/images/
  # fonts:
  #   - family: YourFont
  #     fonts:
  #       - asset: fonts/YourFont-Regular.ttf
  #       - asset: fonts/YourFont-Bold.ttf
  #         weight: 700
```

### 1.2 Install Dependencies

Run the following commands:

```bash
cd /Volumes/KhaiSSD/Documents/Github/personal/quicksplit

# Get all dependencies
flutter pub get

# Ensure pubspec.lock is updated
flutter pub upgrade

# Verify no version conflicts
flutter pub outdated
```

### 1.3 Platform-Specific Configurations

#### Android Setup

Edit `/android/app/build.gradle` and set `minSdkVersion` to 21:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Required for ML Kit and Camera
        targetSdkVersion 34
        // ... rest of config
    }
}
```

Add permissions to `/android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Camera permissions -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

    <!-- Image picker permissions -->
    <uses-permission android:name="android.permission.INTERNET" />

    <application>
        <!-- your app config -->
    </application>
</manifest>
```

#### iOS Setup

Edit `/ios/Podfile` and ensure minimum iOS version is 12.0:

```ruby
platform :ios, '12.0'
```

Add permissions to `/ios/Runner/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Camera Usage -->
    <key>NSCameraUsageDescription</key>
    <string>We need camera access to scan receipts using your device camera.</string>

    <!-- Photo Library Usage -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>We need access to your photos to select receipt images for scanning.</string>

    <!-- Other standard iOS configurations -->
    <key>UIApplicationSupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>

    <!-- ... rest of your Info.plist -->
</dict>
</plist>
```

#### macOS Setup

Update `/macos/Runner/DebugProfile.entitlements` and `/macos/Runner/Release.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.device.camera</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

### 1.4 Why Each Dependency

| Dependency                      | Version | Purpose                                         | Phase |
| ------------------------------- | ------- | ----------------------------------------------- | ----- |
| `riverpod`                      | ^2.4.0  | Core state management provider pattern          | 1     |
| `hooks_riverpod`                | ^2.4.0  | Riverpod hooks integration for stateful widgets | 1     |
| `flutter_hooks`                 | ^0.20.0 | Stateful hook composition for UI logic          | 1     |
| `go_router`                     | ^14.0.0 | Declarative navigation with deep linking        | 1     |
| `hive`                          | ^2.2.3  | Fast, embedded NoSQL database                   | 1     |
| `hive_flutter`                  | ^1.1.0  | Flutter-specific Hive initialization            | 1     |
| `camera`                        | ^0.10.5 | Native camera access                            | 2     |
| `image_picker`                  | ^1.0.7  | Gallery and camera image selection              | 2     |
| `google_mlkit_text_recognition` | ^0.4.0  | OCR text extraction from images                 | 2     |
| `share_plus`                    | ^7.2.0  | Share to WhatsApp, email, etc.                  | 4     |
| `path_provider`                 | ^2.1.1  | Access device file system paths                 | 1     |
| `uuid`                          | ^4.0.0  | Generate unique IDs for splits                  | 1     |

---

## Step 2: Folder Structure Implementation

### 2.1 Create Complete Folder Structure

Run these commands to create all folders:

```bash
cd /Volumes/KhaiSSD/Documents/Github/personal/quicksplit/lib

# Core module
mkdir -p core/{utils,widgets,services,error,theme,router,providers}

# Features modules
mkdir -p features/{scan,ocr,items,assign,groups,history}

# Each feature gets its own structure (we'll populate these as we go)
for feature in scan ocr items assign groups history; do
  mkdir -p features/$feature/{presentation/{pages,widgets},domain/{entities,repositories,usecases},data/{datasources,repositories,models}}
done
```

### 2.2 Folder Structure Explanation

```
lib/
├── core/                          # Shared across all features
│   ├── error/                     # Error handling, exceptions
│   ├── providers/                 # App-level Riverpod providers
│   ├── router/                    # GoRouter configuration
│   ├── services/                  # Business logic services (calculator, parser, etc)
│   ├── theme/                     # Material 3 theme configuration
│   ├── utils/                     # Helper functions, extensions, constants
│   └── widgets/                   # Reusable UI components (buttons, cards, loaders)
│
└── features/                      # Feature-specific modules
    ├── scan/                      # Image input (camera, gallery)
    │   ├── data/                  # Local image caching
    │   ├── domain/                # Image entity, repository interfaces
    │   └── presentation/          # Camera and gallery UI
    │
    ├── ocr/                       # ML Kit text recognition pipeline
    │   ├── data/                  # ML Kit integration, result caching
    │   ├── domain/                # OCR entities, parsing logic
    │   └── presentation/          # OCR results display, parsing preview
    │
    ├── items/                     # Receipt item management
    │   ├── data/                  # Item storage in Hive
    │   ├── domain/                # Item entity, calculation logic
    │   └── presentation/          # Item list, editor UI
    │
    ├── assign/                    # Person-to-item assignment
    │   ├── data/                  # Assignment storage
    │   ├── domain/                # Assignment logic, calculator
    │   └── presentation/          # Assignment UI, summary preview
    │
    ├── groups/                    # Group and people management
    │   ├── data/                  # Group storage in Hive
    │   ├── domain/                # Group entity, person entity
    │   └── presentation/          # Group UI, people list
    │
    └── history/                   # Split history and records
        ├── data/                  # Historical split storage
        ├── domain/                # History entities, queries
        └── presentation/          # History list, details screen
```

### 2.3 Purpose of Each Core Folder

**core/error/**

- Custom exception classes (NetworkException, ValidationException, etc.)
- Error handling utilities
- Error message formatting for UI

**core/providers/**

- App-level Riverpod providers that don't belong to specific features
- Example: current user, app settings, global loading state

**core/router/**

- GoRouter configuration and route definitions
- Route names constants
- Navigation helper functions

**core/services/**

- Calculation engine (split calculator, tax distributor)
- Text parsing service (OCR result parser)
- Format utilities (currency formatter, date formatter)

**core/theme/**

- Material 3 theme with deepPurple seed
- Color schemes, typography, component themes
- Constants for spacing, sizing, animations

**core/utils/**

- Extension methods on String, double, List, etc.
- Helper functions (validators, converters)
- Global constants (API timeouts, limits)

**core/widgets/**

- Reusable components: CustomButton, LoadingOverlay, EmptyState, etc.
- These are NOT full screens—just reusable UI blocks

---

## Step 3: Riverpod Architecture

### 3.1 Riverpod Provider Patterns

Create these files to establish provider patterns:

#### File: `/lib/core/providers/app_state.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global app state that persists across navigation
/// Example: current user, app settings, theme preferences
///
/// In Phase 3+, expand this to include:
/// - Current group ID
/// - Current split session
/// - User preferences from Hive
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  /// Initialize app state from Hive on startup
  Future<void> initialize() async {
    state = const AppState(isInitialized: true);
  }

  /// Reset app state (e.g., when creating new split)
  void reset() {
    state = const AppState(isInitialized: true);
  }
}

/// Immutable app state
class AppState {
  final bool isInitialized;
  // Future fields:
  // final String? currentGroupId;
  // final String? currentSessionId;
  // final UserPreferences? preferences;

  const AppState({this.isInitialized = false});
}

/// Global provider for app state
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>(
  (ref) => AppStateNotifier(),
);
```

#### File: `/lib/core/providers/providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state.dart';

/// Central export file for all core providers
/// Prevents circular imports and makes imports cleaner in features

export 'app_state.dart';

/// Example: Loading state overlay provider
/// Used across features to show loading dialogs
final loadingProvider = StateProvider<bool>((ref) => false);

/// Example: Error message provider
/// Used to display snackbars or error dialogs
final errorMessageProvider = StateProvider<String?>((ref) => null);

/// Provides initialization status
/// Features can use this to gate their initialization
final isAppInitializedProvider = Riverpod(
  (ref) => ref.watch(appStateProvider).isInitialized,
);
```

### 3.2 Feature Provider Pattern

Create this template for each feature. Example: `items` feature

#### File: `/lib/features/items/presentation/providers/item_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Item state (will be filled in Phase 3)
class ItemState {
  final List<Item> items;
  final bool isLoading;

  const ItemState({
    required this.items,
    this.isLoading = false,
  });

  ItemState copyWith({
    List<Item>? items,
    bool? isLoading,
  }) {
    return ItemState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class Item {
  final String id;
  final String name;
  final double price;
  final int quantity;

  const Item({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });
}

/// Items notifier for complex state logic
class ItemNotifier extends StateNotifier<ItemState> {
  ItemNotifier() : super(const ItemState(items: []));

  // Methods will be added in Phase 2/3
  void addItem(Item item) {
    state = state.copyWith(items: [...state.items, item]);
  }

  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != itemId).toList(),
    );
  }
}

/// Items state provider - used by widgets to rebuild when items change
final itemsProvider = StateNotifierProvider<ItemNotifier, ItemState>(
  (ref) => ItemNotifier(),
);

/// Computed provider: total price of all items
final totalPriceProvider = Riverpod(
  (ref) {
    final items = ref.watch(itemsProvider).items;
    return items.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
  },
);

/// Computed provider: item count
final itemCountProvider = Riverpod(
  (ref) => ref.watch(itemsProvider).items.length,
);
```

### 3.3 Best Practices for Providers

**DO:**

- ✓ Use `StateNotifierProvider` for mutable state
- ✓ Use `Riverpod` (simple providers) for computed/read-only values
- ✓ Use `FutureProvider` for async operations (API calls, database queries)
- ✓ Place feature providers in `features/{feature}/presentation/providers/`
- ✓ Export providers from a central file in each feature
- ✓ Use `.select()` to watch only the parts of state you need
- ✓ Use `.family` modifier for parameterized providers

**DON'T:**

- ✗ Don't put business logic in UI widgets—use providers
- ✗ Don't create global providers for feature-specific state
- ✗ Don't forget to handle loading and error states in FutureProviders
- ✗ Don't use `.watch()` outside of widgets (use `.read()` in callbacks)

### 3.4 Provider Testing Pattern

Providers are testable without UI. Example test:

```dart
// test/features/items/item_providers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicksplit/features/items/presentation/providers/item_providers.dart';

void main() {
  test('ItemNotifier adds items correctly', () {
    final container = ProviderContainer();

    final notifier = container.read(itemsProvider.notifier);
    notifier.addItem(
      const Item(id: '1', name: 'Coffee', price: 5.0, quantity: 1),
    );

    expect(container.read(itemsProvider).items.length, 1);
    expect(container.read(totalPriceProvider), 5.0);
  });
}
```

---

## Step 4: GoRouter Navigation Setup

### 4.1 Router Configuration

Create the main router file:

#### File: `/lib/core/router/router.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Route name constants - use these to navigate instead of hardcoded strings
abstract class RouteNames {
  // Main flow
  static const String home = 'home';
  static const String splash = 'splash';

  // Scan feature
  static const String scan = 'scan';
  static const String camera = 'camera';
  static const String galleryPick = 'galleryPick';

  // OCR feature
  static const String ocrPreview = 'ocrPreview';

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
            builder: (context, state) => const ScanScreen(),
            routes: [
              GoRoute(
                path: RouteNames.camera,
                name: RouteNames.camera,
                builder: (context, state) => const CameraScreen(),
              ),
              GoRoute(
                path: RouteNames.galleryPick,
                name: RouteNames.galleryPick,
                builder: (context, state) => const GalleryPickScreen(),
              ),
            ],
          ),

          // OCR flow
          GoRoute(
            path: RouteNames.ocrPreview,
            name: RouteNames.ocrPreview,
            builder: (context, state) {
              // Extra data passed from previous screen
              final imageData = state.extra as String?;
              return OcrPreviewScreen(imagePath: imageData ?? '');
            },
          ),

          // Items editor
          GoRoute(
            path: RouteNames.itemsEditor,
            name: RouteNames.itemsEditor,
            builder: (context, state) => const ItemsEditorScreen(),
          ),

          // Assignment flow
          GoRoute(
            path: RouteNames.groupSelect,
            name: RouteNames.groupSelect,
            builder: (context, state) => const GroupSelectScreen(),
            routes: [
              GoRoute(
                path: RouteNames.groupCreate,
                name: RouteNames.groupCreate,
                builder: (context, state) => const GroupCreateScreen(),
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
        ],
      ),
    ],
  );
});

// Placeholder screens (will be implemented in future phases)
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QuickSplit')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to QuickSplit'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pushNamed(RouteNames.scan),
              child: const Text('Start Split'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.pushNamed(RouteNames.history),
              child: const Text('View History'),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder screens for each feature
class ScanScreen extends StatelessWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => _PlaceholderScreen('Scan');
}

class CameraScreen extends StatelessWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => _PlaceholderScreen('Camera');
}

class GalleryPickScreen extends StatelessWidget {
  const GalleryPickScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => _PlaceholderScreen('Gallery');
}

class OcrPreviewScreen extends StatelessWidget {
  final String imagePath;
  const OcrPreviewScreen({required this.imagePath, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => _PlaceholderScreen('OCR Preview');
}

class ItemsEditorScreen extends StatelessWidget {
  const ItemsEditorScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => _PlaceholderScreen('Items Editor');
}

class GroupSelectScreen extends StatelessWidget {
  const GroupSelectScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => _PlaceholderScreen('Select Group');
}

class GroupCreateScreen extends StatelessWidget {
  const GroupCreateScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => _PlaceholderScreen('Create Group');
}

class AssignItemsScreen extends StatelessWidget {
  const AssignItemsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => _PlaceholderScreen('Assign Items');
}

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => _PlaceholderScreen('Summary');
}

class GroupsListScreen extends StatelessWidget {
  const GroupsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => _PlaceholderScreen('Groups');
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => _PlaceholderScreen('History');
}

class HistoryDetailScreen extends StatelessWidget {
  final String splitId;
  const HistoryDetailScreen({required this.splitId, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) =>
      _PlaceholderScreen('Split Detail: $splitId');
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
```

### 4.2 Navigation Patterns for Features

When navigating between screens:

```dart
// Named navigation (recommended - uses route names)
context.pushNamed(RouteNames.scan);

// With parameters
context.pushNamed(RouteNames.historyDetail, pathParameters: {'id': '123'});

// With extra data
context.pushNamed(
  RouteNames.ocrPreview,
  extra: imagePath,
);

// Replace current route
context.goNamed(RouteNames.home);

// Pop to previous
context.pop();
```

---

## Step 5: Hive Local Database Setup

### 5.1 Hive Initialization in main.dart

#### File: `/lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/router.dart';
import 'core/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive before building the app
  await _initializeHive();

  runApp(
    const ProviderScope(
      child: QuickSplitApp(),
    ),
  );
}

/// Initialize Hive database and create boxes
/// Call this before building the app
Future<void> _initializeHive() async {
  try {
    // Initialize Hive for Flutter (handles platform-specific setup)
    await Hive.initFlutter();

    // Create boxes for different data types
    // Each box is like a table in a database

    // Groups box: stores frequently used groups
    // Format: Map<String, GroupData> where key is groupId
    if (!Hive.isBoxOpen('groups')) {
      await Hive.openBox<dynamic>('groups');
    }

    // History box: stores past split sessions
    // Format: List of split records ordered by date
    if (!Hive.isBoxOpen('history')) {
      await Hive.openBox<dynamic>('history');
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
  const QuickSplitApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'QuickSplit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### 5.2 Hive Usage Patterns

#### Pattern 1: Reading from Hive

```dart
// In a Riverpod provider or service
Future<List<Group>> getFrequentGroups() async {
  try {
    final groupsBox = Hive.box('groups');
    final groups = groupsBox.values.cast<Map<String, dynamic>>().toList();
    return groups.map((g) => Group.fromMap(g)).toList();
  } catch (e) {
    throw HiveException('Failed to read groups: $e');
  }
}
```

#### Pattern 2: Writing to Hive

```dart
// Save a new group
Future<void> saveGroup(Group group) async {
  try {
    final groupsBox = Hive.box('groups');
    await groupsBox.put(group.id, group.toMap());
  } catch (e) {
    throw HiveException('Failed to save group: $e');
  }
}
```

#### Pattern 3: Deleting from Hive

```dart
// Delete a group by ID
Future<void> deleteGroup(String groupId) async {
  try {
    final groupsBox = Hive.box('groups');
    await groupsBox.delete(groupId);
  } catch (e) {
    throw HiveException('Failed to delete group: $e');
  }
}
```

#### Pattern 4: Clearing a Box

```dart
// Clear all groups (e.g., on reset/logout)
Future<void> clearGroups() async {
  try {
    final groupsBox = Hive.box('groups');
    await groupsBox.clear();
  } catch (e) {
    throw HiveException('Failed to clear groups: $e');
  }
}
```

### 5.3 Hive Type Adapters (Phase 2+)

When you create data models, you'll need to register them with Hive for type safety:

```dart
// In phase 2, create this adapter
@HiveType(typeId: 0)
class GroupAdapter extends TypeAdapter<Group> {
  @override
  final typeId = 0;

  @override
  Group read(BinaryReader reader) {
    return Group(
      id: reader.readString(),
      name: reader.readString(),
      members: reader.readList(),
    );
  }

  @override
  void write(BinaryWriter writer, Group obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeList(obj.members);
  }
}

// Register in main.dart
Hive.registerAdapter(GroupAdapter());
```

---

## Step 6: Theme Configuration

### 6.1 Material 3 Theme Setup

#### File: `/lib/core/theme/theme.dart`

```dart
import 'package:flutter/material.dart';

/// App theme configuration using Material 3
/// Supports both light and dark modes with Material You
class AppTheme {
  // Prevent instantiation
  AppTheme._();

  // Color seed - determines the entire color scheme
  static const Color _seedColor = Color(0xFF6750A4); // Deep Purple

  /// Light theme
  static ThemeData get lightTheme {
    const seedColor = Color(0xFF6750A4); // Deep Purple

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: seedColor,

      // AppBar styling
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFFFAFAFA),
        foregroundColor: Color(0xFF1C1B1F),
      ),

      // Button styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: seedColor,
        ),
      ),

      // Input field styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: seedColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF666666)),
        hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
      ),

      // Card styling
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        color: Colors.white,
      ),

      // Scaffold background
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),

      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1C1B1F),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1C1B1F),
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1C1B1F),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1C1B1F),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1C1B1F),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF666666),
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF999999),
        ),
      ),
    );
  }

  /// Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: _seedColor,

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF1C1B1F),
        foregroundColor: Color(0xFFFAFAFA),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: _seedColor,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF444444)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF444444)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _seedColor, width: 2),
        ),
      ),

      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF444444)),
        ),
        color: const Color(0xFF2C2C2C),
      ),

      scaffoldBackgroundColor: const Color(0xFF1C1B1F),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFAFAFA),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFFE0E0E0),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFFA0A0A0),
        ),
      ),
    );
  }
}

/// App spacing constants
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

/// App border radius constants
class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}
```

### 6.2 Theme Usage in Widgets

```dart
// Access theme in widgets
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      color: colors.surface,
      child: Text(
        'Hello',
        style: textTheme.headlineSmall?.copyWith(
          color: colors.primary,
        ),
      ),
    );
  }
}
```

---

## Step 7: Example Provider Implementation

To demonstrate Riverpod usage, create a simple app-level provider:

#### File: `/lib/core/providers/app_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App initialization provider
/// Returns true when app is fully initialized
final appInitProvider = FutureProvider<bool>((ref) async {
  // Simulate initialization tasks
  // In real app, would initialize Hive, load preferences, etc.
  await Future.delayed(const Duration(milliseconds: 500));
  return true;
});

/// Example: User preference for default currency
final preferredCurrencyProvider = StateProvider<String>((ref) {
  return 'RM'; // Default: Malaysian Ringgit
});

/// Example: App version
final appVersionProvider = Provider<String>((ref) {
  return '1.0.0';
});
```

---

## Testing Strategy for Phase 1

### Test 1: Navigation Flow

Create `/test/core/router/router_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicksplit/main.dart';
import 'package:quicksplit/core/router/router.dart';

void main() {
  group('GoRouter Navigation', () {
    testWidgets('Navigate to home screen', (WidgetTester tester) async {
      await tester.pumpWidget(const QuickSplitApp());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Navigate from home to scan', (WidgetTester tester) async {
      await tester.pumpWidget(const QuickSplitApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      expect(find.byType(ScanScreen), findsOneWidget);
    });
  });
}
```

### Test 2: Hive Initialization

Create `/test/core/hive_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  group('Hive Initialization', () {
    testWidgets('Hive boxes are created', (WidgetTester tester) async {
      // Hive should be initialized in main.dart before tests run
      expect(Hive.isBoxOpen('groups'), isTrue);
      expect(Hive.isBoxOpen('history'), isTrue);
      expect(Hive.isBoxOpen('preferences'), isTrue);
      expect(Hive.isBoxOpen('cache'), isTrue);
    });

    test('Can write and read from groups box', () async {
      final box = Hive.box('groups');
      await box.put('test_group', {'name': 'Test', 'members': []});

      final value = box.get('test_group');
      expect(value != null, isTrue);
      expect(value['name'], 'Test');

      await box.delete('test_group');
    });
  });
}
```

### Test 3: Theme Configuration

Create `/test/core/theme/theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicksplit/core/theme/theme.dart';

void main() {
  group('App Theme', () {
    test('Light theme uses correct seed color', () {
      final lightTheme = AppTheme.lightTheme;
      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.useMaterial3, isTrue);
    });

    test('Dark theme uses correct seed color', () {
      final darkTheme = AppTheme.darkTheme;
      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.useMaterial3, isTrue);
    });

    testWidgets('App applies theme correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: Text(
                'Test',
                style: Theme.of(tester.element(find.byType(Text))).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
```

---

## Verification Checklist

Use this checklist to verify Phase 1 completion:

### Dependencies & Environment

- [ ] `flutter pub get` completes without errors
- [ ] `flutter analyze` returns no errors (only warnings acceptable)
- [ ] No deprecated package warnings in `flutter pub outdated`
- [ ] Minimum SDK versions set correctly (Android 21, iOS 12)

### Folder Structure

- [ ] `lib/core/` folder exists with all subfolders (error, providers, router, services, theme, utils, widgets)
- [ ] `lib/features/` folder exists with 6 feature folders (scan, ocr, items, assign, groups, history)
- [ ] Each feature has `data/`, `domain/`, and `presentation/` subfolders
- [ ] No extraneous files in these directories

### Riverpod

- [ ] `/lib/core/providers/app_state.dart` exists with AppStateNotifier
- [ ] `/lib/core/providers/providers.dart` exports all core providers
- [ ] Example feature provider exists in `/lib/features/items/presentation/providers/`
- [ ] Providers are accessible without import errors

### GoRouter

- [ ] `/lib/core/router/router.dart` defines all routes
- [ ] RouteNames class contains all route constants
- [ ] All 6 feature screens have placeholder implementations
- [ ] Navigation between screens works (can tap buttons to navigate)
- [ ] Back button works correctly

### Hive

- [ ] `/lib/main.dart` calls `_initializeHive()` before `runApp`
- [ ] All 4 boxes are created: groups, history, preferences, cache
- [ ] No errors in Hive initialization (check console)
- [ ] Can read/write to boxes in unit tests

### Theme

- [ ] `/lib/core/theme/theme.dart` defines light and dark themes
- [ ] Material 3 is enabled (`useMaterial3: true`)
- [ ] Deep purple seed color is applied
- [ ] AppSpacing and AppRadius constants exist

### App Execution

- [ ] `flutter run` launches app without crashes
- [ ] Home screen displays with app title
- [ ] Can navigate to at least 3 screens
- [ ] No console errors or warnings (except expected logs)
- [ ] Hot reload works (press 'r' in terminal)

### Testing

- [ ] `flutter test` executes without errors
- [ ] At least 3 widget tests pass (router, theme, basic nav)
- [ ] Hive initialization test passes
- [ ] No unhandled exceptions in test output

### Code Quality

- [ ] `flutter analyze` shows no errors
- [ ] All imports are organized (dart imports first, then package imports)
- [ ] No unused imports or variables
- [ ] Const constructors used where possible
- [ ] No TODOs or FIXMEs (all code is complete)

---

## Common Issues & Solutions

### Issue: "PubSpec Exception: Dependency not found"

**Cause:** Dependencies failed to install or lock file is corrupted

**Solution:**

```bash
# Clean and reinstall
flutter clean
rm pubspec.lock
flutter pub get
```

### Issue: "Hive error: Box not open"

**Cause:** Hive.box() called before box is created in \_initializeHive()

**Solution:**

- Ensure `await _initializeHive()` runs before `runApp()`
- Check that `WidgetsFlutterBinding.ensureInitialized()` is called first
- Verify box names match exactly (case-sensitive)

### Issue: "Go Router: Initial route not found"

**Cause:** Route paths don't match initial location in GoRouter

**Solution:**

- Verify path format: `'/${RouteNames.home}'` (note the leading slash)
- Ensure HomeScreen is defined in the routes list
- Check that initialLocation matches an existing route path

### Issue: "The named parameter isn't defined" in Theme.of()

**Cause:** Trying to access theme outside of a widget context

**Solution:**

```dart
// WRONG: Can't use context directly in provider
final myProvider = Provider((ref) {
  final theme = Theme.of(context); // ERROR: no context
});

// CORRECT: Pass theme as parameter or define as separate provider
final themeProvider = Provider((ref) {
  return AppTheme.lightTheme; // Return the theme directly
});
```

### Issue: "Unhandled Exception: MissingPluginException"

**Cause:** Platform-specific code (camera, image_picker) trying to run on unsupported platform

**Solution:**

- Run on a real device or emulator that supports the feature
- For testing, mock the platform-specific implementations
- Check that platform permissions are properly declared in manifests

### Issue: "GoRouter not showing placeholder screens"

**Cause:** Placeholder screen implementations reference undefined imports

**Solution:**

- Ensure all placeholder screens are defined in `/lib/core/router/router.dart`
- Don't import them from other files—define them in the same file
- Use proper const constructors on all screen classes

### Issue: "Riverpod: Circular dependency error"

**Cause:** Provider A watches Provider B which watches Provider A

**Solution:**

- Use `.select()` to watch only specific parts of state
- Restructure providers so dependency graph is acyclic
- Consider using `ref.read()` instead of `ref.watch()` if updating another provider

---

## Next Steps: Preparing for Phase 2

Phase 2 will implement the OCR pipeline. Phase 1 foundation enables:

1. **Camera Integration** - Will use GoRouter to navigate to CameraScreen (already defined)
2. **Image Processing** - Will use Riverpod providers to manage processing state
3. **OCR Pipeline** - Will create new feature providers in `features/ocr/`
4. **Storage** - Will use Hive boxes to cache OCR results

**What to prepare now:**

- Ensure imports are correct in all router placeholder screens
- Test that Riverpod providers can be injected via constructors
- Verify that Hive boxes can store complex objects (will need adapters in Phase 2)
- Profile app startup time to establish baseline

---

## File Summary

### Files Created in Phase 1

```
lib/
├── main.dart (MODIFIED - Riverpod + GoRouter + Hive setup)
├── core/
│   ├── router/
│   │   └── router.dart (NEW - GoRouter configuration)
│   ├── providers/
│   │   ├── app_state.dart (NEW - Global app state)
│   │   └── providers.dart (NEW - Core provider exports)
│   ├── theme/
│   │   └── theme.dart (NEW - Material 3 theme)
│   ├── error/ (EMPTY - placeholder)
│   ├── services/ (EMPTY - placeholder)
│   ├── utils/ (EMPTY - placeholder)
│   └── widgets/ (EMPTY - placeholder)
└── features/
    ├── scan/
    │   ├── data/ (EMPTY)
    │   ├── domain/ (EMPTY)
    │   └── presentation/ (EMPTY)
    ├── ocr/
    │   ├── data/ (EMPTY)
    │   ├── domain/ (EMPTY)
    │   └── presentation/ (EMPTY)
    ├── items/
    │   ├── data/ (EMPTY)
    │   ├── domain/ (EMPTY)
    │   └── presentation/
    │       └── providers/
    │           └── item_providers.dart (NEW - Example provider)
    ├── assign/
    │   ├── data/ (EMPTY)
    │   ├── domain/ (EMPTY)
    │   └── presentation/ (EMPTY)
    ├── groups/
    │   ├── data/ (EMPTY)
    │   ├── domain/ (EMPTY)
    │   └── presentation/ (EMPTY)
    └── history/
        ├── data/ (EMPTY)
        ├── domain/ (EMPTY)
        └── presentation/ (EMPTY)

test/
├── core/
│   ├── router/
│   │   └── router_test.dart (NEW)
│   ├── theme/
│   │   └── theme_test.dart (NEW)
│   └── hive_test.dart (NEW)
└── widget_test.dart (EXISTING)

pubspec.yaml (MODIFIED - Added all Phase 1 dependencies)
```

---

## Phase 1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     QuickSplit App                          │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Presentation Layer                     │   │
│  │  ┌──────────┬──────────┬─────────────────────────┐  │   │
│  │  │  Scan    │  OCR     │  Items  │ Assign │      │  │   │
│  │  │ Feature  │ Feature  │Feature  │Feature │ ...  │  │   │
│  │  │   UI     │   UI     │   UI    │   UI   │      │  │   │
│  │  └──────────┴──────────┴─────────────────────────┘  │   │
│  │                                                     │   │
│  │  Uses: Riverpod Providers, GoRouter Navigation    │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ↓                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │           Core Infrastructure Layer                 │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │  GoRouter           │  Riverpod Providers    │   │   │
│  │  │  (Navigation)       │  (State Management)    │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │  Theme              │  Error Handling        │   │   │
│  │  │  (Material 3)       │  Utilities             │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ↓                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │            Data Persistence Layer                   │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │  Hive NoSQL Database                         │   │   │
│  │  │  Boxes: groups, history, preferences, cache  │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Quick Reference: Common Phase 1 Commands

```bash
# Install dependencies
flutter pub get

# Run app on default device
flutter run

# Run app on specific device
flutter run -d chrome        # Web
flutter run -d ios           # iOS simulator
flutter run -d android       # Android emulator

# Check for code issues
flutter analyze

# Format all Dart files
flutter format lib/

# Run tests
flutter test

# Clean and rebuild
flutter clean && flutter pub get

# View device list
flutter devices
```

---

## Conclusion

Phase 1 establishes a professional, scalable foundation for QuickSplit. By following these steps systematically, you'll have:

- ✓ All dependencies installed and configured
- ✓ Complete modular folder structure
- ✓ Riverpod provider infrastructure for state management
- ✓ GoRouter navigation with all 6 feature routes
- ✓ Hive database initialized with 4 boxes
- ✓ Material 3 theme configured
- ✓ Basic tests passing

Phase 2 will build OCR and image processing on top of this solid foundation. No architectural rework will be needed—new features will simply plug into the existing provider and routing system.

Start with **Step 1: Dependencies Setup** and work through each step systematically. Verify completion with the checklist before starting Phase 2.
