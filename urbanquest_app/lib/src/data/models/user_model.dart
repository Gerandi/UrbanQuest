import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String avatar;
  final DateTime createdAt;
  final List<String> permissions;
  final int totalPoints;
  final int level;
  final UserStats? stats;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.avatar,
    required this.createdAt,
    required this.permissions,
    this.totalPoints = 0,
    this.level = 1,
    this.stats,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatar,
    DateTime? createdAt,
    List<String>? permissions,
    int? totalPoints,
    int? level,
    UserStats? stats,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      permissions: permissions ?? this.permissions,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        avatar,
        createdAt,
        permissions,
        totalPoints,
        level,
        stats,
      ];
}

@JsonSerializable()
class UserStats extends Equatable {
  final int questsCompleted;
  final int stopsVisited;
  final int photosShared;
  final double totalDistance;
  final int citiesVisited;
  final int achievementsUnlocked;
  final int totalPlaytimeMinutes;
  final int longestQuestStreak;
  final int currentQuestStreak;
  final String levelTitle;

  const UserStats({
    required this.questsCompleted,
    required this.stopsVisited,
    required this.photosShared,
    required this.totalDistance,
    required this.citiesVisited,
    required this.achievementsUnlocked,
    required this.totalPlaytimeMinutes,
    required this.longestQuestStreak,
    required this.currentQuestStreak,
    required this.levelTitle,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => _$UserStatsFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatsToJson(this);

  UserStats copyWith({
    int? questsCompleted,
    int? stopsVisited,
    int? photosShared,
    double? totalDistance,
    int? citiesVisited,
    int? achievementsUnlocked,
    int? totalPlaytimeMinutes,
    int? longestQuestStreak,
    int? currentQuestStreak,
    String? levelTitle,
  }) {
    return UserStats(
      questsCompleted: questsCompleted ?? this.questsCompleted,
      stopsVisited: stopsVisited ?? this.stopsVisited,
      photosShared: photosShared ?? this.photosShared,
      totalDistance: totalDistance ?? this.totalDistance,
      citiesVisited: citiesVisited ?? this.citiesVisited,
      achievementsUnlocked: achievementsUnlocked ?? this.achievementsUnlocked,
      totalPlaytimeMinutes: totalPlaytimeMinutes ?? this.totalPlaytimeMinutes,
      longestQuestStreak: longestQuestStreak ?? this.longestQuestStreak,
      currentQuestStreak: currentQuestStreak ?? this.currentQuestStreak,
      levelTitle: levelTitle ?? this.levelTitle,
    );
  }

  @override
  List<Object?> get props => [
        questsCompleted,
        stopsVisited,
        photosShared,
        totalDistance,
        citiesVisited,
        achievementsUnlocked,
        totalPlaytimeMinutes,
        longestQuestStreak,
        currentQuestStreak,
        levelTitle,
      ];
}
