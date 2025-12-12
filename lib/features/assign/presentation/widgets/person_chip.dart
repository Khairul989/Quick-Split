import 'package:flutter/material.dart';
import 'package:quicksplit/features/groups/domain/models/person.dart';

class PersonChip extends StatelessWidget {
  final Person person;
  final VoidCallback? onPressed;

  const PersonChip({required this.person, this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: CircleAvatar(
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.person, color: colorScheme.onPrimary, size: 14),
      ),
      label: Text(
        person.name,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.3)),
      onDeleted: onPressed,
      deleteIcon: const SizedBox.shrink(),
    );
  }
}
