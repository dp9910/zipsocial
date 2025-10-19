import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import 'supabase_auth_service.dart'; // Changed import
import 'content_filter_service.dart';

class PostService {
  static final _client = Supabase.instance.client;

  static Future<Post> createPost({
    required String content,
    required String zipcode,
    required PostTag tag,
    List<String> contentTags = const [],
    Map<String, dynamic>? eventDetails,
  }) async {
    final user = SupabaseAuthService.currentUser; // Changed service call
    if (user == null) throw Exception('User not authenticated');

    final userProfile = await SupabaseAuthService.getUserProfile(); // Changed service call
    if (userProfile == null) throw Exception('User profile not found');

    // Check if user is spamming
    final isSpamming = await ContentFilterService.isUserSpamming(user.id);
    if (isSpamming) {
      throw Exception('Please wait before posting again. Your account has been flagged for potential spam.');
    }

    // Filter content before posting
    final filterResult = ContentFilterService.filterContent(content, 'post');
    
    // Reject content if it's too inappropriate
    if (filterResult.action == FilterAction.rejected) {
      throw Exception(filterResult.message ?? 'Content cannot be posted due to inappropriate language.');
    }

    // Determine if post should be auto-hidden
    final isActive = filterResult.action != FilterAction.autoHidden;
    
    // Create the post
    final response = await _client
        .from('posts')
        .insert({
          'user_id': user.id, // Changed user.uid to user.id
          'username': userProfile.customUserId,
          'zipcode': zipcode,
          'content': content,
          'tag': _tagToString(tag),
          'content_tags': contentTags,
          'event_details': eventDetails,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'is_active': isActive,
        })
        .select()
        .single();

    final postId = response['id'];

    // Log content filtering result
    await ContentFilterService.logFilterResult(
      contentType: 'post',
      contentId: postId,
      userId: user.id,
      result: filterResult,
    );

    // Update user's post count
    try {
      await _client.rpc('increment_post_count', params: {
        'user_id': user.id, // Changed user.uid to user.id
      });
    } catch (e) {
      // Don't throw here - post was created successfully
    }

    final post = Post.fromJson(response);
    
    // If content was flagged but not rejected, inform the user
    if (filterResult.action == FilterAction.flagged) {
      throw Exception('Post created but flagged for review: ${filterResult.message}');
    } else if (filterResult.action == FilterAction.autoHidden) {
      throw Exception('Post created but hidden due to inappropriate content. It will be reviewed by moderators.');
    }

    return post;
  }

  static Future<List<Map<String, dynamic>>> getFeedRaw({
    required String zipcode,
    List<PostTag>? tags,
    int limit = 50,
    int offset = 0,
  }) async {
    final currentUser = SupabaseAuthService.currentUser;
    
    // Get hidden posts for current user
    List<String> hiddenPostIds = [];
    if (currentUser != null) {
      try {
        final hiddenPosts = await _client
            .from('hidden_posts')
            .select('post_id')
            .eq('user_id', currentUser.id);
        hiddenPostIds = hiddenPosts.map((item) => item['post_id'] as String).toList();
      } catch (e) {
        // If hidden_posts table doesn't exist yet, just continue
      }
    }

    // Get blocked users for current user
    List<String> blockedUserIds = [];
    if (currentUser != null) {
      try {
        final blockedUsers = await _client
            .from('user_blocks')
            .select('blocked_id')
            .eq('blocker_id', currentUser.id)
            .eq('is_blocked', true);
        blockedUserIds = blockedUsers.map((item) => item['blocked_id'] as String).toList();
      } catch (e) {
        // If user_blocks table doesn't exist yet, just continue
      }
    }

    // Build the main query
    var query = _client
        .from('posts')
        .select('''
          *,
          users!posts_user_id_fkey(nickname),
          post_interactions!left(user_id, vote, is_saved, is_reported)
        ''')
        .eq('zipcode', zipcode)
        .eq('is_active', true);

    // Exclude hidden posts
    if (hiddenPostIds.isNotEmpty) {
      query = query.not('id', 'in', hiddenPostIds);
    }

    // Exclude posts from blocked users
    if (blockedUserIds.isNotEmpty) {
      query = query.not('user_id', 'in', blockedUserIds);
    }

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
      // Direct table query for now until SQL functions are deployed
      final response = await _client
          .from('posts')
          .select('''
            *,
            users!posts_user_id_fkey(nickname),
            post_interactions!left(user_id, vote, is_saved, is_reported)
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<Post>((json) => Post.fromJson(json)).toList();
    } catch (e) {
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
            users!posts_user_id_fkey(nickname),
            post_interactions!left(user_id, vote, is_saved, is_reported)
          ''')
          .inFilter('user_id', followingIds)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<Post>((json) => Post.fromJson(json)).toList();
    } catch (e) {
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
          users!posts_user_id_fkey(nickname),
          post_interactions!inner(user_id, vote, is_saved, is_reported, updated_at)
        ''')
        .eq('post_interactions.user_id', user.id)
        .eq('post_interactions.is_saved', true)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return response.map<Post>((json) => Post.fromJson(json)).toList();
  }
}