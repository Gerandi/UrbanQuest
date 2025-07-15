// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_tutorial_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestTutorial _$QuestTutorialFromJson(Map<String, dynamic> json) =>
    QuestTutorial(
      id: json['id'] as String,
      questId: json['questId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
      tips: (json['tips'] as List<dynamic>).map((e) => e as String).toList(),
      icon: json['icon'] as String? ?? 'help_outline',
      orderIndex: (json['orderIndex'] as num).toInt(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$QuestTutorialToJson(QuestTutorial instance) =>
    <String, dynamic>{
      'id': instance.id,
      'questId': instance.questId,
      'title': instance.title,
      'description': instance.description,
      'steps': instance.steps,
      'tips': instance.tips,
      'icon': instance.icon,
      'orderIndex': instance.orderIndex,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
