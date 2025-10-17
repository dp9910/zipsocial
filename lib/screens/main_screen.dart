import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'loop_screen.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import '../config/theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final GlobalKey<State<HomeScreen>> _homeKey = GlobalKey<State<HomeScreen>>();
  final GlobalKey<State<LoopScreen>> _loopKey = GlobalKey<State<LoopScreen>>();
  final GlobalKey<State<ProfileScreen>> _profileKey = GlobalKey<State<ProfileScreen>>();
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _homeKey),
      LoopScreen(key: _loopKey),
      const CreatePostScreen(),
      ProfileScreen(key: _profileKey),
    ];
  }

  Future<void> _onTabTap(int index) async {
    // Dismiss keyboard when changing tabs
    FocusScope.of(context).unfocus();
    
    if (index == 2) {
      // Navigate to create post as a modal
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CreatePostScreen(),
          fullscreenDialog: true,
        ),
      );
      
      // If post was created, refresh home feed, loop feed, and profile
      if (result == true) {
        (_homeKey.currentState as dynamic)?.refreshFeed();
        (_loopKey.currentState as dynamic)?.refreshPosts();
        (_profileKey.currentState as dynamic)?.refreshProfile();
      }
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 3 ? 2 : (_currentIndex == 1 ? 1 : 0),
        children: [
          _screens[0], // Home
          _screens[1], // Loop
          _screens[3], // Profile
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.loop),
              label: 'Loop',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              label: 'Post',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}