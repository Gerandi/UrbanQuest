import 'dart:typed_data';
import '../models/user_model.dart';
import '../models/achievement_model.dart';
import '../models/quest_model.dart';
import '../../core/services/supabase_service.dart'; // Import the new service

class UserProfileRepository {
  final SupabaseService _supabaseService = SupabaseService();

  String? get currentUserId => _supabaseService.currentUser?.id;

  Future<User?> getCurrentUserProfile() async {
    try {
      final authUser = _supabaseService.currentUser;
      if (authUser == null) return null;

      final response = await _supabaseService.fetchFromTable(
        'profiles',
        select: '*, user_stats(*)',
        eq: {'id': authUser.id},
        maybeSingle: true,
      );
      
      if (response.isEmpty) {
        await _createUserProfile(authUser);
        return await getCurrentUserProfile();
      }

      final userData = response.first;
      // Handle user_stats - it can be a single object or null
      final userStatsData = userData['user_stats'];
      final statsData = userStatsData is List && userStatsData.isNotEmpty 
          ? userStatsData.first 
          : userStatsData ?? {};
      
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

      return User(
        id: userData['id'],
        email: userData['email'] ?? '',
        displayName: userData['display_name'] ?? 'Anonymous',
        avatar: userData['avatar_url'] ?? '',
        totalPoints: userData['total_points'] ?? 0,
        stats: stats,
        createdAt: DateTime.parse(userData['created_at']),
        permissions: const ['user'],
      );
    } catch (e) {
      print('Error getting current user profile: $e');
      return null;
    }
  }

  Future<void> _createUserProfile(dynamic authUser) async {
    try {
      await _supabaseService.insertIntoTable('profiles', {
        'id': authUser.id,
        'email': authUser.email,
        'display_name': authUser.email?.split('@')[0] ?? 'Anonymous',
        'total_points': 0,
      });

      await _supabaseService.insertIntoTable('user_stats', {
        'user_id': authUser.id,
        'total_points': 0,
        'quests_completed': 0,
        'cities_visited': 0,
        'stops_visited': 0,
        'photos_shared': 0,
        'total_distance_km': 0.0,
        'current_level': 1,
        'level_title': 'Explorer',
        'achievements_unlocked': 0,
        'longest_quest_streak': 0,
        'current_quest_streak': 0,
        'total_playtime_minutes': 0,
      });
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }

  Future<User?> getUserProfile(String userId) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'profiles',
        select: '*, user_stats(*)',
        eq: {'id': userId},
        single: true,
      );
      
      if (response.isEmpty) return null;

      final userData = response.first;
      // Handle user_stats - it can be a single object or null
      final userStatsData = userData['user_stats'];
      final statsData = userStatsData is List && userStatsData.isNotEmpty 
          ? userStatsData.first 
          : userStatsData ?? {};
      
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

      return User(
        id: userData['id'],
        email: userData['email'] ?? '',
        displayName: userData['display_name'] ?? 'Anonymous',
        avatar: userData['avatar_url'] ?? '',
        totalPoints: userData['total_points'] ?? 0,
        stats: stats,
        createdAt: DateTime.parse(userData['created_at']),
        permissions: const ['user'],
      );
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<User?> createUserProfile(User user) async {
    try {
      final success = await _supabaseService.insertIntoTable('profiles', user.toJson());
      return success ? user : null;
    } catch (e) {
      print('Error creating user profile: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    return await _supabaseService.updateTable(
      'profiles',
      updates,
      {'id': userId},
    );
  }

  Future<String?> uploadProfilePhoto(String userId, Uint8List imageBytes) async {
    try {
      final fileName = 'profile_$userId.jpg';
      const bucketName = 'user-avatars';

      final photoUrl = await _supabaseService.uploadFile(imageBytes, fileName, bucketName);
      
      if (photoUrl != null) {
        // Update the user's profile with the new avatar URL
        await updateUserProfile(userId, {'avatar_url': photoUrl});
      }

      return photoUrl;
    } catch (e) {
      print('Error uploading profile photo: $e');
      return null;
    }
  }

  Future<UserStats> calculateUserStats() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return const UserStats(
        questsCompleted: 0,
        stopsVisited: 0,
        photosShared: 0,
        totalDistance: 0.0,
        citiesVisited: 0,
        achievementsUnlocked: 0,
        totalPlaytimeMinutes: 0,
        longestQuestStreak: 0,
        currentQuestStreak: 0,
        currentLevel: 1,
        levelTitle: 'Explorer',
      );
      }

      final response = await _supabaseService.fetchFromTable(
        'user_stats',
        select: '*',
        eq: {'user_id': userId},
        single: true,
      );

      if (response.isEmpty) {
        return const UserStats(
          questsCompleted: 0,
          stopsVisited: 0,
          photosShared: 0,
          totalDistance: 0.0,
          citiesVisited: 0,
          achievementsUnlocked: 0,
          totalPlaytimeMinutes: 0,
          longestQuestStreak: 0,
          currentQuestStreak: 0,
          currentLevel: 1,
          levelTitle: 'Explorer',
        );
      }

      final statsData = response.first;
      return UserStats(
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
    } catch (e) {
      print('Error calculating user stats: $e');
      return const UserStats(
        questsCompleted: 0,
        stopsVisited: 0,
        photosShared: 0,
        totalDistance: 0.0,
        citiesVisited: 0,
        achievementsUnlocked: 0,
        totalPlaytimeMinutes: 0,
        longestQuestStreak: 0,
        currentQuestStreak: 0,
        currentLevel: 1,
        levelTitle: 'Explorer',
      );
    }
  }

  Future<List<Achievement>> getUserAchievements() async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final response = await _supabaseService.fetchFromTable(
        'user_achievements',
        select: 'achievements(*)',
        eq: {'user_id': userId},
      );

      return response
          .map((item) => Achievement.fromJson(item['achievements']))
          .toList();
    } catch (e) {
      print('Error getting user achievements: $e');
      return [];
    }
  }

  Future<List<Quest>> getUserQuestHistory() async {
    try {
      final userId = currentUserId;
      if (userId == null) return [];

      final response = await _supabaseService.fetchFromTable(
        'user_quest_progress',
        select: 'quests(*)',
        eq: {'user_id': userId, 'status': 'completed'},
      );

      return response
          .map((item) => Quest.fromJson(item['quests']))
          .toList();
    } catch (e) {
      print('Error getting user quest history: $e');
      return [];
    }
  }

  Future<int> getUserLeaderboardPosition() async {
    try {
      final userId = currentUserId;
      if (userId == null) return 0;

      final response = await _supabaseService.callRpc('get_user_leaderboard_position', params: {'user_id': userId});

      return response as int? ?? 0;
    } catch (e) {
      print('Error getting user leaderboard position: $e');
      return 0;
    }
  }



  /// Delete user account and all associated data
  Future<bool> deleteUserAccount() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Delete user data from profiles table (cascade deletes will handle related data)
      final success = await _supabaseService.deleteFromTable(
        'profiles',
        {'id': userId},
      );
      
      if (success) {
        // Note: The user will be signed out when the profile is deleted due to auth triggers
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error deleting user account: $e');
      return false;
    }
  }
}
