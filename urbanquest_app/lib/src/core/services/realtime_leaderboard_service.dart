import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeLeaderboardService {
  static final RealtimeLeaderboardService _instance = RealtimeLeaderboardService._internal();
  factory RealtimeLeaderboardService() => _instance;
  RealtimeLeaderboardService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;
  
  // Stream controllers for real-time updates
  final _leaderboardController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _userPositionController = StreamController<int?>.broadcast();
  final _questCompletionController = StreamController<Map<String, dynamic>>.broadcast();

  // Public streams
  Stream<List<Map<String, dynamic>>> get leaderboardStream => _leaderboardController.stream;
  Stream<int?> get userPositionStream => _userPositionController.stream;
  Stream<Map<String, dynamic>> get questCompletionStream => _questCompletionController.stream;

  bool _isSubscribed = false;
  List<Map<String, dynamic>> _currentLeaderboard = [];

  /// Start real-time leaderboard subscriptions
  Future<void> startRealtimeUpdates() async {
    if (_isSubscribed) return;

    try {
      // Load initial leaderboard data
      await _loadInitialData();

      // Create realtime channel
      _channel = _supabase.channel('leaderboard-updates');

      // Subscribe to profile updates (when users gain points)
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'profiles',
        callback: (payload) {
          print('Profile updated: ${payload.newRecord}');
          _handleProfileUpdate(payload.newRecord);
        },
      );

      // Subscribe to quest completions
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'user_quest_progress',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'status',
          value: 'completed',
        ),
        callback: (payload) {
          print('Quest completed: ${payload.newRecord}');
          _handleQuestCompletion(payload.newRecord);
        },
      );

      // Subscribe to the channel
      _channel!.subscribe();
      _isSubscribed = true;
      
      print('Real-time leaderboard updates started');
    } catch (e) {
      print('Error starting real-time updates: $e');
    }
  }

  /// Stop real-time subscriptions
  Future<void> stopRealtimeUpdates() async {
    if (!_isSubscribed) return;

    try {
      await _channel?.unsubscribe();
      _channel = null;
      _isSubscribed = false;
      
      print('Real-time leaderboard updates stopped');
    } catch (e) {
      print('Error stopping real-time updates: $e');
    }
  }

  /// Load initial leaderboard data
  Future<void> _loadInitialData() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, display_name, avatar_url, total_points, level, quests_completed')
          .order('total_points', ascending: false)
          .limit(100);

      _currentLeaderboard = List<Map<String, dynamic>>.from(response);
      _leaderboardController.add(_currentLeaderboard);
      
      // Update current user position
      await _updateUserPosition();
    } catch (e) {
      print('Error loading initial leaderboard data: $e');
    }
  }

  /// Handle profile updates (points changes)
  void _handleProfileUpdate(Map<String, dynamic> updatedProfile) async {
    try {
      // Find and update the user in current leaderboard
      final userId = updatedProfile['id'];
      final existingIndex = _currentLeaderboard.indexWhere((user) => user['id'] == userId);

      if (existingIndex != -1) {
        // Update existing user
        _currentLeaderboard[existingIndex] = updatedProfile;
      } else {
        // Add new user to leaderboard if they have enough points
        final points = updatedProfile['total_points'] ?? 0;
        if (points > 0) {
          _currentLeaderboard.add(updatedProfile);
        }
      }

      // Re-sort leaderboard
      _currentLeaderboard.sort((a, b) => 
          (b['total_points'] ?? 0).compareTo(a['total_points'] ?? 0));

      // Limit to top 100
      if (_currentLeaderboard.length > 100) {
        _currentLeaderboard = _currentLeaderboard.take(100).toList();
      }

      // Emit updated leaderboard
      _leaderboardController.add(List.from(_currentLeaderboard));
      
      // Update user position if it's the current user
      final currentUser = _supabase.auth.currentUser;
      if (currentUser?.id == userId) {
        await _updateUserPosition();
      }
    } catch (e) {
      print('Error handling profile update: $e');
    }
  }

  /// Handle quest completion notifications
  void _handleQuestCompletion(Map<String, dynamic> questCompletion) {
    try {
      // Emit quest completion event for notifications
      _questCompletionController.add({
        'user_id': questCompletion['user_id'],
        'quest_id': questCompletion['quest_id'],
        'points_earned': questCompletion['points_earned'],
        'completed_at': questCompletion['completed_at'],
      });
    } catch (e) {
      print('Error handling quest completion: $e');
    }
  }

  /// Update current user's position in leaderboard
  Future<void> _updateUserPosition() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      // Get user's current rank
      final response = await _supabase.rpc('get_user_leaderboard_position', params: {
        'user_id': currentUser.id,
      });

      final position = response as int?;
      _userPositionController.add(position);
    } catch (e) {
      print('Error updating user position: $e');
      _userPositionController.add(null);
    }
  }

  /// Get current leaderboard snapshot
  List<Map<String, dynamic>> get currentLeaderboard => List.from(_currentLeaderboard);

  /// Get user's current position
  int? getUserPosition(String userId) {
    final index = _currentLeaderboard.indexWhere((user) => user['id'] == userId);
    return index != -1 ? index + 1 : null;
  }

  /// Get users near a specific position
  List<Map<String, dynamic>> getUsersNearPosition(int position, {int range = 2}) {
    final startIndex = (position - 1 - range).clamp(0, _currentLeaderboard.length);
    final endIndex = (position + range).clamp(0, _currentLeaderboard.length);
    
    return _currentLeaderboard.sublist(startIndex, endIndex);
  }

  /// Manually refresh leaderboard data
  Future<void> refreshLeaderboard() async {
    await _loadInitialData();
  }

  /// Subscribe to specific user updates
  Stream<Map<String, dynamic>> subscribeToUserUpdates(String userId) async* {
    await for (final leaderboard in leaderboardStream) {
      final user = leaderboard.firstWhere(
        (user) => user['id'] == userId,
        orElse: () => {},
      );
      if (user.isNotEmpty) {
        yield user;
      }
    }
  }

  /// Get leaderboard for a specific time period
  Future<List<Map<String, dynamic>>> getLeaderboardForPeriod({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
  }) async {
    try {
      // This would require a custom RPC function in Supabase
      final response = await _supabase.rpc('get_leaderboard_for_period', params: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'limit_count': limit,
      });

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting leaderboard for period: $e');
      return [];
    }
  }

  /// Get achievement notifications
  Stream<Map<String, dynamic>> get achievementStream async* {
    await for (final questCompletion in questCompletionStream) {
      // Check if the quest completion triggered any achievements
      try {
        final achievements = await _supabase.rpc('check_new_achievements', params: {
          'user_id': questCompletion['user_id'],
        });

        for (final achievement in achievements) {
          yield {
            'type': 'achievement',
            'achievement': achievement,
            'user_id': questCompletion['user_id'],
          };
        }
      } catch (e) {
        print('Error checking achievements: $e');
      }
    }
  }

  /// Dispose of resources
  void dispose() {
    stopRealtimeUpdates();
    _leaderboardController.close();
    _userPositionController.close();
    _questCompletionController.close();
  }
} 