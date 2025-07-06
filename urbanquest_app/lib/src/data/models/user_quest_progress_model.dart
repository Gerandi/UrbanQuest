import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_quest_progress_model.g.dart';

enum QuestStatus { notStarted, inProgress, completed, abandoned }

@JsonSerializable()
class UserQuestProgress extends Equatable {
  final String id;
  final String userId;
  final String questId;
  final QuestStatus status;
  final List<String> completedStops;
  final int currentStopIndex;
  final int pointsEarned;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final Duration? timeSpent;
  final Map<String, dynamic> challengeAnswers;
  final List<String> photosTaken;
  final double? userRating;
  final String? userReview;

  const UserQuestProgress({
    required this.id,
    required this.userId,
    required this.questId,
    this.status = QuestStatus.notStarted,
    this.completedStops = const [],
    this.currentStopIndex = 0,
    this.pointsEarned = 0,
    this.startedAt,
    this.completedAt,
    this.timeSpent,
    this.challengeAnswers = const {},
    this.photosTaken = const [],
    this.userRating,
    this.userReview,
  });

  factory UserQuestProgress.fromJson(Map<String, dynamic> json) => _$UserQuestProgressFromJson(json);
  Map<String, dynamic> toJson() => _$UserQuestProgressToJson(this);

  UserQuestProgress copyWith({
    String? id,
    String? userId,
    String? questId,
    QuestStatus? status,
    List<String>? completedStops,
    int? currentStopIndex,
    int? pointsEarned,
    DateTime? startedAt,
    DateTime? completedAt,
    Duration? timeSpent,
    Map<String, dynamic>? challengeAnswers,
    List<String>? photosTaken,
    double? userRating,
    String? userReview,
  }) {
    return UserQuestProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      questId: questId ?? this.questId,
      status: status ?? this.status,
      completedStops: completedStops ?? this.completedStops,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      timeSpent: timeSpent ?? this.timeSpent,
      challengeAnswers: challengeAnswers ?? this.challengeAnswers,
      photosTaken: photosTaken ?? this.photosTaken,
      userRating: userRating ?? this.userRating,
      userReview: userReview ?? this.userReview,
    );
  }

  double get progressPercentage {
    if (status == QuestStatus.completed) return 1.0;
    if (status == QuestStatus.notStarted) return 0.0;
    return currentStopIndex / (completedStops.length + currentStopIndex + 1);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        questId,
        status,
        completedStops,
        currentStopIndex,
        pointsEarned,
        startedAt,
        completedAt,
        timeSpent,
        challengeAnswers,
        photosTaken,
        userRating,
        userReview,
      ];
} 