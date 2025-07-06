import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  StreamSubscription<Position>? _positionSubscription;
  Position? _currentPosition;
  final StreamController<Position> _positionController = 
      StreamController<Position>.broadcast();

  Stream<Position> get positionStream => _positionController.stream;
  Position? get currentPosition => _currentPosition;

  // Check if location services are enabled and permissions are granted
  Future<bool> isLocationEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  // Request location permissions
  Future<bool> requestLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException('Location services are disabled');
    }

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Open app settings for user to enable permissions
      await openAppSettings();
      throw LocationServiceException(
        'Location permissions are permanently denied. Please enable them in settings.'
      );
    }

    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  // Get current position once
  Future<Position> getCurrentPosition() async {
    if (!await isLocationEnabled()) {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw LocationServiceException('Location permission not granted');
      }
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return _currentPosition!;
    } catch (e) {
      throw LocationServiceException('Failed to get current position: $e');
    }
  }

  // Start continuous location tracking
  Future<void> startLocationTracking() async {
    if (!await isLocationEnabled()) {
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw LocationServiceException('Location permission not granted');
      }
    }

    // Stop existing subscription if any
    await stopLocationTracking();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _currentPosition = position;
        _positionController.add(position);
      },
      onError: (error) {
        _positionController.addError(
          LocationServiceException('Location tracking error: $error')
        );
      },
    );
  }

  // Stop location tracking
  Future<void> stopLocationTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // Calculate distance between two points in meters
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Check if user is within range of a quest stop
  bool isWithinRange(
    Position userPosition,
    double targetLatitude,
    double targetLongitude,
    {double rangeInMeters = 50.0}
  ) {
    double distance = calculateDistance(
      userPosition.latitude,
      userPosition.longitude,
      targetLatitude,
      targetLongitude,
    );
    return distance <= rangeInMeters;
  }

  // Get bearing (direction) from user to target
  double getBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)}km';
    }
  }

  // Get direction text from bearing
  String getDirectionFromBearing(double bearing) {
    const directions = [
      'North', 'Northeast', 'East', 'Southeast',
      'South', 'Southwest', 'West', 'Northwest'
    ];
    
    int index = ((bearing + 22.5) % 360 / 45).floor();
    return directions[index];
  }

  // Calculate total distance traveled from a list of positions
  double calculateTotalDistance(List<Position> positions) {
    if (positions.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < positions.length; i++) {
      totalDistance += calculateDistance(
        positions[i - 1].latitude,
        positions[i - 1].longitude,
        positions[i].latitude,
        positions[i].longitude,
      );
    }
    return totalDistance;
  }

  // Get estimated time to reach destination (walking speed ~1.4 m/s)
  Duration getEstimatedWalkingTime(double distanceInMeters) {
    const double walkingSpeedMPS = 1.4; // meters per second
    int secondsToReach = (distanceInMeters / walkingSpeedMPS).round();
    return Duration(seconds: secondsToReach);
  }

  // Check if location is in a specific city (basic implementation)
  bool isInCity(Position position, String cityName) {
    // This is a simplified implementation. In a real app, you'd use
    // reverse geocoding or predefined city boundaries
    final Map<String, Map<String, double>> cityBounds = {
      'tirana': {
        'minLat': 41.290,
        'maxLat': 41.370,
        'minLng': 19.750,
        'maxLng': 19.890,
      },
      'berat': {
        'minLat': 40.690,
        'maxLat': 40.720,
        'minLng': 19.940,
        'maxLng': 19.970,
      },
      'shkoder': {
        'minLat': 42.050,
        'maxLat': 42.080,
        'minLng': 19.500,
        'maxLng': 19.530,
      },
      'durres': {
        'minLat': 41.300,
        'maxLat': 41.330,
        'minLng': 19.430,
        'maxLng': 19.460,
      },
    };

    final bounds = cityBounds[cityName.toLowerCase()];
    if (bounds == null) return false;

    return position.latitude >= bounds['minLat']! &&
           position.latitude <= bounds['maxLat']! &&
           position.longitude >= bounds['minLng']! &&
           position.longitude <= bounds['maxLng']!;
  }

  // Cleanup resources
  void dispose() {
    stopLocationTracking();
    _positionController.close();
  }
}

class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}

// Helper class for quest stop location data
class QuestStopLocation {
  final double latitude;
  final double longitude;
  final String name;
  final String description;

  const QuestStopLocation({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.description,
  });

  // Convert to LatLng for compatibility with models
  Map<String, double> toLatLng() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }
} 