// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      avatar: json['avatar'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      permissions: (json['permissions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      stats: json['stats'] == null
          ? null
          : UserStats.fromJson(json['stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'displayName': instance.displayName,
      'avatar': instance.avatar,
      'createdAt': instance.createdAt.toIso8601String(),
      'permissions': instance.permissions,
      'totalPoints': instance.totalPoints,
      'stats': instance.stats,
    };

UserStats _$UserStatsFromJson(Map<String, dynamic> json) => UserStats(
      questsCompleted: (json['questsCompleted'] as num).toInt(),
      stopsVisited: (json['stopsVisited'] as num).toInt(),
      photosShared: (json['photosShared'] as num).toInt(),
      totalDistance: (json['totalDistance'] as num).toDouble(),
      citiesVisited: (json['citiesVisited'] as num).toInt(),
      achievementsUnlocked: (json['achievementsUnlocked'] as num).toInt(),
      totalPlaytimeMinutes: (json['totalPlaytimeMinutes'] as num).toInt(),
      longestQuestStreak: (json['longestQuestStreak'] as num).toInt(),
      currentQuestStreak: (json['currentQuestStreak'] as num).toInt(),
      currentLevel: (json['currentLevel'] as num).toInt(),
      levelTitle: json['levelTitle'] as String,
    );

Map<String, dynamic> _$UserStatsToJson(UserStats instance) => <String, dynamic>{
      'questsCompleted': instance.questsCompleted,
      'stopsVisited': instance.stopsVisited,
      'photosShared': instance.photosShared,
      'totalDistance': instance.totalDistance,
      'citiesVisited': instance.citiesVisited,
      'achievementsUnlocked': instance.achievementsUnlocked,
      'totalPlaytimeMinutes': instance.totalPlaytimeMinutes,
      'longestQuestStreak': instance.longestQuestStreak,
      'currentQuestStreak': instance.currentQuestStreak,
      'currentLevel': instance.currentLevel,
      'levelTitle': instance.levelTitle,
    };
