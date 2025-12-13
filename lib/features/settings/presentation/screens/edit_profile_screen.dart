import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/phone_utils.dart';
import '../../../onboarding/presentation/providers/user_profile_provider.dart';

/// Edit profile screen for updating user information
/// Allows editing name, emoji, and phone number
/// Email cannot be edited as it's tied to Firebase Authentication
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  late String _selectedEmoji;
  late String _selectedCountryCode;
  bool _isSaving = false;

  final List<String> _emojiList = [
    '😊',
    '😎',
    '🤗',
    '😍',
    '🥳',
    '🤠',
    '🦄',
    '🐱',
    '🐶',
    '🦊',
    '🐼',
    '🐨',
    '🐸',
    '🦁',
    '🐯',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _selectedEmoji = '😊';
    _selectedCountryCode = '+60';
    _initializeFormData();
  }

  void _initializeFormData() {
    final profile = ref.read(userProfileProvider);
    if (profile != null) {
      _nameController.text = profile.name;
      _selectedEmoji = profile.emoji;

      if (profile.hasPhone) {
        final countryCode = getCountryCode(profile.phoneNumber!);
        _selectedCountryCode = countryCode.isNotEmpty ? countryCode : '+60';

        // Extract phone number without country code
        final phoneNumber = profile.phoneNumber!.replaceFirst(
          _selectedCountryCode,
          '',
        );
        _phoneController.text = phoneNumber;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<bool> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    setState(() => _isSaving = true);

    // Get current profile
    final currentProfile = ref.read(userProfileProvider);
    if (currentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Profile not found'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSaving = false);
      return false;
    }

    // Normalize phone number if provided
    String? normalizedPhone;
    final phoneInput = _phoneController.text.trim();
    if (phoneInput.isNotEmpty) {
      normalizedPhone = normalizePhoneNumber(
        '$_selectedCountryCode$phoneInput',
        defaultCountryCode: _selectedCountryCode,
      );
    }

    try {
      final updatedProfile = currentProfile.copyWith(
        name: _nameController.text.trim(),
        emoji: _selectedEmoji,
        phoneNumber: normalizedPhone,
        updatedAt: DateTime.now(),
      );

      final success = await ref
          .read(userProfileProvider.notifier)
          .updateProfile(updatedProfile);

      if (mounted) {
        setState(() => _isSaving = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          if (mounted) {
            context.pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      return success;
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                            ? Border.all(
                                color: const Color(0xFF248CFF),
                                width: 2,
                              )
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
    final profile = ref.watch(userProfileProvider);

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: Text('No profile found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar section
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
                    labelText: 'Name',
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

                // Email field (read-only)
                TextFormField(
                  initialValue: profile.email ?? 'Not provided',
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Your email address',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  readOnly: true,
                  enabled: false,
                ),
                const SizedBox(height: 8),
                Text(
                  'Email cannot be changed. Update your Firebase account.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Phone number section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phone Number',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Optional - helps you find friends on QuickSplit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Country code selector
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.dividerColor,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: PopupMenuButton<String>(
                            onSelected: (value) {
                              setState(() => _selectedCountryCode = value);
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: '+60',
                                child: Text('🇲🇾 +60'),
                              ),
                              const PopupMenuItem(
                                value: '+1',
                                child: Text('🇺🇸 +1'),
                              ),
                              const PopupMenuItem(
                                value: '+44',
                                child: Text('🇬🇧 +44'),
                              ),
                              const PopupMenuItem(
                                value: '+91',
                                child: Text('🇮🇳 +91'),
                              ),
                              const PopupMenuItem(
                                value: '+86',
                                child: Text('🇨🇳 +86'),
                              ),
                              const PopupMenuItem(
                                value: '+65',
                                child: Text('🇸🇬 +65'),
                              ),
                              const PopupMenuItem(
                                value: '+66',
                                child: Text('🇹🇭 +66'),
                              ),
                              const PopupMenuItem(
                                value: '+62',
                                child: Text('🇮🇩 +62'),
                              ),
                            ],
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedCountryCode,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_drop_down, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Phone number input
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              hintText: '123 4567 890',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final fullPhone =
                                    '$_selectedCountryCode${value.replaceAll(RegExp(r"[^\d]"), "")}';
                                if (!isValidPhoneNumber(fullPhone)) {
                                  return 'Invalid format';
                                }
                              }
                              return null;
                            },
                            onChanged: (_) {
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_phoneController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Format: ${formatPhoneForDisplay("$_selectedCountryCode${_phoneController.text.replaceAll(RegExp(r"[^\d]"), "")}")}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF248CFF),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF248CFF),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
