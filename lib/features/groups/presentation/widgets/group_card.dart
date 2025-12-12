import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/group.dart';
import '../providers/group_providers.dart';

Widget _buildGradientIcon(ColorScheme colorScheme, {double size = 20}) {
  return Container(
    width: size + 8,
    height: size + 8,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          colorScheme.primary,
          colorScheme.primary.withValues(alpha: 0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      Icons.people_rounded,
      size: size,
      color: Colors.white,
    ),
  );
}

Widget _buildGroupImage(Group group, ColorScheme colorScheme, {double size = 40}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.file(
      File(group.imagePath!),
      width: size + 8,
      height: size + 8,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to gradient icon if image fails to load
        return _buildGradientIcon(colorScheme, size: size);
      },
    ),
  );
}

class GroupCard extends ConsumerWidget {
  final Group group;
  final VoidCallback onTap;
  final bool isCompact;

  const GroupCard({
    required this.group,
    required this.onTap,
    this.isCompact = true,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final groupsState = ref.watch(groupsProvider);
    final members = groupsState.people
        .where((person) => group.personIds.contains(person.id))
        .toList();

    if (isCompact) {
      return _CompactCard(
        group: group,
        members: members,
        colorScheme: colorScheme,
        textTheme: textTheme,
        onTap: onTap,
      );
    }

    return _ExpandedCard(
      group: group,
      members: members,
      colorScheme: colorScheme,
      textTheme: textTheme,
      onTap: onTap,
    );
  }
}

class _CompactCard extends StatelessWidget {
  final Group group;
  final List<dynamic> members;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _CompactCard({
    required this.group,
    required this.members,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with group image or gradient icon
              Padding(
                padding: const EdgeInsets.all(12),
                child: group.imagePath != null
                    ? _buildGroupImage(group, colorScheme, size: 20)
                    : _buildGradientIcon(colorScheme, size: 20),
              ),

              // Group name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 2),

              // Member count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '${members.length} member${members.length != 1 ? 's' : ''}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // Last used date
              Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 4,
                  bottom: 8,
                ),
                child: Text(
                  'Used ${_formatDate(group.lastUsedAt)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),

              // Member avatars
              if (members.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    height: 28,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: List.generate(
                        members.length > 3 ? 3 : members.length,
                        (index) {
                          final member = members[index];
                          return Positioned(
                            left: index * 18.0,
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                member.emoji,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}m ago';
    }
  }
}

class _ExpandedCard extends StatelessWidget {
  final Group group;
  final List<dynamic> members;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _ExpandedCard({
    required this.group,
    required this.members,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with group image or gradient icon and title
                Row(
                  children: [
                    group.imagePath != null
                        ? _buildGroupImage(group, colorScheme, size: 24)
                        : _buildGradientIcon(colorScheme, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${members.length} member${members.length != 1 ? 's' : ''}',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Last used date
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Used ${_formatDate(group.lastUsedAt)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                if (members.isNotEmpty) ...[
                  const SizedBox(height: 12),

                  // Member avatars with names
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: members.map((member) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              member.emoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              member.name,
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${(difference.inDays / 30).floor()}m ago';
    }
  }
}
