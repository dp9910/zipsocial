import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class ImageUploadService {
  static final _client = SupabaseConfig.client;

  static Future<String> uploadPostImage(File imageFile) async {
    try {
      // Generate unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final filePath = 'posts/$fileName';

      // Read file as bytes
      final Uint8List fileBytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      await _client.storage
          .from('post-images')
          .uploadBinary(filePath, fileBytes);

      // Get public URL
      final String publicUrl = _client.storage
          .from('post-images')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<void> deletePostImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the file path after 'post-images'
      final bucketIndex = pathSegments.indexOf('post-images');
      if (bucketIndex == -1 || bucketIndex >= pathSegments.length - 1) {
        throw Exception('Invalid image URL format');
      }
      
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');

      // Delete from Supabase Storage
      await _client.storage
          .from('post-images')
          .remove([filePath]);
    } catch (e) {
      // Don't throw error for delete operations - just log it
      print('Failed to delete image: $e');
    }
  }
}