import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../organisms/top_navigation_bar.dart';
import '../../atoms/custom_button.dart';
import '../../atoms/custom_avatar.dart';
import '../../atoms/custom_text_field.dart';
import '../../../data/models/user_model.dart' as UserModel;
import '../../../data/models/achievement_model.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../core/constants/app_colors.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../templates/app_template.dart';

class ProfileView extends StatefulWidget {
  final Function(AppView, [NavigationData?])? onNavigate;

  const ProfileView({super.key, this.onNavigate});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final UserProfileRepository _profileRepository = UserProfileRepository();
  UserModel.User? currentUser;
  List<Achievement> achievements = [];
  List<Quest> questHistory = [];
  int leaderboardPosition = -1;
  bool isLoading = true;
  bool isRefreshing = false;
  bool questNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationPreferences();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load user profile
      final user = await _profileRepository.getCurrentUserProfile();
      if (user != null) {
        setState(() {
          currentUser = user;
        });

        // Load additional data in parallel
        await Future.wait([
          _loadUserStats(),
          _loadAchievements(),
          _loadQuestHistory(),
          _loadLeaderboardPosition(),
        ]);
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final stats = await _profileRepository.calculateUserStats();
      setState(() {
        currentUser = currentUser?.copyWith(stats: stats);
      });
    } catch (e) {
      print('Error loading user stats: $e');
    }
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        questNotificationsEnabled = prefs.getBool('quest_notifications_enabled') ?? true;
      });
    } catch (e) {
      print('Error loading notification preferences: $e');
    }
  }

  Future<void> _saveNotificationPreference(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('quest_notifications_enabled', enabled);
      setState(() {
        questNotificationsEnabled = enabled;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled 
            ? 'Quest notifications enabled' 
            : 'Quest notifications disabled'),
          backgroundColor: enabled ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      print('Error saving notification preference: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving notification preference'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting account...'),
            ],
          ),
        ),
      );

      // Delete user account through repository
      final success = await _profileRepository.deleteUserAccount();
      
      if (mounted) Navigator.of(context).pop(); // Close loading dialog
      
      if (success) {
        // Sign out user
        context.read<AuthBloc>().add(LogoutEvent());
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to delete account');
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // Close loading dialog
      
      print('Error deleting account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAchievements() async {
    try {
      final userAchievements = await _profileRepository.getUserAchievements();
      setState(() {
        achievements = userAchievements;
      });
    } catch (e) {
      print('Error loading achievements: $e');
    }
  }

  Future<void> _loadQuestHistory() async {
    try {
      final history = await _profileRepository.getUserQuestHistory();
      setState(() {
        questHistory = history;
      });
    } catch (e) {
      print('Error loading quest history: $e');
    }
  }

  Future<void> _loadLeaderboardPosition() async {
    try {
      final position = await _profileRepository.getUserLeaderboardPosition();
      setState(() {
        leaderboardPosition = position;
      });
    } catch (e) {
      print('Error loading leaderboard position: $e');
    }
  }

  Future<void> _refreshProfile() async {
    setState(() {
      isRefreshing = true;
    });
    await _loadUserData();
    setState(() {
      isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && currentUser == null) {
    return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.primaryGradient,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFfef3f2), // Orange-50
            Color(0xFFfdf2f8), // Pink-50
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: TopNavigationBar(
        title: 'Profile',
        actions: [
          NavigationAction(
            icon: Icons.settings,
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
        body: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
                _buildProfileHeader(currentUser!)
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.2, end: 0),

                const SizedBox(height: 24),

                // Level Progress Card
                _buildLevelProgressCard(currentUser!)
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 100.ms)
                    .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 24),

            // Stats Card
                _buildStatsCard(currentUser!)
                .animate()
                .fadeIn(duration: 600.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Leaderboard Position Card
                _buildLeaderboardCard()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 300.ms)
                    .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 24),

            // Achievements Section
                _buildAchievementsSection()
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 24),

                // Quest History
                _buildQuestHistorySection()
                .animate()
                    .fadeIn(duration: 600.ms, delay: 500.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 24),

            // Quick Actions
                _buildQuickActions()
                .animate()
                    .fadeIn(duration: 600.ms, delay: 600.ms)
                .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 100), // Bottom padding for navigation
          ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel.User user) {
    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: AppColors.whiteOpacity90,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.whiteOpacity30,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOpacity10,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar and Basic Info
          Row(
              children: [
                GestureDetector(
                  onTap: _showChangePhotoDialog,
                  child: Stack(
            children: [
                             CustomAvatar(
                 imageUrl: user.avatar,
                 initials: _getInitials(user.displayName),
                 size: AvatarSize.extraLarge,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
               ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                      user.displayName,
                              style: const TextStyle(
                                fontSize: 20,
                        fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: _showEditProfileDialog,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                    ),
                    Text(
                      user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Level ${user.level} Explorer',
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
                ],
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildLevelProgressCard(UserModel.User user) {
    final progress = _calculateLevelProgress(user.totalPoints);
    final pointsNeeded = _getPointsNeededForNextLevel(user.totalPoints);

    return Container(
            decoration: BoxDecoration(
        color: AppColors.whiteOpacity90,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.whiteOpacity30,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOpacity10,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                  'Level Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                      ),
                    ),
                    Text(
                  '${user.totalPoints} pts',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
              pointsNeeded > 0 
                  ? '$pointsNeeded points to level ${user.level + 1}'
                  : 'Max level reached!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildStatsCard(UserModel.User user) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteOpacity90,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.whiteOpacity30,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOpacity10,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Adventure Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.flag,
                    value: '${user.stats?.questsCompleted ?? 0}',
                    label: 'Quests',
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.location_on,
                    value: '${user.stats?.stopsVisited ?? 0}',
                    label: 'Stops',
                    color: AppColors.secondary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.camera_alt,
                    value: '${user.stats?.photosShared ?? 0}',
                    label: 'Photos',
                    color: AppColors.accent,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.directions_walk,
                    value: '${user.stats?.totalDistance.toStringAsFixed(1) ?? 0.0} km',
                    label: 'Walked',
                    color: Colors.green,
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteOpacity90,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.whiteOpacity30,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOpacity10,
            blurRadius: 20,
            offset: const Offset(0, 8),
                  ),
                ],
              ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
              Container(
              padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leaderboard Position',
                  style: TextStyle(
                      fontSize: 16,
                    fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    leaderboardPosition > 0 
                        ? '#$leaderboardPosition'
                        : 'Loading...',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                ),
              ),
            ],
          ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () {
                if (widget.onNavigate != null) {
                  widget.onNavigate!(AppView.leaderboard);
                }
            },
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
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
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteOpacity90,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.whiteOpacity30,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOpacity10,
            blurRadius: 20,
            offset: const Offset(0, 8),
      ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            const SizedBox(height: 16),
            if (achievements.isEmpty)
              Center(
                child: Column(
        children: [
          Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
                      'Complete quests to unlock achievements!',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    final achievement = achievements[index];
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Color(achievement.color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Color(achievement.color),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _getIconData(achievement.icon),
                              color: Color(achievement.color),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            achievement.title,
                            style: const TextStyle(
                              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestHistorySection() {
    final completedQuests = questHistory; // All quests in history are completed
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteOpacity90,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.whiteOpacity30,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOpacity10,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          const SizedBox(height: 16),
            if (completedQuests.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                      Icons.map_outlined,
                    size: 48,
                      color: Colors.grey[400],
                  ),
                    const SizedBox(height: 8),
                  Text(
                      'No completed quests yet.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        if (widget.onNavigate != null) {
                          widget.onNavigate!(AppView.questList);
                        }
                      },
                      child: const Text('Explore Quests'),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: completedQuests.take(3).length,
                itemBuilder: (context, index) {
                  final quest = completedQuests[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.flag,
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        quest.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Completed quest in ${quest.city}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          Text('${quest.points} pts'),
                ],
              ),
            ),
                  );
                },
              ),
            if (completedQuests.length > 3)
              Center(
                child: TextButton(
                  onPressed: _showFullQuestHistory,
                  child: Text('View all ${completedQuests.length} quests'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
        decoration: BoxDecoration(
        color: AppColors.whiteOpacity90,
        borderRadius: BorderRadius.circular(20),
          border: Border.all(
          color: AppColors.whiteOpacity30,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOpacity10,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Edit Profile',
              onPressed: _showEditProfileDialog,
              icon: Icons.edit,
              variant: ButtonVariant.outline,
              size: ButtonSize.large,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Share App',
              onPressed: _shareApp,
              icon: Icons.share,
              variant: ButtonVariant.outline,
              size: ButtonSize.large,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Sign Out',
              onPressed: _showSignOutDialog,
              icon: Icons.logout,
              variant: ButtonVariant.outline,
              size: ButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  int _calculateLevelProgress(int points) {
    // Calculate progress within current level
    final currentLevelMinPoints = _getLevelMinPoints(currentUser?.level ?? 1);
    final nextLevelMinPoints = _getLevelMinPoints((currentUser?.level ?? 1) + 1);
    final progressInLevel = points - currentLevelMinPoints;
    final levelRange = nextLevelMinPoints - currentLevelMinPoints;
    return ((progressInLevel / levelRange) * 100).round().clamp(0, 100);
  }

  int _getPointsNeededForNextLevel(int points) {
    final nextLevelMinPoints = _getLevelMinPoints((currentUser?.level ?? 1) + 1);
    return (nextLevelMinPoints - points).clamp(0, double.infinity).toInt();
  }

  int _getLevelMinPoints(int level) {
    if (level <= 1) return 0;
    if (level == 2) return 100;
    if (level == 3) return 300;
    if (level == 4) return 600;
    if (level == 5) return 1000;
    if (level == 6) return 1500;
    return 1500 + ((level - 6) * 500);
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'star': return Icons.star;
      case 'flag': return Icons.flag;
      case 'camera': return Icons.camera_alt;
      case 'explore': return Icons.explore;
      case 'trophy': return Icons.emoji_events;
      default: return Icons.star;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showChangePhotoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Photo'),
        content: const Text('Choose photo source'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        final imageBytes = await image.readAsBytes();
        final photoUrl = await _profileRepository.uploadProfilePhoto(currentUser!.id, imageBytes);
        if (photoUrl != null) {
          await _refreshProfile();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo updated!')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating photo: $e')),
        );
      }
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: currentUser?.displayName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: nameController,
              labelText: 'Display Name',
              prefixIcon: Icons.person,
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != currentUser?.displayName) {
                final success = await _profileRepository.updateUserProfile(currentUser!.id, {
                  'display_name': newName,
                });
                
                if (success) {
                  await _refreshProfile();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated!')),
                    );
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
             ),
          ],
        ),
    );
  }

  void _showFullQuestHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quest History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: questHistory.length,
            itemBuilder: (context, index) {
              final quest = questHistory[index];
                             return ListTile(
                leading: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                 ),
                title: Text(quest.title),
                subtitle: Text(quest.description),
                trailing: Text('${quest.points} pts'),
               );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showNotificationSettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showPrivacySettings();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showHelpAndSupport();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
        children: [
            SwitchListTile(
              title: const Text('Quest Notifications'),
              subtitle: const Text('Get notified when near quest locations'),
              value: questNotificationsEnabled,
              onChanged: (value) {
                _saveNotificationPreference(value);
              },
              secondary: const Icon(Icons.location_on),
            ),
            SwitchListTile(
              title: const Text('Achievement Alerts'),
              subtitle: const Text('Get notified when you unlock achievements'),
              value: true,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value 
                      ? 'Achievement notifications enabled' 
                      : 'Achievement notifications disabled'),
                  ),
                );
              },
              secondary: const Icon(Icons.emoji_events),
            ),
            SwitchListTile(
              title: const Text('Leaderboard Updates'),
              subtitle: const Text('Get notified about ranking changes'),
              value: false,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value 
                      ? 'Leaderboard notifications enabled' 
                      : 'Leaderboard notifications disabled'),
                  ),
                );
              },
              secondary: const Icon(Icons.leaderboard),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Profile Visibility'),
              subtitle: const Text('Control who can see your profile'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showProfileVisibilityOptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_off),
              title: const Text('Location Privacy'),
              subtitle: const Text('Manage location sharing preferences'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showLocationPrivacyOptions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('Delete Account'),
              subtitle: const Text('Permanently delete your account and data'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showDeleteAccountDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Privacy Policy'),
              subtitle: const Text('Read our privacy policy'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {
                Navigator.pop(context);
                _showPrivacyPolicy();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpAndSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('FAQ'),
              subtitle: const Text('Frequently asked questions'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showFAQ();
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_support),
              title: const Text('Contact Support'),
              subtitle: const Text('Get help from our team'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showContactSupport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Report a Bug'),
              subtitle: const Text('Help us improve the app'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showBugReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('Rate App'),
              subtitle: const Text('Leave a review on the app store'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {
                Navigator.pop(context);
                _rateApp();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Urban Quest'),
              subtitle: const Text('App version and information'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showAboutApp();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProfileVisibilityOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Visibility'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Public'),
              subtitle: const Text('Anyone can see your profile and achievements'),
              value: 'public',
              groupValue: 'public', // Make this dynamic
              onChanged: (value) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile set to public')),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('Friends Only'),
              subtitle: const Text('Only your friends can see your profile'),
              value: 'friends',
              groupValue: 'public',
              onChanged: (value) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile set to friends only')),
                );
              },
            ),
            RadioListTile<String>(
              title: const Text('Private'),
              subtitle: const Text('Hide your profile from others'),
              value: 'private',
              groupValue: 'public',
              onChanged: (value) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile set to private')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLocationPrivacyOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Privacy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Share Quest Locations'),
              subtitle: const Text('Allow others to see where you completed quests'),
              value: true,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value 
                      ? 'Quest location sharing enabled' 
                      : 'Quest location sharing disabled'),
                  ),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Real-time Location'),
              subtitle: const Text('Share your current location with friends'),
              value: false,
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value 
                      ? 'Real-time location sharing enabled' 
                      : 'Real-time location sharing disabled'),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning,
              color: Colors.red,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'This action cannot be undone. All your quest progress, achievements, and account data will be permanently deleted.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Urban Quest Privacy Policy\n\n'
            'We respect your privacy and are committed to protecting your personal data.\n\n'
            '1. Data Collection: We collect location data only when you use quest features.\n\n'
            '2. Data Usage: Your data is used to provide quest functionality and improve the app.\n\n'
            '3. Data Sharing: We do not sell or share your personal data with third parties.\n\n'
            '4. Data Security: We implement industry-standard security measures.\n\n'
            '5. Your Rights: You can request data deletion or modification at any time.\n\n'
            'Contact us at privacy@urbanquest.app for questions.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFAQ() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView(
            children: const [
              ExpansionTile(
                title: Text('How do I start a quest?'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Select a city from the Cities tab, choose a quest, and tap "Start Quest". Make sure location services are enabled.'),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('Why isn\'t my location working?'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Ensure location permissions are granted and GPS is enabled. Try restarting the app if issues persist.'),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('How do I earn points?'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Complete quest stops, take photos, answer trivia questions, and finish entire quests to earn points.'),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('Can I play quests offline?'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Basic quest information is cached, but you need internet connection for full functionality and progress syncing.'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              subtitle: const Text('support@urbanquest.app'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening email app...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Live Chat'),
              subtitle: const Text('Chat with our support team'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Live chat coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.discord),
              title: const Text('Discord Community'),
              subtitle: const Text('Join our community server'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Discord link copied to clipboard')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBugReport() {
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Help us improve Urban Quest by reporting bugs or issues you encounter.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Describe the issue',
                prefixIcon: const Icon(Icons.bug_report),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 4,
              minLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (descriptionController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bug report submitted. Thank you!')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening app store for rating...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Urban Quest'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.explore, color: AppColors.primary, size: 32),
                SizedBox(width: 12),
                Text(
                  'Urban Quest',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Build: 1.0.0+1'),
            SizedBox(height: 16),
            Text(
              'Discover cities through interactive scavenger hunts and location-based adventures. Explore Albanian heritage and culture while earning achievements and competing with friends.',
              style: TextStyle(height: 1.4),
            ),
            SizedBox(height: 16),
            Text(
              '© 2024 Urban Quest Team\nMade with ❤️ for Albanian culture',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Thanks for wanting to share Urban Quest!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(LogoutEvent());
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
} 