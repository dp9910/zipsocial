import '../config/supabase_config.dart';
import '../models/post.dart';
import 'firebase_auth_service.dart';

class PostService {
  static final _client = SupabaseConfig.client;

  static Future<Post> createPost({
    required String content,
    required String zipcode,
    required PostTag tag,
    Map<String, dynamic>? eventDetails,
  }) async {
    final user = FirebaseAuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userProfile = await FirebaseAuthService.getUserProfile();
    if (userProfile == null) throw Exception('User profile not found');

    final response = await _client
        .from('posts')
        .insert({
          'user_id': user.uid,
          'username': userProfile.customUserId,
          'zipcode': zipcode,
          'content': content,
          'tag': _tagToString(tag),
          'event_details': eventDetails,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

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