import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:quicksplit/core/router/router.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';
import 'package:quicksplit/features/ocr/presentation/providers/ocr_providers.dart';
import '../providers/recent_splits_provider.dart';
import '../widgets/recent_split_card.dart';
import '../widgets/monthly_summary_card.dart';

/// Home screen with absolute-positioned header and gradient hero section
///
/// Features:
/// - Absolute-positioned header with QuickSplit title and settings button
/// - 3-color gradient hero section with rounded bottom corners only
/// - Receipt icon (80x80) in rounded-xl container
/// - Action buttons below gradient on white background
/// - Monthly Summary card showing spending statistics
/// - Recent splits list with Material Icons
/// - Full navigation integration
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Pick image from gallery and process OCR inline
  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final picker = img_picker.ImagePicker();
      final pickedFile = await picker.pickImage(
        source: img_picker.ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null && context.mounted) {
        // Reset OCR state before processing
        ref.read(ocrStateProvider.notifier).reset();

        // Show loading dialog
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing receipt...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Process OCR
        await ref.read(ocrStateProvider.notifier).processImage(pickedFile.path);

        // Get result
        final ocrState = ref.read(ocrStateProvider);

        // Close loading dialog
        if (context.mounted) Navigator.of(context).pop();

        if (ocrState is OcrStateSuccess) {
          // Navigate to item editor with parsed items
          if (context.mounted) {
            context.pushNamed(
              RouteNames.itemsEditor,
              extra: ocrState.parsedReceipt.items
                  .map(
                    (parsedItem) => ReceiptItem(
                      name: parsedItem.name,
                      quantity: parsedItem.quantity,
                      price: parsedItem.price,
                    ),
                  )
                  .toList(),
            );
          }
        } else if (ocrState case OcrStateError(:final message)) {
          // Show error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('OCR failed: $message'),
              ),
            );
          }
        }
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            slivers: [
              // 3-color gradient hero section with rounded-b-xl
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: const [
                        Color(0xFF3FC3FF),  // Light blue
                        Color(0xFF248CFF),  // Primary
                        Color(0xFF0063D6),  // Dark blue
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    top: 96,  // Account for absolute header
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  child: Column(
                    children: [
                      // Receipt icon (80x80) in rounded-xl container
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Tagline (32px white text)
                      Text(
                        'Split bills in seconds.',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // Buttons section (on white background, OUTSIDE gradient)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    spacing: 12,
                    children: [
                      // Scan Receipt - BLUE background, WHITE text
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => context.pushNamed(RouteNames.scan),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF248CFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Scan Receipt'),
                        ),
                      ),
                      // Import From Gallery - WHITE background, DARK text, with border
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _pickFromGallery(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1F2937),
                            side: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Import From Gallery'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Monthly Summary card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: MonthlySummaryCard(),
                ),
              ),

              // Recent Splits section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 24,
                    bottom: 16,
                  ),
                  child: Text(
                    'Recent Splits',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),

              // Recent splits list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: ref.watch(recentSplitsProvider).when(
                      data: (splits) {
                        if (splits.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.history_rounded,
                                      size: 48,
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No recent splits yet',
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                        color: theme.textTheme.bodySmall?.color
                                            ?.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final split = splits[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: RecentSplitCard(
                                  entry: split,
                                  onTap: () {
                                    context.pushNamed(
                                      RouteNames.historyDetail,
                                      pathParameters: {
                                        'id': split.session.id,
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                            childCount: splits.length,
                          ),
                        );
                      },
                      loading: () => SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      error: (error, stack) => SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Text(
                              'Error loading splits',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ),
                      ),
                    ),
              ),

              // Bottom padding
              SliverToBoxAdapter(
                child: const SizedBox(height: 32),
              ),
            ],
          ),

          // Absolute positioned header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'QuickSplit',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF1F2937),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.settings,
                          size: 24,
                          color: Color(0xFF1F2937),
                        ),
                        onPressed: () => context.pushNamed(RouteNames.settings),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
