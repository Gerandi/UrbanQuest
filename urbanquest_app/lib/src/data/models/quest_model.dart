import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'quest_requirement_model.dart';

part 'quest_model.g.dart';

@JsonSerializable()
class Quest extends Equatable {
  final String id;
  final String title;
  final String city;
  final String description;
  final String coverImageUrl;
  final String estimatedDuration;
  final String difficulty;
  final bool isActive;
  final int numberOfStops;
  final double rating;
  final int completions;
  final String category;
  final int points;
  final List<String> tags;
  final List<QuestRequirement> requirements;

  const Quest({
    required this.id,
    required this.title,
    required this.city,
    required this.description,
    required this.coverImageUrl,
    required this.estimatedDuration,
    required this.difficulty,
    required this.isActive,
    required this.numberOfStops,
    required this.rating,
    required this.completions,
    required this.category,
    required this.points,
    required this.tags,
    this.requirements = const [],
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    try {
      // Handle nested city name from relationship
      String cityName = '';
      if (json['cities'] != null) {
        if (json['cities'] is Map) {
          cityName = json['cities']['name']?.toString() ?? '';
        } else if (json['cities'] is List && (json['cities'] as List).isNotEmpty) {
          cityName = json['cities'][0]['name']?.toString() ?? '';
        }
      }
      
      // Handle nested category from relationship
      String categoryName = '';
      if (json['quest_categories'] != null) {
        if (json['quest_categories'] is Map) {
          categoryName = json['quest_categories']['name']?.toString() ?? '';
        } else if (json['quest_categories'] is List && (json['quest_categories'] as List).isNotEmpty) {
          categoryName = json['quest_categories'][0]['name']?.toString() ?? '';
        }
      }

      return Quest(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Untitled Quest',
        city: cityName.isNotEmpty ? cityName : (json['city_name']?.toString() ?? 'Unknown City'),
        description: json['description']?.toString() ?? '',
        coverImageUrl: json['cover_image_url']?.toString() ?? 'https://via.placeholder.com/600x400?text=Quest+Image',
        estimatedDuration: json['estimated_duration_minutes']?.toString() ?? '60',
        difficulty: json['difficulty']?.toString() ?? 'Easy',
        isActive: json['is_active'] == true,
        numberOfStops: int.tryParse(json['quest_stops_count']?.toString() ?? '0') ?? 0,
        rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
        completions: int.tryParse(json['total_completions']?.toString() ?? '0') ?? 0,
        category: categoryName.isNotEmpty ? categoryName : (json['category']?.toString() ?? 'General'),
        points: int.tryParse(json['base_points']?.toString() ?? '0') ?? 0,
        tags: _parseTagsList(json['tags']),
        requirements: _parseRequirementsList(json['requirements']),
      );
    } catch (e) {
      print('Error parsing Quest from JSON: $e');
      print('JSON: $json');
      // Return a default quest to prevent crashes
      return const Quest(
        id: 'error',
        title: 'Error Loading Quest',
        city: 'Unknown',
        description: 'This quest could not be loaded properly.',
        coverImageUrl: 'https://via.placeholder.com/600x400?text=Error',
        estimatedDuration: '0',
        difficulty: 'Easy',
        isActive: false,
        numberOfStops: 0,
        rating: 0.0,
        completions: 0,
        category: 'Error',
        points: 0,
        tags: [],
        requirements: [],
      );
    }
  }

  static List<String> _parseTagsList(dynamic tags) {
    if (tags == null) return [];
    if (tags is List) {
      return tags.map((tag) => tag.toString()).toList();
    }
    if (tags is String) {
      try {
        // Try to parse as JSON array
        final parsed = tags.split(',').map((s) => s.trim()).toList();
        return parsed;
      } catch (e) {
        return [tags];
      }
    }
    return [];
  }

  static List<QuestRequirement> _parseRequirementsList(dynamic requirements) {
    if (requirements == null) return [];
    
    if (requirements is List) {
      return requirements
          .map((req) {
            try {
              if (req is Map<String, dynamic>) {
                return QuestRequirement.fromJson(req);
              } else if (req is String) {
                // Handle simple string format: "good_shoes,water,charged_phone"
                final type = QuestRequirementType.fromId(req);
                if (type != null) {
                  return QuestRequirement(type: type);
                }
              }
            } catch (e) {
              print('Error parsing requirement: $e');
            }
            return null;
          })
          .where((req) => req != null)
          .cast<QuestRequirement>()
          .toList();
    }
    
    if (requirements is String) {
      // Handle comma-separated string format
      return requirements
          .split(',')
          .map((req) => req.trim())
          .map((reqId) {
            final type = QuestRequirementType.fromId(reqId);
            return type != null ? QuestRequirement(type: type) : null;
          })
          .where((req) => req != null)
          .cast<QuestRequirement>()
          .toList();
    }
    
    return [];
  }

  Map<String, dynamic> toJson() => _$QuestToJson(this);

  Quest copyWith({
    String? id,
    String? title,
    String? city,
    String? description,
    String? coverImageUrl,
    String? estimatedDuration,
    String? difficulty,
    bool? isActive,
    int? numberOfStops,
    double? rating,
    int? completions,
    String? category,
    int? points,
    List<String>? tags,
    List<QuestRequirement>? requirements,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      city: city ?? this.city,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      difficulty: difficulty ?? this.difficulty,
      isActive: isActive ?? this.isActive,
      numberOfStops: numberOfStops ?? this.numberOfStops,
      rating: rating ?? this.rating,
      completions: completions ?? this.completions,
      category: category ?? this.category,
      points: points ?? this.points,
      tags: tags ?? this.tags,
      requirements: requirements ?? this.requirements,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        city,
        description,
        coverImageUrl,
        estimatedDuration,
        difficulty,
        isActive,
        numberOfStops,
        rating,
        completions,
        category,
        points,
        tags,
        requirements,
      ];
}
