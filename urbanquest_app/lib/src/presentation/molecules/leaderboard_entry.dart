import 'package:flutter/material.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';  // Comment out for now
import '../atoms/custom_avatar.dart';
import '../atoms/custom_card.dart';
import '../../data/models/leaderboard_entry_model.dart';

class LeaderboardEntryWidget extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const LeaderboardEntryWidget({
    super.key,
    required this.entry,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: isCurrentUser 
          ? colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(entry.rank, colorScheme),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: entry.rank <= 3
                  ? Icon(
                      _getRankIcon(entry.rank),
                      color: Colors.white,
                      size: 20,
                    )
                  : Text(
                      entry.rank.toString(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Avatar
          CustomAvatar(
            imageUrl: entry.avatar,
            initials: _getInitials(entry.name),
            size: AvatarSize.medium,
          ),
          
          const SizedBox(width: 16),
          
          // Name
          Expanded(
            child: Text(
              entry.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                color: isCurrentUser 
                    ? colorScheme.primary 
                    : colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  entry.points.toString(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank, ColorScheme colorScheme) {
    switch (rank) {
      case 1:
        return Colors.amber[600]!; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.brown[400]!; // Bronze
      default:
        return colorScheme.primary;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.workspace_premium;
      case 2:
        return Icons.military_tech;
      case 3:
        return Icons.emoji_events;
      default:
        return Icons.person;
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
} 