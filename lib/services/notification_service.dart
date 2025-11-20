import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../services/supabase_auth_service.dart';

class NotificationService {
  final SupabaseClient _client;

  NotificationService(this._client);

  /// Convert NotificationType to database string format
  String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.userFollowedYou:
        return 'user_followed_you';
      case NotificationType.userUnfollowedYou:
        return 'user_unfollowed_you';
      case NotificationType.userBlockedYou:
        return 'user_blocked_you';
      case NotificationType.userSavedYourPost:
        return 'user_saved_your_post';
      case NotificationType.userSentMessage:
        return 'user_sent_message';
      case NotificationType.userCreatedPost:
        return 'user_created_post';
      case NotificationType.yourPostReported:
        return 'your_post_reported';
      case NotificationType.yourPostDeleted:
        return 'your_post_deleted';
      case NotificationType.userCommentedOnPost:
        return 'user_commented_on_post';
      case NotificationType.userLikedYourPost:
        return 'user_liked_your_post';
    }
  }

  /// Create a new notification
  Future<void> createNotification({
    required String recipientUserId,
    required String actorUserId,
    required NotificationType type,
    String? targetId,
    String? targetContent,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Don't create notifications for actions on yourself
      if (recipientUserId == actorUserId) return;

      // Check if recipient has blocked the actor
      final isBlocked = await _isUserBlocked(recipientUserId, actorUserId);
      if (isBlocked) return;

      // For certain types, check if a similar notification already exists recently
      if (await _shouldSkipDuplicateNotification(recipientUserId, actorUserId, type, targetId)) {
        return;
      }

      await _client.from('notifications').insert({
        'recipient_user_id': recipientUserId,
        'actor_user_id': actorUserId,
        'action_type': _notificationTypeToString(type),
        'target_id': targetId,
        'target_content': targetContent,
        'metadata': metadata,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'is_read': false,
      });
    } catch (e) {
      // Don't throw errors for notification failures
      print('Failed to create notification: $e');
    }
  }

  /// Check if recipient has blocked the actor
  Future<bool> _isUserBlocked(String recipientUserId, String actorUserId) async {
    try {
      final result = await _client
          .from('blocked_users')
          .select('id')
          .eq('blocker_user_id', recipientUserId)
          .eq('blocked_user_id', actorUserId)
          .maybeSingle();
      return result != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if we should skip creating a duplicate notification
  Future<bool> _shouldSkipDuplicateNotification(
    String recipientUserId,
    String actorUserId,
    NotificationType type,
    String? targetId,
  ) async {
    try {
      // For follow/unfollow, only keep the latest action
      if (type == NotificationType.userFollowedYou || type == NotificationType.userUnfollowedYou) {
        final existing = await _client
            .from('notifications')
            .select('id')
            .eq('recipient_user_id', recipientUserId)
            .eq('actor_user_id', actorUserId)
            .inFilter('action_type', ['user_followed_you', 'user_unfollowed_you'])
            .gte('created_at', DateTime.now().subtract(Duration(hours: 1)).toUtc().toIso8601String())
            .limit(1)
            .maybeSingle();
        
        if (existing != null) {
          // Delete the old notification and create the new one
          await _client.from('notifications').delete().eq('id', existing['id']);
        }
      }

      // For post interactions, limit one per user per post per hour
      if (type == NotificationType.userSavedYourPost || 
          type == NotificationType.userLikedYourPost ||
          type == NotificationType.userCommentedOnPost) {
        if (targetId != null) {
          final existing = await _client
              .from('notifications')
              .select('id')
              .eq('recipient_user_id', recipientUserId)
              .eq('actor_user_id', actorUserId)
              .eq('action_type', _notificationTypeToString(type))
              .eq('target_id', targetId)
              .gte('created_at', DateTime.now().subtract(Duration(hours: 1)).toUtc().toIso8601String())
              .limit(1)
              .maybeSingle();
          
          return existing != null;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get notifications for the current user
  Future<List<AppNotification>> getNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final user = SupabaseAuthService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _client
          .from('notifications')
          .select('''
            *,
            actor_user:users!notifications_actor_user_id_fkey(nickname, custom_user_id)
          ''')
          .eq('recipient_user_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<AppNotification>((json) => AppNotification.fromJson(json)).toList();
    } catch (e) {
      print('Failed to fetch notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final user = SupabaseAuthService.currentUser;
      if (user == null) return 0;

      final response = await _client
          .from('notifications')
          .select('id')
          .eq('recipient_user_id', user.id)
          .eq('is_read', false)
          .order('created_at', ascending: false);

      return response.length;
    } catch (e) {
      print('Failed to get unread count: $e');
      return 0;
    }
  }

  /// Get a stream of new notifications
  Stream<AppNotification> getNotificationStream() {
    final user = SupabaseAuthService.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('recipient_user_id', user.id)
        .order('created_at')
        .map((maps) {
          if (maps.isEmpty) return null;
          return maps.first;
        })
        .where((data) => data != null)
        .cast<Map<String, dynamic>>()
        .asyncMap((notificationData) async {
      try {
        final actorId = notificationData['actor_user_id'];

        // Fetch actor details
        final actorResponse = await _client
            .from('users')
            .select('nickname, custom_user_id')
            .eq('id', actorId)
            .single();

        // Combine data
        final fullNotificationData = {
          ...notificationData,
          'actor_user': actorResponse,
        };

        return AppNotification.fromJson(fullNotificationData);
      } catch (e) {
        print('Error processing notification stream data: $e');
        // Return a fallback notification or null
        return AppNotification.fromJson(notificationData);
      }
    });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    try {
      final user = SupabaseAuthService.currentUser;
      if (user == null) return;

      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_user_id', user.id)
          .eq('is_read', false);
    } catch (e) {
      print('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete old notifications (cleanup)
  Future<void> cleanupOldNotifications({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      await _client
          .from('notifications')
          .delete()
          .lt('created_at', cutoffDate.toUtc().toIso8601String());
    } catch (e) {
      print('Failed to cleanup old notifications: $e');
    }
  }

  // Convenience methods for creating specific types of notifications

  /// User followed another user
  Future<void> notifyUserFollowed(String followedUserId) async {
    final currentUser = SupabaseAuthService.currentUser;
    if (currentUser == null) return;

    await createNotification(
      recipientUserId: followedUserId,
      actorUserId: currentUser.id,
      type: NotificationType.userFollowedYou,
    );
  }

  /// User unfollowed another user
  Future<void> notifyUserUnfollowed(String unfollowedUserId) async {
    final currentUser = SupabaseAuthService.currentUser;
    if (currentUser == null) return;

    await createNotification(
      recipientUserId: unfollowedUserId,
      actorUserId: currentUser.id,
      type: NotificationType.userUnfollowedYou,
    );
  }

  /// User saved a post
  Future<void> notifyPostSaved(String postId, String postOwnerId, String? postContent) async {
    final currentUser = SupabaseAuthService.currentUser;
    if (currentUser == null) return;

    await createNotification(
      recipientUserId: postOwnerId,
      actorUserId: currentUser.id,
      type: NotificationType.userSavedYourPost,
      targetId: postId,
      targetContent: postContent?.length != null && postContent!.length > 100 
          ? '${postContent.substring(0, 100)}...' 
          : postContent,
    );
  }

  /// User liked a post
  Future<void> notifyPostLiked(String postId, String postOwnerId, String? postContent) async {
    final currentUser = SupabaseAuthService.currentUser;
    if (currentUser == null) return;

    await createNotification(
      recipientUserId: postOwnerId,
      actorUserId: currentUser.id,
      type: NotificationType.userLikedYourPost,
      targetId: postId,
      targetContent: postContent?.length != null && postContent!.length > 100 
          ? '${postContent.substring(0, 100)}...' 
          : postContent,
    );
  }

  /// User commented on a post
  Future<void> notifyPostCommented(String postId, String postOwnerId, String? postContent, String? commentContent) async {
    final currentUser = SupabaseAuthService.currentUser;
    if (currentUser == null) return;

    await createNotification(
      recipientUserId: postOwnerId,
      actorUserId: currentUser.id,
      type: NotificationType.userCommentedOnPost,
      targetId: postId,
      targetContent: postContent?.length != null && postContent!.length > 100 
          ? '${postContent.substring(0, 100)}...' 
          : postContent,
      metadata: {
        'comment_content': commentContent?.length != null && commentContent!.length > 100 
            ? '${commentContent.substring(0, 100)}...' 
            : commentContent,
      },
    );
  }

  /// User sent a message
  Future<void> notifyMessageSent(String recipientUserId, String? messagePreview) async {
    final currentUser = SupabaseAuthService.currentUser;
    if (currentUser == null) return;

    await createNotification(
      recipientUserId: recipientUserId,
      actorUserId: currentUser.id,
      type: NotificationType.userSentMessage,
      targetContent: messagePreview?.length != null && messagePreview!.length > 50 
          ? '${messagePreview.substring(0, 50)}...' 
          : messagePreview,
    );
  }

  /// User created a new post (notify followers)
  Future<void> notifyFollowersOfNewPost(String postId, String? postContent) async {
    final currentUser = SupabaseAuthService.currentUser;
    if (currentUser == null) return;

    try {
      // Get all followers
      final followers = await _client
          .from('followers')
          .select('follower_id')
          .eq('following_id', currentUser.id);

      // Create notifications for all followers
      for (final follower in followers) {
        await createNotification(
          recipientUserId: follower['follower_id'],
          actorUserId: currentUser.id,
          type: NotificationType.userCreatedPost,
          targetId: postId,
          targetContent: postContent?.length != null && postContent!.length > 100 
              ? '${postContent.substring(0, 100)}...' 
              : postContent,
        );
      }
    } catch (e) {
      print('Failed to notify followers of new post: $e');
    }
  }

  /// Post was reported/deleted
  Future<void> notifyPostModerated(String postId, String postOwnerId, NotificationType type, String? reason) async {
    await createNotification(
      recipientUserId: postOwnerId,
      actorUserId: 'system', // or admin user ID
      type: type,
      targetId: postId,
      metadata: reason != null ? {'reason': reason} : null,
    );
  }
}