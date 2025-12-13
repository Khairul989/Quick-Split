import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../domain/exceptions/invite_exceptions.dart';
import '../../domain/models/group_invite.dart';
import '../providers/invite_providers.dart';
import '../../../../features/auth/presentation/providers/auth_state_provider.dart';

final _logger = Logger();

/// Screen for accepting a group invite via code or deep link
/// Displays invite details and allows user to accept or decline
class AcceptInviteScreen extends ConsumerWidget {
  final String inviteCode;

  const AcceptInviteScreen({super.key, required this.inviteCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accept Invite'),
        automaticallyImplyLeading: true,
      ),
      body: FutureBuilder<GroupInvite?>(
        future: Future<GroupInvite?>.value(null).then(
          (_) =>
              ref.read(getInviteByCodeProvider(inviteCode))
                  as Future<GroupInvite?>,
        ),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Finding invite...'),
                ],
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            _logger.e('Error fetching invite: ${snapshot.error}');
            return _ErrorView(
              title: 'Oops!',
              message:
                  'Could not find the invite. It may have expired or been cancelled.',
              onRetry: () => Navigator.of(context).pop(),
            );
          }

          // Invite not found
          final invite = snapshot.data;
          if (invite == null) {
            return _ErrorView(
              title: 'Invite Not Found',
              message: 'This invite code does not exist.',
              onRetry: () => Navigator.of(context).pop(),
            );
          }

          // Invite expired
          if (invite.isExpired) {
            return _ErrorView(
              title: 'Invite Expired',
              message:
                  'This invite expired on ${_formatDate(invite.expiresAt)}.',
              onRetry: () => Navigator.of(context).pop(),
            );
          }

          // Invite already accepted
          if (invite.isAccepted) {
            return _ErrorView(
              title: 'Already Accepted',
              message: 'This invite has already been accepted.',
              onRetry: () => Navigator.of(context).pop(),
            );
          }

          // Not authenticated
          final userId = authState.value?.uid;
          if (userId == null) {
            return _ErrorView(
              title: 'Not Signed In',
              message: 'You must be signed in to accept invites.',
              onRetry: () => context.go('/welcome'),
            );
          }

          // User is the inviter
          if (invite.invitedBy == userId) {
            return _ErrorView(
              title: 'Cannot Accept Own Invite',
              message: 'You cannot accept your own invite.',
              onRetry: () => Navigator.of(context).pop(),
            );
          }

          // Valid invite - show acceptance dialog
          return _InviteDetailsView(
            inviteCode: inviteCode,
            invite: invite,
            userId: userId,
            onAccept: () async {
              await _acceptInvite(context, ref, inviteCode, userId);
            },
            onDecline: () => Navigator.of(context).pop(),
          );
        },
      ),
    );
  }

  /// Accept the invite
  Future<void> _acceptInvite(
    BuildContext context,
    WidgetRef ref,
    String code,
    String userId,
  ) async {
    try {
      // Accept the invite
      await (ref.read(acceptInviteProvider(code: code, userId: userId))
          as Future<dynamic>);

      if (context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the group!'),
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to groups list
        context.go('/home/groupsList');
      }
    } on InviteExpiredException {
      if (context.mounted) {
        _showError(context, 'This invite has expired.');
      }
    } on InviteAlreadyAcceptedException {
      if (context.mounted) {
        _showError(context, 'This invite has already been accepted.');
      }
    } on SelfInviteException {
      if (context.mounted) {
        _showError(context, 'You cannot accept your own invite.');
      }
    } on InviteNotFoundException {
      if (context.mounted) {
        _showError(context, 'Invite not found.');
      }
    } catch (e) {
      _logger.e('Error accepting invite: $e');
      if (context.mounted) {
        _showError(context, 'Failed to accept invite. Please try again.');
      }
    }
  }

  /// Show error snackbar
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// View showing invite details and accept/decline buttons
class _InviteDetailsView extends StatefulWidget {
  final String inviteCode;
  final GroupInvite invite;
  final String userId;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _InviteDetailsView({
    required this.inviteCode,
    required this.invite,
    required this.userId,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_InviteDetailsView> createState() => _InviteDetailsViewState();
}

class _InviteDetailsViewState extends State<_InviteDetailsView> {
  bool _isAccepting = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invite from
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite from',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.invite.invitedByName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Group name
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Group', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 8),
                  Text(
                    widget.invite.groupName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Invite code
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite Code',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.invite.inviteCode,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expires in ${widget.invite.daysUntilExpiry} days',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Action buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _isAccepting ? null : _handleAccept,
                child: _isAccepting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Accept Invite'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isAccepting ? null : widget.onDecline,
                child: const Text('Decline'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What happens next?',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Once you accept this invite, you\'ll be added to the group and can start splitting expenses with the other members.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept() async {
    setState(() => _isAccepting = true);
    try {
      widget.onAccept();
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }
}

/// View for error states
class _ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: onRetry, child: const Text('Go Back')),
        ],
      ),
    );
  }
}
