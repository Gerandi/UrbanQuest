import 'dart:math';
import 'package:json_annotation/json_annotation.dart';

part 'gps_location_model.g.dart';

@JsonSerializable()
class GPSLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime? timestamp;

  const GPSLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.timestamp,
  });

  factory GPSLocation.fromJson(Map<String, dynamic> json) => _$GPSLocationFromJson(json);
  Map<String, dynamic> toJson() => _$GPSLocationToJson(this);

  /// Calculate distance to another GPS location in meters
  double distanceTo(GPSLocation other) {
    return calculateDistance(latitude, longitude, other.latitude, other.longitude);
  }

  /// Calculate if this location is within radius of target location
  bool isWithinRadius(GPSLocation target, double radiusMeters) {
    return distanceTo(target) <= radiusMeters;
  }

  @override
  String toString() => 'GPSLocation(lat: $latitude, lng: $longitude, accuracy: $accuracy)';
}

@JsonSerializable()
class LocationVerificationResult {
  final bool success;
  final String? error;
  @JsonKey(name: 'is_within_radius')
  final bool? isWithinRadius;
  @JsonKey(name: 'distance_meters')
  final double? distanceMeters;
  @JsonKey(name: 'required_radius')
  final double? requiredRadius;
  @JsonKey(name: 'accuracy_meters')
  final double? accuracyMeters;
  @JsonKey(name: 'quest_stop_id')
  final String? questStopId;
  @JsonKey(name: 'calculation_details')
  final Map<String, dynamic>? calculationDetails;

  const LocationVerificationResult({
    required this.success,
    this.error,
    this.isWithinRadius,
    this.distanceMeters,
    this.requiredRadius,
    this.accuracyMeters,
    this.questStopId,
    this.calculationDetails,
  });

  factory LocationVerificationResult.fromJson(Map<String, dynamic> json) => 
      _$LocationVerificationResultFromJson(json);
  Map<String, dynamic> toJson() => _$LocationVerificationResultToJson(this);

  bool get isVerified => success && (isWithinRadius ?? false);
  
  String get statusMessage {
    if (!success) return error ?? 'Verification failed';
    if (isWithinRadius == true) return 'Location verified!';
    if (distanceMeters != null && requiredRadius != null) {
      final extraDistance = distanceMeters! - requiredRadius!;
      return 'You are ${extraDistance.toStringAsFixed(1)}m too far away';
    }
    return 'Location not verified';
  }
}

/// Calculate distance between two GPS coordinates using Haversine formula
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // Earth radius in meters
  
  final double dLat = _toRadians(lat2 - lat1);
  final double dLon = _toRadians(lon2 - lon1);
  
  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return earthRadius * c;
}

double _toRadians(double degrees) => degrees * (pi / 180); 