import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/achievement_model.dart';
import '../atoms/glass_card.dart';

class AchievementShowcase extends StatelessWidget {
  final List<Achievement> achievements;
  final List<Achievement> availableAchievements;
  final VoidCallback? onViewAll;
  final Function(Achievement)? onAchievementTap;
  final bool isCompact;

  const AchievementShowcase({
    super.key,
    required this.achievements,
    this.availableAchievements = const [],
    this.onViewAll,
    this.onAchievementTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (achievements.isEmpty && availableAchievements.isEmpty)
            _buildEmptyState()
          else
            _buildAchievementGrid(),
          if (onViewAll != null && achievements.length > (isCompact ? 4 : 8))
            _buildViewAllButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Achievements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${achievements.length} unlocked',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text('View All'),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No achievements yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete quests to unlock achievements!',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementGrid() {
    final displayAchievements = isCompact 
        ? achievements.take(4).toList()
        : achievements.take(8).toList();
    
    // Add locked achievements if we have available ones
    final lockedAchievements = availableAchievements
        .where((available) => !achievements.any((earned) => earned.id == available.id))
        .take(isCompact ? 2 : 4)
        .toList();

    final allToDisplay = [...displayAchievements, ...lockedAchievements];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isCompact ? 4 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: allToDisplay.length,
      itemBuilder: (context, index) {
        if (index < displayAchievements.length) {
          return _buildAchievementItem(displayAchievements[index], true, index);
        } else {
          final lockedIndex = index - displayAchievements.length;
          return _buildAchievementItem(lockedAchievements[lockedIndex], false, index);
        }
      },
    );
  }

  Widget _buildAchievementItem(Achievement achievement, bool isUnlocked, int index) {
    final color = isUnlocked ? Color(achievement.color) : Colors.grey;
    
    return GestureDetector(
      onTap: () => onAchievementTap?.call(achievement),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(isUnlocked ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: color,
                width: isUnlocked ? 2 : 1,
              ),
              boxShadow: isUnlocked ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _getIconData(achievement.icon),
                    color: color,
                    size: 24,
                  ),
                ),
                if (!isUnlocked)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.lock,
                      color: Colors.grey,
                      size: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? Colors.black87 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
     .fadeIn(duration: 300.ms)
     .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }

  Widget _buildViewAllButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: TextButton.icon(
          onPressed: onViewAll,
          icon: const Icon(Icons.grid_view),
          label: Text('View All ${achievements.length} Achievements'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'star': return Icons.star;
      case 'flag': return Icons.flag;
      case 'camera': return Icons.camera_alt;
      case 'explore': return Icons.explore;
      case 'trophy': return Icons.emoji_events;
      case 'location': return Icons.location_on;
      case 'photo': return Icons.photo_camera;
      case 'walking': return Icons.directions_walk;
      case 'city': return Icons.location_city;
      case 'heart': return Icons.favorite;
      case 'fire': return Icons.local_fire_department;
      case 'diamond': return Icons.diamond;
      case 'crown': return Icons.workspace_premium;
      case 'shield': return Icons.security;
      case 'rocket': return Icons.rocket_launch;
      default: return Icons.star;
    }
  }
}