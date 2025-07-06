// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_review_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestReview _$QuestReviewFromJson(Map<String, dynamic> json) => QuestReview(
      id: json['id'] as String,
      questId: json['questId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      photos:
          (json['photos'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      helpfulVotes: (json['helpfulVotes'] as num?)?.toInt() ?? 0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$QuestReviewToJson(QuestReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'questId': instance.questId,
      'userId': instance.userId,
      'userName': instance.userName,
      'userAvatar': instance.userAvatar,
      'rating': instance.rating,
      'comment': instance.comment,
      'photos': instance.photos,
      'createdAt': instance.createdAt.toIso8601String(),
      'helpfulVotes': instance.helpfulVotes,
      'tags': instance.tags,
    };
