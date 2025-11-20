import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../config/theme.dart';

class NotificationBadge extends StatefulWidget {
  final Widget child;
  
  const NotificationBadge({
    super.key,
    required this.child,
  });

  @override
  State<NotificationBadge> createState() => NotificationBadgeState();
}

// Make the state class public so it can be accessed from main_screen.dart
class NotificationBadgeState extends State<NotificationBadge> with WidgetsBindingObserver {
  int _unreadCount = 0;
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(Supabase.instance.client);
    WidgetsBinding.instance.addObserver(this);
    // Defer notification loading to after UI renders for faster startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUnreadCount();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh badge when app comes to foreground
      _loadUnreadCount();
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _unreadCount = 0;
        });
      }
    }
  }

  // Method to refresh the badge (called from main screen)
  Future<void> refreshBadge() async {
    await _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (_unreadCount > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}