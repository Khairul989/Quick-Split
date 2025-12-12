import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_profile_provider.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Default emojis to choose from
  final List<String> _emojiList = [
    '😊', '😎', '🤗', '😍', '🥳',
    '🤠', '🦄', '🐱', '🐶', '🦊',
    '🐼', '🐨', '🐸', '🦁', '🐯',
  ];

  late String _selectedEmoji;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Select random emoji by default
    _selectedEmoji = (_emojiList..shuffle()).first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<bool> validateAndSave() async {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    setState(() => _isSaving = true);

    final success = await ref.read(userProfileProvider.notifier).saveProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      emoji: _selectedEmoji,
    );

    if (mounted) {
      setState(() => _isSaving = false);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return success;
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
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedEmoji = emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: emoji == _selectedEmoji
                            ? const Color(0xFF248CFF).withValues(alpha: 0.2)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: emoji == _selectedEmoji
                            ? Border.all(color: const Color(0xFF248CFF), width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Set Up Your Profile',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This helps us personalize your experience',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Emoji picker
            GestureDetector(
              onTap: _showEmojiPicker,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF248CFF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF248CFF).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _selectedEmoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _showEmojiPicker,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Change Avatar'),
            ),
            const SizedBox(height: 32),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name *',
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

            // Email field (optional)
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email (Optional)',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final emailRegex = RegExp(
                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                  );
                  if (!emailRegex.hasMatch(value)) {
                    return 'Invalid email format';
                  }
                }
                return null;
              },
            ),

            if (_isSaving) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
