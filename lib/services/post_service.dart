import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/post.dart';
import 'supabase_auth_service.dart'; // Changed import

class PostService {
  static final _client = Supabase.instance.client;

  static Future<Post> createPost({
    required String content,
    required String zipcode,
    required PostTag tag,
    Map<String, dynamic>? eventDetails,
  }) async {
    final user = SupabaseAuthService.currentUser; // Changed service call
    if (user == null) throw Exception('User not authenticated');

    final userProfile = await SupabaseAuthService.getUserProfile(); // Changed service call
    if (userProfile == null) throw Exception('User profile not found');

    // Create the post
    final response = await _client
        .from('posts')
        .insert({
          'user_id': user.id, // Changed user.uid to user.id
          'username': userProfile.customUserId,
          'zipcode': zipcode,
          'content': content,
          'tag': _tagToString(tag),
          'event_details': eventDetails,
          'created_at': DateTime.now().toIso8601String(),
          'is_active': true,
        })
        .select()
        .single();

    // Update user's post count
    try {
      await _client.rpc('increment_post_count', params: {
        'user_id': user.id, // Changed user.uid to user.id
      });
    } catch (e) {
      print('Error updating post count: $e');
      // Don't throw here - post was created successfully
    }

    return Post.fromJson(response);
  }

  static Future<List<Map<String, dynamic>>> getFeedRaw({
    required String zipcode,
    List<PostTag>? tags,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('posts')
        .select('''
          *,
          post_interactions!left(user_id, vote, is_saved)
        ''')
        .eq('zipcode', zipcode)
        .eq('is_active', true);

    if (tags != null && tags.isNotEmpty) {
      final tagStrings = tags.map(_tagToString).toList();
      query = query.inFilter('tag', tagStrings);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return response;
  }

  static Future<List<Post>> getFeed({
    required String zipcode,
    List<PostTag>? tags,
    int limit = 50,
    int offset = 0,
  }) async {
    final rawResponse = await getFeedRaw(zipcode: zipcode, tags: tags, limit: limit, offset: offset);
    return rawResponse.map<Post>((json) => Post.fromJson(json)).toList();
  }

  static String _tagToString(PostTag tag) {
    switch (tag) {
      case PostTag.news: return 'news';
      case PostTag.funFacts: return 'fun_facts';
      case PostTag.events: return 'events';
      case PostTag.random: return 'random';
    }
  }
}


class PostInteractionService {
  static final _client = Supabase.instance.client;

  static Future<void> vote(String postId, bool isUpvote) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client.from('post_interactions').upsert({
      'post_id': postId,
      'user_id': user.id,
      'vote': isUpvote ? 1 : -1,
    });
  }

  static Future<void> report(String postId) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client.rpc('report_post', params: {'post_id': postId});
  }

  static Future<void> save(String postId, bool isSaved) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client.from('post_interactions').upsert({
      'post_id': postId,
      'user_id': user.id,
      'is_saved': isSaved,
    });
  }
}