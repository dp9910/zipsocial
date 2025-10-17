import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_auth_service.dart';

class ModerationService {
  static final _client = Supabase.instance.client;

  /// Block a user
  static Future<void> blockUser(String targetUserId) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // 1. Create or update the block record
      final existingBlock = await _client
          .from('user_blocks')
          .select('id')
          .eq('blocker_id', user.id)
          .eq('blocked_id', targetUserId)
          .maybeSingle();

      if (existingBlock != null) {
        // Update existing record
        await _client
            .from('user_blocks')
            .update({
              'is_blocked': true,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('blocker_id', user.id)
            .eq('blocked_id', targetUserId);
      } else {
        // Insert new record
        await _client.from('user_blocks').insert({
          'blocker_id': user.id,
          'blocked_id': targetUserId,
          'is_blocked': true,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }

      // 2. Handle unfollowing - remove blocked user from blocker's following list
      try {
        await SupabaseAuthService.unfollowUser(targetUserId);
      } catch (e) {
        print('Note: Could not unfollow user during block (might not be following): $e');
      }

      // 3. Handle bidirectional follower removal - break ALL follow relationships between the users
      try {
        // Remove blocker from blocked user's following list (if blocked user was following blocker)
        await _client
            .from('user_follows')
            .delete()
            .eq('follower_id', targetUserId)
            .eq('following_id', user.id);
        
        // Also remove blocked user from blocker's following list (redundant but ensures consistency)
        await _client
            .from('user_follows')
            .delete()
            .eq('follower_id', user.id)
            .eq('following_id', targetUserId);
      } catch (e) {
        print('Note: Could not remove follower relationships during block: $e');
      }

    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  /// Unblock a user
  static Future<void> unblockUser(String targetUserId) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      print('DEBUG: Unblocking user $targetUserId by ${user.id}');
      
      // Update the block record to set is_blocked = false
      await _client.from('user_blocks')
          .update({
            'is_blocked': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('blocker_id', user.id)
          .eq('blocked_id', targetUserId);
      
      print('DEBUG: Successfully unblocked user $targetUserId');
    } catch (e) {
      print('DEBUG: Error unblocking user: $e');
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

  /// Check if current user is blocked by another user (reverse check)
  static Future<bool> isBlockedByUser(String targetUserId) async {
    final user = SupabaseAuthService.currentUser;
    if (user == null) return false;

    try {
      // Query to check if the current user is blocked by the target user
      final response = await _client
          .from('user_blocks')
          .select('*')
          .or('and(blocker_id.eq.$targetUserId,blocked_id.eq.${user.id}),and(blocker_id.eq.${user.id},blocked_id.eq.$targetUserId)')
          .eq('is_blocked', true);

      final foundBlock = response.where((block) => 
        block['blocker_id'] == targetUserId && 
        block['blocked_id'] == user.id && 
        block['is_blocked'] == true
      ).isNotEmpty;

      return foundBlock;
    } catch (e) {
      return false;
    }
  }

  /// Check if users are blocked from messaging each other (bidirectional)
  static Future<bool> areUsersBlockedFromMessaging(String userId1, String userId2) async {
    try {
      // Check if userId1 blocked userId2
      final block1Response = await _client
          .from('user_blocks')
          .select('*')
          .eq('blocker_id', userId1)
          .eq('blocked_id', userId2)
          .eq('is_blocked', true);
      
      // Check if userId2 blocked userId1
      final block2Response = await _client
          .from('user_blocks')
          .select('*')
          .eq('blocker_id', userId2)
          .eq('blocked_id', userId1)
          .eq('is_blocked', true);

      final isBlocked = block1Response.isNotEmpty || block2Response.isNotEmpty;
      return isBlocked;
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