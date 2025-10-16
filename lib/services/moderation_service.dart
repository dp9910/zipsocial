import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_auth_service.dart';

class ModerationService {
  static final _client = Supabase.instance.client;

  /// Block a user
  static Future<void> blockUser(String targetUserId) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      await _client.rpc('block_user', params: {
        'target_user_id': targetUserId,
      });
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  /// Unblock a user
  static Future<void> unblockUser(String targetUserId) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      await _client.rpc('unblock_user', params: {
        'target_user_id': targetUserId,
      });
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  /// Hide a post from the user's feed
  static Future<void> hidePost(String postId) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // Create the hidden_posts table if it doesn't exist and insert the record
      await _client.from('hidden_posts').insert({
        'user_id': user.id,
        'post_id': postId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      // Handle duplicate entries gracefully (user already hid this post)
      if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        return; // Post already hidden, that's fine
      }
      throw Exception('Failed to hide post: $e');
    }
  }


  /// Get list of blocked users
  static Future<List<String>> getBlockedUsers() async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('user_blocks')
          .select('blocked_id')
          .eq('blocker_id', user.id);

      return response.map((item) => item['blocked_id'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get list of hidden posts
  static Future<List<String>> getHiddenPosts() async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('hidden_posts')
          .select('post_id')
          .eq('user_id', user.id);

      return response.map((item) => item['post_id'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get list of blocked users with details
  static Future<List<Map<String, dynamic>>> getBlockedUsersDetailed() async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) return [];

    try {
      final response = await _client.rpc('get_blocked_users');
      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      return [];
    }
  }

  /// Check if a user is blocked
  static Future<bool> isUserBlocked(String targetUserId) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) return false;

    try {
      final response = await _client
          .from('user_blocks')
          .select('id')
          .eq('blocker_id', user.id)
          .eq('blocked_id', targetUserId)
          .eq('is_blocked', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if a post is hidden
  static Future<bool> isPostHidden(String postId) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) return false;

    try {
      final response = await _client
          .from('hidden_posts')
          .select('id')
          .eq('user_id', user.id)
          .eq('post_id', postId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Delete a post (only by owner)
  static Future<void> deletePost(String postId) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // First verify the user owns this post
      final post = await _client
          .from('posts')
          .select('user_id')
          .eq('id', postId)
          .maybeSingle();
      
      if (post == null) {
        throw Exception('Post not found');
      }
      
      if (post['user_id'] != user.id) {
        throw Exception('You can only delete your own posts');
      }
      
      // Delete the post (cascade will handle related data)
      await _client
          .from('posts')
          .delete()
          .eq('id', postId);
      
      // Update user's post count
      await _client
          .from('users')
          .update({
            'post_count': await _getUserPostCount(user.id),
          })
          .eq('id', user.id);
          
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  /// Helper function to get accurate post count
  static Future<int> _getUserPostCount(String userId) async {
    try {
      final response = await _client
          .from('posts')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true);
      return response.length;
    } catch (e) {
      return 0;
    }
  }

  /// Unhide a post
  static Future<void> unhidePost(String postId) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      await _client
          .from('hidden_posts')
          .delete()
          .eq('user_id', user.id)
          .eq('post_id', postId);
    } catch (e) {
      throw Exception('Failed to unhide post: $e');
    }
  }
}