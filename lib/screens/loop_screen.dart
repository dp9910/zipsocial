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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey.shade900 : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final unselectedTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Loop',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: textColor,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4ECDC4),
              unselectedLabelColor: unselectedTextColor,
              indicatorColor: const Color(0xFF4ECDC4),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: unselectedTextColor,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.dynamic_feed, size: 24),
                  text: 'Posts',
                  height: 60,
                ),
                Tab(
                  icon: Icon(Icons.chat_bubble_outline, size: 24),
                  text: 'Chat',
                  height: 60,
                ),
              ],
            ),
          ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
    final primaryTextColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;
    final secondaryTextColor = isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500;
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
          strokeWidth: 3,
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  color: primaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load posts from people you follow',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _refreshPosts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_followingPosts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshPosts,
        color: const Color(0xFF4ECDC4),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                        border: Border.all(
                          color: const Color(0xFF4ECDC4).withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.people_outline,
                        size: 48,
                        color: const Color(0xFF4ECDC4).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No posts yet',
                      style: TextStyle(
                        fontSize: 22,
                        color: primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Follow some users to see their posts in your Loop!',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull down to refresh',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF4ECDC4).withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: const Color(0xFF4ECDC4),
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