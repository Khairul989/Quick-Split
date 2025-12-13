import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

typedef OnPersonAdded = void Function(String name, String emoji);

class AddPersonTile extends StatefulWidget {
  final OnPersonAdded onPersonAdded;
  final VoidCallback onCancel;

  const AddPersonTile({
    required this.onPersonAdded,
    required this.onCancel,
    super.key,
  });

  @override
  State<AddPersonTile> createState() => _AddPersonTileState();
}

class _AddPersonTileState extends State<AddPersonTile> {
  final _nameController = TextEditingController();
  String _selectedEmoji = '👤';
  bool _showEmojiPicker = false;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _validateName() {
    setState(() {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        _nameError = 'Name is required';
      } else if (name.length > 20) {
        _nameError = 'Name must be 20 characters or less';
      } else {
        _nameError = null;
      }
    });
  }

  void _handleAddPerson() {
    _validateName();
    if (_nameError == null) {
      widget.onPersonAdded(_nameController.text.trim(), _selectedEmoji);
      _nameController.clear();
      setState(() {
        _selectedEmoji = '👤';
        _showEmojiPicker = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Column(
      children: [
        // Expandable tile content
        Container(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji picker section
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showEmojiPicker = !_showEmojiPicker;
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _selectedEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tap emoji to change',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Then enter a name',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Name text field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Person name',
                    hintText: 'e.g., Alice, Bob',
                    errorText: _nameError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    helperText: 'Max 20 characters',
                  ),
                  onChanged: (_) => _validateName(),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleAddPerson(),
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleAddPerson,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: colorScheme.primary,
                        ),
                        child: Text(
                          'Add Person',
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Emoji picker bottom sheet or inline (platform-aware)
        if (_showEmojiPicker && !isKeyboardVisible)
          Container(
            color: colorScheme.surface,
            child: SizedBox(
              height: 280,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  setState(() {
                    _selectedEmoji = emoji.emoji;
                  });
                },
                onBackspacePressed: () {},
                config: Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    emojiSizeMax: 28,
                    backgroundColor: colorScheme.surface,
                    columns: 8,
                  ),
                  skinToneConfig: SkinToneConfig(enabled: true),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
