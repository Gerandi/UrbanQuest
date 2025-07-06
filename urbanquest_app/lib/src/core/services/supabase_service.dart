import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Auth methods
  User? get currentUser => _supabase.auth.currentUser;
  String? get currentUserId => _supabase.auth.currentUser?.id;
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Generic method to fetch data from a Supabase table.
  Future<List<Map<String, dynamic>>> fetchFromTable(
    String tableName, {
    String select = '*',
    Map<String, dynamic>? eq,
    String? order,
    bool ascending = false,
    int? limit,
    bool single = false,
    bool maybeSingle = false,
    String? rpc,
    Map<String, dynamic>? rpcParams,
  }) async {
    try {
      dynamic query = _supabase.from(tableName).select(select);

      if (eq != null) {
        eq.forEach((key, value) {
          query = query.eq(key, value);
        });
      }

      if (order != null) {
        query = query.order(order, ascending: ascending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (single) {
        final response = await query.single();
        return [response];
      }

      if (maybeSingle) {
        final response = await query.maybeSingle();
        return response != null ? [response] : [];
      }

      if (rpc != null) {
        final response = await _supabase.rpc(rpc, params: rpcParams ?? {});
        return List<Map<String, dynamic>>.from(response);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching from $tableName: $e');
      return [];
    }
  }

  /// Generic method to insert data into a Supabase table.
  Future<bool> insertIntoTable(String tableName, Map<String, dynamic> data) async {
    try {
      await _supabase.from(tableName).insert(data);
      return true;
    } catch (e) {
      print('Error inserting into $tableName: $e');
      return false;
    }
  }

  /// Generic method to update data in a Supabase table.
  Future<bool> updateTable(String tableName, Map<String, dynamic> updates, Map<String, dynamic> eq) async {
    try {
      dynamic query = _supabase.from(tableName).update(updates);
      eq.forEach((key, value) {
        query = query.eq(key, value);
      });
      await query;
      return true;
    } catch (e) {
      print('Error updating $tableName: $e');
      return false;
    }
  }

  /// Generic method to delete data from a Supabase table.
  Future<bool> deleteFromTable(String tableName, Map<String, dynamic> eq) async {
    try {
      dynamic query = _supabase.from(tableName).delete();
      eq.forEach((key, value) {
        query = query.eq(key, value);
      });
      await query;
      return true;
    } catch (e) {
      print('Error deleting from $tableName: $e');
      return false;
    }
  }

  /// Generic method to call a Supabase RPC function.
  Future<dynamic> callRpc(String functionName, {Map<String, dynamic>? params}) async {
    try {
      final response = await _supabase.rpc(functionName, params: params ?? {});
      return response;
    } catch (e) {
      print('Error calling RPC function $functionName: $e');
      rethrow;
    }
  }

  /// Generic method to upload a file to Supabase Storage.
  Future<String?> uploadFile(Uint8List fileBytes, String fileName, String bucketName) async {
    try {
      await _supabase.storage.from(bucketName).uploadBinary(fileName, fileBytes);
      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(fileName);
      return publicUrl;
    } on StorageException catch (e) {
      print('Storage error uploading file: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  // Auth methods
  // Keep these as they are direct Supabase auth calls
  // User operations
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await fetchFromTable(
        'profiles',
        select: '*',
        eq: {'id': userId},
        single: true,
      );
      return response.isNotEmpty ? response.first : null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<bool> createUserProfile(Map<String, dynamic> userData) async {
    return await insertIntoTable('profiles', userData);
  }

  Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    return await updateTable(
      'profiles',
      {...updates, 'updated_at': DateTime.now().toIso8601String()},
      {'id': userId},
    );
  }

  // Quest operations using direct queries
  Future<List<Map<String, dynamic>>> getQuests() async {
    return await fetchFromTable(
      'quests_with_city',
      select: '''
        *,
        quest_categories!inner(name, color, icon)
      ''',
      eq: {'is_active': true},
      order: 'is_featured',
      ascending: false,
    );
  }

  Future<List<Map<String, dynamic>>> getQuestsByCity(String cityId) async {
    return await fetchFromTable(
      'quests_with_city',
      select: '''
        *,
        quest_categories!inner(name, color, icon)
      ''',
      eq: {'city_id': cityId, 'is_active': true},
      order: 'is_featured',
      ascending: false,
    );
  }

  Future<Map<String, dynamic>?> getQuestById(String questId) async {
    try {
      final questResponse = await fetchFromTable(
        'quests_with_city',
        select: '''
          *,
          quest_categories!inner(name, color, icon)
        ''',
        eq: {'id': questId},
        maybeSingle: true,
      );

      if (questResponse.isEmpty) {
        return null; // Quest not found
      }

      final stopsResponse = await fetchFromTable(
        'quest_stops',
        select: '*',
        eq: {'quest_id': questId},
        order: 'order_index',
      );

      return {
        'quest': questResponse.first,
        'stops': stopsResponse,
      };
    } catch (e) {
      print('Error getting quest: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getQuestStops(String questId) async {
    return await fetchFromTable(
      'quest_stops',
      select: '*',
      eq: {'quest_id': questId},
      order: 'order_index',
    );
  }

  // City operations
  Future<List<Map<String, dynamic>>> getCities() async {
    return await fetchFromTable(
      'cities',
      select: '''
        *,
        countries!inner(name)
      ''',
      eq: {'is_active': true},
      order: 'is_featured',
      ascending: false,
    );
  }

  // Enhanced Leaderboard using Edge Function
  Future<Map<String, dynamic>> getLeaderboard({
    int limit = 50,
    String? cityId,
    String timeframe = 'all_time',
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'leaderboard-manager',
        body: {
          'action': 'get',
          'limit': limit,
          'city_id': cityId,
          'timeframe': timeframe,
        },
      );

      if (response.status == 200) {
        return response.data;
      } else {
        throw Exception('Leaderboard request failed: ${response.status}');
      }
    } catch (e) {
      print('Error getting leaderboard via Edge Function: $e');
      
      // Fallback to direct query
      try {
        final response = await fetchFromTable(
          'leaderboard',
          select: '*',
          order: 'rank',
          limit: limit,
        );
        
        return {
          'leaderboard': response,
          'total_users': response.length,
        };
      } catch (fallbackError) {
        print('Error with fallback leaderboard query: $fallbackError');
        return {'leaderboard': [], 'total_users': 0};
      }
    }
  }

  Future<Map<String, dynamic>?> getUserPosition(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'leaderboard-manager',
        body: {
          'action': 'user_position',
          'user_id': userId,
        },
      );

      if (response.status == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Error getting user position: $e');
      return null;
    }
  }

  // Achievement Processing using Edge Function
  Future<Map<String, dynamic>> processAchievements({
    required String action,
    String? questId,
    String? stopId,
    Map<String, dynamic>? locationData,
    Map<String, dynamic>? photoData,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final body = {
        'action': action,
        'user_id': userId,
      };

      if (questId != null) body['quest_id'] = questId;
      if (stopId != null) body['stop_id'] = stopId;
      if (locationData != null) body['location_data'] = jsonEncode(locationData);
      if (photoData != null) body['photo_data'] = jsonEncode(photoData);

      final response = await _supabase.functions.invoke(
        'achievement-processor',
        body: body,
      );

      if (response.status == 200) {
        return response.data;
      } else {
        throw Exception('Achievement processing failed: ${response.status}');
      }
    } catch (e) {
      print('Error processing achievements: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Progress operations enhanced with achievement processing
  Future<bool> startQuest(String userId, String questId) async {
    return await insertIntoTable(
      'user_quest_progress',
      {
        'user_id': userId,
        'quest_id': questId,
        'status': 'in_progress',
        'started_at': DateTime.now().toIso8601String(),
        'completed_stops': [],
        'current_stop_index': 0,
        'points_earned': 0,
      },
    );
  }

  Future<Map<String, dynamic>?> getQuestProgress(String userId, String questId) async {
    try {
      final response = await fetchFromTable(
        'user_quest_progress',
        select: '*',
        eq: {'user_id': userId, 'quest_id': questId},
        maybeSingle: true,
      );
      return response.isNotEmpty ? response.first : null;
    } catch (e) {
      print('Error getting quest progress: $e');
      return null;
    }
  }

  Future<bool> completeStop({
    required String userId,
    required String questId,
    required String stopId,
    required Map<String, dynamic> stopData,
  }) async {
    try {
      // Get current progress
      final progress = await getQuestProgress(userId, questId);
      if (progress == null) return false;

      List<dynamic> completedStops = List.from(progress['completed_stops'] ?? []);
      completedStops.add(stopId);

      final success = await updateTable(
        'user_quest_progress',
        {
          'completed_stops': completedStops,
          'current_stop_index': (progress['current_stop_index'] ?? 0) + 1,
          'points_earned': (progress['points_earned'] ?? 0) + (stopData['points'] ?? 0),
          'updated_at': DateTime.now().toIso8601String(),
        },
        {'user_id': userId, 'quest_id': questId},
      );

      if (success) {
        // Process achievements for location visit
        await processAchievements(
          action: 'location_visited',
          questId: questId,
          stopId: stopId,
          locationData: stopData,
        );
      }
      return success;
    } catch (e) {
      print('Error completing stop: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> completeQuest({
    required String userId,
    required String questId,
    required Map<String, dynamic> completionData,
  }) async {
    try {
      // Use the achievement processor Edge Function for quest completion
      final result = await processAchievements(
        action: 'quest_completed',
        questId: questId,
      );

      if (result['success'] == true) {
        // Update quest progress status
        await updateTable(
          'user_quest_progress',
          {
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
            ...completionData,
          },
          {'user_id': userId, 'quest_id': questId},
        );
      }

      return result;
    } catch (e) {
      print('Error completing quest: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Achievement operations
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    return await fetchFromTable(
      'user_achievements',
      select: '*, achievements!inner(*)',
      eq: {'user_id': userId},
    );
  }

  Future<List<Map<String, dynamic>>> getAllAchievements() async {
    return await fetchFromTable(
      'achievements',
      select: '*',
      eq: {'is_active': true},
      order: 'category',
      ascending: false,
    );
  }

  // Photo upload with achievement processing
  Future<String?> uploadPhoto(Uint8List fileBytes, String fileName, String bucketName) async {
    try {
      // Check if user is authenticated
      if (currentUser == null) {
        print('Error uploading photo: User not authenticated');
        return null;
      }

      final publicUrl = await uploadFile(fileBytes, fileName, bucketName);

      // Process photo achievement
      await processAchievements(
        action: 'photo_uploaded',
        photoData: {'file_name': fileName, 'bucket': bucketName, 'public_url': publicUrl},
      );

      return publicUrl;
    } on StorageException catch (storageError) {
      print('Storage error uploading photo: ${storageError.message}');
      
      // If it's an RLS policy violation, try a fallback approach
      if (storageError.statusCode == 403 || storageError.message.contains('row-level security')) {
        print('RLS policy violation detected. Storage bucket may need proper policies configured.');
        
        // For now, return a placeholder URL to prevent app crashes
        // In production, you'd want to configure proper RLS policies
        return 'https://via.placeholder.com/150x150?text=Profile+Photo';
      }
      return null;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  // Create a user-specific photo upload with proper file path
  Future<String?> uploadUserPhoto(Uint8List fileBytes, String originalFileName) async {
    if (currentUser == null) return null;
    
    final userId = currentUser!.id;
    final fileExtension = originalFileName.split('.').last.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'profile_photos/${userId}_$timestamp.$fileExtension';
    
    return uploadPhoto(fileBytes, fileName, 'user-avatars');
  }

  // Real-time subscriptions
  Stream<List<Map<String, dynamic>>> streamLeaderboard() {
    return _supabase
        .from('leaderboard')
        .stream(primaryKey: ['rank'])
        .order('rank');
  }

  Stream<Map<String, dynamic>?> streamUserProfile(String userId) {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((data) => data.isNotEmpty ? data.first : null);
  }

  // Admin functions using Edge Function
  Future<Map<String, dynamic>> adminCreateQuest(Map<String, dynamic> questData) async {
    try {
      final response = await _supabase.functions.invoke(
        'admin-manager',
        body: {
          'action': 'create_quest',
          'quest_data': questData,
        },
      );

      if (response.status == 200) {
        return response.data;
      } else {
        throw Exception('Admin quest creation failed: ${response.status}');
      }
    } catch (e) {
      print('Error creating quest via admin: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final response = await _supabase.functions.invoke(
        'admin-manager',
        body: {'action': 'get_analytics'},
      );

      if (response.status == 200) {
        return response.data;
      } else {
        throw Exception('Analytics request failed: ${response.status}');
      }
    } catch (e) {
      print('Error getting analytics: $e');
      return {'error': e.toString()};
    }
    }

  // Location verification
  Future<Map<String, dynamic>> verifyLocation({
    required double latitude,
    required double longitude,
    required String stopId,
    double radiusMeters = 50.0,
  }) async {
    try {
      final response = await callRpc('verify_location', params: {
        'p_user_lat': latitude,
        'p_user_lng': longitude,
        'p_stop_id': stopId,
        'p_radius_meters': radiusMeters,
      });

      return response ?? {'verified': false};
    } catch (e) {
      print('Error verifying location: $e');
      return {'verified': false, 'error': e.toString()};
    }
  }
}
