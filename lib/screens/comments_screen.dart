import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';
import '../services/supabase_auth_service.dart';
import '../widgets/comment_widget.dart';
import '../config/theme.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  final int? initialCommentCount; // Pass the comment count from the post

  const CommentsScreen({super.key, required this.postId, this.initialCommentCount});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  Comment? _replyingTo;
  String? _currentUserId;
  int? _displayCommentCount;

  @override
  void initState() {
    super.initState();
    _displayCommentCount = widget.initialCommentCount;
    _initializeUser();
    _loadComments();
  }

  void _initializeUser() {
    _currentUserId = SupabaseAuthService.currentUser?.id;
  }

  Future<void> _loadComments() async {
    if (!_isRefreshing) {
      setState(() => _isLoading = true);
    }
    
    try {
      final comments = await CommentService.getThreadedComments(widget.postId);
      setState(() {
        _comments = comments;
        // Update display count to actual loaded comments if no initial count provided
        if (_displayCommentCount == null) {
          _displayCommentCount = _getTotalCommentCount();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load comments: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshComments() async {
    setState(() => _isRefreshing = true);
    await _loadComments();
  }

  void _onCommentAdded(Comment comment) {
    // Update count immediately for better UX
    setState(() {
      if (_displayCommentCount != null) {
        _displayCommentCount = _displayCommentCount! + 1;
      }
    });
    // Refresh the entire comment tree to get updated structure
    _refreshComments();
  }

  void _onReply(Comment comment) {
    setState(() {
      _replyingTo = comment;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  void _onVoteChanged(Comment updatedComment) {
    // Update the comment in the list
    setState(() {
      _updateCommentInList(updatedComment);
    });
  }

  void _updateCommentInList(Comment updatedComment) {
    void updateComment(List<Comment> comments) {
      for (int i = 0; i < comments.length; i++) {
        if (comments[i].id == updatedComment.id) {
          comments[i] = updatedComment;
          return;
        }
        updateComment(comments[i].replies);
      }
    }
    updateComment(_comments);
  }

  Future<void> _onDeleteComment(String commentId) async {
    try {
      await CommentService.deleteComment(commentId);
      // Update count immediately for better UX
      setState(() {
        if (_displayCommentCount != null && _displayCommentCount! > 0) {
          _displayCommentCount = _displayCommentCount! - 1;
        }
      });
      _refreshComments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Comments'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Please log in to view comments'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Comments (${_displayCommentCount ?? 0})'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshComments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Main comment input
          CommentInput(
            postId: widget.postId,
            onCommentAdded: _onCommentAdded,
            placeholder: 'Write a comment...',
          ),
          
          // Reply input (if replying to a comment)
          if (_replyingTo != null)
            CommentInput(
              postId: widget.postId,
              parentId: _replyingTo!.id,
              onCommentAdded: (comment) {
                _onCommentAdded(comment);
                _cancelReply();
              },
              onCancel: _cancelReply,
              placeholder: 'Reply to @${_replyingTo!.username}...',
            ),
          
          const Divider(height: 1),
          
          // Comments list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      strokeWidth: 2,
                    ),
                  )
                : _comments.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: _refreshComments,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            return CommentWidget(
                              comment: _comments[index],
                              currentUserId: _currentUserId!,
                              onReply: _onReply,
                              onVoteChanged: _onVoteChanged,
                              onDelete: _onDeleteComment,
                              maxDepth: 5,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _refreshComments,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark 
                        ? Theme.of(context).colorScheme.surface.withOpacity(0.3)
                        : Colors.grey.shade100,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 40,
                    color: AppTheme.primary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Comments Yet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark 
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to share your thoughts!',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark 
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                        : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getTotalCommentCount() {
    int count = 0;
    void countComments(List<Comment> comments) {
      count += comments.length;
      for (final comment in comments) {
        countComments(comment.replies);
      }
    }
    countComments(_comments);
    return count;
  }
}
