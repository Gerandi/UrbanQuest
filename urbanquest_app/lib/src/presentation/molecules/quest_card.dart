import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';  // Comment out for now
import '../atoms/custom_card.dart';
import '../../data/models/quest_model.dart';

class QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback? onTap;
  final bool showRating;
  final bool showStats;

  const QuestCard({
    super.key,
    required this.quest,
    this.onTap,
    this.showRating = true,
    this.showStats = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: quest.coverImageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                // Category Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      quest.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Rating Badge
                if (showRating)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            quest.rating.toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  quest.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showStats) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.access_time,
                          label: quest.estimatedDuration,
                          theme: theme,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.location_on,
                          label: '${quest.numberOfStops} stops',
                          theme: theme,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.bolt,
                          label: '${quest.points} pts',
                          theme: theme,
                          valueColor: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required ThemeData theme,
    Color? valueColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: valueColor ?? theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: valueColor ?? theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
} 