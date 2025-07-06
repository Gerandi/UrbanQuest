// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_quest_progress_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserQuestProgress _$UserQuestProgressFromJson(Map<String, dynamic> json) =>
    UserQuestProgress(
      id: json['id'] as String,
      userId: json['userId'] as String,
      questId: json['questId'] as String,
      status: $enumDecodeNullable(_$QuestStatusEnumMap, json['status']) ??
          QuestStatus.notStarted,
      completedStops: (json['completedStops'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      currentStopIndex: (json['currentStopIndex'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      timeSpent: json['timeSpent'] == null
          ? null
          : Duration(microseconds: (json['timeSpent'] as num).toInt()),
      challengeAnswers:
          json['challengeAnswers'] as Map<String, dynamic>? ?? const {},
      photosTaken: (json['photosTaken'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      userRating: (json['userRating'] as num?)?.toDouble(),
      userReview: json['userReview'] as String?,
    );

Map<String, dynamic> _$UserQuestProgressToJson(UserQuestProgress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'questId': instance.questId,
      'status': _$QuestStatusEnumMap[instance.status]!,
      'completedStops': instance.completedStops,
      'currentStopIndex': instance.currentStopIndex,
      'pointsEarned': instance.pointsEarned,
      'startedAt': instance.startedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'timeSpent': instance.timeSpent?.inMicroseconds,
      'challengeAnswers': instance.challengeAnswers,
      'photosTaken': instance.photosTaken,
      'userRating': instance.userRating,
      'userReview': instance.userReview,
    };

const _$QuestStatusEnumMap = {
  QuestStatus.notStarted: 'notStarted',
  QuestStatus.inProgress: 'inProgress',
  QuestStatus.completed: 'completed',
  QuestStatus.abandoned: 'abandoned',
};
