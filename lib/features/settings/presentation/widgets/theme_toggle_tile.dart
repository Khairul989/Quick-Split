import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicksplit/core/constants/app_spacing.dart';
import 'package:quicksplit/core/providers/theme_provider.dart';

/// Theme toggle widget with Light/Dark/System options
class ThemeToggleTile extends ConsumerWidget {
  const ThemeToggleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return Column(
      children: [
        _ThemeOptionTile(
          icon: Icons.brightness_auto,
          title: 'System',
          subtitle: 'Follow device theme',
          themeMode: ThemeMode.system,
          currentMode: themeState.themeMode,
          onChanged: (mode) =>
              ref.read(themeProvider.notifier).setThemeMode(mode),
        ),
        SizedBox(height: AppSpacing.sm),
        _ThemeOptionTile(
          icon: Icons.light_mode,
          title: 'Light',
          subtitle: 'Light theme',
          themeMode: ThemeMode.light,
          currentMode: themeState.themeMode,
          onChanged: (mode) =>
              ref.read(themeProvider.notifier).setThemeMode(mode),
        ),
        SizedBox(height: AppSpacing.sm),
        _ThemeOptionTile(
          icon: Icons.dark_mode,
          title: 'Dark',
          subtitle: 'Dark theme',
          themeMode: ThemeMode.dark,
          currentMode: themeState.themeMode,
          onChanged: (mode) =>
              ref.read(themeProvider.notifier).setThemeMode(mode),
        ),
      ],
    );
  }
}

/// Private helper widget for each theme option tile
class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeMode themeMode;
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.themeMode,
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = themeMode == currentMode;

    return InkWell(
      onTap: () => onChanged(themeMode),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              size: 24,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
