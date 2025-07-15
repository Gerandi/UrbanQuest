import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../organisms/top_navigation_bar.dart';
import '../../molecules/profile_header_card.dart';
import '../../molecules/achievement_showcase.dart';
import '../../molecules/stats_overview_card.dart';
import '../../molecules/quest_history_card.dart';
import '../../molecules/photo_upload_widget.dart';
import '../../atoms/glass_card.dart';
import '../../atoms/custom_button.dart';
import '../../atoms/custom_text_field.dart';
import '../../../data/models/user_model.dart' as UserModel;
import '../../../data/models/achievement_model.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/models/user_stats_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/profile_service.dart';
import '../../../logic/auth_bloc/auth_bloc.dart';
import '../../templates/app_template.dart';

class EnhancedProfileView extends StatefulWidget {
  final Function(AppView, [NavigationData?])? onNavigate;

  const EnhancedProfileView({super.key, this.onNavigate});

  @override
  State<EnhancedProfileView> createState() => _EnhancedProfileViewState();
}

class _EnhancedProfileViewState extends State<EnhancedProfileView> {
  final ProfileService _profileService = ProfileService();
  
  UserModel.User? currentUser;
  List<Achievement> achievements = [];
  List<Achievement> availableAchievements = [];
  List<Quest> questHistory = [];
  List<Quest> inProgressQuests = [];
  UserStats userStats = const UserStats();
  
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load user profile with all related data
      final user = await _profileService.getCurrentUserProfile();
      if (user != null) {
        setState(() {
          currentUser = user;
        });

        // Load additional data in parallel
        await Future.wait([
          _loadUserStats(),
          _loadAchievements(),
          _loadQuestHistory(),
          _checkNewAchievements(),
        ]);
      }
    } catch (e) {
      print('Error loading profile data: $e');
      _showErrorSnackBar('Failed to load profile data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadUserStats() async {
    try {
      if (currentUser != null) {
        final stats = await _profileService.calculateUserStats(currentUser!.id);
        setState(() {
          userStats = stats;
          currentUser = currentUser!.copyWith(
            stats: stats,
            level: stats.currentLevel,
            totalPoints: stats.totalPoints,
          );
        });
      }
    } catch (e) {
      print('Error loading user stats: $e');
    }
  }

  Future<void> _loadAchievements() async {
    try {
      if (currentUser != null) {
        final [earned, available] = await Future.wait([
          _profileService.getUserAchievements(currentUser!.id),
          _profileService.getAvailableAchievements(currentUser!.id),
        ]);
        
        setState(() {
          achievements = earned as List<Achievement>;
          availableAchievements = available as List<Achievement>;
        });
      }
    } catch (e) {
      print('Error loading achievements: $e');
    }
  }

  Future<void> _loadQuestHistory() async {
    try {
      if (currentUser != null) {
        final [completed, inProgress] = await Future.wait([
          _profileService.getUserQuestHistory(currentUser!.id),
          _profileService.getUserInProgressQuests(currentUser!.id),
        ]);
        
        setState(() {
          questHistory = completed as List<Quest>;
          inProgressQuests = inProgress as List<Quest>;
        });
      }
    } catch (e) {
      print('Error loading quest history: $e');
    }
  }

  Future<void> _checkNewAchievements() async {
    try {
      if (currentUser != null) {
        final newAchievements = await _profileService.checkAndUnlockAchievements(currentUser!.id);
        if (newAchievements.isNotEmpty) {
          _showNewAchievements(newAchievements);
          await _loadAchievements(); // Refresh achievements
        }
      }
    } catch (e) {
      print('Error checking new achievements: $e');
    }
  }

  Future<void> _refreshProfile() async {
    setState(() {
      isRefreshing = true;
    });
    await _loadProfileData();
    setState(() {
      isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && currentUser == null) {
      return _buildLoadingView();
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
              onPressed: () => _showSettingsSheet(context),
            ),
            NavigationAction(
              icon: Icons.refresh,
              onPressed: isRefreshing ? null : _refreshProfile,
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
                ProfileHeaderCard(
                  user: currentUser!,
                  onEditProfile: _showEditProfileDialog,
                  onChangePhoto: _showChangePhotoDialog,
                  additionalActions: _buildQuickStats(),
                ).animate()
                 .fadeIn(duration: 600.ms)
                 .slideY(begin: -0.2, end: 0),

                const SizedBox(height: 24),

                // Level Progress Card
                _buildLevelProgressCard()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 100.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Stats Overview
                StatsOverviewCard(
                  stats: userStats,
                  onTap: _showDetailedStats,
                ).animate()
                 .fadeIn(duration: 600.ms, delay: 200.ms)
                 .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Achievements Showcase
                AchievementShowcase(
                  achievements: achievements,
                  availableAchievements: availableAchievements,
                  onViewAll: _showAllAchievements,
                  onAchievementTap: _showAchievementDetail,
                  isCompact: true,
                ).animate()
                 .fadeIn(duration: 600.ms, delay: 300.ms)
                 .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Quest History
                QuestHistoryCard(
                  completedQuests: questHistory,
                  inProgressQuests: inProgressQuests,
                  onViewAll: _showQuestHistoryDetails,
                  onQuestTap: _onQuestTap,
                  isCompact: true,
                ).animate()
                 .fadeIn(duration: 600.ms, delay: 400.ms)
                 .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 100), // Bottom padding for navigation
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
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

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient.map((c) => c.withOpacity(0.1)).toList(),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickStatItem('Level', '${currentUser?.level ?? 1}', Icons.trending_up),
          Container(width: 1, height: 30, color: Colors.grey[300]),
          _buildQuickStatItem('Points', '${userStats.totalPoints}', Icons.star),
          Container(width: 1, height: 30, color: Colors.grey[300]),
          _buildQuickStatItem('Rank', userStats.rankDisplay, Icons.leaderboard),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
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

  Widget _buildLevelProgressCard() {
    final progress = userStats.levelProgress;
    final pointsNeeded = userStats.pointsToNextLevel;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                      Icons.trending_up,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Level Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                '${userStats.totalPoints} pts',
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
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            pointsNeeded > 0 
                ? '$pointsNeeded points to level ${userStats.currentLevel + 1}'
                : 'Max level reached!',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GlassCard(
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
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Edit Profile',
                  onPressed: _showEditProfileDialog,
                  icon: Icons.edit,
                  variant: ButtonVariant.outline,
                  size: ButtonSize.medium,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Share App',
                  onPressed: _shareApp,
                  icon: Icons.share,
                  variant: ButtonVariant.outline,
                  size: ButtonSize.medium,
                ),
              ),
            ],
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
    );
  }

  // Dialog and sheet methods
  void _showChangePhotoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Profile Photo'),
        content: ProfilePhotoUpload(
          currentPhotoUrl: currentUser?.avatar,
          userId: currentUser!.id,
          onPhotoChanged: (photoUrl) {
            setState(() {
              currentUser = currentUser!.copyWith(avatar: photoUrl);
            });
            Navigator.pop(context);
            _showSuccessSnackBar('Profile photo updated!');
          },
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: currentUser?.displayName);
    final bioController = TextEditingController(text: currentUser?.bio);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nameController,
                labelText: 'Display Name',
                prefixIcon: Icons.person,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: bioController,
                labelText: 'Bio',
                prefixIcon: Icons.info,
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newBio = bioController.text.trim();
              
              final success = await _profileService.updateUserProfile(
                userId: currentUser!.id,
                displayName: newName.isNotEmpty ? newName : null,
                bio: newBio.isNotEmpty ? newBio : null,
              );
              
              if (success) {
                setState(() {
                  currentUser = currentUser!.copyWith(
                    displayName: newName,
                    bio: newBio,
                  );
                });
                Navigator.pop(context);
                _showSuccessSnackBar('Profile updated!');
              } else {
                _showErrorSnackBar('Failed to update profile');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
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
              title: const Text('Privacy & Security'),
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
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _showAboutApp();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Navigation methods
  void _showDetailedStats() {
    // Navigate to detailed stats view
    // Implementation depends on your navigation setup
  }

  void _showAllAchievements() {
    // Navigate to achievements view
    // Implementation depends on your navigation setup
  }

  void _showQuestHistoryDetails() {
    // Navigate to quest history view
  }

  void _onQuestTap(Quest quest) {
    // Navigate to quest detail view
  }

  void _showAchievementDetail(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconData(achievement.icon),
              size: 64,
              color: Color(achievement.color),
            ),
            const SizedBox(height: 16),
            Text(achievement.description),
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

  void _showNewAchievements(List<Achievement> achievements) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 New Achievement Unlocked!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: achievements.map((achievement) => ListTile(
            leading: Icon(
              _getIconData(achievement.icon),
              color: Color(achievement.color),
            ),
            title: Text(achievement.title),
            subtitle: Text(achievement.description),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  // Settings methods (simplified implementations)
  void _showNotificationSettings() {
    // Implementation for notification settings
  }

  void _showPrivacySettings() {
    // Implementation for privacy settings
  }

  void _showHelpAndSupport() {
    // Implementation for help and support
  }

  void _showAboutApp() {
    // Implementation for about app
  }

  void _shareApp() {
    _showSuccessSnackBar('🎉 Thanks for wanting to share Urban Quest!');
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

  // Helper methods
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

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}