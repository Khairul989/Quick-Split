import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/models/group.dart';
import '../../domain/models/person.dart';
import '../../domain/services/contact_matching_service.dart';
import '../providers/contact_matching_provider.dart';
import '../providers/group_providers.dart';

/// Screen showing matched contacts from the user's device who are registered on QuickSplit
/// Uses ContactMatchingService for automatic caching and provides pull-to-refresh functionality
class FindFriendsScreen extends ConsumerStatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  ConsumerState<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends ConsumerState<FindFriendsScreen> {
  static final _logger = Logger();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load initial matches from cache on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialMatches();
    });
  }

  /// Load initial matches - uses cache if available, otherwise triggers matching
  Future<void> _loadInitialMatches() async {
    final notifier = ref.read(contactMatchingProvider.notifier);
    final state = ref.read(contactMatchingProvider);

    // If no cached matches, trigger matching
    if (state.matches.isEmpty) {
      await notifier.matchContacts();
    }
  }

  /// Refresh matches by re-querying Firestore
  Future<void> _refreshMatches() async {
    final notifier = ref.read(contactMatchingProvider.notifier);
    await notifier.refreshMatches();
  }

  Future<void> _addToGroup(Person person, String groupId) async {
    setState(() => _isLoading = true);

    try {
      final groupsNotifier = ref.read(groupsProvider.notifier);
      final group = groupsNotifier.getGroupById(groupId);

      if (group == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Group not found')));
        return;
      }

      // Check if person already in group
      if (group.personIds.contains(person.id)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${person.name} is already in this group')),
        );
        return;
      }

      // Add person to group
      final updatedGroup = group.copyWith(
        personIds: [...group.personIds, person.id],
      );

      await groupsNotifier.updateGroup(updatedGroup);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${person.name} added to group')));
    } catch (e) {
      _logger.e('Error adding person to group: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add person to group')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsState = ref.watch(groupsProvider);
    final matchingState = ref.watch(contactMatchingProvider);
    final matchedContacts = ref.watch(matchedContactsProvider);
    final cacheInfo = ref.watch(contactMatchCacheInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Find Friends'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: _refreshMatches,
        child: _buildContent(
          context,
          matchingState,
          matchedContacts,
          cacheInfo,
          groupsState,
        ),
      ),
    );
  }

  /// Build main content based on matching state
  Widget _buildContent(
    BuildContext context,
    ContactMatchingState matchingState,
    List<(Person, String)> matchedContacts,
    ContactMatchCacheInfo cacheInfo,
    GroupsState groupsState,
  ) {
    // Show loading state
    if (matchingState.isLoading && matchedContacts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (matchingState.error != null && matchedContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading matches',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                matchingState.error ?? 'An unknown error occurred',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshMatches,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (matchedContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No matches found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'None of your contacts are registered on QuickSplit yet',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (cacheInfo.lastMatchedAt != null)
              Text(
                'Last checked: ${cacheInfo.formattedLastMatchedAt}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
          ],
        ),
      );
    }

    // Show matched users
    return Column(
      children: [
        // Header showing match count
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.withValues(alpha: 0.1),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${matchedContacts.length} of your contacts are on QuickSplit!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add them to your groups to split expenses',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List of matched users
        Expanded(
          child: ListView.builder(
            itemCount: matchedContacts.length,
            itemBuilder: (context, index) {
              final (person, userId) = matchedContacts[index];

              return _MatchedContactTile(
                person: person,
                groups: groupsState.groups,
                isLoading: _isLoading,
                onAddToGroup: (groupId) => _addToGroup(person, groupId),
              );
            },
          ),
        ),

        // Footer showing last updated timestamp
        if (cacheInfo.lastMatchedAt != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Last checked: ${cacheInfo.formattedLastMatchedAt}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
      ],
    );
  }
}

/// Tile showing a single matched contact with quick-add buttons
class _MatchedContactTile extends StatefulWidget {
  final Person person;
  final List<Group> groups;
  final bool isLoading;
  final Function(String groupId) onAddToGroup;

  const _MatchedContactTile({
    required this.person,
    required this.groups,
    required this.isLoading,
    required this.onAddToGroup,
  });

  @override
  State<_MatchedContactTile> createState() => _MatchedContactTileState();
}

class _MatchedContactTileState extends State<_MatchedContactTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = false;
  }

  @override
  Widget build(BuildContext context) {
    // Filter out groups that already have this person
    final availableGroups = widget.groups
        .where((g) => !g.personIds.contains(widget.person.id))
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: Text(
              widget.person.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            title: Text(widget.person.name),
            subtitle: widget.person.email != null
                ? Text(widget.person.email!)
                : null,
            trailing: _isExpanded
                ? const Icon(Icons.expand_less)
                : const Icon(Icons.expand_more),
            onTap: () {
              setState(() => _isExpanded = !_isExpanded);
            },
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (availableGroups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Person is already in all your groups',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    )
                  else
                    Text(
                      'Add to group:',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableGroups.map((group) {
                      return ElevatedButton.icon(
                        onPressed: widget.isLoading
                            ? null
                            : () => widget.onAddToGroup(group.id),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(group.name),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
