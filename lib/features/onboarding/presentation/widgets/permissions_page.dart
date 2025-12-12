import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/permissions_provider.dart';
import '../../utils/permission_helper.dart';

class PermissionsPage extends ConsumerWidget {
  const PermissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final permissionsState = ref.watch(permissionsProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            'Grant Permissions',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We need a few permissions to provide the best experience',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Camera permission card
          _PermissionCard(
            permission: AppPermission.camera,
            status: permissionsState.cameraStatus,
            onRequest: () => ref.read(permissionsProvider.notifier).requestCameraPermission(),
            onOpenSettings: () => ref.read(permissionsProvider.notifier).openSettings(),
          ),
          const SizedBox(height: 16),

          // Contacts permission card
          _PermissionCard(
            permission: AppPermission.contacts,
            status: permissionsState.contactsStatus,
            onRequest: () => ref.read(permissionsProvider.notifier).requestContactsPermission(),
            onOpenSettings: () => ref.read(permissionsProvider.notifier).openSettings(),
          ),
          const SizedBox(height: 24),

          // Info text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can change these permissions later in app settings',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final AppPermission permission;
  final PermissionStatus status;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  const _PermissionCard({
    required this.permission,
    required this.status,
    required this.onRequest,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGranted = status.isGranted;
    final isPermanentlyDenied = status.isPermanentlyDenied;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGranted
            ? Colors.green.shade50
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? Colors.green.shade200
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isGranted
                  ? Colors.green.shade100
                  : const Color(0xFF248CFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              PermissionHelper.getPermissionIcon(permission),
              color: isGranted
                  ? Colors.green.shade700
                  : const Color(0xFF248CFF),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Title and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      PermissionHelper.getPermissionTitle(permission),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isGranted) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade700,
                        size: 20,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  PermissionHelper.getPermissionRationale(permission),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Action button
          if (!isGranted)
            isPermanentlyDenied
                ? TextButton(
                    onPressed: onOpenSettings,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange.shade100,
                      foregroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Settings'),
                  )
                : ElevatedButton(
                    onPressed: onRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF248CFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Allow'),
                  ),
        ],
      ),
    );
  }
}
