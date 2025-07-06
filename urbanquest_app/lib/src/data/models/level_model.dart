import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'level_model.g.dart';

@JsonSerializable()
class Level extends Equatable {
  final int level;
  final int minPoints;
  final int maxPoints;
  final String title;
  final String description;
  final String icon;
  final int color;
  final List<String> perks;
  final bool isActive;
  final DateTime createdAt;

  const Level({
    required this.level,
    required this.minPoints,
    required this.maxPoints,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.perks,
    required this.isActive,
    required this.createdAt,
  });

  factory Level.fromJson(Map<String, dynamic> json) => _$LevelFromJson(json);
  Map<String, dynamic> toJson() => _$LevelToJson(this);

  Level copyWith({
    int? level,
    int? minPoints,
    int? maxPoints,
    String? title,
    String? description,
    String? icon,
    int? color,
    List<String>? perks,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Level(
      level: level ?? this.level,
      minPoints: minPoints ?? this.minPoints,
      maxPoints: maxPoints ?? this.maxPoints,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      perks: perks ?? this.perks,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        level,
        minPoints,
        maxPoints,
        title,
        description,
        icon,
        color,
        perks,
        isActive,
        createdAt,
      ];
} 