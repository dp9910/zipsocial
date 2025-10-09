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
          'created_at': DateTime.now().toUtc().toIso8601String(),
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

  static Future<List<Post>> getUserPosts({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('posts')
          .select('''
            *,
            post_interactions!left(user_id, vote, is_saved)
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<Post>((json) => Post.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching user posts: $e');
      return [];
    }
  }

  static Future<List<Post>> getFollowingPosts({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final currentUser = SupabaseAuthService.currentUser;
      if (currentUser == null) return [];

      // First get the list of users the current user is following
      final followingResponse = await _client
          .from('followers')
          .select('following_id')
          .eq('follower_id', currentUser.id);

      if (followingResponse.isEmpty) {
        return [];
      }

      // Extract the user IDs that the current user is following
      final followingIds = followingResponse
          .map((item) => item['following_id'] as String)
          .toList();

      // Fetch posts from these users
      final response = await _client
          .from('posts')
          .select('''
            *,
            post_interactions!left(user_id, vote, is_saved)
          ''')
          .inFilter('user_id', followingIds)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<Post>((json) => Post.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching following posts: $e');
      return [];
    }
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

    try {
      // Insert or update the report in post_interactions table
      await _client.from('post_interactions').upsert({
        'post_id': postId,
        'user_id': user.id,
        'is_reported': true,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Get current report count and update posts table
      final reportCountResponse = await _client
          .from('post_interactions')
          .select('id')
          .eq('post_id', postId)
          .eq('is_reported', true);
      
      final reportCount = reportCountResponse.length;
      
      await _client
          .from('posts')
          .update({'report_count': reportCount})
          .eq('id', postId);
          
    } catch (e) {
      print('Error in report operation: $e');
      rethrow;
    }
  }

  static Future<void> save(String postId, bool isSaved) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // First, try to find existing interaction
      final existingInteraction = await _client
          .from('post_interactions')
          .select()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingInteraction != null) {
        // Update existing record
        await _client
            .from('post_interactions')
            .update({
              'is_saved': isSaved,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('post_id', postId)
            .eq('user_id', user.id);
      } else {
        // Insert new record
        await _client.from('post_interactions').insert({
          'post_id': postId,
          'user_id': user.id,
          'is_saved': isSaved,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error in save operation: $e');
      rethrow;
    }
  }

  /// Get saved posts for current user
  static Future<List<Post>> getSavedPosts({
    int limit = 50,
    int offset = 0,
  }) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await _client
        .from('posts')
        .select('''
          *,
          post_interactions!inner(user_id, vote, is_saved, updated_at)
        ''')
        .eq('post_interactions.user_id', user.id)
        .eq('post_interactions.is_saved', true)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return response.map<Post>((json) => Post.fromJson(json)).toList();
  }
}