// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_entry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaderboardEntry _$LeaderboardEntryFromJson(Map<String, dynamic> json) =>
    LeaderboardEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      points: (json['points'] as num).toInt(),
      rank: (json['rank'] as num).toInt(),
      level: (json['level'] as num?)?.toInt(),
      questsCompleted: (json['questsCompleted'] as num?)?.toInt(),
      city: json['city'] as String?,
      lastActiveAt: json['lastActiveAt'] == null
          ? null
          : DateTime.parse(json['lastActiveAt'] as String),
    );

Map<String, dynamic> _$LeaderboardEntryToJson(LeaderboardEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatar': instance.avatar,
      'points': instance.points,
      'rank': instance.rank,
      'level': instance.level,
      'questsCompleted': instance.questsCompleted,
      'city': instance.city,
      'lastActiveAt': instance.lastActiveAt?.toIso8601String(),
    };
