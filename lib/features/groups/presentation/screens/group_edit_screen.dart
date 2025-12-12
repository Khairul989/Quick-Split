import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quicksplit/features/groups/domain/models/group.dart';
import 'package:quicksplit/features/groups/domain/models/person.dart';
import 'package:quicksplit/features/groups/presentation/providers/group_providers.dart';
import 'package:quicksplit/features/groups/presentation/widgets/add_person_tile.dart';
import 'package:quicksplit/features/groups/presentation/widgets/person_tile.dart';

class GroupEditScreen extends ConsumerStatefulWidget {
  final Group group;
  const GroupEditScreen({required this.group, super.key});

  @override
  ConsumerState<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends ConsumerState<GroupEditScreen> {
  final _groupNameController = TextEditingController();
  final List<Person> _currentMembers = [];
  final List<Person> _originalMembers = [];
  bool _showAddPersonForm = false;
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;
  String? _groupNameError;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _initializeScreen() {
    _groupNameController.text = widget.group.name;

    // Get current members
    final members = ref.read(groupsProvider.notifier).getPeopleForGroup(widget.group.id);
    _currentMembers.addAll(members);
    _originalMembers.addAll(members.map((p) => p.copyWith()).toList());

    // Set current image path if exists
    _selectedImagePath = widget.group.imagePath;
  }

  void _validateGroupName() {
    setState(() {
      final name = _groupNameController.text.trim();
      if (name.isNotEmpty && name.length > 50) {
        _groupNameError = 'Group name must be 50 characters or less';
      } else {
        _groupNameError = null;
      }
      _checkForUnsavedChanges();
    });
  }

  void _checkForUnsavedChanges() {
    final hasNameChange = _groupNameController.text.trim() != widget.group.name;
    final hasImageChange = _selectedImagePath != widget.group.imagePath;
    final hasMemberChanges = !_listsEqual(
      _currentMembers.map((p) => p.id).toList(),
      _originalMembers.map((p) => p.id).toList(),
    );

    setState(() {
      _hasUnsavedChanges = hasNameChange || hasImageChange || hasMemberChanges;
    });
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _handleAddPerson(String name, String emoji) {
    final person = Person(name: name, emoji: emoji);
    setState(() {
      _currentMembers.add(person);
      _showAddPersonForm = false;
      _checkForUnsavedChanges();
    });
  }

  void _handleRemovePerson(int index) {
    final removedPerson = _currentMembers[index];

    // Check if person is being used in any other groups
    final isUsedInOtherGroups = ref.read(groupsProvider).groups.any((group) {
      if (group.id == widget.group.id) return false;
      return group.personIds.contains(removedPerson.id);
    });

    if (isUsedInOtherGroups) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${removedPerson.name} is used in other groups and cannot be removed'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _currentMembers.removeAt(index);
      _checkForUnsavedChanges();
    });
  }

  void _handleEditPerson(int index, Person updatedPerson) {
    setState(() {
      _currentMembers[index] = updatedPerson;
      _checkForUnsavedChanges();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    // Show dialog to choose between camera and gallery
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: const Text('Choose where to get the image from'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 8),
                  Text('Camera'),
                ],
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    _selectedImagePath = image.path;
                    _checkForUnsavedChanges();
                  });
                }
              },
            ),
            TextButton(
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library),
                  SizedBox(width: 8),
                  Text('Gallery'),
                ],
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (image != null) {
                  setState(() {
                    _selectedImagePath = image.path;
                    _checkForUnsavedChanges();
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
      _checkForUnsavedChanges();
    });
  }

  Widget _buildDefaultIcon(ColorScheme colorScheme) {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.groups_rounded,
        size: 48,
        color: Colors.white,
      ),
    );
  }

  Future<void> _handleEditMember(int index) async {
    final person = _currentMembers[index];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditPersonBottomSheet(
        person: person,
        onEdit: (updatedPerson) {
          _handleEditPerson(index, updatedPerson);
        },
      ),
    );
  }

  Future<void> _handleSaveGroup() async {
    _validateGroupName();

    // Validate minimum people requirement
    if (_currentMembers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group must have at least 2 members'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_groupNameError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create updated group
      final updatedGroup = widget.group.copyWith(
        name: _groupNameController.text.trim(),
        personIds: _currentMembers.map((p) => p.id).toList(),
        imagePath: _selectedImagePath,
      );

      // Update group via provider
      await ref.read(groupsProvider.notifier).updateGroup(updatedGroup);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "${updatedGroup.name}" updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );

        // Pop back to previous screen
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update group: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final canSave = _currentMembers.length >= 2 && _groupNameError == null;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onWillPop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Group'),
          elevation: 0,
          centerTitle: true,
          actions: [
            if (_hasUnsavedChanges)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.circle,
                  size: 8,
                  color: colorScheme.error,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: canSave ? _handleSaveGroup : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          backgroundColor: canSave
                              ? colorScheme.primary
                              : colorScheme.primary.withValues(alpha: 0.5),
                          disabledBackgroundColor: colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        child: Text(
                          'Save',
                          style: textTheme.labelLarge?.copyWith(
                            color: canSave ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar section
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Background circle
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                          ),
                        ),
                        // Image or default icon
                        if (_selectedImagePath != null)
                          ClipOval(
                            child: Image.file(
                              File(_selectedImagePath!),
                              width: 116,
                              height: 116,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultIcon(colorScheme);
                              },
                            ),
                          )
                        else
                          _buildDefaultIcon(colorScheme),
                        // Edit button overlay
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                _selectedImagePath != null
                                    ? Icons.edit_rounded
                                    : Icons.add_a_photo_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _pickImage,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                        // Remove button if image is selected
                        if (_selectedImagePath != null)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: colorScheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                onPressed: _removeImage,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Group name section
                Text(
                  'Group Name',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _groupNameController,
                  decoration: InputDecoration(
                    labelText: 'Enter group name',
                    hintText: 'e.g., Weekend Trip, Dinner',
                    errorText: _groupNameError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    helperText: 'Update your group name',
                    helperMaxLines: 2,
                  ),
                  maxLength: 50,
                  onChanged: (_) => _validateGroupName(),
                ),

                const SizedBox(height: 32),

                // Members section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Members',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Minimum 2 members required',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _currentMembers.length >= 2
                            ? colorScheme.primaryContainer
                            : colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_currentMembers.length} members',
                        style: textTheme.labelSmall?.copyWith(
                          color: _currentMembers.length >= 2
                              ? colorScheme.primary
                              : colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // List of members
                if (_currentMembers.isNotEmpty)
                  ...List.generate(_currentMembers.length, (index) {
                    final person = _currentMembers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PersonTile(
                        person: person,
                        onRemove: () => _handleRemovePerson(index),
                        onEdit: () => _handleEditMember(index),
                        isRemovable: true,
                      ),
                    );
                  }),

                // Add person button
                if (!_showAddPersonForm)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _showAddPersonForm = true);
                    },
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('Add Member'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else ...[
                  const SizedBox(height: 12),
                  AddPersonTile(
                    onPersonAdded: _handleAddPerson,
                    onCancel: () {
                      setState(() => _showAddPersonForm = false);
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // Unsaved changes warning
                if (_hasUnsavedChanges)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.error.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_rounded,
                          size: 16,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You have unsaved changes. Press Save to keep your changes or go back to discard them.',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
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

class _EditPersonBottomSheet extends StatelessWidget {
  final Person person;
  final Function(Person) onEdit;

  const _EditPersonBottomSheet({
    required this.person,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final nameController = TextEditingController(text: person.name);
    final emojiController = TextEditingController(text: person.emoji);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Edit Member',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Name',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Enter name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Emoji',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: emojiController,
              decoration: InputDecoration(
                hintText: 'Enter emoji',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLength: 2,
              maxLines: 1,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isNotEmpty &&
                          emojiController.text.trim().isNotEmpty) {
                        onEdit(
                          person.copyWith(
                            name: nameController.text.trim(),
                            emoji: emojiController.text.trim(),
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}