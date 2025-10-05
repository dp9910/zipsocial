import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment.dart';
import 'supabase_auth_service.dart'; // Changed import

class CommentService {
  static final _supabase = Supabase.instance.client;

  static Future<List<Comment>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select()
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      return response.map((data) => Comment.fromJson(data)).toList();
    } catch (e) {
      // Handle error
      print('Error fetching comments: $e');
      return [];
    }
  }

  static Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    try {
      final user = await SupabaseAuthService.getUserProfile(); // Changed service call
      if (user == null) {
        throw Exception('User not found');
      }

      await _supabase.from('comments').insert({
        'post_id': postId,
        'user_id': user.id,
        'username': user.customUserId,
        'content': content,
      });
    } catch (e) {
      // Handle error
      print('Error adding comment: $e');
      rethrow;
    }
  }
}