import '../config/supabase_config.dart';
import '../models/post.dart';
import 'supabase_auth_service.dart'; // Changed import

class PostService {
  static final _client = SupabaseConfig.client;

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

  static Future<List<Post>> getFeed({
    required String zipcode,
    List<PostTag>? tags,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('posts')
        .select('''
          *,
          post_interactions!left(vote, is_saved)
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

    return response.map<Post>((json) => Post.fromJson(json)).toList();
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
