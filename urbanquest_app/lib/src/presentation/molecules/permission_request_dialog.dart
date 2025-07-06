import 'package:flutter/material.dart';
import 'package:urbanquest_app/src/core/constants/app_colors.dart';
import 'package:urbanquest_app/src/presentation/atoms/custom_button.dart';
import 'package:urbanquest_app/src/core/services/permission_service.dart';

class PermissionRequestDialog extends StatelessWidget {
  final String permissionType;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onGranted;
  final VoidCallback? onDenied;

  const PermissionRequestDialog({
    super.key,
    required this.permissionType,
    required this.title,
    required this.description,
    required this.icon,
    this.onGranted,
    this.onDenied,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFfef3f2), // Orange-50
              Color(0xFFfdf2f8), // Pink-50
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Not Now',
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDenied?.call();
                    },
                    variant: ButtonVariant.secondary,
                    size: ButtonSize.medium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Allow',
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _requestPermission();
                    },
                    size: ButtonSize.medium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPermission() async {
    final permissionService = PermissionService();
    bool granted = false;

    switch (permissionType) {
      case 'location':
        granted = await permissionService.requestLocationPermission();
        break;
      case 'camera':
        granted = await permissionService.requestCameraPermission();
        break;
      case 'storage':
        granted = await permissionService.requestStoragePermission();
        break;
      case 'notifications':
        granted = await permissionService.requestNotificationPermission();
        break;
    }

    if (granted) {
      onGranted?.call();
    } else {
      onDenied?.call();
    }
  }

  // Static methods to show specific permission dialogs
  static void showLocationPermission(BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionRequestDialog(
        permissionType: 'location',
        title: 'Location Access',
        description: 'Urban Quest needs access to your location to track your progress on quests and guide you to quest stops.',
        icon: Icons.location_on,
        onGranted: onGranted,
        onDenied: onDenied,
      ),
    );
  }

  static void showCameraPermission(BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionRequestDialog(
        permissionType: 'camera',
        title: 'Camera Access',
        description: 'Urban Quest needs access to your camera to complete photo challenges and document your quest adventures.',
        icon: Icons.camera_alt,
        onGranted: onGranted,
        onDenied: onDenied,
      ),
    );
  }

  static void showStoragePermission(BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionRequestDialog(
        permissionType: 'storage',
        title: 'Photo Access',
        description: 'Urban Quest needs access to your photos to save quest memories and share your adventure experiences.',
        icon: Icons.photo_library,
        onGranted: onGranted,
        onDenied: onDenied,
      ),
    );
  }

  static void showNotificationPermission(BuildContext context, {
    VoidCallback? onGranted,
    VoidCallback? onDenied,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionRequestDialog(
        permissionType: 'notifications',
        title: 'Notifications',
        description: 'Get notified when you reach quest stops, complete challenges, or unlock achievements.',
        icon: Icons.notifications,
        onGranted: onGranted,
        onDenied: onDenied,
      ),
    );
  }

  // Show all permissions setup dialog
  static void showPermissionSetup(BuildContext context, {
    VoidCallback? onCompleted,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PermissionSetupDialog(onCompleted: onCompleted),
    );
  }
}

class _PermissionSetupDialog extends StatefulWidget {
  final VoidCallback? onCompleted;

  const _PermissionSetupDialog({this.onCompleted});

  @override
  State<_PermissionSetupDialog> createState() => _PermissionSetupDialogState();
}

class _PermissionSetupDialogState extends State<_PermissionSetupDialog> {
  bool isRequesting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFfef3f2), // Orange-50
              Color(0xFFfdf2f8), // Pink-50
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'Setup Urban Quest',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'To provide the best scavenger hunt experience, Urban Quest needs access to your location and camera. This enables quest tracking, photo challenges, and location-based adventures.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Setup Button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: isRequesting ? 'Setting up...' : 'Setup Permissions',
                onPressed: isRequesting ? null : _setupPermissions,
                size: ButtonSize.large,
                icon: isRequesting ? null : Icons.security,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Skip Button
            TextButton(
              onPressed: isRequesting ? null : () {
                Navigator.of(context).pop();
                widget.onCompleted?.call();
              },
              child: Text(
                'Skip for now',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setupPermissions() async {
    setState(() {
      isRequesting = true;
    });

    final permissionService = PermissionService();
    await permissionService.requestAllPermissions();

    if (mounted) {
      Navigator.of(context).pop();
      widget.onCompleted?.call();
    }
  }
} 