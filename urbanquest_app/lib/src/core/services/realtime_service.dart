import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Real-time service for UrbanQuest app using Supabase subscriptions
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  
  // Stream controllers
  final _leaderboardController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Public streams
  Stream<List<Map<String, dynamic>>> get leaderboardStream => _leaderboardController.stream;
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  bool _isActive = false;

  /// Start real-time subscriptions
  Future<void> start() async {
    if (_isActive) return;

    try {
      _channel = _supabase.channel('urbanquest-realtime');

      // Subscribe to leaderboard changes
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'profiles',
        callback: (payload) => _handleLeaderboardUpdate(payload.newRecord),
      );

      // Subscribe to quest completions
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'user_quest_progress',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'status',
          value: 'completed',
        ),
        callback: (payload) => _handleQuestCompletion(payload.newRecord),
      );

      _channel!.subscribe();
      _isActive = true;
      
      print('✅ Real-time services started');
    } catch (e) {
      print('❌ Error starting real-time services: $e');
    }
  }

  /// Stop real-time subscriptions
  Future<void> stop() async {
    if (!_isActive) return;

    await _channel?.unsubscribe();
    _channel = null;
    _isActive = false;
    print('🛑 Real-time services stopped');
  }

  /// Handle leaderboard updates
  void _handleLeaderboardUpdate(Map<String, dynamic> updatedUser) async {
    try {
      // Fetch updated leaderboard
      final leaderboard = await _supabase
          .from('profiles')
          .select('id, display_name, avatar_url, total_points, level')
          .order('total_points', ascending: false)
          .limit(50);

      _leaderboardController.add(List<Map<String, dynamic>>.from(leaderboard));
    } catch (e) {
      print('Error handling leaderboard update: $e');
    }
  }

  /// Handle quest completion notifications
  void _handleQuestCompletion(Map<String, dynamic> completion) {
    _notificationController.add({
      'type': 'quest_completion',
      'data': completion,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get current leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, display_name, avatar_url, total_points, level')
          .order('total_points', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  void dispose() {
    stop();
    _leaderboardController.close();
    _notificationController.close();
  }
} 