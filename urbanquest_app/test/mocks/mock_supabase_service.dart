import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:urbanquest_app/src/core/services/supabase_service.dart';

class MockSupabaseService extends Mock implements SupabaseService {
  // Mock user for testing
  static const mockUserId = 'test-user-123';
  static final mockUser = User(
    id: mockUserId,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
  );

  @override
  User? get currentUser => mockUser;

  @override
  String? get currentUserId => mockUserId;

  @override
  bool get isAuthenticated => true;
}

// Mock data for testing
class MockData {
  static const mockUserProfile = {
    'id': MockSupabaseService.mockUserId,
    'email': 'test@example.com',
    'display_name': 'Test User',
    'avatar_url': 'https://example.com/avatar.jpg',
    'total_points': 850,
    'created_at': '2023-01-01T00:00:00.000Z',
    'user_stats': [
      {
        'user_id': MockSupabaseService.mockUserId,
        'quests_completed': 5,
        'stops_visited': 23,
        'photos_shared': 12,
        'total_distance_km': 15.5,
        'cities_visited': 2,
        'achievements_unlocked': 3,
        'total_playtime_minutes': 180,
        'longest_quest_streak': 7,
        'current_quest_streak': 3,
        'current_level': 4,
        'level_title': 'Explorer',
      }
    ],
  };

  static const mockUserStats = {
    'user_id': MockSupabaseService.mockUserId,
    'quests_completed': 5,
    'stops_visited': 23,
    'photos_shared': 12,
    'total_distance_km': 15.5,
    'cities_visited': 2,
    'achievements_unlocked': 3,
    'total_playtime_minutes': 180,
    'longest_quest_streak': 7,
    'current_quest_streak': 3,
    'current_level': 4,
    'level_title': 'Explorer',
  };

  static const mockAchievements = [
    {
      'achievements': {
        'id': 'welcome',
        'title': 'Welcome!',
        'description': 'Started your Urban Quest journey',
        'icon': 'star',
        'color': 4294951175, // 0xFFFFD700 in int format
        'condition': {
          'type': 'quest_completion',
          'target_value': 1,
          'description': 'Complete your first quest'
        },
        'points': 10,
        'is_active': true,
        'created_at': '2023-01-01T00:00:00.000Z',
      }
    },
    {
      'achievements': {
        'id': 'first_quest',
        'title': 'First Steps',
        'description': 'Complete your first quest',
        'icon': 'baby-steps',
        'color': 4294940928, // 0xFFFF6B00 in int format
        'condition': {
          'type': 'quest_completion',
          'target_value': 1,
          'description': 'Complete your first quest'
        },
        'points': 50,
        'is_active': true,
        'created_at': '2023-01-01T00:00:00.000Z',
      }
    },
  ];

  static const mockQuestHistory = [
    {
      'quests': {
        'id': 'tirana-heritage-discovery',
        'title': 'Tirana Heritage Discovery',
        'cities': {'name': 'Tirana'},
        'description': 'Explore the historic center of Albania\'s capital city.',
        'cover_image_url': 'https://example.com/tirana-quest.jpg',
        'estimated_duration_minutes': '90',
        'difficulty': 'Medium',
        'is_active': true,
        'quest_stops_count': '5',
        'rating': '4.7',
        'total_completions': '1247',
        'quest_categories': {'name': 'Culture & Heritage'},
        'base_points': '250',
        'tags': ['historic', 'walking', 'culture'],
        'requirements': [
          {'type': 'good_shoes', 'is_required': true},
          {'type': 'water', 'is_required': true},
        ],
      }
    },
  ];

  static const mockQuest = {
    'id': 'test-quest-123',
    'title': 'Test Quest',
    'cities': {'name': 'Test City'},
    'description': 'A test quest for unit testing',
    'cover_image_url': 'https://example.com/test-quest.jpg',
    'estimated_duration_minutes': '60',
    'difficulty': 'Easy',
    'is_active': true,
    'quest_stops_count': '3',
    'rating': '4.5',
    'total_completions': '100',
    'quest_categories': {'name': 'Test Category'},
    'base_points': '150',
    'tags': ['test', 'easy'],
    'requirements': [
      {'type': 'good_shoes', 'is_required': true},
    ],
  };

  static const mockQuestStops = [
    {
      'id': 'stop-1',
      'quest_id': 'test-quest-123',
      'order_index': 1,
      'name': 'Test Stop 1',
      'description': 'First test stop',
      'latitude': 41.3275,
      'longitude': 19.8187,
      'radius_meters': 50,
      'stop_type': 'location',
      'challenge_type': 'photo',
      'challenge_data': {'instruction': 'Take a photo of the monument'},
      'hints': ['Look for the tall building'],
      'is_active': true,
    },
    {
      'id': 'stop-2',
      'quest_id': 'test-quest-123',
      'order_index': 2,
      'name': 'Test Stop 2',
      'description': 'Second test stop',
      'latitude': 41.3280,
      'longitude': 19.8190,
      'radius_meters': 30,
      'stop_type': 'location',
      'challenge_type': 'trivia',
      'challenge_data': {
        'question': 'What year was this built?',
        'options': ['1920', '1930', '1940', '1950'],
        'correct_answer': 1
      },
      'hints': ['Check the plaque'],
      'is_active': true,
    },
  ];

  static const mockCategories = [
    {
      'id': 'culture-heritage',
      'name': 'Culture & Heritage',
      'description': 'Explore historical and cultural landmarks',
      'icon': 'museum',
      'color': '#FF6B6B',
      'is_active': true,
      'sort_order': 1,
      'created_at': '2023-01-01T00:00:00.000Z',
    },
    {
      'id': 'nature-outdoor',
      'name': 'Nature & Outdoor',
      'description': 'Explore natural landscapes and outdoor adventures',
      'icon': 'nature',
      'color': '#228B22',
      'is_active': true,
      'sort_order': 2,
      'created_at': '2023-01-01T00:00:00.000Z',
    },
  ];

  static const mockLeaderboard = [
    {
      'id': 'user-1',
      'display_name': 'Top Player',
      'avatar_url': 'https://example.com/avatar1.jpg',
      'total_points': 2500,
      'level': 8,
      'quests_completed': 25,
    },
    {
      'id': MockSupabaseService.mockUserId,
      'display_name': 'Test User',
      'avatar_url': 'https://example.com/avatar.jpg',
      'total_points': 850,
      'level': 4,
      'quests_completed': 5,
    },
    {
      'id': 'user-3',
      'display_name': 'Third Player',
      'avatar_url': 'https://example.com/avatar3.jpg',
      'total_points': 650,
      'level': 3,
      'quests_completed': 8,
    },
  ];
}

// Helper class for creating mock responses
class MockResponse {
  static List<Map<String, dynamic>> userProfile() => [MockData.mockUserProfile];
  
  static List<Map<String, dynamic>> userStats() => [MockData.mockUserStats];
  
  static List<Map<String, dynamic>> achievements() => MockData.mockAchievements;
  
  static List<Map<String, dynamic>> questHistory() => MockData.mockQuestHistory;
  
  static List<Map<String, dynamic>> quest() => [MockData.mockQuest];
  
  static List<Map<String, dynamic>> questStops() => MockData.mockQuestStops;
  
  static List<Map<String, dynamic>> categories() => MockData.mockCategories;
  
  static List<Map<String, dynamic>> leaderboard() => MockData.mockLeaderboard;
  
  static List<Map<String, dynamic>> empty() => [];
  
  static int leaderboardPosition() => 2; // Test user is in 2nd place
}