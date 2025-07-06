import 'package:flutter/material.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';  // Comment out for now
import '../atoms/custom_card.dart';
import '../../data/models/user_model.dart';

class UserStatsCard extends StatelessWidget {
  final UserStats stats;
  final bool showTitle;

  const UserStatsCard({
    super.key,
    required this.stats,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Text(
              'Adventurer Stats',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ],
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _StatItem(
                icon: Icons.flag,
                label: 'Quests Done',
                value: stats.questsCompleted.toString(),
                color: Colors.blue,
              ),
              _StatItem(
                icon: Icons.location_on,
                label: 'Stops Visited',
                value: stats.stopsVisited.toString(),
                color: Colors.green,
              ),
              _StatItem(
                icon: Icons.directions_walk,
                label: 'Distance',
                value: stats.totalDistance,
                color: Colors.orange,
              ),
              _StatItem(
                icon: Icons.camera_alt,
                label: 'Photos Shared',
                value: stats.photosShared.toString(),
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
} 