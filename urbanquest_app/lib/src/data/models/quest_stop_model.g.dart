// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quest_stop_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestStop _$QuestStopFromJson(Map<String, dynamic> json) => QuestStop(
      id: json['id'] as String,
      questId: json['questId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      clue: json['clue'] as String?,
      hints:
          (json['hints'] as List<dynamic>?)?.map((e) => e as String).toList(),
      challengeText: json['challengeText'] as String?,
      challengeAnswer: json['challengeAnswer'] as String?,
      challengeType: json['challengeType'] as String? ?? 'location_only',
      challengeOptions: json['challengeOptions'] as Map<String, dynamic>?,
      challengeRegex: json['challengeRegex'] as String?,
      multipleChoiceOptions: json['multipleChoiceOptions'] as List<dynamic>?,
      correctChoiceIndex: (json['correctChoiceIndex'] as num?)?.toInt(),
      photoRequirements: json['photoRequirements'] as Map<String, dynamic>?,
      minPhotoConfidence: (json['minPhotoConfidence'] as num?)?.toDouble(),
      challengeInstructions: json['challengeInstructions'] as String?,
      successMessage: json['successMessage'] as String?,
      failureMessage: json['failureMessage'] as String?,
      infoText: json['infoText'] as String?,
      historicalContext: json['historicalContext'] as String?,
      funFacts: (json['funFacts'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toInt() ?? 50,
      points: (json['points'] as num?)?.toInt() ?? 10,
      orderIndex: (json['orderIndex'] as num).toInt(),
    );

Map<String, dynamic> _$QuestStopToJson(QuestStop instance) => <String, dynamic>{
      'id': instance.id,
      'questId': instance.questId,
      'title': instance.title,
      'description': instance.description,
      'clue': instance.clue,
      'hints': instance.hints,
      'challengeText': instance.challengeText,
      'challengeAnswer': instance.challengeAnswer,
      'challengeType': instance.challengeType,
      'challengeOptions': instance.challengeOptions,
      'challengeRegex': instance.challengeRegex,
      'multipleChoiceOptions': instance.multipleChoiceOptions,
      'correctChoiceIndex': instance.correctChoiceIndex,
      'photoRequirements': instance.photoRequirements,
      'minPhotoConfidence': instance.minPhotoConfidence,
      'challengeInstructions': instance.challengeInstructions,
      'successMessage': instance.successMessage,
      'failureMessage': instance.failureMessage,
      'infoText': instance.infoText,
      'historicalContext': instance.historicalContext,
      'funFacts': instance.funFacts,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radius': instance.radius,
      'points': instance.points,
      'orderIndex': instance.orderIndex,
    };

LatLng _$LatLngFromJson(Map<String, dynamic> json) => LatLng(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );

Map<String, dynamic> _$LatLngToJson(LatLng instance) => <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
    };
