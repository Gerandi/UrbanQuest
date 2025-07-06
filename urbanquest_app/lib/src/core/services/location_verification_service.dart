import 'package:geolocator/geolocator.dart';
import 'supabase_service.dart';

class LocationVerificationService {
  static final LocationVerificationService _instance = LocationVerificationService._internal();
  factory LocationVerificationService() => _instance;
  LocationVerificationService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  /// Verify if user is at the correct location for a quest stop
  Future<LocationVerificationResult> verifyStopLocation({
    required String stopId,
    required double userLatitude,
    required double userLongitude,
    double radiusMeters = 50.0,
  }) async {
    try {
      // Use the backend verification function
      final result = await _supabaseService.verifyLocation(
        latitude: userLatitude,
        longitude: userLongitude,
        stopId: stopId,
        radiusMeters: radiusMeters,
      );

      if (result['verified'] == true) {
        return LocationVerificationResult(
          isVerified: true,
          distance: result['distance_meters']?.toDouble() ?? 0.0,
          points: result['points'] ?? 10,
          message: 'Location verified! You\'re at the right spot.',
        );
      } else {
        return LocationVerificationResult(
          isVerified: false,
          distance: result['distance_meters']?.toDouble() ?? double.infinity,
          points: 0,
          message: result['error'] ?? 'You need to get closer to the location.',
        );
      }
    } catch (e) {
      print('Error verifying location: $e');
      return const LocationVerificationResult(
        isVerified: false,
        distance: double.infinity,
        points: 0,
        message: 'Location verification failed. Please try again.',
      );
    }
  }

  /// Get current user location
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in settings.');
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('Error getting current location: $e');
      rethrow;
    }
  }

  /// Calculate distance between two points using Haversine formula
  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Get formatted distance string
  String getFormattedDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Check if user is within acceptable range for a stop
  bool isWithinRange(double distance, double radiusMeters) {
    return distance <= radiusMeters;
  }

  /// Get location accuracy level
  LocationAccuracyLevel getAccuracyLevel(double accuracy) {
    if (accuracy <= 5) return LocationAccuracyLevel.excellent;
    if (accuracy <= 10) return LocationAccuracyLevel.good;
    if (accuracy <= 20) return LocationAccuracyLevel.fair;
    return LocationAccuracyLevel.poor;
  }

  /// Stream location updates for real-time tracking
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      ),
    );
  }

  /// Check location permissions status
  Future<LocationPermissionStatus> checkLocationPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionStatus.serviceDisabled;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      switch (permission) {
        case LocationPermission.denied:
          return LocationPermissionStatus.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionStatus.deniedForever;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return LocationPermissionStatus.granted;
        default:
          return LocationPermissionStatus.denied;
      }
    } catch (e) {
      print('Error checking location permissions: $e');
      return LocationPermissionStatus.error;
    }
  }

  /// Request location permissions
  Future<LocationPermissionStatus> requestLocationPermissions() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      switch (permission) {
        case LocationPermission.denied:
          return LocationPermissionStatus.denied;
        case LocationPermission.deniedForever:
          return LocationPermissionStatus.deniedForever;
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return LocationPermissionStatus.granted;
        default:
          return LocationPermissionStatus.denied;
      }
    } catch (e) {
      print('Error requesting location permissions: $e');
      return LocationPermissionStatus.error;
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      print('Error opening location settings: $e');
      return false;
    }
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
      return false;
    }
  }
}

class LocationVerificationResult {
  final bool isVerified;
  final double distance;
  final int points;
  final String message;

  const LocationVerificationResult({
    required this.isVerified,
    required this.distance,
    required this.points,
    required this.message,
  });

  @override
  String toString() {
    return 'LocationVerificationResult(isVerified: $isVerified, distance: $distance, points: $points, message: $message)';
  }
}

enum LocationAccuracyLevel {
  excellent, // <= 5m
  good,      // <= 10m
  fair,      // <= 20m
  poor,      // > 20m
}

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  error,
} 