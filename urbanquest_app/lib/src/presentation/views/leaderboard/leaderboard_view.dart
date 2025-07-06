import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../atoms/custom_avatar.dart';
import '../../atoms/custom_button.dart';
import '../../atoms/custom_card.dart';
import '../../templates/app_template.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/leaderboard_entry_model.dart';
import '../../../core/services/supabase_service.dart';


class LeaderboardView extends StatefulWidget {
  final Function(AppView, [NavigationData?])? onNavigate;

  const LeaderboardView({super.key, this.onNavigate});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> with TickerProviderStateMixin {
  List<LeaderboardEntry> leaderboard = [];
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? currentUserPosition;
  final UserRepository _userRepository = UserRepository();
  final SupabaseService _supabaseService = SupabaseService();
  
  late AnimationController _podiumAnimationController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadLeaderboard();
    _loadCurrentUserPosition();
  }

  void _initializeAnimations() {
    _podiumAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _podiumAnimationController.forward();
  }

  @override
  void dispose() {
    _podiumAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Use direct Supabase query instead of Edge Function to avoid issues
      final response = await _supabaseService.fetchFromTable(
        'profiles',
        select: '''
          id,
          display_name,
          avatar_url,
          total_points,
          level,
          quests_completed,
          created_at
        ''',
        order: 'total_points',
        ascending: false,
        limit: 50,
      );

        if (mounted) {
        final entries = response.map<LeaderboardEntry>((data) {
          return LeaderboardEntry(
            id: data['id'] as String,
            name: data['display_name'] as String? ?? 'Anonymous Explorer',
            avatar: data['avatar_url'] as String? ?? '',
            points: data['total_points'] as int? ?? 0,
            level: data['level'] as int? ?? 1,
            questsCompleted: data['quests_completed'] as int? ?? 0,
            rank: 0, // Will be set below
          );
        }).toList();

        // Set ranks
        for (int i = 0; i < entries.length; i++) {
          entries[i] = entries[i].copyWith(rank: i + 1);
        }

          setState(() {
            leaderboard = entries;
            isLoading = false;
          });
      }
    } catch (e) {
      print('Error loading leaderboard: $e');
      if (mounted) {
        setState(() {
          leaderboard = [];
          isLoading = false;
          errorMessage = 'Failed to load leaderboard. Please check your connection and try again.';
        });
      }
    }
  }

  Future<void> _loadCurrentUserPosition() async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        // Get user's profile
        final userProfile = await _supabaseService.fetchFromTable(
          'profiles',
          select: 'total_points, display_name, avatar_url, level, quests_completed',
          eq: {'id': currentUser.id},
          single: true,
        );

        if (userProfile.isNotEmpty) {
          final userPoints = userProfile.first['total_points'] as int? ?? 0;
          
          // Get user's rank by counting users with higher points
          final allProfiles = await _supabaseService.fetchFromTable(
            'profiles',
            select: 'total_points',
            order: 'total_points',
            ascending: false,
          );
          
          final higherRankedCount = allProfiles.where((profile) => 
            (profile['total_points'] as int? ?? 0) > userPoints
          ).length;

        if (mounted) {
          setState(() {
              currentUserPosition = {
                'rank': higherRankedCount + 1,
                'display_name': userProfile.first['display_name'] ?? 'You',
                'avatar_url': userProfile.first['avatar_url'],
                'total_points': userProfile.first['total_points'] ?? 0,
                'level': userProfile.first['level'] ?? 1,
                'quests_completed': userProfile.first['quests_completed'] ?? 0,
              };
          });
          }
        }
      }
    } catch (e) {
      print('Error loading user position: $e');
    }
  }



  Widget _buildUserPositionCard() {
    if (currentUserPosition == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '#${currentUserPosition!['rank']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Avatar
          CustomAvatar(
            imageUrl: currentUserPosition!['avatar_url'],
            initials: (currentUserPosition!['display_name'] as String).isNotEmpty 
              ? (currentUserPosition!['display_name'] as String)[0]
              : 'Y',
              size: AvatarSize.medium,
          ),
          const SizedBox(width: 16),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUserPosition!['display_name'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(
                      '${currentUserPosition!['total_points']} pts',
                        style: const TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(width: 16),
                    const Icon(Icons.emoji_events, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                      'Lvl ${currentUserPosition!['level']}',
                        style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Your Position Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'YOU',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                            'Leaderboard',
                style: TextStyle(
                              fontSize: 28,
                  fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.3),
                          Text(
                            'Top Explorers',
                            style: TextStyle(
                              fontSize: 16,
                              color: (isDark ? Colors.white : Colors.black87).withOpacity(0.7),
                            ),
                          ).animate(delay: 100.ms).fadeIn(duration: 600.ms).slideX(begin: -0.3),
                        ],
                ),
              ),
                  ],
                ),
              ),
              
              // User Position Card
              if (currentUserPosition != null) _buildUserPositionCard(),
              
              // Leaderboard List
              Expanded(
                child: _buildLeaderboardContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    if (isLoading) {
      return _buildLoadingList();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (leaderboard.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Top 3 Podium
            if (leaderboard.length >= 3) _buildPodium(),
            const SizedBox(height: 24),
            
            // Remaining Users (4th place and below)
            if (leaderboard.length > 3) _buildRemainingUsers(),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium() {
    final topThree = leaderboard.take(3).toList();
    
    // Ensure we have at least 3 users, pad with empty entries if needed
    while (topThree.length < 3) {
      topThree.add(LeaderboardEntry(
        id: '', name: '', avatar: '', points: 0, level: 0, questsCompleted: 0, rank: topThree.length + 1,
      ));
    }
    
    // Arrange for podium display: 2nd, 1st, 3rd
    final first = topThree[0]; // 1st place
    final second = topThree[1]; // 2nd place  
    final third = topThree[2]; // 3rd place
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.8), AppColors.secondary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Top Champions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            const SizedBox(height: 24),
            
            // Podium
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd Place
                _buildPodiumPosition(second, 2, 120).animate(
                  delay: 200.ms,
                ).slideY(begin: 0.5, duration: 600.ms).fadeIn(),
                
                // 1st Place (tallest)
                _buildPodiumPosition(first, 1, 140).animate(
                  delay: 400.ms,
                ).slideY(begin: 0.5, duration: 600.ms).fadeIn(),
                
                // 3rd Place
                _buildPodiumPosition(third, 3, 100).animate(
                  delay: 600.ms,
                ).slideY(begin: 0.5, duration: 600.ms).fadeIn(),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumPosition(LeaderboardEntry entry, int place, double height) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color getPlaceColor() {
      switch (place) {
        case 1: return const Color(0xFFFFD700); // Gold
        case 2: return const Color(0xFFC0C0C0); // Silver
        case 3: return const Color(0xFFCD7F32); // Bronze
        default: return Colors.grey;
      }
    }
    
    IconData getPlaceIcon() {
      switch (place) {
        case 1: return Icons.workspace_premium;
        case 2: return Icons.military_tech;
        case 3: return Icons.workspace_premium;
        default: return Icons.emoji_events;
      }
    }
    
    if (entry.id.isEmpty) {
      // Empty placeholder
      return SizedBox(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Center(
                child: Text(
                  '$place',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          // Crown/Trophy Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: getPlaceColor().withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: getPlaceColor().withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  getPlaceIcon(),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // User Avatar
          CustomAvatar(
            imageUrl: entry.avatar,
            initials: entry.name.isNotEmpty ? entry.name[0] : 'U',
            size: AvatarSize.medium,
          ),
          const SizedBox(height: 8),
          
          // User Name
          Text(
            entry.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Points
          Text(
            '${entry.points} pts',
            style: TextStyle(
              fontSize: 10,
              color: getPlaceColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Podium Base
          Container(
            width: 80,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  getPlaceColor().withOpacity(0.8),
                  getPlaceColor().withOpacity(0.6),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              boxShadow: [
                BoxShadow(
                  color: getPlaceColor().withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$place',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemainingUsers() {
    final remainingUsers = leaderboard.skip(3).take(17).toList(); // Top 20 total
    
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.format_list_numbered, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Top 20 Rankings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: remainingUsers.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.withOpacity(0.2),
            ),
            itemBuilder: (context, index) {
              final entry = remainingUsers[index];
              return _buildLeaderboardItem(entry, index + 3).animate(
                delay: Duration(milliseconds: 100 * index),
              ).fadeIn(duration: 600.ms).slideX(begin: 0.3);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Loading leaderboard...',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: CustomCard(
        margin: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load leaderboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: (isDark ? Colors.white : Colors.black87).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Try Again',
              onPressed: _loadLeaderboard,
              icon: Icons.refresh,
              size: ButtonSize.medium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: CustomCard(
        margin: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: (isDark ? Colors.white : Colors.black87).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No rankings yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete quests to appear on the leaderboard!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: (isDark ? Colors.white : Colors.black87).withOpacity(0.7),
              ),
      ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Rank Number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${entry.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Avatar
          CustomAvatar(
            imageUrl: entry.avatar,
            initials: entry.name.isNotEmpty ? entry.name[0] : 'U',
            size: AvatarSize.medium,
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.questsCompleted} quests',
                      style: TextStyle(
                        fontSize: 12,
                        color: (isDark ? Colors.white : Colors.black87).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.trending_up, color: Colors.blue, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Lvl ${entry.level}',
                      style: TextStyle(
                        fontSize: 12,
                        color: (isDark ? Colors.white : Colors.black87).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'points',
                style: TextStyle(
                  fontSize: 12,
                  color: (isDark ? Colors.white : Colors.black87).withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}