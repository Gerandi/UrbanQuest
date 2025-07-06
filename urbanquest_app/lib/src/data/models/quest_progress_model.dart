import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quest_progress_model.g.dart';

@JsonSerializable()
class QuestProgress extends Equatable {
  final String id;
  final String userId;
  final String questId;
  final String status; // 'not_started', 'in_progress', 'completed'
  final int currentStopOrder;
  final int earnedPoints;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<String> completedStops;

  const QuestProgress({
    required this.id,
    required this.userId,
    required this.questId,
    required this.status,
    required this.currentStopOrder,
    required this.earnedPoints,
    this.startedAt,
    this.completedAt,
    required this.completedStops,
  });

  factory QuestProgress.fromJson(Map<String, dynamic> json) => _$QuestProgressFromJson(json);
  Map<String, dynamic> toJson() => _$QuestProgressToJson(this);

  QuestProgress copyWith({
    String? id,
    String? userId,
    String? questId,
    String? status,
    int? currentStopOrder,
    int? earnedPoints,
    DateTime? startedAt,
    DateTime? completedAt,
    List<String>? completedStops,
  }) {
    return QuestProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questId: questId ?? this.questId,
      status: status ?? this.status,
      currentStopOrder: currentStopOrder ?? this.currentStopOrder,
      earnedPoints: earnedPoints ?? this.earnedPoints,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      completedStops: completedStops ?? this.completedStops,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        questId,
        status,
        currentStopOrder,
        earnedPoints,
        startedAt,
        completedAt,
        completedStops,
      ];
} 