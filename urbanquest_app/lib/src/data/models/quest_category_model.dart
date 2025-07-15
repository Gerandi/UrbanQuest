import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quest_category_model.g.dart';

@JsonSerializable()
class QuestCategory extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final bool isActive;
  final int? sortOrder;
  final DateTime? createdAt;

  const QuestCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.isActive = true,
    this.sortOrder,
    this.createdAt,
  });

  factory QuestCategory.fromJson(Map<String, dynamic> json) {
    try {
      return QuestCategory(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown Category',
        description: json['description']?.toString(),
        icon: json['icon']?.toString(),
        color: json['color']?.toString(),
        isActive: json['is_active'] as bool? ?? true,
        sortOrder: int.tryParse(json['sort_order']?.toString() ?? '0'),
        createdAt: json['created_at'] != null 
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );
    } catch (e) {
      print('Error parsing QuestCategory from JSON: $e');
      return const QuestCategory(
        id: 'error',
        name: 'Error Loading Category',
      );
    }
  }

  Map<String, dynamic> toJson() => _$QuestCategoryToJson(this);

  QuestCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? color,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return QuestCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        icon,
        color,
        isActive,
        sortOrder,
        createdAt,
      ];
}