import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quest_tutorial_model.g.dart';

@JsonSerializable()
class QuestTutorial extends Equatable {
  final String id;
  final String questId;
  final String title;
  final String? description;
  final List<String> steps;
  final List<String> tips;
  final String icon;
  final int orderIndex;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuestTutorial({
    required this.id,
    required this.questId,
    required this.title,
    this.description,
    required this.steps,
    required this.tips,
    this.icon = 'help_outline',
    required this.orderIndex,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuestTutorial.fromJson(Map<String, dynamic> json) {
    return QuestTutorial(
      id: json['id'] as String,
      questId: json['quest_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      steps: List<String>.from(json['steps'] ?? []),
      tips: List<String>.from(json['tips'] ?? []),
      icon: json['icon'] as String? ?? 'help_outline',
      orderIndex: json['order_index'] as int,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => _$QuestTutorialToJson(this);

  @override
  List<Object?> get props => [
        id,
        questId,
        title,
        description,
        steps,
        tips,
        icon,
        orderIndex,
        isActive,
        createdAt,
        updatedAt,
      ];
}