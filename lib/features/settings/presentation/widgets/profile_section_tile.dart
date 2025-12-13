import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicksplit/core/constants/app_spacing.dart';
import '../../../onboarding/presentation/providers/user_profile_provider.dart';

class ProfileSectionTile extends ConsumerWidget {
  const ProfileSectionTile({super.key});

  void _navigateToEditProfile(BuildContext context) {
    context.pushNamed('editProfile');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider);

    return GestureDetector(
      onTap: () => _navigateToEditProfile(context),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  profile?.emoji ?? '😊',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.name ?? 'Set up your profile',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    profile?.email ??
                        'Tap to ${profile == null ? 'create' : 'edit'} your profile',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurface),
          ],
        ),
      ),
    );
  }
}
