// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      color: (json['color'] as num).toInt(),
      condition: Achievement._achievementConditionFromJson(
          json['condition'] as Map<String, dynamic>),
      points: (json['points'] as num).toInt(),
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'icon': instance.icon,
      'color': instance.color,
      'condition': Achievement._achievementConditionToJson(instance.condition),
      'points': instance.points,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
    };

AchievementCondition _$AchievementConditionFromJson(
        Map<String, dynamic> json) =>
    AchievementCondition(
      type: json['type'] as String,
      threshold: (json['threshold'] as num).toInt(),
      badgeId: json['badgeId'] as String?,
    );

Map<String, dynamic> _$AchievementConditionToJson(
        AchievementCondition instance) =>
    <String, dynamic>{
      'type': instance.type,
      'threshold': instance.threshold,
      'badgeId': instance.badgeId,
    };

UserAchievement _$UserAchievementFromJson(Map<String, dynamic> json) =>
    UserAchievement(
      id: json['id'] as String,
      userId: json['userId'] as String,
      achievementId: json['achievementId'] as String,
      unlockedAt: DateTime.parse(json['unlockedAt'] as String),
      pointsEarned: (json['pointsEarned'] as num).toInt(),
    );

Map<String, dynamic> _$UserAchievementToJson(UserAchievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'achievementId': instance.achievementId,
      'unlockedAt': instance.unlockedAt.toIso8601String(),
      'pointsEarned': instance.pointsEarned,
    };
