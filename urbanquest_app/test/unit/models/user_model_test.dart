import 'package:flutter_test/flutter_test.dart';
import 'package:urbanquest_app/src/data/models/user_model.dart';

void main() {
  group('User Model Tests', () {
    late User user;
    late UserStats stats;

    setUp(() {
      stats = const UserStats(
        questsCompleted: 5,
        stopsVisited: 23,
        photosShared: 12,
        totalDistance: 15.5,
        citiesVisited: 2,
        achievementsUnlocked: 3,
        totalPlaytimeMinutes: 180,
        longestQuestStreak: 7,
        currentQuestStreak: 3,
        currentLevel: 4,
        levelTitle: 'Explorer',
      );

      user = User(
        id: 'test-user-123',
        email: 'test@example.com',
        displayName: 'Test User',
        avatar: 'https://example.com/avatar.jpg',
        createdAt: DateTime(2023, 1, 1),
        permissions: const ['user'],
        totalPoints: 850,
        stats: stats,
      );
    });

    test('should create User with correct properties', () {
      expect(user.id, 'test-user-123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
      expect(user.avatar, 'https://example.com/avatar.jpg');
      expect(user.totalPoints, 850);
      expect(user.permissions, ['user']);
      expect(user.stats, isNotNull);
    });

    test('should get level from UserStats', () {
      expect(user.level, 4);
    });

    test('should return level 1 when stats is null', () {
      final userWithoutStats = User(
        id: 'test-user-456',
        email: 'test2@example.com',
        displayName: 'Test User 2',
        avatar: '',
        createdAt: DateTime(2023, 1, 1),
        permissions: const ['user'],
        totalPoints: 0,
        stats: null,
      );

      expect(userWithoutStats.level, 1);
    });

    test('should create User from JSON correctly', () {
      final json = {
        'id': 'json-user-123',
        'email': 'json@example.com',
        'displayName': 'JSON User',
        'avatar': 'https://example.com/json-avatar.jpg',
        'createdAt': '2023-01-01T00:00:00.000Z',
        'permissions': ['user', 'admin'],
        'totalPoints': 1200,
        'stats': {
          'questsCompleted': 10,
          'stopsVisited': 45,
          'photosShared': 20,
          'totalDistance': 25.8,
          'citiesVisited': 3,
          'achievementsUnlocked': 5,
          'totalPlaytimeMinutes': 300,
          'longestQuestStreak': 10,
          'currentQuestStreak': 5,
          'currentLevel': 6,
          'levelTitle': 'Adventurer',
        },
      };

      final userFromJson = User.fromJson(json);

      expect(userFromJson.id, 'json-user-123');
      expect(userFromJson.email, 'json@example.com');
      expect(userFromJson.displayName, 'JSON User');
      expect(userFromJson.totalPoints, 1200);
      expect(userFromJson.permissions, ['user', 'admin']);
      expect(userFromJson.stats?.questsCompleted, 10);
      expect(userFromJson.level, 6);
    });

    test('should convert User to JSON correctly', () {
      final json = user.toJson();

      expect(json['id'], 'test-user-123');
      expect(json['email'], 'test@example.com');
      expect(json['displayName'], 'Test User');
      expect(json['totalPoints'], 850);
      expect(json['permissions'], ['user']);
      expect(json['stats'], isNotNull);
    });

    test('should create copy with updated properties', () {
      final updatedUser = user.copyWith(
        displayName: 'Updated User',
        totalPoints: 1000,
      );

      expect(updatedUser.id, user.id); // unchanged
      expect(updatedUser.displayName, 'Updated User'); // changed
      expect(updatedUser.totalPoints, 1000); // changed
      expect(updatedUser.email, user.email); // unchanged
    });

    test('should implement Equatable correctly', () {
      final user1 = User(
        id: 'same-id',
        email: 'same@example.com',
        displayName: 'Same User',
        avatar: 'same-avatar.jpg',
        createdAt: DateTime(2023, 1, 1),
        permissions: const ['user'],
        totalPoints: 100,
        stats: stats,
      );

      final user2 = User(
        id: 'same-id',
        email: 'same@example.com',
        displayName: 'Same User',
        avatar: 'same-avatar.jpg',
        createdAt: DateTime(2023, 1, 1),
        permissions: const ['user'],
        totalPoints: 100,
        stats: stats,
      );

      expect(user1, equals(user2));
    });
  });

  group('UserStats Model Tests', () {
    test('should create UserStats with correct properties', () {
      const stats = UserStats(
        questsCompleted: 10,
        stopsVisited: 50,
        photosShared: 25,
        totalDistance: 30.5,
        citiesVisited: 4,
        achievementsUnlocked: 8,
        totalPlaytimeMinutes: 400,
        longestQuestStreak: 12,
        currentQuestStreak: 5,
        currentLevel: 7,
        levelTitle: 'Master Explorer',
      );

      expect(stats.questsCompleted, 10);
      expect(stats.stopsVisited, 50);
      expect(stats.photosShared, 25);
      expect(stats.totalDistance, 30.5);
      expect(stats.citiesVisited, 4);
      expect(stats.achievementsUnlocked, 8);
      expect(stats.totalPlaytimeMinutes, 400);
      expect(stats.longestQuestStreak, 12);
      expect(stats.currentQuestStreak, 5);
      expect(stats.currentLevel, 7);
      expect(stats.levelTitle, 'Master Explorer');
    });

    test('should create UserStats from JSON correctly', () {
      final json = {
        'questsCompleted': 15,
        'stopsVisited': 75,
        'photosShared': 30,
        'totalDistance': 45.2,
        'citiesVisited': 5,
        'achievementsUnlocked': 12,
        'totalPlaytimeMinutes': 600,
        'longestQuestStreak': 15,
        'currentQuestStreak': 8,
        'currentLevel': 9,
        'levelTitle': 'Legend',
      };

      final stats = UserStats.fromJson(json);

      expect(stats.questsCompleted, 15);
      expect(stats.totalDistance, 45.2);
      expect(stats.levelTitle, 'Legend');
    });

    test('should convert UserStats to JSON correctly', () {
      const stats = UserStats(
        questsCompleted: 20,
        stopsVisited: 100,
        photosShared: 40,
        totalDistance: 60.0,
        citiesVisited: 6,
        achievementsUnlocked: 15,
        totalPlaytimeMinutes: 800,
        longestQuestStreak: 20,
        currentQuestStreak: 10,
        currentLevel: 10,
        levelTitle: 'Ultimate Explorer',
      );

      final json = stats.toJson();

      expect(json['questsCompleted'], 20);
      expect(json['totalDistance'], 60.0);
      expect(json['levelTitle'], 'Ultimate Explorer');
    });

    test('should create copy with updated properties', () {
      const originalStats = UserStats(
        questsCompleted: 5,
        stopsVisited: 25,
        photosShared: 10,
        totalDistance: 15.0,
        citiesVisited: 2,
        achievementsUnlocked: 3,
        totalPlaytimeMinutes: 200,
        longestQuestStreak: 7,
        currentQuestStreak: 3,
        currentLevel: 4,
        levelTitle: 'Explorer',
      );

      final updatedStats = originalStats.copyWith(
        questsCompleted: 6,
        currentLevel: 5,
        levelTitle: 'Advanced Explorer',
      );

      expect(updatedStats.questsCompleted, 6); // changed
      expect(updatedStats.currentLevel, 5); // changed
      expect(updatedStats.levelTitle, 'Advanced Explorer'); // changed
      expect(updatedStats.stopsVisited, 25); // unchanged
      expect(updatedStats.totalDistance, 15.0); // unchanged
    });
  });
}