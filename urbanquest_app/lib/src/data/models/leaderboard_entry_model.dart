import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'leaderboard_entry_model.g.dart';

@JsonSerializable()
class LeaderboardEntry extends Equatable {
  final String id;
  final String name;
  final String avatar;
  final int points;
  final int rank;
  final int? level;
  final int? questsCompleted;
  final String? city;
  final DateTime? lastActiveAt;

  const LeaderboardEntry({
    required this.id,
    required this.name,
    required this.avatar,
    required this.points,
    required this.rank,
    this.level,
    this.questsCompleted,
    this.city,
    this.lastActiveAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => _$LeaderboardEntryFromJson(json);
  Map<String, dynamic> toJson() => _$LeaderboardEntryToJson(this);

  LeaderboardEntry copyWith({
    String? id,
    String? name,
    String? avatar,
    int? points,
    int? rank,
    int? level,
    int? questsCompleted,
    String? city,
    DateTime? lastActiveAt,
  }) {
    return LeaderboardEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      points: points ?? this.points,
      rank: rank ?? this.rank,
      level: level ?? this.level,
      questsCompleted: questsCompleted ?? this.questsCompleted,
      city: city ?? this.city,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  List<Object?> get props => [id, name, avatar, points, rank, level, questsCompleted, city, lastActiveAt];
} 