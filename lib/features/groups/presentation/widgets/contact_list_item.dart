import 'package:flutter/material.dart';
import '../../domain/models/person.dart';
import '../providers/contacts_provider.dart';

class ContactListItem extends StatelessWidget {
  final Person contact;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final List<Person> existingPeople;
  final String searchQuery;

  const ContactListItem({
    required this.contact,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.existingPeople,
    this.searchQuery = '',
    super.key,
  });

  bool get _isDuplicate => ContactDuplicateDetector.existsInGroup(contact, existingPeople);

  Widget _buildHighlightedText(
    String text,
    TextStyle? style,
    TextStyle? highlightStyle,
  ) {
    if (searchQuery.isEmpty) {
      return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final query = searchQuery.toLowerCase();
    final textLower = text.toLowerCase();

    if (!textLower.contains(query)) {
      return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    final index = textLower.indexOf(query);
    final before = text.substring(0, index);
    final match = text.substring(index, index + query.length);
    final after = text.substring(index + query.length);

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: before),
          TextSpan(text: match, style: highlightStyle),
          TextSpan(text: after),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return CheckboxListTile(
      value: isSelected && !_isDuplicate,
      onChanged: _isDuplicate ? null : (value) => onSelectionChanged(value ?? false),
      enabled: !_isDuplicate,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      title: _buildHighlightedText(
        contact.name,
        textTheme.bodyMedium?.copyWith(
          color: _isDuplicate ? colorScheme.onSurfaceVariant : null,
        ),
        textTheme.bodyMedium?.copyWith(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.3),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contact.formattedPhone != null)
            _buildHighlightedText(
              contact.formattedPhone!,
              textTheme.labelSmall?.copyWith(
                color: _isDuplicate
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurfaceVariant,
              ),
              textTheme.labelSmall?.copyWith(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
          if (contact.email != null)
            Text(
              contact.email!,
              style: textTheme.labelSmall?.copyWith(
                color: _isDuplicate
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      secondary: _isDuplicate
          ? Tooltip(
              message: 'Already in group',
              child: Icon(
                Icons.check_circle_rounded,
                color: colorScheme.primary,
              ),
            )
          : CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                contact.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tileColor: _isDuplicate
          ? colorScheme.primaryContainer.withValues(alpha: 0.2)
          : null,
    );
  }
}
