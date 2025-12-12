import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/person.dart';
import '../providers/contacts_provider.dart';
import 'contact_list_item.dart';

/// Callback when contacts are selected
typedef OnContactsSelected = void Function(List<Person> selected);

class ContactSelectorBottomSheet extends ConsumerStatefulWidget {
  final List<Person> existingPeople;
  final OnContactsSelected onContactsSelected;

  const ContactSelectorBottomSheet({
    required this.existingPeople,
    required this.onContactsSelected,
    super.key,
  });

  @override
  ConsumerState<ContactSelectorBottomSheet> createState() =>
      _ContactSelectorBottomSheetState();
}

class _ContactSelectorBottomSheetState
    extends ConsumerState<ContactSelectorBottomSheet> {
  final _searchController = TextEditingController();
  final Set<String> _selectedContactIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(contactsProvider.notifier).loadContacts(),
    );
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<Person> _filterContacts(List<Person> contacts) {
    if (_searchQuery.isEmpty) return contacts;

    return contacts.where((person) {
      final nameMatch = person.name.toLowerCase().contains(_searchQuery);
      final phoneMatch = person.phoneNumber
              ?.replaceAll(RegExp(r'[^\d]'), '')
              .contains(_searchQuery.replaceAll(RegExp(r'[^\d]'), '')) ??
          false;
      final emailMatch = person.email?.toLowerCase().contains(_searchQuery) ?? false;

      return nameMatch || phoneMatch || emailMatch;
    }).toList();
  }

  void _handleSubmit() {
    final contactsState = ref.read(contactsProvider);
    final selected = contactsState.contacts
        .where((contact) => _selectedContactIds.contains(contact.id))
        .toList();

    widget.onContactsSelected(selected);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final contactsState = ref.watch(contactsProvider);
    final filteredContacts = _filterContacts(contactsState.contacts);
    final categories = ContactSorter.categorizeContacts(filteredContacts);
    final recentContacts = categories['recent'] ?? [];
    final allContacts = categories['all'] ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header with title and selection count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add from Contacts',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedContactIds.isNotEmpty
                        ? colorScheme.primaryContainer
                        : colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_selectedContactIds.length} selected',
                    style: textTheme.labelSmall?.copyWith(
                      color: _selectedContactIds.isNotEmpty
                          ? colorScheme.primary
                          : colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or phone',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Contact list or loading/error state
          Expanded(
            child: contactsState.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading contacts...',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : contactsState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.error,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading contacts',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              contactsState.error!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : filteredContacts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.contacts_outlined,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No contacts found'
                                      : 'No contacts found for "$_searchQuery"',
                                  style: textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            itemCount: _buildListItems(
                              recentContacts,
                              allContacts,
                              _searchQuery.isNotEmpty,
                            ).length,
                            itemBuilder: (context, index) {
                              final items = _buildListItems(
                                recentContacts,
                                allContacts,
                                _searchQuery.isNotEmpty,
                              );
                              final item = items[index];

                              if (item is SectionHeader) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    top: 16,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    item.title,
                                    style: textTheme.labelMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              } else if (item is Person) {
                                return ContactListItem(
                                  contact: item,
                                  isSelected: _selectedContactIds
                                      .contains(item.id),
                                  onSelectionChanged: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedContactIds.add(item.id);
                                      } else {
                                        _selectedContactIds.remove(item.id);
                                      }
                                    });
                                  },
                                  existingPeople: widget.existingPeople,
                                  searchQuery: _searchQuery,
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          ),
          ),

          // Submit button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _selectedContactIds.isEmpty ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: colorScheme.primary,
                  disabledBackgroundColor:
                      colorScheme.primary.withValues(alpha: 0.5),
                ),
                child: Text(
                  _selectedContactIds.isEmpty
                      ? 'Select Contacts'
                      : 'Add ${_selectedContactIds.length} Contact${_selectedContactIds.length == 1 ? '' : 's'}',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _buildListItems(
    List<Person> recentContacts,
    List<Person> allContacts,
    bool isSearching,
  ) {
    final items = <dynamic>[];

    // Only show section headers if not searching
    if (!isSearching && recentContacts.isNotEmpty) {
      items.add(SectionHeader('Recent'));
      items.addAll(recentContacts);

      // Only add "All Contacts" header if we have non-recent contacts
      if (allContacts.length > recentContacts.length) {
        items.add(SectionHeader('All Contacts'));
        items.addAll(
          allContacts.where((c) => !recentContacts.contains(c)),
        );
      }
    } else {
      // If searching or no recent contacts, just show all
      items.addAll(allContacts);
    }

    return items;
  }
}

class SectionHeader {
  final String title;

  SectionHeader(this.title);
}
