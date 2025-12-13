import 'package:flutter/material.dart';
import '../../domain/models/person.dart';

class EditPersonBottomSheet extends StatefulWidget {
  final Person person;

  const EditPersonBottomSheet({super.key, required this.person});

  @override
  State<EditPersonBottomSheet> createState() => _EditPersonBottomSheetState();
}

class _EditPersonBottomSheetState extends State<EditPersonBottomSheet> {
  late TextEditingController _nameController;
  String _selectedEmoji = '';
  bool _hasError = false;
  final FocusNode _nameFocusNode = FocusNode();

  // List of common emojis
  static const List<String> _emojiOptions = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😊',
    '😎',
    '🤩',
    '🥳',
    '😍',
    '🤗',
    '🤔',
    '😴',
    '😭',
    '😡',
    '🤬',
    '🤯',
    '😱',
    '🥶',
    '😇',
    '🥸',
    '🤠',
    '🤡',
    '👻',
    '💀',
    '👽',
    '🤖',
    '🎃',
    '😈',
    '👹',
    '👺',
    '🤡',
    '💩',
    '👻',
    '👾',
    '🤖',
    '🎃',
    '😺',
    '😸',
    '😹',
    '😻',
    '😼',
    '😽',
    '🙀',
    '😿',
    '😾',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person.name);
    _selectedEmoji = widget.person.emoji;
    _nameFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _handleSave() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    if (_selectedEmoji.isEmpty) {
      // Keep original emoji if none selected
      _selectedEmoji = widget.person.emoji;
    }

    final updatedPerson = widget.person.copyWith(
      name: name,
      emoji: _selectedEmoji,
    );

    Navigator.of(context).pop(updatedPerson);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Title
          Text(
            'Edit Person',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 24),

          // Emoji grid
          Text(
            'Select Emoji',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),

          SizedBox(
            height: 180,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _emojiOptions.length,
              itemBuilder: (context, index) {
                final emoji = _emojiOptions[index];
                final isSelected = emoji == _selectedEmoji;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = emoji;
                      _hasError = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: TextStyle(fontSize: 24, height: 1),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 24),

          // Name field
          Text(
            'Name',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            decoration: InputDecoration(
              labelText: 'Enter person name',
              errorText: _hasError ? 'Name cannot be empty' : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              if (_hasError && value.trim().isNotEmpty) {
                setState(() {
                  _hasError = false;
                });
              }
            },
          ),
          SizedBox(height: 32),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Cancel button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              ),
              SizedBox(width: 8),

              // Save button
              ElevatedButton(onPressed: _handleSave, child: const Text('Save')),
            ],
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
