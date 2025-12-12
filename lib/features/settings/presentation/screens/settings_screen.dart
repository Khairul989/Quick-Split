import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicksplit/core/constants/app_spacing.dart';
import 'package:quicksplit/features/settings/presentation/widgets/theme_toggle_tile.dart';
import 'package:quicksplit/features/settings/presentation/widgets/profile_section_tile.dart';
import 'package:quicksplit/features/settings/presentation/widgets/permissions_section_tiles.dart';

/// Settings screen with user profile, permissions, appearance and other preferences
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          // User Profile Card
          _SectionCard(
            title: 'User Profile',
            child: const ProfileSectionTile(),
          ),
          SizedBox(height: AppSpacing.lg),

          // Permissions Card
          _SectionCard(
            title: 'Permissions',
            child: Column(
              children: [
                const CameraPermissionTile(),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: _PartialDivider(),
                ),
                const ContactsPermissionTile(),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // Appearance Card
          _SectionCard(
            title: 'Appearance',
            child: const ThemeToggleTile(),
          ),
        ],
      ),
    );
  }
}

/// Reusable section card widget with title and content
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor, width: 1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.textTheme.labelLarge?.color?.withValues(alpha: 0.8),
              ),
            ),
          ),
          // Section content
          child,
          SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }
}

/// Partial divider widget (60% width) for separating items within a card
class _PartialDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconWidth = 44.0; // Icon width
    final spacing = AppSpacing.md; // Spacing after icon

    return Row(
      children: [
        SizedBox(width: iconWidth + spacing + AppSpacing.md),
        Expanded(
          flex: 60,
          child: Divider(
            color: theme.dividerColor.withValues(alpha: 0.6),
            height: 1,
            thickness: 1,
          ),
        ),
        Expanded(flex: 40, child: SizedBox()),
      ],
    );
  }
}
