import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quest_review_model.g.dart';

@JsonSerializable()
class QuestReview extends Equatable {
  final String id;
  final String questId;
  final String userId;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final List<String> photos;
  final DateTime createdAt;
  final int helpfulVotes;
  final List<String> tags;

  const QuestReview({
    required this.id,
    required this.questId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.photos,
    required this.createdAt,
    this.helpfulVotes = 0,
    this.tags = const [],
  });

  factory QuestReview.fromJson(Map<String, dynamic> json) => _$QuestReviewFromJson(json);
  Map<String, dynamic> toJson() => _$QuestReviewToJson(this);

  QuestReview copyWith({
    String? id,
    String? questId,
    String? userId,
    String? userName,
    String? userAvatar,
    double? rating,
    String? comment,
    List<String>? photos,
    DateTime? createdAt,
    int? helpfulVotes,
    List<String>? tags,
  }) {
    return QuestReview(
      id: id ?? this.id,
      questId: questId ?? this.questId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      helpfulVotes: helpfulVotes ?? this.helpfulVotes,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        questId,
        userId,
        userName,
        userAvatar,
        rating,
        comment,
        photos,
        createdAt,
        helpfulVotes,
        tags,
      ];
} 