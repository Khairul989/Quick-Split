import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicksplit/core/providers/theme_provider.dart';

/// Theme toggle widget with Light/Dark/System options
class ThemeToggleTile extends ConsumerWidget {
  const ThemeToggleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Three radio options
          _ThemeOption(
            title: 'Light',
            subtitle: 'Always use light theme',
            icon: Icons.light_mode,
            themeMode: ThemeMode.light,
            currentMode: themeState.themeMode,
            onChanged: (mode) =>
                ref.read(themeProvider.notifier).setThemeMode(mode),
          ),
          const SizedBox(height: 8),

          _ThemeOption(
            title: 'Dark',
            subtitle: 'Always use dark theme',
            icon: Icons.dark_mode,
            themeMode: ThemeMode.dark,
            currentMode: themeState.themeMode,
            onChanged: (mode) =>
                ref.read(themeProvider.notifier).setThemeMode(mode),
          ),
          const SizedBox(height: 8),

          _ThemeOption(
            title: 'System',
            subtitle: 'Follow device settings',
            icon: Icons.brightness_auto,
            themeMode: ThemeMode.system,
            currentMode: themeState.themeMode,
            onChanged: (mode) =>
                ref.read(themeProvider.notifier).setThemeMode(mode),
          ),
        ],
      ),
    );
  }
}

/// Private helper widget for each theme option
class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeMode themeMode;
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeOption({
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.iconTheme.color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
