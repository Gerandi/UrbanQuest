import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to test Supabase storage setup
class StorageTestService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Test if storage buckets are accessible
  Future<Map<String, bool>> testBucketAccess() async {
    final results = <String, bool>{};

    try {
      // Test quest-photos bucket
      final questPhotosResult = await _testBucket('quest-photos');
      results['quest-photos'] = questPhotosResult;

      // Test user-avatars bucket  
      final userAvatarsResult = await _testBucket('user-avatars');
      results['user-avatars'] = userAvatarsResult;

      print('📊 Storage Test Results:');
      results.forEach((bucket, success) {
        print('  $bucket: ${success ? "✅ Working" : "❌ Failed"}');
      });

      return results;
    } catch (e) {
      print('❌ Storage test error: $e');
      return {'error': false};
    }
  }

  Future<bool> _testBucket(String bucketName) async {
    try {
      // Try to list files (should work even if empty)
      final files = await _supabase.storage.from(bucketName).list();
      
      // If we get here without error, bucket is accessible
      print('✅ Bucket "$bucketName" is accessible (${files.length} files)');
      return true;
    } catch (e) {
      print('❌ Bucket "$bucketName" error: $e');
      return false;
    }
  }

  /// Test uploading a small file
  Future<bool> testFileUpload() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user for upload test');
        return false;
      }

      // Create a small test image (1x1 pixel PNG)
      final testImageBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 pixel
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
        0x54, 0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00,
        0xFF, 0xFF, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01,
        0xE2, 0x21, 0xBC, 0x33, 0x00, 0x00, 0x00, 0x00, // IEND chunk
        0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
      ]);

      final fileName = '${user.id}/test_${DateTime.now().millisecondsSinceEpoch}.png';

      // Test upload to quest-photos
      await _supabase.storage
          .from('quest-photos')
          .uploadBinary(fileName, testImageBytes);

      print('✅ Test file uploaded successfully');

      // Clean up - delete the test file
      await _supabase.storage
          .from('quest-photos')
          .remove([fileName]);

      print('✅ Test file cleaned up');
      return true;
    } catch (e) {
      print('❌ File upload test failed: $e');
      return false;
    }
  }

  /// Show storage configuration
  Future<void> showStorageInfo() async {
    try {
      print('📋 UrbanQuest Storage Configuration:');
      print('');
      
      // List all available buckets
      final buckets = await _supabase.storage.listBuckets();
      print('Available buckets:');
      for (final bucket in buckets) {
        final isUrbanQuest = ['quest-photos', 'user-avatars'].contains(bucket.id);
        print('  ${isUrbanQuest ? "✅" : "ℹ️"} ${bucket.name} (${bucket.public ? "public" : "private"})');
      }
      
      print('');
      print('Required buckets for UrbanQuest:');
      print('  📸 quest-photos (public) - for quest challenge photos');
      print('  👤 user-avatars (public) - for user profile pictures');
      
    } catch (e) {
      print('❌ Could not retrieve storage info: $e');
    }
  }
} 