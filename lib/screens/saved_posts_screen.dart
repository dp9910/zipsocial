import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../config/theme.dart';
import '../widgets/post_card.dart';
import '../utils/time_formatter.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  List<Post> _savedPosts = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPosts() async {
    if (!_isRefreshing) {
      setState(() => _isLoading = true);
    }

    try {
      final posts = await PostInteractionService.getSavedPosts();
      setState(() {
        _savedPosts = posts;
      });
    } catch (e) {
      print('Error loading saved posts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load saved posts: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshSavedPosts() async {
    setState(() => _isRefreshing = true);
    await _loadSavedPosts();
  }

  void _onPostUpdated() {
    // Refresh the saved posts when a post is updated (e.g., unsaved)
    _refreshSavedPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Posts (${_savedPosts.length})'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshSavedPosts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedPosts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refreshSavedPosts,
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _savedPosts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return PostCard(
                        post: _savedPosts[index],
                        onPostUpdated: _onPostUpdated,
                      );
                    },
                  ),
                ),
      floatingActionButton: _savedPosts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // Show saved posts stats
                _showSavedPostsStats();
              },
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Stats'),
              backgroundColor: AppTheme.primary,
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshSavedPosts,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  'No Saved Posts',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Start saving posts you want to read later!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppTheme.primary,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tip: Tap the bookmark icon on any post to save it here!',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSavedPostsStats() {
    // Group posts by tag
    final Map<PostTag, int> tagCounts = {};
    for (final post in _savedPosts) {
      tagCounts[post.tag] = (tagCounts[post.tag] ?? 0) + 1;
    }

    // Find most recent save
    DateTime? mostRecent;
    for (final post in _savedPosts) {
      if (mostRecent == null || post.createdAt.isAfter(mostRecent)) {
        mostRecent = post.createdAt;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.analytics, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text('Saved Posts Stats'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Saved', '${_savedPosts.length}', Icons.bookmark),
            const SizedBox(height: 12),
            const Text(
              'By Category:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...tagCounts.entries.map(
              (entry) => _buildStatRow(
                entry.key.name.toUpperCase(),
                '${entry.value}',
                _getTagIcon(entry.key),
              ),
            ),
            if (mostRecent != null) ...[
              const SizedBox(height: 12),
              _buildStatRow(
                'Latest Save',
                TimeFormatter.formatRelativeTime(mostRecent),
                Icons.schedule,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  IconData _getTagIcon(PostTag tag) {
    switch (tag) {
      case PostTag.news:
        return Icons.newspaper;
      case PostTag.funFacts:
        return Icons.lightbulb;
      case PostTag.events:
        return Icons.event;
      case PostTag.random:
        return Icons.casino;
    }
  }

}