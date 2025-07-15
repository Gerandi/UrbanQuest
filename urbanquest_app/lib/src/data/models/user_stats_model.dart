import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_stats_model.g.dart';

@JsonSerializable()
class UserStats extends Equatable {
  @JsonKey(name: 'quests_completed')
  final int questsCompleted;
  
  @JsonKey(name: 'stops_visited')
  final int stopsVisited;
  
  @JsonKey(name: 'photos_shared')
  final int photosShared;
  
  @JsonKey(name: 'total_distance')
  final double totalDistance;
  
  @JsonKey(name: 'total_points')
  final int totalPoints;
  
  @JsonKey(name: 'achievements_earned')
  final int achievementsEarned;
  
  @JsonKey(name: 'current_streak')
  final int currentStreak;
  
  @JsonKey(name: 'longest_streak')
  final int longestStreak;
  
  @JsonKey(name: 'total_time_spent')
  final int totalTimeSpent; // in minutes
  
  @JsonKey(name: 'leaderboard_rank')
  final int leaderboardRank;
  
  @JsonKey(name: 'cities_visited')
  final int citiesVisited;
  
  @JsonKey(name: 'challenges_completed')
  final int challengesCompleted;
  
  @JsonKey(name: 'perfect_scores')
  final int perfectScores;
  
  @JsonKey(name: 'hints_used')
  final int hintsUsed;
  
  @JsonKey(name: 'favourite_city')
  final String? favouriteCity;
  
  @JsonKey(name: 'favourite_quest_type')
  final String? favouriteQuestType;
  
  @JsonKey(name: 'last_activity_date')
  final DateTime? lastActivityDate;
  
  @JsonKey(name: 'first_quest_date')
  final DateTime? firstQuestDate;

  const UserStats({
    this.questsCompleted = 0,
    this.stopsVisited = 0,
    this.photosShared = 0,
    this.totalDistance = 0.0,
    this.totalPoints = 0,
    this.achievementsEarned = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalTimeSpent = 0,
    this.leaderboardRank = 0,
    this.citiesVisited = 0,
    this.challengesCompleted = 0,
    this.perfectScores = 0,
    this.hintsUsed = 0,
    this.favouriteCity,
    this.favouriteQuestType,
    this.lastActivityDate,
    this.firstQuestDate,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => _$UserStatsFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatsToJson(this);

  UserStats copyWith({
    int? questsCompleted,
    int? stopsVisited,
    int? photosShared,
    double? totalDistance,
    int? totalPoints,
    int? achievementsEarned,
    int? currentStreak,
    int? longestStreak,
    int? totalTimeSpent,
    int? leaderboardRank,
    int? citiesVisited,
    int? challengesCompleted,
    int? perfectScores,
    int? hintsUsed,
    String? favouriteCity,
    String? favouriteQuestType,
    DateTime? lastActivityDate,
    DateTime? firstQuestDate,
  }) {
    return UserStats(
      questsCompleted: questsCompleted ?? this.questsCompleted,
      stopsVisited: stopsVisited ?? this.stopsVisited,
      photosShared: photosShared ?? this.photosShared,
      totalDistance: totalDistance ?? this.totalDistance,
      totalPoints: totalPoints ?? this.totalPoints,
      achievementsEarned: achievementsEarned ?? this.achievementsEarned,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      leaderboardRank: leaderboardRank ?? this.leaderboardRank,
      citiesVisited: citiesVisited ?? this.citiesVisited,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      perfectScores: perfectScores ?? this.perfectScores,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      favouriteCity: favouriteCity ?? this.favouriteCity,
      favouriteQuestType: favouriteQuestType ?? this.favouriteQuestType,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      firstQuestDate: firstQuestDate ?? this.firstQuestDate,
    );
  }

  // Helper methods for level calculation
  int get currentLevel {
    if (totalPoints <= 0) return 1;
    if (totalPoints < 100) return 1;
    if (totalPoints < 300) return 2;
    if (totalPoints < 600) return 3;
    if (totalPoints < 1000) return 4;
    if (totalPoints < 1500) return 5;
    return 5 + ((totalPoints - 1500) ~/ 500);
  }

  int get pointsToNextLevel {
    final nextLevel = currentLevel + 1;
    final nextLevelThreshold = _getLevelThreshold(nextLevel);
    return (nextLevelThreshold - totalPoints).clamp(0, double.infinity).toInt();
  }

  double get levelProgress {
    final currentLevelThreshold = _getLevelThreshold(currentLevel);
    final nextLevelThreshold = _getLevelThreshold(currentLevel + 1);
    final progressInLevel = totalPoints - currentLevelThreshold;
    final levelRange = nextLevelThreshold - currentLevelThreshold;
    return (progressInLevel / levelRange).clamp(0.0, 1.0);
  }

  int _getLevelThreshold(int level) {
    if (level <= 1) return 0;
    if (level == 2) return 100;
    if (level == 3) return 300;
    if (level == 4) return 600;
    if (level == 5) return 1000;
    if (level == 6) return 1500;
    return 1500 + ((level - 6) * 500);
  }

  // Helper getters for UI display
  String get formattedDistance {
    if (totalDistance < 1) {
      return '${(totalDistance * 1000).round()}m';
    }
    return '${totalDistance.toStringAsFixed(1)}km';
  }

  String get formattedTime {
    if (totalTimeSpent < 60) return '${totalTimeSpent}m';
    final hours = totalTimeSpent ~/ 60;
    final minutes = totalTimeSpent % 60;
    if (hours < 24) return '${hours}h ${minutes}m';
    final days = hours ~/ 24;
    final remainingHours = hours % 24;
    return '${days}d ${remainingHours}h';
  }

  String get rankDisplay {
    if (leaderboardRank <= 0) return 'Unranked';
    return '#$leaderboardRank';
  }

  double get averagePointsPerQuest {
    if (questsCompleted == 0) return 0.0;
    return totalPoints / questsCompleted;
  }

  double get averageDistancePerQuest {
    if (questsCompleted == 0) return 0.0;
    return totalDistance / questsCompleted;
  }

  double get completionRate {
    if (challengesCompleted == 0) return 0.0;
    return perfectScores / challengesCompleted;
  }

  @override
  List<Object?> get props => [
    questsCompleted,
    stopsVisited,
    photosShared,
    totalDistance,
    totalPoints,
    achievementsEarned,
    currentStreak,
    longestStreak,
    totalTimeSpent,
    leaderboardRank,
    citiesVisited,
    challengesCompleted,
    perfectScores,
    hintsUsed,
    favouriteCity,
    favouriteQuestType,
    lastActivityDate,
    firstQuestDate,
  ];
}