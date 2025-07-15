import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoUploadService {
  static final PhotoUploadService _instance = PhotoUploadService._internal();
  factory PhotoUploadService() => _instance;
  PhotoUploadService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload a quest photo to Supabase Storage
  Future<String?> uploadQuestPhoto({
    required String questId,
    required String stopId,
    required String imagePath,
    int maxWidth = 1080,
    int maxHeight = 1080,
    int quality = 80,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Read and compress the image
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final compressedBytes = await _compressImage(bytes, maxWidth, maxHeight, quality);

      // Create unique filename
      final extension = path.extension(imagePath).toLowerCase();
      final fileName = '${user.id}/$questId/${stopId}_${DateTime.now().millisecondsSinceEpoch}$extension';

      // Upload to Supabase Storage
      await _supabase.storage
          .from('quest-photos')
          .uploadBinary(fileName, compressedBytes);

      // Get public URL
      final url = _supabase.storage
          .from('quest-photos')
          .getPublicUrl(fileName);

      // Save photo metadata to database
      await _savePhotoMetadata(
        userId: user.id,
        questId: questId,
        stopId: stopId,
        photoUrl: url,
        fileName: fileName,
      );

      return url;
    } catch (e) {
      print('Error uploading quest photo: $e');
      return null;
    }
  }

  /// Upload user avatar photo
  Future<String?> uploadUserAvatar({
    required String imagePath,
    int maxSize = 400,
    int quality = 90,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Read and compress the image (square crop)
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final compressedBytes = await _compressImage(bytes, maxSize, maxSize, quality, cropSquare: true);

      // Create unique filename
      final extension = path.extension(imagePath).toLowerCase();
      final fileName = 'avatars/${user.id}_${DateTime.now().millisecondsSinceEpoch}$extension';

      // Upload to Supabase Storage
      await _supabase.storage
          .from('user-avatars')
          .uploadBinary(fileName, compressedBytes);

      // Get public URL
      final url = _supabase.storage
          .from('user-avatars')
          .getPublicUrl(fileName);

      // Update user profile with new avatar URL
      await _supabase
          .from('profiles')
          .update({'avatar_url': url})
          .eq('id', user.id);

      return url;
    } catch (e) {
      print('Error uploading user avatar: $e');
      return null;
    }
  }

  /// Compress and resize image
  Future<Uint8List> _compressImage(
    Uint8List bytes,
    int maxWidth,
    int maxHeight,
    int quality, {
    bool cropSquare = false,
  }) async {
    // Decode the image
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Invalid image format');

    img.Image resized;

    if (cropSquare) {
      // Crop to square aspect ratio
      final size = image.width < image.height ? image.width : image.height;
      final x = (image.width - size) ~/ 2;
      final y = (image.height - size) ~/ 2;
      final cropped = img.copyCrop(image, x: x, y: y, width: size, height: size);
      resized = img.copyResize(cropped, width: maxWidth, height: maxHeight);
    } else {
      // Resize maintaining aspect ratio
      resized = img.copyResize(
        image,
        width: maxWidth,
        height: maxHeight,
        maintainAspect: true,
      );
    }

    // Encode with compression
    final compressed = img.encodeJpg(resized, quality: quality);
    return Uint8List.fromList(compressed);
  }

  /// Save photo metadata to database
  Future<void> _savePhotoMetadata({
    required String userId,
    required String questId,
    required String stopId,
    required String photoUrl,
    required String fileName,
  }) async {
    await _supabase.from('quest_photos').insert({
      'user_id': userId,
      'quest_id': questId,
      'stop_id': stopId,
      'photo_url': photoUrl,
      'file_name': fileName,
      'uploaded_at': DateTime.now().toIso8601String(),
    });
  }

  /// Delete a photo from storage and database
  Future<bool> deletePhoto(String photoId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get photo metadata
      final photoData = await _supabase
          .from('quest_photos')
          .select('file_name, user_id')
          .eq('id', photoId)
          .single();

      // Verify ownership
      if (photoData['user_id'] != user.id) {
        throw Exception('Not authorized to delete this photo');
      }

      // Delete from storage
      await _supabase.storage
          .from('quest-photos')
          .remove([photoData['file_name']]);

      // Delete from database
      await _supabase
          .from('quest_photos')
          .delete()
          .eq('id', photoId);

      return true;
    } catch (e) {
      print('Error deleting photo: $e');
      return false;
    }
  }

  /// Get photos for a quest
  Future<List<Map<String, dynamic>>> getQuestPhotos(String questId) async {
    try {
      final response = await _supabase
          .from('quest_photos')
          .select('*, profiles(display_name, avatar_url)')
          .eq('quest_id', questId)
          .order('uploaded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting quest photos: $e');
      return [];
    }
  }

  /// Get user's uploaded photos
  Future<List<Map<String, dynamic>>> getUserPhotos(String userId) async {
    try {
      final response = await _supabase
          .from('quest_photos')
          .select('*, quests(title)')
          .eq('user_id', userId)
          .order('uploaded_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user photos: $e');
      return [];
    }
  }
} 