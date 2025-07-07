import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbanquest_app/src/data/models/quest_requirement_model.dart';

void main() {
  group('QuestRequirementType Tests', () {
    test('should have correct properties for goodShoes', () {
      const type = QuestRequirementType.goodShoes;
      
      expect(type.id, 'good_shoes');
      expect(type.displayName, 'Good Shoes');
      expect(type.icon, Icons.directions_walk);
    });

    test('should have correct properties for water', () {
      const type = QuestRequirementType.water;
      
      expect(type.id, 'water');
      expect(type.displayName, 'Water');
      expect(type.icon, Icons.water_drop_outlined);
    });

    test('should have correct properties for chargedPhone', () {
      const type = QuestRequirementType.chargedPhone;
      
      expect(type.id, 'charged_phone');
      expect(type.displayName, 'Charged Phone');
      expect(type.icon, Icons.battery_charging_full);
    });

    test('should have correct properties for camera', () {
      const type = QuestRequirementType.camera;
      
      expect(type.id, 'camera');
      expect(type.displayName, 'Camera');
      expect(type.icon, Icons.camera_alt_outlined);
    });

    test('should find requirement type by id', () {
      final type = QuestRequirementType.fromId('good_shoes');
      expect(type, QuestRequirementType.goodShoes);
      
      final waterType = QuestRequirementType.fromId('water');
      expect(waterType, QuestRequirementType.water);
      
      final phoneType = QuestRequirementType.fromId('charged_phone');
      expect(phoneType, QuestRequirementType.chargedPhone);
    });

    test('should return null for invalid id', () {
      final type = QuestRequirementType.fromId('invalid_id');
      expect(type, isNull);
      
      final emptyType = QuestRequirementType.fromId('');
      expect(emptyType, isNull);
    });

    test('should have all 15 requirement types', () {
      expect(QuestRequirementType.values, hasLength(15));
      
      // Verify all types have unique IDs
      final ids = QuestRequirementType.values.map((type) => type.id).toSet();
      expect(ids, hasLength(15));
    });

    test('should have meaningful display names for all types', () {
      for (final type in QuestRequirementType.values) {
        expect(type.displayName, isNotEmpty);
        expect(type.displayName.length, greaterThan(2));
      }
    });

    test('should have valid icons for all types', () {
      for (final type in QuestRequirementType.values) {
        expect(type.icon, isNotNull);
        expect(type.icon, isA<IconData>());
      }
    });

    test('should find all standard requirement types', () {
      final expectedTypes = [
        'good_shoes',
        'water',
        'charged_phone',
        'camera',
        'sunscreen',
        'hat',
        'snacks',
        'notebook',
        'pen',
        'flashlight',
        'first_aid',
        'umbrella',
        'jacket',
        'backpack',
        'tickets',
      ];

      for (final id in expectedTypes) {
        final type = QuestRequirementType.fromId(id);
        expect(type, isNotNull, reason: 'Type with id "$id" should exist');
      }
    });
  });

  group('QuestRequirement Tests', () {
    test('should create QuestRequirement with required properties', () {
      const requirement = QuestRequirement(
        type: QuestRequirementType.goodShoes,
        isRequired: true,
      );

      expect(requirement.type, QuestRequirementType.goodShoes);
      expect(requirement.isRequired, true);
      expect(requirement.customNote, isNull);
    });

    test('should create QuestRequirement with custom note', () {
      const requirement = QuestRequirement(
        type: QuestRequirementType.camera,
        isRequired: false,
        customNote: 'For capturing beautiful moments',
      );

      expect(requirement.type, QuestRequirementType.camera);
      expect(requirement.isRequired, false);
      expect(requirement.customNote, 'For capturing beautiful moments');
    });

    test('should default isRequired to true', () {
      const requirement = QuestRequirement(
        type: QuestRequirementType.water,
      );

      expect(requirement.isRequired, true);
    });

    test('should create QuestRequirement from JSON', () {
      final json = {
        'type': 'good_shoes',
        'is_required': true,
        'custom_note': 'Comfortable walking shoes recommended',
      };

      final requirement = QuestRequirement.fromJson(json);

      expect(requirement.type, QuestRequirementType.goodShoes);
      expect(requirement.isRequired, true);
      expect(requirement.customNote, 'Comfortable walking shoes recommended');
    });

    test('should create QuestRequirement from JSON with minimal data', () {
      final json = {
        'type': 'water',
      };

      final requirement = QuestRequirement.fromJson(json);

      expect(requirement.type, QuestRequirementType.water);
      expect(requirement.isRequired, true); // default value
      expect(requirement.customNote, isNull);
    });

    test('should throw error for invalid requirement type in JSON', () {
      final json = {
        'type': 'invalid_type',
        'is_required': true,
      };

      expect(
        () => QuestRequirement.fromJson(json),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should convert QuestRequirement to JSON', () {
      const requirement = QuestRequirement(
        type: QuestRequirementType.camera,
        isRequired: false,
        customNote: 'Optional for photos',
      );

      final json = requirement.toJson();

      expect(json['type'], 'camera');
      expect(json['is_required'], false);
      expect(json['custom_note'], 'Optional for photos');
    });

    test('should convert QuestRequirement to JSON without custom note', () {
      const requirement = QuestRequirement(
        type: QuestRequirementType.goodShoes,
        isRequired: true,
      );

      final json = requirement.toJson();

      expect(json['type'], 'good_shoes');
      expect(json['is_required'], true);
      expect(json['custom_note'], isNull);
    });

    test('should implement Equatable correctly', () {
      const requirement1 = QuestRequirement(
        type: QuestRequirementType.water,
        isRequired: true,
        customNote: 'Stay hydrated',
      );

      const requirement2 = QuestRequirement(
        type: QuestRequirementType.water,
        isRequired: true,
        customNote: 'Stay hydrated',
      );

      const requirement3 = QuestRequirement(
        type: QuestRequirementType.water,
        isRequired: false,
        customNote: 'Stay hydrated',
      );

      expect(requirement1, equals(requirement2));
      expect(requirement1, isNot(equals(requirement3)));
    });

    test('should handle JSON with different boolean formats', () {
      final json1 = {
        'type': 'water',
        'is_required': true,
      };

      final json2 = {
        'type': 'water',
        'is_required': 'true',
      };

      final json3 = {
        'type': 'water',
        'is_required': 1,
      };

      final requirement1 = QuestRequirement.fromJson(json1);
      expect(requirement1.isRequired, true);

      // These should handle type conversion gracefully or use defaults
      final requirement2 = QuestRequirement.fromJson(json2);
      expect(requirement2.isRequired, true); // Default when not bool

      final requirement3 = QuestRequirement.fromJson(json3);
      expect(requirement3.isRequired, true); // Default when not bool
    });

    test('should create requirements for all standard types', () {
      for (final type in QuestRequirementType.values) {
        final requirement = QuestRequirement(type: type);
        
        expect(requirement.type, type);
        expect(requirement.isRequired, true);
        expect(requirement.customNote, isNull);
      }
    });

    test('should preserve all data in JSON round trip', () {
      const original = QuestRequirement(
        type: QuestRequirementType.flashlight,
        isRequired: false,
        customNote: 'Useful for evening quests',
      );

      final json = original.toJson();
      final restored = QuestRequirement.fromJson(json);

      expect(restored, equals(original));
      expect(restored.type, original.type);
      expect(restored.isRequired, original.isRequired);
      expect(restored.customNote, original.customNote);
    });
  });
}