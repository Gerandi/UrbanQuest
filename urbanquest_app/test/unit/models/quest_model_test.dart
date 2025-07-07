import 'package:flutter_test/flutter_test.dart';
import 'package:urbanquest_app/src/data/models/quest_model.dart';
import 'package:urbanquest_app/src/data/models/quest_requirement_model.dart';

void main() {
  group('Quest Model Tests', () {
    late Quest quest;
    late List<QuestRequirement> requirements;

    setUp(() {
      requirements = [
        const QuestRequirement(
          type: QuestRequirementType.goodShoes,
          isRequired: true,
        ),
        const QuestRequirement(
          type: QuestRequirementType.water,
          isRequired: true,
        ),
        const QuestRequirement(
          type: QuestRequirementType.camera,
          isRequired: false,
          customNote: 'For capturing great photos',
        ),
      ];

      quest = Quest(
        id: 'test-quest-123',
        title: 'Tirana Heritage Discovery',
        city: 'Tirana',
        description: 'Explore the historic center of Albania\'s capital city.',
        coverImageUrl: 'https://example.com/quest-image.jpg',
        estimatedDuration: '90 min',
        difficulty: 'Medium',
        isActive: true,
        numberOfStops: 5,
        rating: 4.7,
        completions: 1247,
        category: 'Culture & Heritage',
        points: 250,
        tags: const ['historic', 'walking', 'culture', 'beginner-friendly'],
        requirements: requirements,
      );
    });

    test('should create Quest with correct properties', () {
      expect(quest.id, 'test-quest-123');
      expect(quest.title, 'Tirana Heritage Discovery');
      expect(quest.city, 'Tirana');
      expect(quest.description, 'Explore the historic center of Albania\'s capital city.');
      expect(quest.coverImageUrl, 'https://example.com/quest-image.jpg');
      expect(quest.estimatedDuration, '90 min');
      expect(quest.difficulty, 'Medium');
      expect(quest.isActive, true);
      expect(quest.numberOfStops, 5);
      expect(quest.rating, 4.7);
      expect(quest.completions, 1247);
      expect(quest.category, 'Culture & Heritage');
      expect(quest.points, 250);
      expect(quest.tags, ['historic', 'walking', 'culture', 'beginner-friendly']);
      expect(quest.requirements, hasLength(3));
    });

    test('should create Quest from JSON with requirements', () {
      final json = {
        'id': 'json-quest-456',
        'title': 'JSON Quest',
        'cities': {'name': 'Berat'},
        'description': 'A quest from JSON',
        'cover_image_url': 'https://example.com/json-quest.jpg',
        'estimated_duration_minutes': '120',
        'difficulty': 'Hard',
        'is_active': true,
        'quest_stops_count': '6',
        'rating': '4.9',
        'total_completions': '892',
        'quest_categories': {'name': 'UNESCO Heritage'},
        'base_points': '350',
        'tags': ['unesco', 'architecture', 'photography'],
        'requirements': [
          {'type': 'good_shoes', 'is_required': true},
          {'type': 'water', 'is_required': true},
          {'type': 'camera', 'is_required': false, 'custom_note': 'Optional for photos'},
        ],
      };

      final questFromJson = Quest.fromJson(json);

      expect(questFromJson.id, 'json-quest-456');
      expect(questFromJson.title, 'JSON Quest');
      expect(questFromJson.city, 'Berat');
      expect(questFromJson.category, 'UNESCO Heritage');
      expect(questFromJson.requirements, hasLength(3));
      expect(questFromJson.requirements[0].type, QuestRequirementType.goodShoes);
      expect(questFromJson.requirements[2].customNote, 'Optional for photos');
    });

    test('should handle JSON with missing requirements field', () {
      final json = {
        'id': 'quest-no-reqs',
        'title': 'Quest Without Requirements',
        'city_name': 'Shkoder',
        'description': 'A simple quest',
        'cover_image_url': 'https://example.com/simple.jpg',
        'estimated_duration_minutes': '60',
        'difficulty': 'Easy',
        'is_active': true,
        'quest_stops_count': '3',
        'rating': '4.2',
        'total_completions': '500',
        'category': 'Nature',
        'base_points': '150',
        'tags': ['nature', 'easy'],
      };

      final questFromJson = Quest.fromJson(json);

      expect(questFromJson.requirements, isEmpty);
    });

    test('should parse requirements from string format', () {
      final json = {
        'id': 'quest-string-reqs',
        'title': 'Quest with String Requirements',
        'city_name': 'Durres',
        'description': 'A quest with comma-separated requirements',
        'cover_image_url': 'https://example.com/string-reqs.jpg',
        'estimated_duration_minutes': '90',
        'difficulty': 'Medium',
        'is_active': true,
        'quest_stops_count': '4',
        'rating': '4.5',
        'total_completions': '750',
        'category': 'History',
        'base_points': '200',
        'tags': ['history', 'coastal'],
        'requirements': 'good_shoes,water,charged_phone',
      };

      final questFromJson = Quest.fromJson(json);

      expect(questFromJson.requirements, hasLength(3));
      expect(questFromJson.requirements[0].type, QuestRequirementType.goodShoes);
      expect(questFromJson.requirements[1].type, QuestRequirementType.water);
      expect(questFromJson.requirements[2].type, QuestRequirementType.chargedPhone);
    });

    test('should handle invalid requirement types gracefully', () {
      final json = {
        'id': 'quest-invalid-reqs',
        'title': 'Quest with Invalid Requirements',
        'city_name': 'Vlore',
        'description': 'A quest with some invalid requirements',
        'cover_image_url': 'https://example.com/invalid-reqs.jpg',
        'estimated_duration_minutes': '75',
        'difficulty': 'Easy',
        'is_active': true,
        'quest_stops_count': '3',
        'rating': '4.0',
        'total_completions': '300',
        'category': 'Coastal',
        'base_points': '175',
        'tags': ['coastal', 'relaxing'],
        'requirements': [
          {'type': 'good_shoes', 'is_required': true},
          {'type': 'invalid_requirement', 'is_required': true},
          {'type': 'water', 'is_required': true},
        ],
      };

      final questFromJson = Quest.fromJson(json);

      // Should only include valid requirements
      expect(questFromJson.requirements, hasLength(2));
      expect(questFromJson.requirements[0].type, QuestRequirementType.goodShoes);
      expect(questFromJson.requirements[1].type, QuestRequirementType.water);
    });

    test('should convert Quest to JSON correctly', () {
      final json = quest.toJson();

      expect(json['id'], 'test-quest-123');
      expect(json['title'], 'Tirana Heritage Discovery');
      expect(json['city'], 'Tirana');
      expect(json['requirements'], isA<List>());
      expect(json['requirements'], hasLength(3));
    });

    test('should create copy with updated properties', () {
      final updatedQuest = quest.copyWith(
        title: 'Updated Quest Title',
        difficulty: 'Hard',
        points: 300,
        requirements: [
          const QuestRequirement(
            type: QuestRequirementType.goodShoes,
            isRequired: true,
          ),
        ],
      );

      expect(updatedQuest.id, quest.id); // unchanged
      expect(updatedQuest.title, 'Updated Quest Title'); // changed
      expect(updatedQuest.difficulty, 'Hard'); // changed
      expect(updatedQuest.points, 300); // changed
      expect(updatedQuest.requirements, hasLength(1)); // changed
      expect(updatedQuest.city, quest.city); // unchanged
    });

    test('should handle error in JSON parsing gracefully', () {
      final invalidJson = {
        'id': 'error-quest',
        // Missing required fields to trigger error
      };

      final errorQuest = Quest.fromJson(invalidJson);

      expect(errorQuest.id, 'error');
      expect(errorQuest.title, 'Error Loading Quest');
      expect(errorQuest.isActive, false);
      expect(errorQuest.requirements, isEmpty);
    });

    test('should implement Equatable correctly', () {
      final quest1 = Quest(
        id: 'same-quest',
        title: 'Same Quest',
        city: 'Same City',
        description: 'Same description',
        coverImageUrl: 'same-image.jpg',
        estimatedDuration: '60 min',
        difficulty: 'Easy',
        isActive: true,
        numberOfStops: 3,
        rating: 4.5,
        completions: 100,
        category: 'Test',
        points: 150,
        tags: const ['test'],
        requirements: const [],
      );

      final quest2 = Quest(
        id: 'same-quest',
        title: 'Same Quest',
        city: 'Same City',
        description: 'Same description',
        coverImageUrl: 'same-image.jpg',
        estimatedDuration: '60 min',
        difficulty: 'Easy',
        isActive: true,
        numberOfStops: 3,
        rating: 4.5,
        completions: 100,
        category: 'Test',
        points: 150,
        tags: const ['test'],
        requirements: const [],
      );

      expect(quest1, equals(quest2));
    });

    test('should parse tags correctly from different formats', () {
      final json1 = {
        'id': 'quest-1',
        'title': 'Quest 1',
        'city_name': 'City 1',
        'description': 'Description 1',
        'cover_image_url': 'image1.jpg',
        'estimated_duration_minutes': '60',
        'difficulty': 'Easy',
        'is_active': true,
        'quest_stops_count': '3',
        'rating': '4.0',
        'total_completions': '100',
        'category': 'Test',
        'base_points': '100',
        'tags': ['tag1', 'tag2', 'tag3'],
      };

      final quest1 = Quest.fromJson(json1);
      expect(quest1.tags, ['tag1', 'tag2', 'tag3']);

      final json2 = {
        'id': 'quest-2',
        'title': 'Quest 2',
        'city_name': 'City 2',
        'description': 'Description 2',
        'cover_image_url': 'image2.jpg',
        'estimated_duration_minutes': '60',
        'difficulty': 'Easy',
        'is_active': true,
        'quest_stops_count': '3',
        'rating': '4.0',
        'total_completions': '100',
        'category': 'Test',
        'base_points': '100',
        'tags': 'tag1,tag2,tag3',
      };

      final quest2 = Quest.fromJson(json2);
      expect(quest2.tags, ['tag1', 'tag2', 'tag3']);
    });
  });
}