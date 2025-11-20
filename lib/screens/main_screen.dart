import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'loop_screen.dart';
import 'create_post_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import '../config/theme.dart';
import '../widgets/notification_badge.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<State<HomeScreen>> _homeKey = GlobalKey<State<HomeScreen>>();
  final GlobalKey<State<LoopScreen>> _loopKey = GlobalKey<State<LoopScreen>>();
  final GlobalKey<NotificationBadgeState> _notificationBadgeKey = GlobalKey<NotificationBadgeState>();
  final GlobalKey<State<NotificationsScreen>> _notificationsKey = GlobalKey<State<NotificationsScreen>>();
  final GlobalKey<State<ProfileScreen>> _profileKey = GlobalKey<State<ProfileScreen>>();
  
  late final List<Widget?> _screens;
  final Set<int> _loadedScreens = {0}; // Home screen is loaded by default

  @override
  void initState() {
    super.initState();
    // Initialize with only home screen, others will be lazy-loaded
    _screens = [
      HomeScreen(key: _homeKey), // Load home immediately
      null, // LoopScreen - lazy load
      null, // CreatePostScreen - lazy load  
      null, // NotificationsScreen - lazy load
      null, // ProfileScreen - lazy load
    ];
  }

  Widget _getScreen(int index) {
    if (!_loadedScreens.contains(index)) {
      // Lazy load the screen when first accessed
      switch (index) {
        case 1:
          _screens[1] = LoopScreen(key: _loopKey);
          break;
        case 2:
          _screens[2] = const CreatePostScreen();
          break;
        case 3:
          _screens[3] = NotificationsScreen(
            key: _notificationsKey,
            onBadgeUpdate: () => _notificationBadgeKey.currentState?.refreshBadge(),
          );
          break;
        case 4:
          _screens[4] = ProfileScreen(key: _profileKey);
          break;
      }
      _loadedScreens.add(index);
    }
    return _screens[index]!;
  }

  void _dismissKeyboardCompletely() {
    // Comprehensive keyboard dismissal
    FocusScope.of(context).unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    // Additional dismissal for persistent keyboards
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      }
    });
  }

  Future<void> _onTabTap(int index) async {
    // Dismiss keyboard when changing tabs - enhanced dismissal
    _dismissKeyboardCompletely();
    
    // Refresh badge when leaving notifications tab
    if (_currentIndex == 3 && index != 3) {
      _notificationBadgeKey.currentState?.refreshBadge();
    }
    
    if (index == 2) {
      // Ensure keyboard is fully dismissed before navigation
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Navigate to create post as a modal
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CreatePostScreen(),
          fullscreenDialog: true,
        ),
      );
      
      if (!mounted) return;
      
      // If post was created, navigate to home tab and refresh feeds
      if (result == true) {
        // Switch to home tab first
        setState(() => _currentIndex = 0);
        
        // Then refresh all feeds
        (_homeKey.currentState as dynamic)?.refreshFeed();
        (_loopKey.currentState as dynamic)?.refreshPosts();
        (_notificationsKey.currentState as dynamic)?.refreshNotifications();
        _notificationBadgeKey.currentState?.refreshBadge();
        (_profileKey.currentState as dynamic)?.refreshProfile();
        
        // Ensure keyboard stays dismissed
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _dismissKeyboardCompletely();
        }
      }
    } else {
      setState(() => _currentIndex = index);
      
      // Refresh notification badge when navigating to notifications tab
      if (index == 3) {
        _notificationBadgeKey.currentState?.refreshBadge();
        (_notificationsKey.currentState as dynamic)?.refreshNotifications();
      }
      
      // Ensure keyboard stays dismissed after tab change
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        _dismissKeyboardCompletely();
      }
    }
  }

  @override
  void deactivate() {
    // Ensure keyboard is dismissed when main screen becomes inactive
    _dismissKeyboardCompletely();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: IndexedStack(
          index: _currentIndex == 4 ? 3 : (_currentIndex == 3 ? 2 : (_currentIndex == 1 ? 1 : 0)),
        children: [
          _getScreen(0), // Home
          _getScreen(1), // Loop
          _getScreen(3), // Notifications
          _getScreen(4), // Profile
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.secondary,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.loop),
              label: 'Loop',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              label: 'Post',
            ),
            BottomNavigationBarItem(
              icon: NotificationBadge(
                key: _notificationBadgeKey,
                child: const Icon(Icons.notifications),
              ),
              label: 'Notifications',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}