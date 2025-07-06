// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gps_location_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GPSLocation _$GPSLocationFromJson(Map<String, dynamic> json) => GPSLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$GPSLocationToJson(GPSLocation instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'accuracy': instance.accuracy,
      'timestamp': instance.timestamp?.toIso8601String(),
    };

LocationVerificationResult _$LocationVerificationResultFromJson(
        Map<String, dynamic> json) =>
    LocationVerificationResult(
      success: json['success'] as bool,
      error: json['error'] as String?,
      isWithinRadius: json['is_within_radius'] as bool?,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      requiredRadius: (json['required_radius'] as num?)?.toDouble(),
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
      questStopId: json['quest_stop_id'] as String?,
      calculationDetails: json['calculation_details'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$LocationVerificationResultToJson(
        LocationVerificationResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'error': instance.error,
      'is_within_radius': instance.isWithinRadius,
      'distance_meters': instance.distanceMeters,
      'required_radius': instance.requiredRadius,
      'accuracy_meters': instance.accuracyMeters,
      'quest_stop_id': instance.questStopId,
      'calculation_details': instance.calculationDetails,
    };
