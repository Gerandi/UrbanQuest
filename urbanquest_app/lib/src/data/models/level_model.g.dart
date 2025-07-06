// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'level_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Level _$LevelFromJson(Map<String, dynamic> json) => Level(
      level: (json['level'] as num).toInt(),
      minPoints: (json['minPoints'] as num).toInt(),
      maxPoints: (json['maxPoints'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      color: (json['color'] as num).toInt(),
      perks: (json['perks'] as List<dynamic>).map((e) => e as String).toList(),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$LevelToJson(Level instance) => <String, dynamic>{
      'level': instance.level,
      'minPoints': instance.minPoints,
      'maxPoints': instance.maxPoints,
      'title': instance.title,
      'description': instance.description,
      'icon': instance.icon,
      'color': instance.color,
      'perks': instance.perks,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
    };
