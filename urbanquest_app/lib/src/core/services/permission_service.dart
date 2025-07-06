import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting camera permission: $e');
      return false;
    }
  }

  /// Request storage permission
  Future<bool> requestStoragePermission() async {
    try {
      // For Android 13+, use photos permission, otherwise use storage
      final permission = await _getStoragePermission();
      final status = await permission.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting storage permission: $e');
      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Request activity recognition permission (for pedometer)
  Future<bool> requestActivityRecognitionPermission() async {
    try {
      final status = await Permission.activityRecognition.request();
      return status.isGranted;
    } catch (e) {
      print('Error requesting activity recognition permission: $e');
      return false;
    }
  }

  /// Request all essential permissions
  Future<void> requestAllPermissions() async {
    await requestLocationPermission();
    await requestCameraPermission();
    await requestStoragePermission();
    await requestNotificationPermission();
    await requestActivityRecognitionPermission();
  }

  /// Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Check if camera permission is granted
  Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Check if storage permission is granted
  Future<bool> isStoragePermissionGranted() async {
    final permission = await _getStoragePermission();
    final status = await permission.status;
    return status.isGranted;
  }

  /// Check if notification permission is granted
  Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Check if activity recognition permission is granted
  Future<bool> isActivityRecognitionPermissionGranted() async {
    final status = await Permission.activityRecognition.status;
    return status.isGranted;
  }

  /// Get appropriate storage permission based on Android version
  Future<Permission> _getStoragePermission() async {
    // For Android 13+ (API 33+), use more specific permissions
    if (await Permission.photos.status != PermissionStatus.denied) {
      return Permission.photos;
    } else {
      return Permission.storage;
    }
  }

  /// Open app settings to manually grant permissions
  Future<void> openPermissionSettings() async {
    await openAppSettings();
  }

  /// Check if any critical permissions are missing
  Future<bool> hasCriticalPermissions() async {
    final locationGranted = await isLocationPermissionGranted();
    final cameraGranted = await isCameraPermissionGranted();
    return locationGranted && cameraGranted;
  }

  /// Get permission status summary
  Future<Map<String, bool>> getPermissionStatus() async {
    return {
      'location': await isLocationPermissionGranted(),
      'camera': await isCameraPermissionGranted(),
      'storage': await isStoragePermissionGranted(),
      'notification': await isNotificationPermissionGranted(),
      'activityRecognition': await isActivityRecognitionPermissionGranted(),
    };
  }
} 