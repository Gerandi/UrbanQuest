import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../atoms/glass_card.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/quest_model.dart';

class QuestHistoryCard extends StatelessWidget {
  final List<Quest> completedQuests;
  final List<Quest> inProgressQuests;
  final VoidCallback? onViewAll;
  final Function(Quest)? onQuestTap;
  final bool isCompact;

  const QuestHistoryCard({
    super.key,
    required this.completedQuests,
    this.inProgressQuests = const [],
    this.onViewAll,
    this.onQuestTap,
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
          if (completedQuests.isEmpty && inProgressQuests.isEmpty)
            _buildEmptyState()
          else
            _buildQuestList(),
          if (onViewAll != null && completedQuests.length > (isCompact ? 3 : 5))
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
                Icons.history,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quest History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${completedQuests.length} completed',
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
              Icons.map_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No completed quests yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start exploring to see your quest history here!',
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

  Widget _buildQuestList() {
    final displayQuests = isCompact 
        ? completedQuests.take(3).toList()
        : completedQuests.take(5).toList();

    return Column(
      children: [
        // In Progress Section
        if (inProgressQuests.isNotEmpty) ...[
          _buildSectionTitle('In Progress', inProgressQuests.length, Colors.orange),
          const SizedBox(height: 8),
          ...inProgressQuests.take(isCompact ? 1 : 2).map((quest) => 
            _buildQuestItem(quest, false, inProgressQuests.indexOf(quest))),
          if (completedQuests.isNotEmpty) const SizedBox(height: 16),
        ],

        // Completed Section
        if (completedQuests.isNotEmpty) ...[
          _buildSectionTitle('Completed', completedQuests.length, Colors.green),
          const SizedBox(height: 8),
          ...displayQuests.map((quest) => 
            _buildQuestItem(quest, true, completedQuests.indexOf(quest))),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestItem(Quest quest, bool isCompleted, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildQuestIcon(quest, isCompleted),
        title: Text(
          quest.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quest in ${quest.city}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '${quest.estimatedDuration} min',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  isCompleted ? Icons.star : Icons.hourglass_empty,
                  size: 12,
                  color: isCompleted ? Colors.amber : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  isCompleted ? '${quest.points} pts' : 'In progress',
                  style: TextStyle(
                    color: isCompleted ? Colors.amber[700] : Colors.orange[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDifficultyBadge(quest.difficulty),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
        onTap: () => onQuestTap?.call(quest),
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
     .fadeIn(duration: 300.ms)
     .slideX(begin: 0.3, end: 0);
  }

  Widget _buildQuestIcon(Quest quest, bool isCompleted) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted 
              ? [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0.1)]
              : [Colors.orange.withOpacity(0.2), Colors.orange.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        isCompleted ? Icons.check_circle : Icons.play_circle_outline,
        color: isCompleted ? Colors.green : Colors.orange,
        size: 24,
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = Colors.green;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'hard':
        color = Colors.red;
        break;
      case 'expert':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildViewAllButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: TextButton.icon(
          onPressed: onViewAll,
          icon: const Icon(Icons.history),
          label: Text('View All ${completedQuests.length} Quests'),
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
}