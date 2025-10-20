enum NotificationType {
  userFollowedYou,
  userUnfollowedYou,
  userBlockedYou,
  userSavedYourPost,
  userSentMessage,
  userCreatedPost,
  yourPostReported,
  yourPostDeleted,
  userCommentedOnPost,
  userLikedYourPost,
}

class AppNotification {
  final String id;
  final String recipientUserId;
  final String actorUserId;
  final String? actorNickname;
  final String? actorUsername;
  final NotificationType type;
  final String? targetId; // post_id, message_id, etc.
  final String? targetContent; // post content preview, message preview, etc.
  final Map<String, dynamic>? metadata; // additional context data
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.recipientUserId,
    required this.actorUserId,
    this.actorNickname,
    this.actorUsername,
    required this.type,
    this.targetId,
    this.targetContent,
    this.metadata,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty || json['id'] == null) {
      // Return a dummy/empty notification if JSON is empty
      return AppNotification(
        id: '',
        recipientUserId: '',
        actorUserId: '',
        type: NotificationType.userFollowedYou, // A default type
        createdAt: DateTime.now(),
      );
    }
    
    // Parse actor information from joined users table
    String? actorNickname;
    String? actorUsername;
    if (json['actor_user'] != null && json['actor_user'] is Map) {
      actorNickname = json['actor_user']['nickname'];
      actorUsername = json['actor_user']['custom_user_id'];
    }

    return AppNotification(
      id: json['id'],
      recipientUserId: json['recipient_user_id'],
      actorUserId: json['actor_user_id'],
      actorNickname: actorNickname,
      actorUsername: actorUsername,
      type: _stringToNotificationType(json['action_type']),
      targetId: json['target_id'],
      targetContent: json['target_content'],
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      isRead: json['is_read'] ?? false,
    );
  }

  static NotificationType _stringToNotificationType(String typeString) {
    switch (typeString) {
      case 'user_followed_you':
        return NotificationType.userFollowedYou;
      case 'user_unfollowed_you':
        return NotificationType.userUnfollowedYou;
      case 'user_blocked_you':
        return NotificationType.userBlockedYou;
      case 'user_saved_your_post':
        return NotificationType.userSavedYourPost;
      case 'user_sent_message':
        return NotificationType.userSentMessage;
      case 'user_created_post':
        return NotificationType.userCreatedPost;
      case 'your_post_reported':
        return NotificationType.yourPostReported;
      case 'your_post_deleted':
        return NotificationType.yourPostDeleted;
      case 'user_commented_on_post':
        return NotificationType.userCommentedOnPost;
      case 'user_liked_your_post':
        return NotificationType.userLikedYourPost;
      default:
        return NotificationType.userFollowedYou; // fallback
    }
  }

  String get typeString {
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

  /// Generate a human-readable message for this notification
  String get message {
    final displayName = actorNickname ?? actorUsername ?? 'Someone';
    
    switch (type) {
      case NotificationType.userFollowedYou:
        return '$displayName started following you';
      case NotificationType.userUnfollowedYou:
        return '$displayName unfollowed you';
      case NotificationType.userBlockedYou:
        return '$displayName blocked you';
      case NotificationType.userSavedYourPost:
        return '$displayName saved your post';
      case NotificationType.userSentMessage:
        return '$displayName sent you a message';
      case NotificationType.userCreatedPost:
        return '$displayName created a new post';
      case NotificationType.yourPostReported:
        return 'Your post was reported';
      case NotificationType.yourPostDeleted:
        return 'Your post was deleted';
      case NotificationType.userCommentedOnPost:
        return '$displayName commented on your post';
      case NotificationType.userLikedYourPost:
        return '$displayName liked your post';
    }
  }

  /// Get the appropriate icon for this notification type
  String get iconName {
    switch (type) {
      case NotificationType.userFollowedYou:
        return 'person_add';
      case NotificationType.userUnfollowedYou:
        return 'person_remove';
      case NotificationType.userBlockedYou:
        return 'block';
      case NotificationType.userSavedYourPost:
        return 'bookmark';
      case NotificationType.userSentMessage:
        return 'message';
      case NotificationType.userCreatedPost:
        return 'article';
      case NotificationType.yourPostReported:
        return 'flag';
      case NotificationType.yourPostDeleted:
        return 'delete';
      case NotificationType.userCommentedOnPost:
        return 'comment';
      case NotificationType.userLikedYourPost:
        return 'thumb_up';
    }
  }

  /// Get the color associated with this notification type
  String get colorType {
    switch (type) {
      case NotificationType.userFollowedYou:
      case NotificationType.userSavedYourPost:
      case NotificationType.userSentMessage:
      case NotificationType.userCommentedOnPost:
      case NotificationType.userLikedYourPost:
        return 'positive'; // Green/Blue tones
      case NotificationType.userCreatedPost:
        return 'neutral'; // Default app colors
      case NotificationType.userUnfollowedYou:
        return 'warning'; // Orange tones
      case NotificationType.userBlockedYou:
      case NotificationType.yourPostReported:
      case NotificationType.yourPostDeleted:
        return 'negative'; // Red tones
    }
  }

  AppNotification copyWith({
    String? id,
    String? recipientUserId,
    String? actorUserId,
    String? actorNickname,
    String? actorUsername,
    NotificationType? type,
    String? targetId,
    String? targetContent,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      actorUserId: actorUserId ?? this.actorUserId,
      actorNickname: actorNickname ?? this.actorNickname,
      actorUsername: actorUsername ?? this.actorUsername,
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      targetContent: targetContent ?? this.targetContent,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}