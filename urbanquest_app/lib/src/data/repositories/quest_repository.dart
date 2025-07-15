import '../models/quest_model.dart';
import '../models/quest_stop_model.dart';
import '../../core/services/supabase_service.dart';
import '../services/app_data_service.dart';

class QuestRepository {
  final SupabaseService _supabaseService = SupabaseService();
  final AppDataService _appDataService = AppDataService.instance;

  /// Get all active quests
  Future<List<Quest>> getQuests() async {
    try {
      return await _appDataService.getQuests();
    } catch (e) {
      print('Error getting all quests: $e');
      rethrow; // Let the UI handle the error properly
    }
  }

  /// Get quests by city from backend
  Future<List<Quest>> getQuestsByCity(String cityId) async {
    try {
      return await _appDataService.getQuests(cityId: cityId);
    } catch (e) {
      print('Error getting quests by city: $e');
      rethrow; // Let the UI handle the error properly
    }
  }

  /// Get a specific quest by ID with full details
  Future<Quest?> getQuestById(String questId) async {
    try {
      print('QuestRepository: Getting quest by ID: $questId');
      final quest = await _appDataService.getQuestById(questId);
      if (quest == null) {
        print('QuestRepository: Quest not found with ID: $questId');
        // Try fallback method
        return await _getQuestByIdFallback(questId);
      }
      print('QuestRepository: Successfully found quest: ${quest.title}');
      return quest;
    } catch (e) {
      print('Error getting quest by ID: $e');
      // Try fallback method on error
      return await _getQuestByIdFallback(questId);
    }
  }

  /// Fallback method using direct table queries
  Future<Quest?> _getQuestByIdFallback(String questId) async {
    try {
      print('QuestRepository: Using fallback method for quest ID: $questId');
      final questDetails = await _supabaseService.getQuestById(questId);
      if (questDetails == null || questDetails['quest'] == null) {
        print('QuestRepository: Fallback also failed for quest ID: $questId');
        return null;
      }

      final quest = Quest.fromJson(questDetails['quest']);
      print('QuestRepository: Fallback succeeded for quest: ${quest.title}');
      return quest;
    } catch (e) {
      print('Error in fallback quest loading: $e');
      return null;
    }
  }

  /// Get quest stops for a specific quest
  Future<List<QuestStop>> getQuestStops(String questId) async {
    try {
      print('QuestRepository: Getting quest stops for quest ID: $questId');
      return await _appDataService.getQuestStops(questId: questId);
    } catch (e) {
      print('Error getting quest stops: $e');
      rethrow;
    }
  }

  /// Get popular quests (by completions/rating)
  Future<List<Quest>> getPopularQuests({int limit = 10}) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'quests_with_city',
        select: '''
          *, 
          quest_categories!inner(name, color, icon)
        ''',
        eq: {'is_active': true},
        order: 'total_completions',
        ascending: false,
        limit: limit,
      );

      return response.map((data) => Quest.fromJson(data)).toList();
    } catch (e) {
      print('Error getting popular quests: $e');
      rethrow;
    }
  }

  /// Search quests by text
  Future<List<Quest>> searchQuests(String searchTerm) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'quests',
        select: '''
          *, 
          quest_categories!inner(name, color, icon),
          cities!quests_city_id_fkey(name)
        ''',
        eq: {'is_active': true},
        order: 'rating',
        ascending: false,
        // textSearch is not directly supported by fetchFromTable, handle it here or extend fetchFromTable
        // For now, we'll assume the RPC function handles text search if needed, or implement it manually
      );

      // Manual text search filtering if not handled by RPC or SupabaseService
      return response.where((data) {
        final title = data['title']?.toString().toLowerCase() ?? '';
        final description = data['description']?.toString().toLowerCase() ?? '';
        final category = data['category_name']?.toString().toLowerCase() ?? '';
        final searchLower = searchTerm.toLowerCase();
        return title.contains(searchLower) ||
               description.contains(searchLower) ||
               category.contains(searchLower);
      }).map((data) => Quest.fromJson(data)).toList();
    } catch (e) {
      print('Error searching quests: $e');
      rethrow;
    }
  }

  /// Get featured quests
  Future<List<Quest>> getFeaturedQuests() async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'quests_with_city',
        select: '''
          *, 
          quest_categories!inner(name, color, icon)
        ''',
        eq: {'is_active': true, 'is_featured': true},
        order: 'rating',
        ascending: false,
      );

      return response.map((data) => Quest.fromJson(data)).toList();
    } catch (e) {
      print('Error getting featured quests: $e');
      rethrow;
    }
  }

  /// Get quests by category
  Future<List<Quest>> getQuestsByCategory(String categoryId) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'quests_with_city',
        select: '''
          *, 
          quest_categories!inner(name, color, icon)
        ''',
        eq: {'category_id': categoryId, 'is_active': true},
        order: 'is_featured',
        ascending: false,
      );

      return response.map((data) => Quest.fromJson(data)).toList();
    } catch (e) {
      print('Error getting quests by category: $e');
      rethrow;
    }
  }

  /// Get quests by difficulty
  Future<List<Quest>> getQuestsByDifficulty(String difficulty) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'quests_with_city',
        select: '''
          *, 
          quest_categories!inner(name, color, icon)
        ''',
        eq: {'difficulty': difficulty, 'is_active': true},
        order: 'rating',
        ascending: false,
      );

      return response.map((data) => Quest.fromJson(data)).toList();
    } catch (e) {
      print('Error getting quests by difficulty: $e');
      rethrow;
    }
  }

  /// Get recently added quests
  Future<List<Quest>> getRecentQuests({int limit = 10}) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'quests',
        select: '*',
        eq: {'is_active': true},
        order: 'created_at',
        ascending: false,
        limit: limit,
      );

      return response.map((data) => Quest.fromJson(data)).toList();
    } catch (e) {
      print('Error getting recent quests: $e');
      rethrow;
    }
  }

  /// Get quest categories
  Future<List<Map<String, dynamic>>> getQuestCategories() async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'quest_categories',
        select: '*',
        eq: {'is_active': true},
        order: 'sort_order',
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting quest categories: $e');
      rethrow;
    }
  }

  /// Start a quest for the current user
  Future<bool> startQuest(String questId) async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      return await _supabaseService.startQuest(userId, questId);
    } catch (e) {
      print('Error starting quest: $e');
      rethrow;
    }
  }

  /// Complete a quest stop with location verification
  Future<Map<String, dynamic>> completeStop({
    required String questId,
    required String stopId,
    required double latitude,
    required double longitude,
    Map<String, dynamic>? challengeData,
    String? photoUrl,
  }) async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // First verify location
      final locationResult = await _supabaseService.verifyLocation(
        latitude: latitude,
        longitude: longitude,
        stopId: stopId,
      );

      if (locationResult['verified'] != true) {
        return {
          'success': false,
          'error': 'Location verification failed. Please get closer to the location.',
        };
      }

      // Complete the stop
      final stopData = {
        'latitude': latitude,
        'longitude': longitude,
        'points': locationResult['points'] ?? 10,
        if (challengeData != null) ...challengeData,
        if (photoUrl != null) 'photo_url': photoUrl,
      };

      final success = await _supabaseService.completeStop(
        userId: userId,
        questId: questId,
        stopId: stopId,
        stopData: stopData,
      );

      return {
        'success': success,
        'points_earned': stopData['points'],
        'achievements': [], // Will be populated by achievement processor
      };
    } catch (e) {
      print('Error completing stop: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Complete entire quest
  Future<Map<String, dynamic>> completeQuest({
    required String questId,
    double? userRating,
    String? userReview,
  }) async {
    try {
      final userId = _supabaseService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final completionData = <String, dynamic>{};
      if (userRating != null) completionData['user_rating'] = userRating;
      if (userReview != null) completionData['user_review'] = userReview;

      return await _supabaseService.completeQuest(
        userId: userId,
        questId: questId,
        completionData: completionData,
      );
    } catch (e) {
      print('Error completing quest: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get user quest progress
  Future<Map<String, dynamic>?> getUserQuestProgress(String questId) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabaseService.fetchFromTable(
        'user_quest_progress',
        select: '*',
        eq: {'user_id': userId, 'quest_id': questId},
        maybeSingle: true,
      );

      return response.isNotEmpty ? response.first : null;
    } catch (e) {
      print('Error getting user quest progress: $e');
      return null;
    }
  }
}
