import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart' as share_plus;

import '../../../../core/utils/whatsapp_helper.dart';
import '../../domain/models/group.dart';
import '../../domain/models/group_invite.dart';
import '../providers/invite_providers.dart';

final _logger = Logger();

/// Screen for displaying and sharing an invite to a group
/// Shows the invite code and provides multiple sharing options:
/// - Copy code
/// - WhatsApp share
/// - Copy deep link
/// - Native share dialog
class InviteScreen extends ConsumerWidget {
  final Group group;
  final String currentUserId;
  final String currentUserName;

  const InviteScreen({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createInviteFuture = Future<GroupInvite?>.value(null).then(
      (_) =>
          ref.read(
                createGroupInviteProvider(
                  groupId: group.id,
                  groupName: group.name,
                  invitedBy: currentUserId,
                  invitedByName: currentUserName,
                ),
              )
              as Future<GroupInvite?>,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Invite to Group')),
      body: FutureBuilder<GroupInvite?>(
        future: createInviteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            _logger.e('Error creating invite: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error creating invite'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final invite = snapshot.data;
          if (invite == null) {
            return const Center(child: Text('Invite not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group name
                Text(
                  'Invite to ${group.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),

                // Invite code card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Text(
                          'Invite Code',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 16),
                        // Large, spaced-out code
                        Text(
                          invite.inviteCode,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                                fontFamily: 'monospace',
                              ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Valid for ${invite.daysUntilExpiry} days',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Share options
                Text('Share', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),

                // Copy code button
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Copy Code'),
                  subtitle: const Text('Copy invite code to clipboard'),
                  onTap: () => _copyCode(context, invite.inviteCode),
                ),

                // Copy link button
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text('Copy Deep Link'),
                  subtitle: const Text('Copy link to clipboard'),
                  onTap: () => _copyLink(context, invite.inviteCode),
                ),

                // WhatsApp share button
                ListTile(
                  leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
                  title: const Text('Share via WhatsApp'),
                  subtitle: const Text('Send to WhatsApp contacts'),
                  onTap: () => _shareViaWhatsApp(context, invite),
                ),

                // Native share button
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Share Link'),
                  subtitle: const Text('Share with other apps'),
                  onTap: () => _shareLink(context, invite),
                ),

                const SizedBox(height: 32),

                // Info section
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
                        'How it works',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Share the code or link with others\n'
                        '2. They open QuickSplit and paste the code or click the link\n'
                        '3. They accept the invite\n'
                        '4. They\'re added to the group!',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Copy invite code to clipboard
  void _copyCode(BuildContext context, String code) {
    final message = code;
    _copyToClipboard(context, message, 'Code copied to clipboard');
  }

  /// Copy deep link to clipboard
  void _copyLink(BuildContext context, String code) {
    final link = 'quicksplit://invite/$code';
    _copyToClipboard(context, link, 'Link copied to clipboard');
  }

  /// Copy text to clipboard and show snackbar
  void _copyToClipboard(BuildContext context, String text, String message) {
    services.Clipboard.setData(services.ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// Share via WhatsApp
  Future<void> _shareViaWhatsApp(
    BuildContext context,
    GroupInvite invite,
  ) async {
    try {
      final deepLink = 'quicksplit://invite/${invite.inviteCode}';
      await WhatsAppHelper.shareInviteToContact(
        groupName: group.name,
        inviteCode: invite.inviteCode,
        deepLink: deepLink,
      );
    } catch (e) {
      _logger.e('Error sharing via WhatsApp: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Share link using native share dialog
  Future<void> _shareLink(BuildContext context, GroupInvite invite) async {
    try {
      final deepLink = 'quicksplit://invite/${invite.inviteCode}';
      final message = WhatsAppHelper.generateInviteMessage(
        groupName: group.name,
        inviteCode: invite.inviteCode,
        deepLink: deepLink,
      );

      await share_plus.SharePlus.instance.share(
        share_plus.ShareParams(
          text: message,
          subject: 'Join "${group.name}" on QuickSplit',
        ),
      );
    } catch (e) {
      _logger.e('Error sharing link: $e');
    }
  }
}
