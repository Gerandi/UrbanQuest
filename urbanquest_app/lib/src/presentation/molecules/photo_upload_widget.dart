import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:io';
import '../atoms/custom_button.dart';
import '../atoms/glass_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/photo_upload_service.dart';

class PhotoUploadWidget extends StatefulWidget {
  final Function(String photoUrl)? onPhotoUploaded;
  final Function(String error)? onError;
  final String? initialImageUrl;
  final String uploadPath;
  final bool isCircular;
  final double? width;
  final double? height;
  final String uploadButtonText;
  final bool showPreview;

  const PhotoUploadWidget({
    super.key,
    this.onPhotoUploaded,
    this.onError,
    this.initialImageUrl,
    required this.uploadPath,
    this.isCircular = false,
    this.width,
    this.height,
    this.uploadButtonText = 'Upload Photo',
    this.showPreview = true,
  });

  @override
  State<PhotoUploadWidget> createState() => _PhotoUploadWidgetState();
}

class _PhotoUploadWidgetState extends State<PhotoUploadWidget> {
  final PhotoUploadService _photoService = PhotoUploadService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isUploading = false;
  String? _currentImageUrl;
  Uint8List? _selectedImageBytes;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showPreview) ...[
            _buildImagePreview(),
            const SizedBox(height: 16),
          ],
          _buildUploadButtons(),
          if (_isUploading) ...[
            const SizedBox(height: 16),
            _buildUploadProgress(),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final hasImage = _selectedImageBytes != null || _currentImageUrl != null;
    
    return Container(
      width: widget.width ?? 200,
      height: widget.height ?? 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: widget.isCircular 
            ? BorderRadius.circular((widget.width ?? 200) / 2)
            : BorderRadius.circular(12),
        border: Border.all(
          color: hasImage ? AppColors.primary.withOpacity(0.3) : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: hasImage
          ? _buildImageDisplay()
          : _buildPlaceholder(),
    );
  }

  Widget _buildImageDisplay() {
    if (_selectedImageBytes != null) {
      return ClipRRect(
        borderRadius: widget.isCircular 
            ? BorderRadius.circular((widget.width ?? 200) / 2)
            : BorderRadius.circular(10),
        child: Image.memory(
          _selectedImageBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (_currentImageUrl != null) {
      return ClipRRect(
        borderRadius: widget.isCircular 
            ? BorderRadius.circular((widget.width ?? 200) / 2)
            : BorderRadius.circular(10),
        child: Image.network(
          _currentImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    }
    
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'No photo selected',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Camera',
            onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
            icon: Icons.camera_alt,
            variant: ButtonVariant.outline,
            size: ButtonSize.medium,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            text: 'Gallery',
            onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
            icon: Icons.photo_library,
            variant: ButtonVariant.outline,
            size: ButtonSize.medium,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadProgress() {
    return Column(
      children: [
        const LinearProgressIndicator(
          backgroundColor: Colors.grey,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Uploading photo...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final imageBytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = imageBytes;
        });

        await _uploadImage(imageBytes);
      }
    } catch (e) {
      _handleError('Failed to pick image: $e');
    }
  }

  Future<void> _uploadImage(Uint8List imageBytes) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final photoUrl = await _photoService.uploadPhoto(
        imageBytes,
        '${widget.uploadPath}/$fileName',
      );

      if (photoUrl != null) {
        setState(() {
          _currentImageUrl = photoUrl;
          _selectedImageBytes = null;
        });
        widget.onPhotoUploaded?.call(photoUrl);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to upload photo');
      }
    } catch (e) {
      _handleError('Upload failed: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _handleError(String error) {
    widget.onError?.call(error);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class ProfilePhotoUpload extends StatelessWidget {
  final String? currentPhotoUrl;
  final Function(String photoUrl)? onPhotoChanged;
  final String userId;

  const ProfilePhotoUpload({
    super.key,
    this.currentPhotoUrl,
    this.onPhotoChanged,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return PhotoUploadWidget(
      initialImageUrl: currentPhotoUrl,
      uploadPath: 'profile_photos/$userId',
      isCircular: true,
      width: 120,
      height: 120,
      uploadButtonText: 'Change Photo',
      onPhotoUploaded: onPhotoChanged,
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile photo: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
}

class QuestPhotoUpload extends StatelessWidget {
  final Function(String photoUrl) onPhotoUploaded;
  final String questId;
  final String stopId;

  const QuestPhotoUpload({
    super.key,
    required this.onPhotoUploaded,
    required this.questId,
    required this.stopId,
  });

  @override
  Widget build(BuildContext context) {
    return PhotoUploadWidget(
      uploadPath: 'quest_photos/$questId/$stopId',
      width: double.infinity,
      height: 250,
      uploadButtonText: 'Take Photo',
      onPhotoUploaded: onPhotoUploaded,
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload quest photo: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }
}