import 'dart:math';

import '../models/quest_stop_model.dart';
import '../models/achievement_model.dart';
import '../repositories/quest_repository.dart';
import '../repositories/user_repository.dart';
import '../../core/services/supabase_service.dart'; // Import the new service

class QuestCompletionService {
  final SupabaseService _supabaseService = SupabaseService(); // Use the new service
  final QuestRepository _questRepository = QuestRepository();
  final UserRepository _userRepository = UserRepository();

  String? get currentUserId => _supabaseService.currentUser?.id;

  Future<Map<String, dynamic>> calculateCompletionData({
    required String questId,
    required List<QuestStop> questStops,
    required List<Map<String, dynamic>> capturedPhotos,
    required Duration duration,
    required Map<String, dynamic> stats,
  }) async {
    try {
      // Get quest details
      final quest = await _questRepository.getQuestById(questId);
      if (quest == null) {
        throw Exception('Quest not found');
      }

      // Calculate points earned
      final pointsEarned = questStops.fold<int>(0, (sum, stop) => sum + stop.points);
      
      // Calculate bonus points based on completion time and efficiency
      int bonusPoints = 0;
      
      // Time bonus - faster completion gets bonus
      final estimatedMinutes = int.tryParse(quest.estimatedDuration) ?? 60;
      if (duration.inMinutes <= estimatedMinutes) {
        bonusPoints += 50; // Fast completion bonus
      }
      
      // Photo bonus
      if (capturedPhotos.isNotEmpty) {
        bonusPoints += capturedPhotos.length * 10; // 10 points per photo
      }

      // Steps bonus (if walking data available)
      if (stats.containsKey('steps') && stats['steps'] > 0) {
        bonusPoints += ((stats['steps'] as num) / 100).floor() * 5; // 5 points per 100 steps
      }

      final totalPoints = pointsEarned + bonusPoints;

      // Check for level up
      final currentUser = await _userRepository.getCurrentUser();
      bool leveledUp = false;
      int newLevel = currentUser?.level ?? 1;
      
      if (currentUser != null) {
        final newTotalPoints = (currentUser.totalPoints + totalPoints);
        final calculatedLevel = _calculateLevelFromPoints(newTotalPoints);
        leveledUp = calculatedLevel > currentUser.level;
        newLevel = calculatedLevel;
      }

      // Mock achievements for now - in real app, check against achievement criteria
      final achievements = <Achievement>[];
      
      // Quest completion data
      final completionData = {
        'quest': quest,
        'questId': questId,
        'pointsEarned': pointsEarned,
        'bonusPoints': bonusPoints,
        'totalPoints': totalPoints,
        'tasksCompleted': questStops.length,
        'totalTasks': questStops.length,
        'failedTasks': <String>[], // For now, assume all tasks completed
        'leveledUp': leveledUp,
        'newLevel': newLevel,
        'achievementDetails': achievements,
        'photosTaken': capturedPhotos.map((photo) => photo['url'] ?? '').toList(),
        'totalTimeSpent': duration,
        'distanceWalked': stats['distance'] ?? 0.0,
        'stepsCount': stats['steps'] ?? 0,
        'completedAt': DateTime.now().toIso8601String(),
      };
      
      return completionData;
    } catch (e) {
      print('Error calculating completion data: $e');
      // Return minimal data on error
      return {
        'quest': null,
        'questId': questId,
        'pointsEarned': 0,
        'bonusPoints': 0,
        'totalPoints': 0,
        'tasksCompleted': 0,
        'totalTasks': questStops.length,
        'failedTasks': <String>[],
        'leveledUp': false,
        'newLevel': 1,
        'achievementDetails': <Achievement>[],
        'photosTaken': <String>[],
        'totalTimeSpent': duration,
        'distanceWalked': 0.0,
        'stepsCount': 0,
        'completedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  int _calculateLevelFromPoints(int points) {
    // Exponential level system: Level = floor(sqrt(points / 100)) + 1
    // Level 1: 0-99 points
    // Level 2: 100-399 points  
    // Level 3: 400-899 points
    // Level 4: 900-1599 points
    // etc.
    if (points < 100) return 1;
    return sqrt(points / 100).floor() + 1;
  }

  Future<bool> saveQuestCompletion(Map<String, dynamic> completionData) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('Error: No authenticated user');
        return false;
      }

      // Convert Duration to minutes for database storage
      final durationMinutes = (completionData['totalTimeSpent'] as Duration).inMinutes;

      // Prepare serializable completion data
      final dbCompletionData = {
        'pointsEarned': completionData['pointsEarned'],
        'bonusPoints': completionData['bonusPoints'],
        'totalPoints': completionData['totalPoints'],
        'duration': durationMinutes,
        'stepsCount': completionData['stepsCount'],
        'distanceWalked': completionData['distanceWalked'],
        'photosShared': (completionData['photosTaken'] as List).length,
        'completedAt': completionData['completedAt'],
      };

      // Save completion record
      await _supabaseService.insertIntoTable('user_quest_progress', {
        'user_id': userId,
        'quest_id': completionData['questId'],
        'status': 'completed',
        'completion_data': dbCompletionData,
        'completed_at': completionData['completedAt'],
      });

      // Update user's total points
      try {
        await _supabaseService.callRpc('increment_user_points', params: {
          'user_id': userId,
          'points_increment': completionData['totalPoints'],
        });
      } catch (e) {
        print('Warning: Could not update user points: $e');
        // Continue anyway - quest completion saved successfully
      }

      print('Quest completion saved successfully');
      return true;
    } catch (e) {
      print('Error saving quest completion: $e');
      return false;
    }
  }

  /// Submit a quest review
  Future<bool> submitQuestReview({
    required String questId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    try {
      // Here you would typically call your backend API
      // For now, we'll simulate a successful submission
      print('Submitting quest review: questId=$questId, rating=$rating');
      
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));
      
      return true;
    } catch (e) {
      print('Error submitting quest review: $e');
      return false;
    }
  }
}
