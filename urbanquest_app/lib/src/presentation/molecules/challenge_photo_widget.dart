import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_card.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/quest_stop_model.dart';

class ChallengePhotoWidget extends StatefulWidget {
  final QuestStop questStop;
  final Function(XFile) onPhotoTaken;
  final bool isSubmitting;

  const ChallengePhotoWidget({
    Key? key,
    required this.questStop,
    required this.onPhotoTaken,
    this.isSubmitting = false,
  }) : super(key: key);

  @override
  State<ChallengePhotoWidget> createState() => _ChallengePhotoWidgetState();
}

class _ChallengePhotoWidgetState extends State<ChallengePhotoWidget> {
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedImage;
  bool _hasPermission = false;
  bool _isAnalyzing = false;
  Map<String, bool> _requirementChecks = {};

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else if (status.isDenied) {
      final result = await Permission.camera.request();
      setState(() {
        _hasPermission = result.isGranted;
      });
    }
  }

  Future<void> _takePhoto() async {
    if (!_hasPermission) {
      await _checkCameraPermission();
      if (!_hasPermission) return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _capturedImage = image;
          _isAnalyzing = true;
        });
        
        await _analyzePhoto(image);
        
        setState(() {
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _analyzePhoto(XFile image) async {
    final requirements = widget.questStop.photoRequirements;
    if (requirements == null || requirements.isEmpty) {
      // No requirements, consider it valid
      widget.onPhotoTaken(image);
      return;
    }

    final checks = <String, bool>{};
    
    // Basic photo analysis (in a real app, you'd use ML/AI services)
    // For now, we'll do basic file validation
    final file = File(image.path);
    final fileSize = await file.length();
    
    // Check file size requirements
    if (requirements.containsKey('min_size')) {
      final minSize = int.tryParse(requirements['min_size'].toString()) ?? 0;
      checks['File size'] = fileSize >= minSize;
    }
    
    if (requirements.containsKey('max_size')) {
      final maxSize = int.tryParse(requirements['max_size'].toString()) ?? 10000000;
      checks['File size limit'] = fileSize <= maxSize;
    }
    
    // Mock analysis for demonstration
    if (requirements.containsKey('must_contain')) {
      final requiredObjects = requirements['must_contain'].toString().split(',');
      // In a real app, you'd use image recognition APIs
      // For now, we'll simulate with random success
      for (final obj in requiredObjects) {
        checks['Contains ${obj.trim()}'] = DateTime.now().second % 2 == 0;
      }
    }
    
    if (requirements.containsKey('lighting')) {
      // Simulate lighting analysis
      checks['Good lighting'] = DateTime.now().second % 3 != 0;
    }
    
    if (requirements.containsKey('clarity')) {
      // Simulate clarity analysis
      checks['Clear image'] = DateTime.now().second % 4 != 0;
    }
    
    setState(() {
      _requirementChecks = checks;
    });
    
    // Check if all requirements are met
    final allMet = checks.values.every((check) => check);
    
    if (allMet) {
      // Auto-submit if all requirements are met
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          widget.onPhotoTaken(image);
        }
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _requirementChecks.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenge Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.purpleAccent],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Photo Challenge',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Capture the moment',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Challenge Instructions
          if (widget.questStop.challengeInstructions?.isNotEmpty == true) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blackOpacity10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.blackOpacity20,
                ),
              ),
              child: Text(
                widget.questStop.challengeInstructions!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Photo Requirements
          if (widget.questStop.photoRequirements?.isNotEmpty == true) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Photo Requirements:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...widget.questStop.photoRequirements!.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Colors.blue, fontSize: 12)),
                          Expanded(
                            child: Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(color: Colors.blue, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Photo Capture/Preview Section
          if (!_hasPermission) ...[
            _buildPermissionRequest(),
          ] else if (_capturedImage != null) ...[
            _buildPhotoPreview(),
          ] else ...[
            _buildCameraPrompt(),
          ],
          
          const SizedBox(height: 16),
          
          // Control Buttons
          if (_capturedImage != null) ...[
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Retake Photo',
                    icon: Icons.refresh,
                    onPressed: _retakePhoto,
                    variant: ButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: 'Use This Photo',
                    icon: Icons.check,
                    onPressed: () => widget.onPhotoTaken(_capturedImage!),
                    isLoading: widget.isSubmitting,
                  ),
                ),
              ],
            ),
          ] else ...[
            CustomButton(
              text: 'Take Photo',
              icon: Icons.camera_alt,
              onPressed: widget.isSubmitting ? null : _takePhoto,
              isLoading: widget.isSubmitting || _isAnalyzing,
              isFullWidth: true,
              size: ButtonSize.medium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 48,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Camera Permission Required',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please grant camera permission to take photos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPrompt() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 48,
              color: Colors.purple,
            ),
            SizedBox(height: 16),
            Text(
              'Ready to Capture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap "Take Photo" to begin',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Column(
      children: [
        // Photo Preview
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: _capturedImage != null
                ? Image.file(
                    File(_capturedImage!.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Analysis Status
        if (_isAnalyzing) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Analyzing photo...',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ] else if (_requirementChecks.isNotEmpty) ...[
          // Requirement Checks
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Photo Analysis Results:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                ..._requirementChecks.entries.map((entry) {
                  final isValid = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          isValid ? Icons.check_circle : Icons.error,
                          color: isValid ? Colors.green : Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: isValid ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 12),
                
                // Overall Status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _requirementChecks.values.every((check) => check)
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _requirementChecks.values.every((check) => check)
                          ? Colors.green.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _requirementChecks.values.every((check) => check)
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _requirementChecks.values.every((check) => check)
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _requirementChecks.values.every((check) => check)
                              ? 'All requirements met! Photo will be submitted automatically.'
                              : 'Some requirements not met. You can still submit or retake the photo.',
                          style: TextStyle(
                            color: _requirementChecks.values.every((check) => check)
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}