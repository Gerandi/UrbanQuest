import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'quest_stop_model.g.dart';

@JsonSerializable()
class QuestStop extends Equatable {
  final String id;
  final String questId;
  final String title;
  final String? description;
  final String? clue;
  final List<String>? hints;
  final String? challengeText;
  final String? challengeAnswer;
  final String challengeType;
  final Map<String, dynamic>? challengeOptions;
  final String? challengeRegex;
  final List<dynamic>? multipleChoiceOptions;
  final int? correctChoiceIndex;
  final Map<String, dynamic>? photoRequirements;
  final double? minPhotoConfidence;
  final String? challengeInstructions;
  final String? successMessage;
  final String? failureMessage;
  final String? infoText;
  final String? historicalContext;
  final List<String>? funFacts;
  final List<String>? helpSteps;
  final List<String>? helpTips;
  final List<Map<String, String>>? helpExamples;
  final double latitude;
  final double longitude;
  final int radius;
  final int points;
  final int orderIndex;

  const QuestStop({
    required this.id,
    required this.questId,
    required this.title,
    this.description,
    this.clue,
    this.hints,
    this.challengeText,
    this.challengeAnswer,
    this.challengeType = 'location_only',
    this.challengeOptions,
    this.challengeRegex,
    this.multipleChoiceOptions,
    this.correctChoiceIndex,
    this.photoRequirements,
    this.minPhotoConfidence,
    this.challengeInstructions,
    this.successMessage,
    this.failureMessage,
    this.infoText,
    this.historicalContext,
    this.funFacts,
    this.helpSteps,
    this.helpTips,
    this.helpExamples,
    required this.latitude,
    required this.longitude,
    this.radius = 50,
    this.points = 10,
    required this.orderIndex,
  });

  factory QuestStop.fromJson(Map<String, dynamic> json) {
    return QuestStop(
      id: json['id'] as String? ?? '',
      questId: json['quest_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      clue: json['clue'] as String?,
      hints: json['hints'] != null ? List<String>.from(json['hints']) : null,
      challengeText: json['challenge_text'] as String?,
      challengeAnswer: json['challenge_answer'] as String?,
      challengeType: json['challenge_type'] as String? ?? 'location_only',
      challengeOptions: json['challenge_options'] as Map<String, dynamic>?,
      challengeRegex: json['challenge_regex'] as String?,
      multipleChoiceOptions: json['multiple_choice_options'] as List<dynamic>?,
      correctChoiceIndex: json['correct_choice_index'] as int?,
      photoRequirements: json['photo_requirements'] as Map<String, dynamic>?,
      minPhotoConfidence: json['min_photo_confidence'] != null 
          ? (json['min_photo_confidence'] as num).toDouble() 
          : null,
      challengeInstructions: json['challenge_instructions'] as String?,
      successMessage: json['success_message'] as String?,
      failureMessage: json['failure_message'] as String?,
      infoText: json['info_text'] as String?,
      historicalContext: json['historical_context'] as String?,
      funFacts: json['fun_facts'] != null ? List<String>.from(json['fun_facts']) : null,
      helpSteps: json['help_steps'] != null ? List<String>.from(json['help_steps']) : null,
      helpTips: json['help_tips'] != null ? List<String>.from(json['help_tips']) : null,
      helpExamples: json['help_examples'] != null 
          ? List<Map<String, String>>.from(
              json['help_examples'].map((x) => Map<String, String>.from(x))
            )
          : null,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: json['radius'] as int? ?? 50,
      points: json['points'] as int? ?? 10,
      orderIndex: json['order_index'] as int,
    );
  }

  Map<String, dynamic> toJson() => _$QuestStopToJson(this);

  @override
  List<Object?> get props => [
        id,
        questId,
        title,
        description,
        clue,
        hints,
        challengeText,
        challengeAnswer,
        challengeType,
        challengeOptions,
        challengeRegex,
        multipleChoiceOptions,
        correctChoiceIndex,
        photoRequirements,
        minPhotoConfidence,
        challengeInstructions,
        successMessage,
        failureMessage,
        infoText,
        historicalContext,
        funFacts,
        helpSteps,
        helpTips,
        helpExamples,
        latitude,
        longitude,
        radius,
        points,
        orderIndex,
      ];

  // Helper methods for challenge types
  bool get isTextChallenge => challengeType == 'text';
  bool get isTriviaChallenge => challengeType == 'trivia';
  bool get isPhotoChallenge => challengeType == 'photo';
  bool get isMultipleChoiceChallenge => challengeType == 'multiple_choice';
  bool get isRegexChallenge => challengeType == 'regex';
  bool get isLocationOnlyChallenge => challengeType == 'location_only';
  bool get isQrCodeChallenge => challengeType == 'qr_code';
  bool get isAudioChallenge => challengeType == 'audio';

  bool get hasChallenge => !isLocationOnlyChallenge;

  String get displayInstructions => 
      challengeInstructions ?? 
      challengeText ?? 
      'Complete this challenge to continue.';

  String get displaySuccessMessage => 
      successMessage ?? 
      'Great job! Challenge completed!';

  String get displayFailureMessage => 
      failureMessage ?? 
      'Not quite right. Try again!';
}

@JsonSerializable()
class LatLng extends Equatable {
  final double lat;
  final double lng;

  const LatLng({
    required this.lat,
    required this.lng,
  });

  factory LatLng.fromJson(Map<String, dynamic> json) => _$LatLngFromJson(json);
  Map<String, dynamic> toJson() => _$LatLngToJson(this);

  @override
  List<Object?> get props => [lat, lng];
}
