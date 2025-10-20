import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../utils/time_formatter.dart';
import './user_profile_screen.dart';
import './comments_screen.dart';
import './chat_conversation_screen.dart';
import '../services/supabase_auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;
  StreamSubscription<AppNotification>? _notificationSubscription;
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(Supabase.instance.client);
    _loadInitialNotifications();
    _listenForNewNotifications();
    _loadUnreadCount();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _listenForNewNotifications() {
    _notificationSubscription = _notificationService.getNotificationStream().listen((notification) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, notification);
          _unreadCount++;
        });
      }
    }, onError: (error) {
      // Handle stream errors if necessary
      print('Error in notification stream: $error');
    });
  }
  
  Future<void> _loadInitialNotifications() async {
    await _loadNotifications();
  }


  // Method to refresh notifications (called from main screen)
  Future<void> refreshNotifications() async {
    await _loadNotifications();
    await _loadUnreadCount();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final notifications = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      // Ignore errors for unread count
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    // Optimistically update UI
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(isRead: true);
        _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
      }
    });

    // Update in database
    await _notificationService.markAsRead(notification.id);
  }

  Future<void> _markAllAsRead() async {
    // Optimistically update UI
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
    });

    // Update in database
    await _notificationService.markAllAsRead();
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
    await _loadUnreadCount();
  }

  IconData _getNotificationIcon(AppNotification notification) {
    switch (notification.type) {
      case NotificationType.userFollowedYou:
        return Icons.person_add;
      case NotificationType.userUnfollowedYou:
        return Icons.person_remove;
      case NotificationType.userBlockedYou:
        return Icons.block;
      case NotificationType.userSavedYourPost:
        return Icons.bookmark;
      case NotificationType.userSentMessage:
        return Icons.message;
      case NotificationType.userCreatedPost:
        return Icons.article;
      case NotificationType.yourPostReported:
        return Icons.flag;
      case NotificationType.yourPostDeleted:
        return Icons.delete;
      case NotificationType.userCommentedOnPost:
        return Icons.comment;
      case NotificationType.userLikedYourPost:
        return Icons.thumb_up;
    }
  }

  Color _getNotificationColor(AppNotification notification) {
    switch (notification.colorType) {
      case 'positive':
        return const Color(0xFF4ECDC4);
      case 'warning':
        return Colors.orange;
      case 'negative':
        return Colors.red;
      case 'neutral':
      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(AppNotification notification) async {
    // Mark as read when tapped
    _markAsRead(notification);

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.userFollowedYou:
      case NotificationType.userUnfollowedYou:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => UserProfileScreen(userId: notification.actorUserId),
        ));
        break;
      case NotificationType.userSavedYourPost:
      case NotificationType.userLikedYourPost:
      case NotificationType.userCommentedOnPost:
      case NotificationType.userCreatedPost:
        if (notification.targetId != null) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => CommentsScreen(postId: notification.targetId!),
          ));
        }
        break;
      case NotificationType.userSentMessage:
         if (notification.targetId != null) {
          // Fetch the actor user's nickname
          final actorUser = await SupabaseAuthService.getUserProfileById(notification.actorUserId);
          if (actorUser != null) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => ChatConversationScreen(
                conversationId: notification.targetId!,
                otherUserNickname: actorUser.nickname ?? 'Unknown User',
                otherUserId: actorUser.id,
              ),
            ));
          }
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: Theme.of(context).brightness,
        ),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(
                  color: Color(0xFF4ECDC4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'When you receive notifications, they\'ll appear here',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification, isDark);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification, bool isDark) {
    final color = _getNotificationColor(notification);
    final icon = _getNotificationIcon(notification);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? (isDark ? Theme.of(context).colorScheme.surface : Colors.white)
            : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead 
              ? (isDark ? Theme.of(context).colorScheme.outline.withOpacity(0.3) : Colors.grey.shade300)
              : color.withOpacity(0.3),
          width: notification.isRead ? 1 : 2,
        ),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (notification.targetContent != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          notification.targetContent!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        TimeFormatter.formatRelativeTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Unread indicator
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}