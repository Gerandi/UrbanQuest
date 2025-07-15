import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../atoms/glass_card.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_stats_model.dart';

class StatsOverviewCard extends StatelessWidget {
  final UserStats stats;
  final bool isCompact;
  final VoidCallback? onTap;

  const StatsOverviewCard({
    super.key,
    required this.stats,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          if (isCompact)
            _buildCompactStats()
          else
            _buildDetailedStats(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.secondaryGradient,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.analytics,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Your Adventure Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        if (onTap != null)
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: onTap,
          ),
      ],
    );
  }

  Widget _buildCompactStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            icon: Icons.flag,
            value: '${stats.questsCompleted}',
            label: 'Quests',
            color: AppColors.primary,
            index: 0,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            icon: Icons.star,
            value: '${stats.totalPoints}',
            label: 'Points',
            color: AppColors.accent,
            index: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.flag,
                value: '${stats.questsCompleted}',
                label: 'Quests',
                color: AppColors.primary,
                index: 0,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.location_on,
                value: '${stats.stopsVisited}',
                label: 'Stops',
                color: AppColors.secondary,
                index: 1,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.camera_alt,
                value: '${stats.photosShared}',
                label: 'Photos',
                color: AppColors.accent,
                index: 2,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.directions_walk,
                value: '${stats.totalDistance.toStringAsFixed(1)} km',
                label: 'Walked',
                color: Colors.green,
                index: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.emoji_events,
                value: '${stats.achievementsEarned}',
                label: 'Achievements',
                color: Colors.amber,
                index: 4,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.local_fire_department,
                value: '${stats.currentStreak}',
                label: 'Day Streak',
                color: Colors.orange,
                index: 5,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.timer,
                value: '${_formatTime(stats.totalTimeSpent)}',
                label: 'Time',
                color: Colors.purple,
                index: 6,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.trending_up,
                value: '#${stats.leaderboardRank}',
                label: 'Rank',
                color: Colors.blue,
                index: 7,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required int index,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ).animate(delay: Duration(milliseconds: index * 100))
     .fadeIn(duration: 400.ms)
     .slideY(begin: 0.3, end: 0);
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours < 24) return '${hours}h ${remainingMinutes}m';
    final days = hours ~/ 24;
    final remainingHours = hours % 24;
    return '${days}d ${remainingHours}h';
  }
}