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

      print('--- Invoking toggle_vote ---');
      print('URL: $url');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.post(url, headers: headers, body: body);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to toggle vote: ${response.body}');
      }
      print('Successfully toggled vote for post $postId. New vote: $isUpvote'); // Add this line
    } catch (e) {
      print('Error toggling vote: $e');
      rethrow;
    }
  }

  static Future<void> reportPost(String postId) async {
    try {
      await _supabase.functions.invoke('report_post', body: {
        'post_id': postId,
      });
      print('Successfully reported post $postId'); // Add this line
    } catch (e) {
      print('Error reporting post: $e');
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
      print('Successfully saved post $postId. Is saved: $isSaved'); // Add this line
    } catch (e) {
      print('Error saving post: $e');
      rethrow;
    }
  }
}
