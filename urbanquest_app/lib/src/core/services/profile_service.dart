import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_model.dart' as UserModel;
import '../../data/models/user_stats_model.dart';
import '../../data/models/achievement_model.dart';
import '../../data/models/quest_model.dart';
import 'supabase_service.dart';
import 'photo_upload_service.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final PhotoUploadService _photoUploadService = PhotoUploadService();

  // Get current user profile
  Future<UserModel.User?> getCurrentUserProfile() async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return null;

      final response = await _supabaseService.fetchFromTable(
        'profiles',
        select: '''
          *,
          user_stats(*),
          user_achievements(
            *,
            achievements(*)
          )
        ''',
        eq: {'id': currentUser.id},
        single: true,
      );

      if (response.isEmpty) return null;

      return _mapUserFromResponse(response.first);
    } catch (e) {
      print('Error getting current user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String userId,
    String? displayName,
    String? bio,
    String? avatar,
    String? phoneNumber,
    String? location,
    DateTime? dateOfBirth,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (displayName != null) updateData['display_name'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (avatar != null) updateData['avatar'] = avatar;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (location != null) updateData['location'] = location;
      if (dateOfBirth != null) updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabaseService.updateTable('profiles', updateData, {'id': userId});

      // Update preferences if provided
      if (preferences != null) {
        await _updateUserPreferences(userId, preferences);
      }

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Upload profile photo
  Future<String?> uploadProfilePhoto(String userId, Uint8List imageBytes) async {
    try {
      final fileName = 'profile_$userId.jpg';
      final photoUrl = await _photoUploadService.uploadPhoto(
        imageBytes,
        'profile_photos/$fileName',
      );

      if (photoUrl != null) {
        // Update user record with new avatar URL
        await updateUserProfile(userId: userId, avatar: photoUrl);
      }

      return photoUrl;
    } catch (e) {
      print('Error uploading profile photo: $e');
      return null;
    }
  }

  // Calculate and cache user stats
  Future<UserStats> calculateUserStats(String userId) async {
    try {
      // Get quest completions
      final questCompletions = await _supabaseService.fetchFromTable(
        'user_quest_progress',
        select: '''
          *,
          quests(title, city, difficulty, estimated_duration, points),
          quest_photos(photo_url)
        ''',
        eq: {'user_id': userId},
      );

      // Get achievements
      final achievements = await _supabaseService.fetchFromTable(
        'user_achievements',
        select: '*',
        eq: {'user_id': userId},
      );

      // Get quest stops visited
      final stopsVisited = await _supabaseService.fetchFromTable(
        'user_quest_stop_progress',
        select: '*',
        eq: {'user_id': userId, 'is_completed': true},
      );

      // Calculate stats
      final stats = _calculateStatsFromData(
        questCompletions: questCompletions,
        achievements: achievements,
        stopsVisited: stopsVisited,
      );

      // Cache stats in database
      await _cacheUserStats(userId, stats);

      return stats;
    } catch (e) {
      print('Error calculating user stats: $e');
      return const UserStats();
    }
  }

  // Get user achievements
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'user_achievements',
        select: '''
          *,
          achievements(*)
        ''',
        eq: {'user_id': userId},
        order: 'unlocked_at',
        ascending: false,
      );

      return response.map<Achievement>((data) => 
          Achievement.fromJson(data['achievements'])).toList();
    } catch (e) {
      print('Error getting user achievements: $e');
      return [];
    }
  }

  // Get available achievements (not yet earned)
  Future<List<Achievement>> getAvailableAchievements(String userId) async {
    try {
      // Get all achievements
      final allAchievements = await _supabaseService.fetchFromTable(
        'achievements',
        select: '*',
        eq: {'is_active': true},
      );

      // Get user's earned achievements
      final earnedAchievements = await _supabaseService.fetchFromTable(
        'user_achievements',
        select: 'achievement_id',
        eq: {'user_id': userId},
      );

      final earnedIds = earnedAchievements.map((e) => e['achievement_id']).toSet();

      return allAchievements.where((achievement) => 
          !earnedIds.contains(achievement['id']))
          .map<Achievement>((data) => Achievement.fromJson(data))
          .toList();
    } catch (e) {
      print('Error getting available achievements: $e');
      return [];
    }
  }

  // Get user's quest history
  Future<List<Quest>> getUserQuestHistory(String userId) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'user_quest_progress',
        select: '''
          *,
          quests(
            *,
            cities(name),
            quest_categories(name),
            quest_stops(id)
          )
        ''',
        eq: {'user_id': userId, 'is_completed': true},
        order: 'completed_at',
        ascending: false,
      );

      return response.map<Quest>((data) => 
          Quest.fromJson(data['quests'])).toList();
    } catch (e) {
      print('Error getting user quest history: $e');
      return [];
    }
  }

  // Get user's in-progress quests
  Future<List<Quest>> getUserInProgressQuests(String userId) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'user_quest_progress',
        select: '''
          *,
          quests(
            *,
            cities(name),
            quest_categories(name),
            quest_stops(id)
          )
        ''',
        eq: {'user_id': userId, 'is_completed': false},
        order: 'started_at',
        ascending: false,
      );

      return response.map<Quest>((data) => 
          Quest.fromJson(data['quests'])).toList();
    } catch (e) {
      print('Error getting user in-progress quests: $e');
      return [];
    }
  }

  // Get user's leaderboard position
  Future<int> getUserLeaderboardPosition(String userId) async {
    try {
      final response = await _supabaseService.callRpc(
        'get_user_leaderboard_position',
        params: {'user_id': userId},
      );
      
      return response ?? -1;
    } catch (e) {
      print('Error getting leaderboard position: $e');
      return -1;
    }
  }

  // Check and unlock achievements
  Future<List<Achievement>> checkAndUnlockAchievements(String userId) async {
    try {
      final newAchievements = <Achievement>[];
      
      // Get current user stats
      final stats = await calculateUserStats(userId);
      
      // Get available achievements
      final availableAchievements = await getAvailableAchievements(userId);
      
      for (final achievement in availableAchievements) {
        if (_checkAchievementCondition(achievement, stats)) {
          await _unlockAchievement(userId, achievement.id);
          newAchievements.add(achievement);
        }
      }
      
      return newAchievements;
    } catch (e) {
      print('Error checking achievements: $e');
      return [];
    }
  }

  // Update user preferences
  Future<bool> _updateUserPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      await _supabaseService.updateTable(
        'user_preferences',
        {
          'user_id': userId,
          ...preferences,
          'updated_at': DateTime.now().toIso8601String(),
        },
        {'user_id': userId},
      );
      
      return true;
    } catch (e) {
      print('Error updating user preferences: $e');
      return false;
    }
  }

  // Delete user account
  Future<bool> deleteUserAccount(String userId) async {
    try {
      // Delete related data first (due to foreign key constraints)
      await Future.wait([
        _supabaseService.deleteFromTable('user_quest_progress', {'user_id': userId}),
        _supabaseService.deleteFromTable('user_quest_stop_progress', {'user_id': userId}),
        _supabaseService.deleteFromTable('user_achievements', {'user_id': userId}),
        _supabaseService.deleteFromTable('user_preferences', {'user_id': userId}),
        _supabaseService.deleteFromTable('quest_photos', {'user_id': userId}),
      ]);

      // Delete user record
      await _supabaseService.deleteFromTable('profiles', {'id': userId});

      // Delete profile photo if exists
      try {
        await _supabaseService.client.storage
            .from('profile_photos')
            .remove(['profile_$userId.jpg']);
      } catch (e) {
        // Photo might not exist, ignore error
      }

      return true;
    } catch (e) {
      print('Error deleting user account: $e');
      return false;
    }
  }

  // Helper methods
  UserModel.User _mapUserFromResponse(Map<String, dynamic> response) {
    return UserModel.User(
      id: response['id'],
      email: response['email'],
      displayName: response['display_name'] ?? '',
      avatar: response['avatar'],
      bio: response['bio'],
      phoneNumber: response['phone_number'],
      location: response['location'],
      dateOfBirth: response['date_of_birth'] != null 
          ? DateTime.parse(response['date_of_birth']) 
          : null,
      isVerified: response['is_verified'] ?? false,
      createdAt: DateTime.parse(response['created_at']),
      updatedAt: response['updated_at'] != null 
          ? DateTime.parse(response['updated_at']) 
          : null,
      stats: response['user_stats'] != null 
          ? UserStats.fromJson(response['user_stats']) 
          : const UserStats(),
      level: response['user_stats']?['total_points'] != null 
          ? _calculateLevel(response['user_stats']['total_points']) 
          : 1,
      totalPoints: response['user_stats']?['total_points'] ?? 0,
    );
  }

  UserStats _calculateStatsFromData({
    required List<dynamic> questCompletions,
    required List<dynamic> achievements,
    required List<dynamic> stopsVisited,
  }) {
    final completedQuests = questCompletions.where((q) => q['is_completed'] == true).toList();
    final totalPoints = completedQuests.fold<int>(0, (sum, quest) => sum + (quest['total_points'] ?? 0));
    final totalDistance = completedQuests.fold<double>(0, (sum, quest) => sum + (quest['total_distance'] ?? 0.0));
    final totalTime = completedQuests.fold<int>(0, (sum, quest) => sum + (quest['total_time_minutes'] ?? 0));
    
    // Count photos
    final photosShared = questCompletions
        .expand((q) => q['quest_photos'] ?? [])
        .length;

    // Calculate cities visited
    final citiesVisited = completedQuests
        .map((q) => q['quests']?['city'])
        .where((city) => city != null)
        .toSet()
        .length;

    // Calculate streak (simplified)
    final currentStreak = _calculateCurrentStreak(completedQuests);

    return UserStats(
      questsCompleted: completedQuests.length,
      stopsVisited: stopsVisited.length,
      photosShared: photosShared,
      totalDistance: totalDistance,
      totalPoints: totalPoints,
      achievementsEarned: achievements.length,
      currentStreak: currentStreak,
      longestStreak: currentStreak, // Simplified
      totalTimeSpent: totalTime,
      citiesVisited: citiesVisited,
      challengesCompleted: stopsVisited.length,
      perfectScores: completedQuests.where((q) => q['score'] == 100).length,
      lastActivityDate: completedQuests.isNotEmpty 
          ? DateTime.parse(completedQuests.first['completed_at']) 
          : null,
      firstQuestDate: completedQuests.isNotEmpty 
          ? DateTime.parse(completedQuests.last['started_at']) 
          : null,
    );
  }

  int _calculateLevel(int points) {
    if (points <= 0) return 1;
    if (points < 100) return 1;
    if (points < 300) return 2;
    if (points < 600) return 3;
    if (points < 1000) return 4;
    if (points < 1500) return 5;
    return 5 + ((points - 1500) ~/ 500);
  }

  int _calculateCurrentStreak(List<dynamic> completedQuests) {
    if (completedQuests.isEmpty) return 0;
    
    // Sort by completion date
    completedQuests.sort((a, b) => 
        DateTime.parse(b['completed_at']).compareTo(DateTime.parse(a['completed_at'])));
    
    int streak = 0;
    DateTime? lastDate;
    
    for (final quest in completedQuests) {
      final completedAt = DateTime.parse(quest['completed_at']);
      final completedDate = DateTime(completedAt.year, completedAt.month, completedAt.day);
      
      if (lastDate == null) {
        // First quest
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        
        if (completedDate == todayDate || completedDate == todayDate.subtract(const Duration(days: 1))) {
          streak = 1;
          lastDate = completedDate;
        } else {
          break; // Streak broken
        }
      } else {
        final expectedDate = lastDate.subtract(const Duration(days: 1));
        if (completedDate == expectedDate) {
          streak++;
          lastDate = completedDate;
        } else {
          break; // Streak broken
        }
      }
    }
    
    return streak;
  }

  Future<void> _cacheUserStats(String userId, UserStats stats) async {
    try {
      await _supabaseService.updateTable(
        'user_stats',
        {
          'user_id': userId,
          ...stats.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {'user_id': userId},
      );
    } catch (e) {
      print('Error caching user stats: $e');
    }
  }

  bool _checkAchievementCondition(Achievement achievement, UserStats stats) {
    // This would contain the logic for each achievement type
    // For now, simplified examples:
    switch (achievement.id) {
      case 'first_quest':
        return stats.questsCompleted >= 1;
      case 'explorer':
        return stats.questsCompleted >= 5;
      case 'photographer':
        return stats.photosShared >= 10;
      case 'walker':
        return stats.totalDistance >= 5.0;
      case 'point_collector':
        return stats.totalPoints >= 1000;
      default:
        return false;
    }
  }

  Future<void> _unlockAchievement(String userId, String achievementId) async {
    try {
      await _supabaseService.insertIntoTable(
        'user_achievements',
        {
          'user_id': userId,
          'achievement_id': achievementId,
          'unlocked_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('Error unlocking achievement: $e');
    }
  }
}