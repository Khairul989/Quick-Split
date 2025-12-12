import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicksplit/core/constants/app_spacing.dart';
import 'package:quicksplit/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:quicksplit/features/settings/presentation/widgets/permissions_section_tiles.dart';
import 'package:quicksplit/features/settings/presentation/widgets/profile_section_tile.dart';
import 'package:quicksplit/features/settings/presentation/widgets/theme_toggle_tile.dart';

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
          _SectionCard(title: 'Appearance', child: const ThemeToggleTile()),
          SizedBox(height: AppSpacing.lg),

          // Account Actions Card
          _SectionCard(title: 'Account', child: _LogoutTile()),
        ],
      ),
    );
  }
}

/// Reusable section card widget with title and content
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

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
                color: theme.textTheme.labelLarge?.color?.withValues(
                  alpha: 0.8,
                ),
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

/// Logout tile widget
class _LogoutTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return ListTile(
      leading: Icon(Icons.logout, color: theme.colorScheme.error),
      title: Text(
        'Logout',
        style: TextStyle(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        'Sign out of your account',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
        ),
      ),
      trailing: authState.isLoading
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.error,
              ),
            )
          : null,
      onTap: authState.isLoading
          ? null
          : () async {
              // Show confirmation dialog
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) {
                  context.goNamed('welcome');
                }
              }
            },
    );
  }
}
