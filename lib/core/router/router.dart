import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:quicksplit/features/groups/presentation/screens/group_select_screen.dart';
import 'package:quicksplit/features/groups/presentation/screens/group_create_screen.dart';
import 'package:quicksplit/features/assign/presentation/screens/assign_items_screen.dart';
import 'package:quicksplit/features/assign/presentation/screens/summary_screen.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';
import 'package:quicksplit/features/scan/presentation/screens/camera_screen.dart';
import 'package:quicksplit/features/ocr/presentation/screens/ocr_processing_screen.dart';
import 'package:quicksplit/features/ocr/presentation/screens/item_editor_screen.dart';

/// Route name constants - use these to navigate instead of hardcoded strings
abstract class RouteNames {
  // Main flow
  static const String home = 'home';
  static const String splash = 'splash';

  // Scan feature
  static const String scan = 'scan';
  static const String camera = 'camera';

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
            ],
          ),

          // OCR flow
          GoRoute(
            path: RouteNames.ocrPreview,
            name: RouteNames.ocrPreview,
            builder: (context, state) {
              // Extra data passed from previous screen
              final imageData = state.extra as String?;
              return OcrProcessingScreen(imagePath: imageData ?? '');
            },
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
        ],
      ),
    ],
  );
});

// Home screen with modern minimalist design
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // App Icon/Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'QuickSplit',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Split bills in seconds with smart OCR',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 16,
                ),
              ),

              const Spacer(),

              // Main Action Button - Start Split
              ElevatedButton(
                onPressed: () => context.pushNamed(RouteNames.scan),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Start Split',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Secondary Action Button - View History
              OutlinedButton(
                onPressed: () => context.pushNamed(RouteNames.history),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: colorScheme.primary, width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 24,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'View History',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Feature Highlights
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FeatureChip(
                    icon: Icons.camera_alt_outlined,
                    label: 'OCR Scan',
                    colorScheme: colorScheme,
                  ),
                  _FeatureChip(
                    icon: Icons.people_outline_rounded,
                    label: 'Group Split',
                    colorScheme: colorScheme,
                  ),
                  _FeatureChip(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    colorScheme: colorScheme,
                  ),
                ],
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for feature chips
class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

// Modern scan screen with camera/gallery options
class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final picker = img_picker.ImagePicker();
      final pickedFile = await picker.pickImage(
        source: img_picker.ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null && context.mounted) {
        context.pushNamed(
          RouteNames.ocrPreview,
          extra: pickedFile.path,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Hero section with icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'How to scan?',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Choose how you want to capture your receipt',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Camera Capture Card
              _ScanActionCard(
                icon: Icons.camera_alt_rounded,
                title: 'Camera Capture',
                description: 'Take a photo of your receipt',
                isPrimary: true,
                onPressed: () => context.pushNamed(RouteNames.camera),
                colorScheme: colorScheme,
              ),

              const SizedBox(height: 16),

              // Gallery Pick Card
              _ScanActionCard(
                icon: Icons.image_rounded,
                title: 'Pick from Gallery',
                description: 'Select from your phone',
                isPrimary: false,
                onPressed: () => _pickFromGallery(context),
                colorScheme: colorScheme,
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// Action card widget for scan options
class _ScanActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isPrimary;
  final VoidCallback onPressed;
  final ColorScheme colorScheme;

  const _ScanActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isPrimary,
    required this.onPressed,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isPrimary
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0.08),
            border: isPrimary
                ? null
                : Border.all(color: colorScheme.primary, width: 2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.2)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isPrimary ? Colors.white : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isPrimary ? Colors.white : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.8)
                            : Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_rounded,
                color: isPrimary ? Colors.white : colorScheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class GroupsListScreen extends StatelessWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context) => _PlaceholderScreen('Groups');
}

// Modern history screen with empty state
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Empty state icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    size: 56,
                    color: colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Empty state title
              Text(
                'No splits yet',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Empty state subtitle
              Text(
                'Start your first split to see your history here',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // CTA Button
              ElevatedButton(
                onPressed: () => context.pushNamed(RouteNames.scan),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_rounded, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Start Your First Split',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryDetailScreen extends StatelessWidget {
  final String splitId;
  const HistoryDetailScreen({required this.splitId, super.key});

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
