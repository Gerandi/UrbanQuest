// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Quest _$QuestFromJson(Map<String, dynamic> json) => Quest(
      id: json['id'] as String,
      title: json['title'] as String,
      city: json['city'] as String,
      description: json['description'] as String,
      coverImageUrl: json['coverImageUrl'] as String,
      estimatedDuration: json['estimatedDuration'] as String,
      difficulty: json['difficulty'] as String,
      isActive: json['isActive'] as bool,
      numberOfStops: (json['numberOfStops'] as num).toInt(),
      rating: (json['rating'] as num).toDouble(),
      completions: (json['completions'] as num).toInt(),
      category: json['category'] as String,
      points: (json['points'] as num).toInt(),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$QuestToJson(Quest instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'city': instance.city,
      'description': instance.description,
      'coverImageUrl': instance.coverImageUrl,
      'estimatedDuration': instance.estimatedDuration,
      'difficulty': instance.difficulty,
      'isActive': instance.isActive,
      'numberOfStops': instance.numberOfStops,
      'rating': instance.rating,
      'completions': instance.completions,
      'category': instance.category,
      'points': instance.points,
      'tags': instance.tags,
    };
