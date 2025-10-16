import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class InteractionService {
  static final _supabase = Supabase.instance.client;

  static Future<void> toggleVote(String postId, bool? isUpvote) async {
    try {
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

      // Also add to reported_posts table for admin tracking
      try {
        await _supabase.from('reported_posts').insert({
          'post_id': postId,
          'reporter_user_id': user.id,
          'reported_at': DateTime.now().toUtc().toIso8601String(),
          'status': 'pending', // pending, reviewed, resolved
        });
      } catch (e) {
        // Don't fail the main report if this fails (table might not exist yet)
        print('Failed to log to reported_posts table: $e');
      }

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
      });
    } catch (e) {
      rethrow;
    }
  }
}
