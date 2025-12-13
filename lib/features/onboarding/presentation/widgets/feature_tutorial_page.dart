import 'package:flutter/material.dart';
import '../../utils/onboarding_content.dart';

class FeatureTutorialPage extends StatelessWidget {
  final Feature feature;

  const FeatureTutorialPage({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = tutorials[feature]!;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Feature icon
          Icon(content.icon, size: 120, color: const Color(0xFF248CFF)),
          const SizedBox(height: 32),

          // Title
          Text(
            content.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            content.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Tip card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF248CFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF248CFF),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(content.tip, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
