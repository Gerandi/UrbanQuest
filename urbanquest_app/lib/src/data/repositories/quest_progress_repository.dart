import '../models/user_quest_progress_model.dart';
import '../../core/services/supabase_service.dart'; // Import the new service

class QuestProgressRepository {
  final SupabaseService _supabaseService = SupabaseService();

  /// Start a new quest for the current user
  Future<bool> startQuest(String questId) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final startTime = DateTime.now();

      final questProgressData = {
        'user_id': user.id,
        'quest_id': questId,
        'status': QuestStatus.inProgress.toString().split('.').last,
        'completed_stops': [],
        'current_stop_index': 0,
        'points_earned': 0,
        'started_at': startTime.toIso8601String(),
        'challenge_answers': {},
        'photos_taken': [],
      };

      final success = await _supabaseService.insertIntoTable('user_quest_progress', questProgressData);
      return success;
    } catch (e) {
      print('Error starting quest: $e');
      return false;
    }
  }

  /// Get user's progress for a specific quest
  Future<UserQuestProgress?> getQuestProgress(String questId) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return null;

      final response = await _supabaseService.fetchFromTable(
        'user_quest_progress',
        select: '*',
        eq: {'user_id': user.id, 'quest_id': questId},
        maybeSingle: true,
      );

      if (response.isNotEmpty) {
        return UserQuestProgress.fromJson(response.first);
      }
      return null;
    } catch (e) {
      print('Error getting quest progress: $e');
      return null;
    }
  }

  /// Update quest progress when completing a stop
  Future<bool> completeStop({
    required String questId,
    required String stopId,
    required int stopIndex,
    required int pointsEarned,
    required Map<String, dynamic> challengeAnswer,
    List<String>? photosTaken,
  }) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current progress
      final current = await getQuestProgress(questId);
      if (current == null) throw Exception('Quest progress not found');

      // Update completed stops and other fields
      final updatedStops = List<String>.from(current.completedStops)..add(stopId);
      final updatedAnswers = Map<String, dynamic>.from(current.challengeAnswers);
      updatedAnswers[stopId] = challengeAnswer;
      
      final updatedPhotos = List<String>.from(current.photosTaken);
      if (photosTaken != null) {
        updatedPhotos.addAll(photosTaken);
      }

      await _supabaseService.updateTable(
        'user_quest_progress',
        {
          'completed_stops': updatedStops,
          'current_stop_index': stopIndex + 1,
          'points_earned': current.pointsEarned + pointsEarned,
          'challenge_answers': updatedAnswers,
          'photos_taken': updatedPhotos,
          'updated_at': DateTime.now().toIso8601String(),
        },
        {'user_id': user.id, 'quest_id': questId},
      );

      return true;
    } catch (e) {
      print('Error completing stop: $e');
      return false;
    }
  }

  /// Complete the entire quest
  Future<bool> completeQuest({
    required String questId,
    required int totalPointsEarned,
    Duration? timeSpent,
    double? userRating,
    String? userReview,
  }) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final completedAt = DateTime.now();

      // Update quest progress
      await _supabaseService.updateTable(
        'user_quest_progress',
        {
          'status': 'completed',
          'completed_at': completedAt.toIso8601String(),
          if (timeSpent != null) 'time_spent': timeSpent.inMinutes,
          if (userRating != null) 'user_rating': userRating,
          if (userReview != null) 'user_review': userReview,
        },
        {'user_id': user.id, 'quest_id': questId},
      );

      // Update user's total points using RPC function
      await _supabaseService.callRpc('increment_user_points', params: {
        'user_id': user.id,
        'points_increment': totalPointsEarned,
      });

      // Update quest completion stats using RPC function
      await _supabaseService.callRpc('increment_quest_completions', params: {
        'quest_id': questId,
      });

      return true;
    } catch (e) {
      print('Error completing quest: $e');
      return false;
    }
  }

  /// Get all quest progress for current user
  Future<List<UserQuestProgress>> getUserQuestHistory() async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return [];

      final response = await _supabaseService.fetchFromTable(
        'user_quest_progress',
        select: '*',
        eq: {'user_id': user.id},
        order: 'started_at',
        ascending: false,
      );

      return response
          .map((data) => UserQuestProgress.fromJson(data))
          .toList();
    } catch (e) {
      print('Error getting user quest history: $e');
      return [];
    }
  }

  /// Get quest statistics for analytics
  Future<Map<String, dynamic>> getQuestStatistics(String questId) async {
    try {
      // Get completed quests
      final completedResponse = await _supabaseService.fetchFromTable(
        'user_quest_progress',
        select: 'time_spent, user_rating',
        eq: {'quest_id': questId, 'status': 'completed'},
      );

      final completions = completedResponse;
      
      // Calculate average completion time and rating
      double avgCompletionTime = 0;
      double avgRating = 0;
      int ratedCompletions = 0;

      if (completions.isNotEmpty) {
        int totalTime = 0;
        double totalRating = 0;

        for (var completion in completions) {
          if (completion['time_spent'] != null) {
            totalTime += (completion['time_spent'] as int);
          }
          if (completion['user_rating'] != null) {
            totalRating += (completion['user_rating'] as double);
            ratedCompletions++;
          }
        }

        if (totalTime > 0) {
          avgCompletionTime = totalTime / completions.length;
        }
        if (ratedCompletions > 0) {
          avgRating = totalRating / ratedCompletions;
        }
      }

      return {
        'totalCompletions': completions.length,
        'averageCompletionTimeMinutes': avgCompletionTime,
        'averageRating': avgRating,
        'ratedCompletions': ratedCompletions,
      };
    } catch (e) {
      print('Error getting quest statistics: $e');
      return {
        'totalCompletions': 0,
        'averageCompletionTimeMinutes': 0.0,
        'averageRating': 0.0,
        'ratedCompletions': 0,
      };
    }
  }

  /// Delete quest progress (for testing or user data cleanup)
  Future<bool> deleteQuestProgress(String questId) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabaseService.deleteFromTable(
        'user_quest_progress',
        {'user_id': user.id, 'quest_id': questId},
      );

      return true;
    } catch (e) {
      print('Error deleting quest progress: $e');
      return false;
    }
  }

  /// Check if user has completed a quest
  Future<bool> hasUserCompletedQuest(String questId) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return false;

      final response = await _supabaseService.fetchFromTable(
        'user_quest_progress',
        select: 'status',
        eq: {'user_id': user.id, 'quest_id': questId, 'status': 'completed'},
        maybeSingle: true,
      );

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking quest completion: $e');
      return false;
    }
  }
} 