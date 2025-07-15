import '../models/user_model.dart';
import '../models/leaderboard_entry_model.dart';
import '../../core/services/supabase_service.dart';

class UserRepository {
  final SupabaseService _supabaseService = SupabaseService();

  /// Get current user ID
  String? get currentUserId => _supabaseService.currentUser?.id;

  /// Get current user profile with full data
  Future<User?> getCurrentUser() async {
    try {
      final authUser = _supabaseService.currentUser;
      if (authUser == null) return null;

      return await getUserById(authUser.id);
    } catch (e) {
      print('Error getting current user: $e');
      rethrow;
    }
  }

  /// Get user by ID with comprehensive profile data
  Future<User?> getUserById(String userId) async {
    try {
      // Get profile with stats and achievements
      final profileResponse = await _supabaseService.fetchFromTable(
        'profiles',
        select: '''
          *,
          user_stats(*),
          user_achievements(
            achieved_at,
            achievements(*)
          )
        ''',
        eq: {'id': userId},
        single: true,
      );

      if (profileResponse.isEmpty) return null;

      // Get completed quests
      final progressResponse = await _supabaseService.fetchFromTable(
        'user_quest_progress',
        select: 'quest_id, completed_at, points_earned',
        eq: {'user_id': userId, 'status': 'completed'},
      );

      // Get user level info
      await _getUserLevel(profileResponse.first['total_points'] ?? 0);

      // Build user stats
      final statsData = profileResponse.first['user_stats'] ?? {};
      final stats = UserStats(
        questsCompleted: statsData['quests_completed'] ?? 0,
        stopsVisited: statsData['stops_visited'] ?? 0,
        photosShared: statsData['photos_shared'] ?? 0,
        totalDistance: (statsData['total_distance_km'] ?? 0.0).toDouble(),
        citiesVisited: statsData['cities_visited'] ?? 0,
        achievementsUnlocked: statsData['achievements_unlocked'] ?? 0,
        totalPlaytimeMinutes: statsData['total_playtime_minutes'] ?? 0,
        longestQuestStreak: statsData['longest_quest_streak'] ?? 0,
        currentQuestStreak: statsData['current_quest_streak'] ?? 0,
        currentLevel: statsData['current_level'] ?? 1,
        levelTitle: statsData['level_title'] ?? 'Explorer',
      );

      // Extract achievements (not currently used but preserved for future use)
      // final achievementsList = (profileResponse.first['user_achievements'] as List? ?? [])
      //     .map((userAchievement) => userAchievement['achievements']['name'] as String)
      //     .toList();

      return User(
        id: userId,
        email: profileResponse.first['email'] ?? '',
        displayName: profileResponse.first['display_name'] ?? 'Anonymous Explorer',
        avatar: profileResponse.first['avatar_url'] ?? '',
        totalPoints: profileResponse.first['total_points'] ?? 0,
        stats: stats,
        createdAt: DateTime.parse(profileResponse.first['created_at']),
        permissions: const ['user'],
      );
    } catch (e) {
      print('Error getting user by ID: $e');
      rethrow;
    }
  }

  /// Get user level information based on points
  Future<Map<String, dynamic>> _getUserLevel(int totalPoints) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'levels',
        select: '*',
        limit: 1,
      );

      // Find the appropriate level based on points
      for (final level in response) {
        final minPoints = level['min_points'] ?? 0;
        final maxPoints = level['max_points'] ?? 999999;
        if (totalPoints >= minPoints && totalPoints <= maxPoints) {
          return {
            'level_number': level['level'],
            'title': level['title'],
            'min_points': minPoints,
            'max_points': maxPoints,
          };
        }
      }

      // Default to level 1 if no levels found
      return {
        'level_number': 1,
        'name': 'Explorer',
        'min_points': 0,
        'max_points': 999,
      };
    } catch (e) {
      print('Error getting user level: $e');
      return {
        'level_number': 1,
        'name': 'Explorer',
        'min_points': 0,
        'max_points': 999,
      };
    }
  }

  /// Get all users for leaderboard using Edge Function
  Future<List<LeaderboardEntry>> getLeaderboard({
    int limit = 50,
    String? cityId,
    String timeframe = 'all_time',
  }) async {
    try {
      final response = await _supabaseService.getLeaderboard(
        limit: limit,
        cityId: cityId,
        timeframe: timeframe,
      );

      final leaderboardData = response['leaderboard'] as List? ?? [];

      return leaderboardData.map((entry) {
        return LeaderboardEntry(
          id: entry['user_id'] ?? '',
          name: entry['display_name'] ?? 'Anonymous',
          avatar: entry['avatar_url'] ?? '',
          points: entry['total_points'] ?? 0,
          rank: entry['rank'] ?? 0,
          level: entry['level'] ?? 1,
          questsCompleted: entry['quests_completed'] ?? 0,
          city: entry['city_name'],
        );
      }).toList();
    } catch (e) {
      print('Error getting leaderboard: $e');
      rethrow;
    }
  }

  /// Get user's position in leaderboard
  Future<Map<String, dynamic>?> getUserLeaderboardPosition(String userId) async {
    try {
      return await _supabaseService.getUserPosition(userId);
    } catch (e) {
      print('Error getting user position: $e');
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? avatarUrl,
    String? cityId,
  }) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return false;

      final updates = <String, dynamic>{};
      if (displayName != null) updates['display_name'] = displayName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (cityId != null) updates['city_id'] = cityId;

      return await _supabaseService.updateUserProfile(user.id, updates);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Stream user data changes
  Stream<User?> streamCurrentUser() {
    final user = _supabaseService.currentUser;
    if (user == null) return Stream.value(null);

    return _supabaseService.streamUserProfile(user.id).asyncMap((userData) async {
      if (userData == null) return null;
      
      try {
        return await getUserById(user.id);
      } catch (e) {
        print('Error streaming user data: $e');
        return null;
      }
        });
  }

  /// Get user quest history
  Future<List<Map<String, dynamic>>> getUserQuestHistory() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return [];

      final response = await _supabaseService.fetchFromTable(
        'user_quest_progress',
        select: '''
          *,
          quests!inner(
            title,
            difficulty,
            estimated_duration_minutes,
            cities!inner(name)
          )
        ''',
        eq: {'user_id': user.id},
        order: 'started_at',
        ascending: false,
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user quest history: $e');
      rethrow;
    }
  }

  /// Get user achievements with details
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      return await _supabaseService.getUserAchievements(userId);
    } catch (e) {
      print('Error getting user achievements: $e');
      rethrow;
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'user_stats',
        select: '*',
        eq: {'user_id': userId},
        single: true,
      );
      
      return response.first;
    } catch (e) {
      print('Error getting user stats: $e');
      rethrow;
    }
  }

  /// Create user profile during authentication
  Future<bool> createUserProfile({
    required String userId,
    required String email,
    String? displayName,
    String? avatarUrl,
    String? cityId,
  }) async {
    try {
      final profileData = {
        'id': userId,
        'email': email,
        'display_name': displayName ?? email.split('@').first,
        'avatar_url': avatarUrl,
        'city_id': cityId,
        'total_points': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      return await _supabaseService.createUserProfile(profileData);
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }
  
  /// Delete user profile (for account deletion)
  Future<bool> deleteUserProfile(String userId) async {
    try {
      // Delete user achievements
      await _supabaseService.deleteFromTable(
        'user_achievements',
        {'user_id': userId},
      );

      // Delete user quest progress
      await _supabaseService.deleteFromTable(
        'user_quest_progress',
        {'user_id': userId},
      );

      // Delete user stats
      await _supabaseService.deleteFromTable(
        'user_stats',
        {'user_id': userId},
      );

      // Delete profile
      await _supabaseService.deleteFromTable(
        'profiles',
        {'id': userId},
      );

      return true;
    } catch (e) {
      print('Error deleting user profile: $e');
      return false;
    }
  }

  /// Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'profiles',
        select: 'id',
        eq: {'id': userId},
        maybeSingle: true,
      );

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  /// Get all available user levels
  Future<List<Map<String, dynamic>>> getUserLevels() async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'levels',
        select: '*',
        order: 'level_number',
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user levels: $e');
      rethrow;
    }
  }

  /// Update user location (for location-based features)
  Future<bool> updateUserLocation(double latitude, double longitude) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return false;

      await _supabaseService.updateTable(
        'profiles',
        {
          'last_lat': latitude,
          'last_lng': longitude,
          'last_location_update': DateTime.now().toIso8601String(),
        },
        {'id': user.id},
      );

      return true;
    } catch (e) {
      print('Error updating user location: $e');
      return false;
    }
  }
}
