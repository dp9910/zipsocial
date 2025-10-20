import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../services/notification_service.dart';

class InteractionService {
  static final _supabase = Supabase.instance.client;

  static Future<void> toggleVote(String postId, bool? isUpvote) async {
    try {
      // Get post details for notification
      final post = await _supabase
          .from('posts')
          .select('user_id, content')
          .eq('id', postId)
          .single();

      final url = Uri.parse('${SupabaseConfig.url}/functions/v1/toggle-vote');
      final headers = {
        'Content-Type': 'application/json',
        'apikey': SupabaseConfig.anonKey,
        'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken}',
      };
      final body = jsonEncode({
        'post_id': postId,
        'vote': isUpvote == null ? null : (isUpvote ? 'up' : 'down'),
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode != 200) {
        throw Exception('Failed to toggle vote: ${response.body}');
      }

      // Send notification for upvotes only
      if (isUpvote == true) {
        try {
          final notificationService = NotificationService(_supabase);
          await notificationService.notifyPostLiked(
            postId,
            post['user_id'],
            post['content'],
          );
        } catch (e) {
          print('Failed to send like notification: $e');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> reportPost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Use the same pattern as the working save function
      final existingInteraction = await _supabase
          .from('post_interactions')
          .select()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingInteraction != null) {
        // Check if already reported
        if (existingInteraction['is_reported'] == true) {
          throw Exception('You have already reported this post');
        }
        // Update existing record
        await _supabase
            .from('post_interactions')
            .update({'is_reported': true})
            .eq('post_id', postId)
            .eq('user_id', user.id);
      } else {
        // Insert new record
        await _supabase.from('post_interactions').insert({
          'post_id': postId,
          'user_id': user.id,
          'is_reported': true,
        });
      }

      // Update report count in posts table
      final reportCountResponse = await _supabase
          .from('post_interactions')
          .select('id')
          .eq('post_id', postId)
          .eq('is_reported', true);
      
      final reportCount = reportCountResponse.length;
      
      await _supabase
          .from('posts')
          .update({'report_count': reportCount})
          .eq('id', postId);

      // Note: Using post_interactions table to track reports instead of separate reported_posts table

    } catch (e) {
      rethrow;
    }
  }

  static Future<void> savePost(String postId, bool isSaved) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('post_interactions').upsert({
        'post_id': postId,
        'user_id': user.id,
        'is_saved': isSaved,
      }, onConflict: 'post_id,user_id');

      // Send notification when post is saved
      if (isSaved) {
        try {
          // Get post details for notification
          final post = await _supabase
              .from('posts')
              .select('user_id, content')
              .eq('id', postId)
              .single();

          final notificationService = NotificationService(_supabase);
          await notificationService.notifyPostSaved(
            postId,
            post['user_id'],
            post['content'],
          );
        } catch (e) {
          print('Failed to send save notification: $e');
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
