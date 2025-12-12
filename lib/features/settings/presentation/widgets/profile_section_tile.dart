import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicksplit/core/constants/app_spacing.dart';
import '../../../onboarding/presentation/providers/user_profile_provider.dart';
import '../../../onboarding/data/models/user_profile.dart';

class ProfileSectionTile extends ConsumerWidget {
  const ProfileSectionTile({super.key});

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserProfile? profile) {
    showDialog(
      context: context,
      builder: (context) => _EditProfileDialog(currentProfile: profile),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider);

    return GestureDetector(
      onTap: () => _showEditProfileDialog(context, ref, profile),
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
                    profile?.email ?? 'Tap to ${profile == null ? 'create' : 'edit'} your profile',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileDialog extends ConsumerStatefulWidget {
  final UserProfile? currentProfile;

  const _EditProfileDialog({this.currentProfile});

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late String _selectedEmoji;
  bool _isSaving = false;

  final List<String> _emojiList = [
    '😊', '😎', '🤗', '😍', '🥳',
    '🤠', '🦄', '🐱', '🐶', '🦊',
    '🐼', '🐨', '🐸', '🦁', '🐯',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentProfile?.name ?? '');
    _emailController = TextEditingController(text: widget.currentProfile?.email ?? '');
    _selectedEmoji = widget.currentProfile?.emoji ?? '😊';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final success = await ref.read(userProfileProvider.notifier).saveProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      emoji: _selectedEmoji,
    );

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEmojiPicker() {
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
            children: [
              Text(
                'Choose Your Avatar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: _emojiList.map((emoji) {
                  final theme = Theme.of(context);
                  final isSelected = emoji == _selectedEmoji;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedEmoji = emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: theme.colorScheme.primary, width: 2)
                            : Border.all(color: theme.dividerColor, width: 1),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 32)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.currentProfile == null ? 'Create Profile' : 'Edit Profile'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji picker
              GestureDetector(
                onTap: _showEmojiPicker,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(_selectedEmoji, style: const TextStyle(fontSize: 40)),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _showEmojiPicker,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Change Avatar'),
              ),
              const SizedBox(height: 16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Invalid email format';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
