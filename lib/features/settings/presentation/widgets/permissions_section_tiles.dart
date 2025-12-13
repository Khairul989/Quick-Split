import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quicksplit/core/constants/app_spacing.dart';
import '../../../onboarding/presentation/providers/permissions_provider.dart';

class CameraPermissionTile extends ConsumerWidget {
  const CameraPermissionTile({super.key});

  String _getStatusText(PermissionStatus status) {
    if (status.isGranted) return 'Granted';
    if (status.isPermanentlyDenied) return 'Denied - Tap to open settings';
    if (status.isDenied) return 'Not granted - Tap to request';
    return 'Unknown';
  }

  void _showPermissionInfo(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsState = ref.watch(permissionsProvider);
    final status = permissionsState.cameraStatus;

    return _PermissionTile(
      icon: Icons.camera_alt,
      title: 'Camera',
      subtitle: _getStatusText(status),
      status: status,
      onTap: () async {
        if (status.isGranted) {
          _showPermissionInfo(
            context,
            'Camera',
            'Camera permission is already granted',
          );
        } else if (status.isPermanentlyDenied) {
          await ref.read(permissionsProvider.notifier).openSettings();
        } else {
          await ref
              .read(permissionsProvider.notifier)
              .requestCameraPermission();
        }
      },
    );
  }
}

class ContactsPermissionTile extends ConsumerWidget {
  const ContactsPermissionTile({super.key});

  String _getStatusText(PermissionStatus status) {
    if (status.isGranted) return 'Granted';
    if (status.isPermanentlyDenied) return 'Denied - Tap to open settings';
    if (status.isDenied) return 'Not granted - Tap to request';
    return 'Unknown';
  }

  void _showPermissionInfo(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsState = ref.watch(permissionsProvider);
    final status = permissionsState.contactsStatus;

    return _PermissionTile(
      icon: Icons.contacts,
      title: 'Contacts',
      subtitle: _getStatusText(status),
      status: status,
      onTap: () async {
        if (status.isGranted) {
          _showPermissionInfo(
            context,
            'Contacts',
            'Contacts permission is already granted',
          );
        } else if (status.isPermanentlyDenied) {
          await ref.read(permissionsProvider.notifier).openSettings();
        } else {
          await ref
              .read(permissionsProvider.notifier)
              .requestContactsPermission();
        }
      },
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final PermissionStatus status;
  final VoidCallback onTap;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGranted = status.isGranted;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isGranted
                    ? theme.colorScheme.secondary.withValues(alpha: 0.12)
                    : theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: isGranted
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
                size: 20,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isGranted
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            if (isGranted)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.secondary,
                size: 20,
              )
            else
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}
