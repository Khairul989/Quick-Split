import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' as img_picker;
import 'package:quicksplit/core/router/router.dart';
import 'package:quicksplit/features/groups/presentation/providers/group_providers.dart';
import 'package:quicksplit/features/groups/presentation/providers/preselected_group_provider.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';
import 'package:quicksplit/features/ocr/presentation/providers/ocr_providers.dart';

import '../providers/recent_splits_provider.dart';
import '../widgets/financial_summary_card.dart';
import '../widgets/home_group_card.dart';
import '../widgets/recent_split_card.dart';

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
  /// Show bottom sheet with camera and gallery options
  void _showAddReceiptOptions(BuildContext context) {
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
              // Bottom sheet title
              Text(
                'Add Receipt',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Camera option
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF248CFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    color: Color(0xFF248CFF),
                  ),
                ),
                title: const Text('Scan with Camera'),
                subtitle: const Text('Take a photo of your receipt'),
                onTap: () {
                  Navigator.pop(context);
                  context.pushNamed(RouteNames.scan);
                },
              ),
              // Gallery option
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF248CFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF248CFF),
                  ),
                ),
                title: const Text('Import from Gallery'),
                subtitle: const Text('Choose an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Pick image from gallery and process OCR inline
  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      // Pick image from gallery
      final pickedFile = await img_picker.ImagePicker().pickImage(
        source: img_picker.ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Use ref.context which remains valid across async operations
        if (!ref.context.mounted) {
          return;
        }

        // Reset OCR state before processing
        ref.read(ocrStateProvider.notifier).reset();

        // Store context reference and show loading dialog (NON-BLOCKING)
        final dialogContext = ref.context;
        showDialog(
          context: ref.context,
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

        // Process OCR with error handling
        try {
          await ref
              .read(ocrStateProvider.notifier)
              .processImage(pickedFile.path);

          // Close dialog on success
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
        } catch (e) {
          // Close dialog on error
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
          }
          throw Exception('OCR processing failed: $e');
        }

        // Get OCR result
        final ocrState = ref.read(ocrStateProvider);

        // Handle OCR result
        if (ocrState is OcrStateSuccess) {
          if (ref.context.mounted) {
            ref.context.pushReplacementNamed(
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
          if (ref.context.mounted) {
            ScaffoldMessenger.of(
              ref.context,
            ).showSnackBar(SnackBar(content: Text('OCR failed: $message')));
          }
        }
      }
    } catch (e) {
      if (ref.context.mounted) {
        ScaffoldMessenger.of(
          ref.context,
        ).showSnackBar(SnackBar(content: Text('Gallery error: $e')));
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
              // Financial summary card
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20 + MediaQuery.of(context).padding.top,
                    20,
                    20,
                  ),
                  child: const FinancialSummaryCard(),
                ),
              ),

              // Add & Split button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddReceiptOptions(context),
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      label: const Text(
                        'Add & Split',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Your Groups section
              SliverToBoxAdapter(child: _buildGroupsSection(context, ref)),

              // Monthly Summary card
              // SliverToBoxAdapter(
              //   child: Padding(
              //     padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              //     child: MonthlySummaryCard(),
              //   ),
              // ),

              // Recent Splits section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: 12,
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: ref
                    .watch(recentSplitsProvider)
                    .when(
                      data: (splits) {
                        if (splits.isEmpty) {
                          return SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
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
                                            color: theme
                                                .textTheme
                                                .bodySmall
                                                ?.color
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
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final split = splits[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: RecentSplitCard(
                                entry: split,
                                onTap: () {
                                  context.pushNamed(
                                    RouteNames.historyDetail,
                                    pathParameters: {'id': split.session.id},
                                  );
                                },
                              ),
                            );
                          }, childCount: splits.length),
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
              SliverToBoxAdapter(child: const SizedBox(height: 24)),
            ],
          ),
        ],
      ),
    );
  }

  /// Build the "Your Groups" section with horizontal scrollable cards
  Widget _buildGroupsSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final frequentGroups = ref.watch(frequentGroupsProvider);

    // If no groups, show empty state
    if (frequentGroups.isEmpty) {
      return _buildEmptyGroupsState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with "See All" button
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Groups',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              TextButton(
                onPressed: () => context.pushNamed(RouteNames.groupsList),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See All',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF248CFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Color(0xFF248CFF),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Horizontal scrollable group cards
        SizedBox(
          height: 120,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: frequentGroups.length,
            itemBuilder: (context, index) {
              final group = frequentGroups[index];
              return HomeGroupCard(
                group: group,
                onTap: () => _showGroupOptions(context, group),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Build empty state when user has no groups yet
  Widget _buildEmptyGroupsState(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF248CFF).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF248CFF).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Icon with subtle background
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF248CFF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_rounded,
                size: 32,
                color: Color(0xFF248CFF),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'No groups yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              'Create a group to split bills faster with friends',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // CTA Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => context.pushNamed(RouteNames.groupCreate),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF248CFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'Create Your First Group',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show bottom sheet with group options
  void _showGroupOptions(BuildContext context, group) {
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
              // Bottom sheet title
              Text(
                'Group Options',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Use for new split option
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
                  // Show add receipt options
                  _showAddReceiptOptions(context);
                },
              ),
              // Edit current group option
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
              // View all groups option
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF248CFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.list, color: Color(0xFF248CFF)),
                ),
                title: const Text('Manage All Groups'),
                subtitle: const Text('View, edit, or delete groups'),
                onTap: () {
                  Navigator.pop(context);
                  context.pushNamed(RouteNames.groupsList);
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
