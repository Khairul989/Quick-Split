import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quicksplit/core/router/router.dart';
import 'package:quicksplit/features/assign/presentation/providers/session_provider.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';

import '../../domain/models/person.dart';
import '../../domain/services/contact_service.dart';
import '../providers/group_providers.dart';
import '../widgets/add_person_tile.dart';
import '../widgets/person_tile.dart';
import '../widgets/contact_selector_bottom_sheet.dart';

class GroupCreateScreen extends ConsumerStatefulWidget {
  final Receipt? receipt;
  const GroupCreateScreen({this.receipt, super.key});

  @override
  ConsumerState<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends ConsumerState<GroupCreateScreen> {
  final _groupNameController = TextEditingController();
  final List<Person> _selectedPeople = [];
  bool _showAddPersonForm = false;
  bool _isLoading = false;
  String? _groupNameError;
  String? _selectedImagePath;

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _validateGroupName() {
    setState(() {
      final name = _groupNameController.text.trim();
      if (name.isNotEmpty && name.length > 50) {
        _groupNameError = 'Group name must be 50 characters or less';
      } else {
        _groupNameError = null;
      }
    });
  }

  void _handleAddPerson(String name, String emoji) {
    final person = Person(name: name, emoji: emoji);
    setState(() {
      _selectedPeople.add(person);
      _showAddPersonForm = false;
    });
  }

  void _handleRemovePerson(int index) {
    setState(() {
      _selectedPeople.removeAt(index);
    });
  }

  Future<void> _openContactSelector() async {
    try {
      final hasPermission = await ContactService.hasPermission();

      if (!hasPermission) {
        if (mounted) {
          final granted = await _showPermissionDialog();
          if (!granted) return;
        }
      }

      if (mounted) {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return ContactSelectorBottomSheet(
              existingPeople: _selectedPeople,
              onContactsSelected: (selected) {
                setState(() {
                  _selectedPeople.addAll(selected);
                });
              },
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening contacts: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool> _showPermissionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final textTheme = theme.textTheme;
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          title: const Text('Contact Permission Required'),
          content: Text(
            'QuickSplit needs access to your contacts to quickly add group members.',
            style: textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Cancel',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final granted = await ContactService.requestPermission();
                if (mounted && dialogContext.mounted) {
                  Navigator.pop(dialogContext, granted);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
              ),
              child: Text(
                'Grant Access',
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
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

  Future<void> _handleSaveGroup() async {
    _validateGroupName();

    // Validate minimum people requirement
    if (_selectedPeople.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least 2 people to create a group'),
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
      // Generate group name if empty
      final groupName = _groupNameController.text.trim().isEmpty
          ? _generateGroupName()
          : _groupNameController.text.trim();

      // Create group via provider
      final group = await ref
          .read(groupsProvider.notifier)
          .createGroup(groupName, _selectedPeople, imagePath: _selectedImagePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "$groupName" created successfully'),
            duration: const Duration(seconds: 1),
          ),
        );

        // Only start session if coming from receipt flow
        if (widget.receipt != null) {
          ref
              .read(sessionProvider.notifier)
              .startSession(
                receipt: widget.receipt!,
                group: group,
                participants: _selectedPeople,
              );

          if (mounted) {
            context.pushReplacementNamed(RouteNames.assignItems);
          }
        } else {
          // Created standalone group, show success and go back
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Group "$groupName" created successfully'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );

            // Pop back to previous screen (GroupsList or Home)
            context.pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
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

  String _generateGroupName() {
    // Generate name from selected people
    if (_selectedPeople.isEmpty) return 'New Group';
    if (_selectedPeople.length == 1) return _selectedPeople.first.name;

    final names = _selectedPeople.take(2).map((p) => p.name).join(' & ');

    if (_selectedPeople.length > 2) {
      return '$names +${_selectedPeople.length - 2}';
    }
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final canSave = _selectedPeople.length >= 2 && _groupNameError == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        elevation: 0,
        centerTitle: true,
        actions: [
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
                  labelText: 'Enter group name (optional)',
                  hintText: 'e.g., Weekend Trip, Dinner',
                  errorText: _groupNameError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  helperText: 'Leave empty to auto-generate from members',
                  helperMaxLines: 2,
                ),
                maxLength: 50,
                onChanged: (_) => _validateGroupName(),
              ),

              const SizedBox(height: 32),

              // People section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add People',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Minimum 2 people required',
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
                      color: _selectedPeople.length >= 2
                          ? colorScheme.primaryContainer
                          : colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_selectedPeople.length} selected',
                      style: textTheme.labelSmall?.copyWith(
                        color: _selectedPeople.length >= 2
                            ? colorScheme.primary
                            : colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // List of selected people
              if (_selectedPeople.isNotEmpty)
                ...List.generate(_selectedPeople.length, (index) {
                  final person = _selectedPeople[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PersonTile(
                      person: person,
                      onRemove: () => _handleRemovePerson(index),
                      isRemovable: true,
                    ),
                  );
                }),

              // Add person form or button
              if (!_showAddPersonForm)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openContactSelector,
                      icon: const Icon(Icons.contacts_rounded),
                      label: const Text('Add from Contacts'),
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
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _showAddPersonForm = true);
                      },
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Add Person Manually'),
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
                    ),
                  ],
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

              // Help text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Groups help you quickly split bills between the same people. Each person has an emoji identifier for easy recognition.',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
