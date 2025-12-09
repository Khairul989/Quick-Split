import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quicksplit/core/router/router.dart';
import 'package:quicksplit/features/assign/presentation/providers/session_provider.dart';
import 'package:quicksplit/features/ocr/domain/models/receipt.dart';
import '../../domain/models/person.dart';
import '../providers/group_providers.dart';
import '../widgets/add_person_tile.dart';
import '../widgets/person_tile.dart';

class GroupCreateScreen extends ConsumerStatefulWidget {
  final Receipt receipt;
  const GroupCreateScreen({required this.receipt, super.key});

  @override
  ConsumerState<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends ConsumerState<GroupCreateScreen> {
  final _groupNameController = TextEditingController();
  final List<Person> _selectedPeople = [];
  bool _showAddPersonForm = false;
  bool _isLoading = false;
  String? _groupNameError;

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
      final group = await ref.read(groupsProvider.notifier).createGroup(
            groupName,
            _selectedPeople,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "$groupName" created successfully'),
            duration: const Duration(seconds: 1),
          ),
        );

        // Start session with newly created group
        ref.read(sessionProvider.notifier).startSession(
          receipt: widget.receipt,
          group: group,
          participants: _selectedPeople,
        );

        // Navigate to assign items screen
        context.pushNamed(RouteNames.assignItems);
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

    final names = _selectedPeople
        .take(2)
        .map((p) => p.name)
        .join(' & ');

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
                        disabledBackgroundColor:
                            colorScheme.primary.withValues(alpha: 0.5),
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
                ...List.generate(
                  _selectedPeople.length,
                  (index) {
                    final person = _selectedPeople[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PersonTile(
                        person: person,
                        onRemove: () => _handleRemovePerson(index),
                        isRemovable: true,
                      ),
                    );
                  },
                ),

              // Add person form or button
              if (!_showAddPersonForm)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _showAddPersonForm = true);
                  },
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Add Person'),
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
