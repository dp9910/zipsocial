import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/supabase_auth_service.dart';
import '../widgets/post_card.dart';
import 'chat_list_screen.dart';

class LoopScreen extends StatefulWidget {
  const LoopScreen({super.key});

  @override
  State<LoopScreen> createState() => _LoopScreenState();
}

// Adding a mixin to expose refresh method for external calls
mixin LoopScreenMixin {
  void refreshPosts();
}

class _LoopScreenState extends State<LoopScreen> with TickerProviderStateMixin, LoopScreenMixin {
  late TabController _tabController;
  List<Post> _followingPosts = [];
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFollowingPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowingPosts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final posts = await PostService.getFollowingPosts();
      if (mounted) {
        setState(() {
          _followingPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading following posts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _loadFollowingPosts();
  }

  @override
  void refreshPosts() {
    _refreshPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Loop',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF8CE830),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF8CE830),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.dynamic_feed),
              text: 'Posts',
            ),
            Tab(
              icon: Icon(Icons.chat_bubble_outline),
              text: 'Chat',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPostsTab(),
          _buildChatTab(),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8CE830)),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load posts from people you follow',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshPosts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8CE830),
                foregroundColor: Colors.white,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_followingPosts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshPosts,
        color: const Color(0xFF8CE830),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Follow some users to see their posts here!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: const Color(0xFF8CE830),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _followingPosts.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PostCard(
              post: _followingPosts[index],
              onPostUpdated: () {
                // Refresh the specific post or entire list
                _refreshPosts();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatTab() {
    return const ChatListScreen();
  }
}