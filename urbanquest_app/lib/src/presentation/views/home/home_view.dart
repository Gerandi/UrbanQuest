import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/repositories/quest_repository.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../templates/app_template.dart';
import '../../molecules/quest_card.dart';

class HomeView extends StatefulWidget {
  final Function(AppView, [NavigationData?])? onNavigate;

  const HomeView({super.key, this.onNavigate});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final QuestRepository _questRepository = QuestRepository();
  final UserProfileRepository _userProfileRepository = UserProfileRepository();
  
  User? currentUser;
  List<Quest> featuredQuests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      setState(() => isLoading = true);
      
      // Load user profile and featured quests in parallel
      final results = await Future.wait([
        _userProfileRepository.getCurrentUserProfile(),
        _questRepository.getPopularQuests(limit: 3),
      ]);
      
      final user = results[0] as User?;
      final quests = results[1] as List<Quest>;
      
      if (mounted) {
        setState(() {
          currentUser = user;
          featuredQuests = quests;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading home data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }
    
    return _buildHomeContent();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your adventure...'),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection()
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.2, end: 0),
            
            const SizedBox(height: 24),
            
            // Quick Stats Section
            _buildQuickStatsSection()
                .animate()
                .fadeIn(duration: 600.ms, delay: 100.ms)
                .slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 24),
            
            // Featured Quests Section
            _buildFeaturedQuestsSection()
                .animate()
                .fadeIn(duration: 600.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 100), // Bottom padding for navigation
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    if (currentUser == null) return const SizedBox.shrink();
    
    final firstName = currentUser!.displayName.split(' ').first;
    final currentLevel = currentUser!.level;
    final totalPoints = currentUser!.totalPoints;
    final pointsToNextLevel = _getPointsToNextLevel(currentLevel);
    final pointsInCurrentLevel = _getPointsInCurrentLevel(totalPoints, currentLevel);
    final levelProgress = pointsInCurrentLevel / pointsToNextLevel;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $firstName!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Level $currentLevel Explorer',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Points',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    '$totalPoints',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Level Progress
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress to Level ${currentLevel + 1}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${(levelProgress * 100).round()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: levelProgress.clamp(0.0, 1.0),
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    if (currentUser?.stats == null) return const SizedBox.shrink();
    
    final stats = [
      {
        'label': 'Quests',
        'value': '${currentUser!.stats?.questsCompleted ?? 0}',
        'icon': Icons.explore,
        'color': AppColors.primary,
      },
      {
        'label': 'Distance',
        'value': '${currentUser!.stats?.totalDistance.toStringAsFixed(1) ?? 0.0} km',
        'icon': Icons.navigation,
        'color': AppColors.secondary,
      },
      {
        'label': 'Photos',
        'value': '${currentUser!.stats?.photosShared ?? 0}',
        'icon': Icons.camera_alt,
        'color': AppColors.accent,
      },
    ];

    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: index == 0 ? 0 : 6,
              right: index == stats.length - 1 ? 0 : 6,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stat['value'] as String,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: stat['color'] as Color,
                  ),
                ),
                Text(
                  stat['label'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeaturedQuestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Quests',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            GestureDetector(
              onTap: () {
                widget.onNavigate?.call(AppView.citySelection);
              },
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (featuredQuests.isEmpty)
          _buildEmptyQuestsState()
        else
          Column(
            children: featuredQuests.map((quest) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: QuestCard(
                quest: quest,
                onTap: () {
                  widget.onNavigate?.call(
                    AppView.questDetail,
                    NavigationData(questId: quest.id),
                  );
                },
              ),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyQuestsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.explore_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No quests available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Run the SQL file to add quest data!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getPointsToNextLevel(int level) {
    // XP required for each level increases exponentially
    return 100.0 * (level * 1.5);
  }

  double _getPointsInCurrentLevel(int totalPoints, int level) {
    // Calculate points accumulated in current level
    double pointsUsed = 0;
    for (int i = 1; i < level; i++) {
      pointsUsed += _getPointsToNextLevel(i);
    }
    return (totalPoints - pointsUsed).clamp(0.0, _getPointsToNextLevel(level));
    }
  }

