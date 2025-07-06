// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_progress_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestProgress _$QuestProgressFromJson(Map<String, dynamic> json) =>
    QuestProgress(
      id: json['id'] as String,
      userId: json['userId'] as String,
      questId: json['questId'] as String,
      status: json['status'] as String,
      currentStopOrder: (json['currentStopOrder'] as num).toInt(),
      earnedPoints: (json['earnedPoints'] as num).toInt(),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      completedStops: (json['completedStops'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$QuestProgressToJson(QuestProgress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'questId': instance.questId,
      'status': instance.status,
      'currentStopOrder': instance.currentStopOrder,
      'earnedPoints': instance.earnedPoints,
      'startedAt': instance.startedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'completedStops': instance.completedStops,
    };
