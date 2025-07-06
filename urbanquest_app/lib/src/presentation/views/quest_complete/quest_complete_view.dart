import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';  // Comment out for now
import '../../atoms/custom_card.dart';
import '../../atoms/custom_button.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/models/achievement_model.dart';
import '../../../data/services/quest_completion_service.dart';
import '../../templates/app_template.dart';
import '../../../data/models/quest_stop_model.dart';

class QuestCompleteView extends StatefulWidget {
  final String questId;
  final Function(AppView, [NavigationData?])? onNavigate;
  final List<QuestStop>? questStops;
  final List<Map<String, dynamic>>? capturedPhotos;
  final Duration? duration;
  final Map<String, dynamic>? stats;

  const QuestCompleteView({
    super.key,
    required this.questId,
    this.onNavigate,
    this.questStops,
    this.capturedPhotos,
    this.duration,
    this.stats,
  });

  @override
  State<QuestCompleteView> createState() => _QuestCompleteViewState();
}

class _QuestCompleteViewState extends State<QuestCompleteView> {
  final QuestCompletionService _completionService = QuestCompletionService();
  Map<String, dynamic>? _completionData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCompletionData();
  }

  Future<void> _loadCompletionData() async {
    try {
      print('QuestCompleteView: Loading completion data for quest ${widget.questId}');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _completionService.calculateCompletionData(
        questId: widget.questId,
        questStops: widget.questStops ?? [],
        capturedPhotos: widget.capturedPhotos ?? [],
        duration: widget.duration ?? const Duration(minutes: 30),
        stats: widget.stats ?? {},
      );
      print('QuestCompleteView: Completion data calculated successfully');
      
      // Save completion data to Supabase
      await _completionService.saveQuestCompletion(data);
      print('QuestCompleteView: Supabase updated successfully');

      setState(() {
        _completionData = data;
        _isLoading = false;
      });
      
      print('QuestCompleteView: State updated, loading complete');
    } catch (e) {
      print('QuestCompleteView: Error loading completion data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Unable to load completion data',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Try Again',
                    onPressed: _loadCompletionData,
                    variant: ButtonVariant.outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final quest = _completionData!['quest'] as Quest?;
    final pointsEarned = _completionData!['pointsEarned'] as int;
    final tasksCompleted = _completionData!['tasksCompleted'] as int;
    final totalTasks = _completionData!['totalTasks'] as int;
    final failedTasks = _completionData!['failedTasks'] as List<String>;
    final leveledUp = _completionData!['leveledUp'] as bool;
    final newLevel = _completionData!['newLevel'] as int;
    final achievementDetails = _completionData!['achievementDetails'] as List<Achievement>;
    final photosTaken = (_completionData!['photosTaken'] as List<dynamic>?)?.cast<String>() ?? <String>[];
    final timeSpent = _completionData!['totalTimeSpent'] as Duration;
    final distanceWalked = _completionData!['distanceWalked'] as double;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Celebration Header
                _buildCelebrationHeader(theme, pointsEarned)
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),

                const SizedBox(height: 32),

                // Quest Summary
                if (quest != null)
                  _buildQuestSummary(quest, theme)
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 200.ms)
                      .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 24),

                // Stats Card
                _buildStatsCard(theme, pointsEarned, tasksCompleted, totalTasks, timeSpent, distanceWalked)
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 400.ms)
                    .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 24),

                // Level Up Card (if leveled up)
                if (leveledUp)
                  _buildLevelUpCard(theme, newLevel)
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 500.ms)
                      .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 24),

                // Failed Tasks (if any)
                if (failedTasks.isNotEmpty)
                  _buildFailedTasksCard(theme, failedTasks)
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 600.ms)
                      .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 24),

                // Achievements
                if (achievementDetails.isNotEmpty)
                  _buildAchievements(achievementDetails, theme)
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 700.ms)
                      .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 24),

                // Photo Gallery
                if (photosTaken.isNotEmpty)
                  _buildPhotoGallery(photosTaken, theme)
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 800.ms)
                      .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 32),

                // Action Buttons
                _buildActionButtons(theme)
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 1000.ms)
                    .slideY(begin: 0.3, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCelebrationHeader(ThemeData theme, int pointsEarned) {
    return Column(
      children: [
        // Trophy Animation
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.amber.shade300,
                Colors.amber.shade600,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events,
            size: 60,
            color: Colors.white,
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3))
            .animate()
            .rotate(end: 0.02)
            .then()
            .rotate(end: -0.02)
            .then()
            .rotate(end: 0.0),

        const SizedBox(height: 24),

        // Congratulations Text
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Colors.amber],
          ).createShader(bounds),
          child: Text(
            'Quest Complete!',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Text(
          'You earned $pointsEarned points!',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
        ),

        const SizedBox(height: 16),

        // Confetti Effect
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (index) {
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: [Colors.amber, Colors.orange, Colors.red, Colors.pink, Colors.purple][index],
                shape: BoxShape.circle,
              ),
            )
                .animate(delay: (index * 200).ms)
                .slideY(begin: 0, end: -1, duration: 1000.ms)
                .then()
                .slideY(begin: -1, end: 0, duration: 1000.ms);
          }),
        ),
      ],
    );
  }

  Widget _buildQuestSummary(Quest quest, ThemeData theme) {
    return CustomCard(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(quest.coverImageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      quest.city,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(theme, 'Points Earned', '${quest.points}', Icons.emoji_events, Colors.amber),
              _buildStatItem(theme, 'Time Taken', '78 min', Icons.access_time, Colors.blue),
              _buildStatItem(theme, 'Photos', '12', Icons.camera_alt, Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsCard(ThemeData theme, int pointsEarned, int tasksCompleted, int totalTasks, Duration timeSpent, double distanceWalked) {
    final completionPercentage = totalTasks > 0 ? (tasksCompleted / totalTasks * 100).round() : 0;
    final timeString = '${timeSpent.inMinutes} min ${timeSpent.inSeconds % 60} sec';
    final distanceString = distanceWalked >= 1.0 
        ? '${distanceWalked.toStringAsFixed(1)} km'
        : '${(distanceWalked * 1000).round()} m';

    return CustomCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.assessment,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Quest Statistics',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(theme, 'Points Earned', pointsEarned.toString(), Icons.star, Colors.amber),
              ),
              Expanded(
                child: _buildStatItem(theme, 'Tasks Completed', '$tasksCompleted/$totalTasks', Icons.task_alt, Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(theme, 'Time Spent', timeString, Icons.timer, Colors.blue),
              ),
              Expanded(
                child: _buildStatItem(theme, 'Distance', distanceString, Icons.directions_walk, Colors.purple),
              ),
            ],
          ),
          if (completionPercentage < 100) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: completionPercentage / 100,
              backgroundColor: theme.colorScheme.surface,
              valueColor: AlwaysStoppedAnimation<Color>(
                completionPercentage >= 80 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$completionPercentage% completion rate',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelUpCard(ThemeData theme, int newLevel) {
    return CustomCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.blue.shade400],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.trending_up,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  'Level Up!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'You reached Level $newLevel',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedTasksCard(ThemeData theme, List<String> failedTasks) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                'Missed Tasks',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You can revisit these tasks on your next quest:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          ...failedTasks.take(3).map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
          if (failedTasks.length > 3)
            Text(
              'and ${failedTasks.length - 3} more...',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievements(List<Achievement> achievements, ThemeData theme) {
    if (achievements.isEmpty) return const SizedBox.shrink();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Colors.purple,
              ),
              const SizedBox(width: 8),
              Text(
                'New Achievements',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...achievements.map((achievement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.1),
                      Colors.pink.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.purple.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getAchievementIcon(achievement.id),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            achievement.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+${achievement.points}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery(List<String> photos, ThemeData theme) {
    if (photos.isEmpty) return const SizedBox.shrink();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Quest Photos',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(photos[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Share Your Achievement',
            onPressed: () => _shareAchievement(),
            icon: Icons.share,
            size: ButtonSize.large,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'View Leaderboard',
                onPressed: () => widget.onNavigate?.call(AppView.leaderboard),
                variant: ButtonVariant.outline,
                icon: Icons.emoji_events,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Explore More',
                onPressed: () => widget.onNavigate?.call(AppView.citySelection),
                variant: ButtonVariant.outline,
                icon: Icons.explore,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Back to Home',
            onPressed: () => widget.onNavigate?.call(AppView.home),
            variant: ButtonVariant.ghost,
            icon: Icons.home,
          ),
        ),
      ],
    );
  }

  IconData _getAchievementIcon(String achievementId) {
    switch (achievementId) {
      case 'first_quest':
        return Icons.star;
      case 'photo_master':
        return Icons.camera_alt;
      case 'trivia_champion':
        return Icons.psychology;
      case 'speed_runner':
        return Icons.bolt;
      default:
        return Icons.emoji_events;
    }
  }

  void _shareAchievement() {
    // Implement sharing functionality
  }
} 