import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'achievement_model.g.dart';

@JsonSerializable()
class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int color;
  @JsonKey(toJson: _achievementConditionToJson, fromJson: _achievementConditionFromJson)
  final AchievementCondition condition;
  final int points;
  final bool isActive;
  final DateTime createdAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.condition,
    required this.points,
    required this.isActive,
    required this.createdAt,
  });

  static Map<String, dynamic> _achievementConditionToJson(AchievementCondition condition) => condition.toJson();
  static AchievementCondition _achievementConditionFromJson(Map<String, dynamic> json) => AchievementCondition.fromJson(json);

  factory Achievement.fromJson(Map<String, dynamic> json) => _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? color,
    AchievementCondition? condition,
    int? points,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      condition: condition ?? this.condition,
      points: points ?? this.points,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        icon,
        color,
        condition,
        points,
        isActive,
        createdAt,
      ];
}

@JsonSerializable()
class AchievementCondition extends Equatable {
  final String type; // 'quests_completed', 'points_earned', 'photos_shared', 'stops_visited', 'badge_earned'
  final int threshold;
  final String? badgeId; // Only for badge_earned type

  const AchievementCondition({
    required this.type,
    required this.threshold,
    this.badgeId,
  });

  factory AchievementCondition.fromJson(Map<String, dynamic> json) => _$AchievementConditionFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementConditionToJson(this);

  AchievementCondition copyWith({
    String? type,
    int? threshold,
    String? badgeId,
  }) {
    return AchievementCondition(
      type: type ?? this.type,
      threshold: threshold ?? this.threshold,
      badgeId: badgeId ?? this.badgeId,
    );
  }

  @override
  List<Object?> get props => [type, threshold, badgeId];
}

@JsonSerializable()
class UserAchievement extends Equatable {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final int pointsEarned;

  const UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    required this.pointsEarned,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) => _$UserAchievementFromJson(json);
  Map<String, dynamic> toJson() => _$UserAchievementToJson(this);

  UserAchievement copyWith({
    String? id,
    String? userId,
    String? achievementId,
    DateTime? unlockedAt,
    int? pointsEarned,
  }) {
    return UserAchievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      pointsEarned: pointsEarned ?? this.pointsEarned,
    );
  }

  @override
  List<Object?> get props => [id, userId, achievementId, unlockedAt, pointsEarned];
} 