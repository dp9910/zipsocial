import 'package:flutter/material.dart';
import '../models/post.dart';
import '../config/theme.dart';
import '../screens/user_profile_screen.dart';
import '../screens/comments_screen.dart';
import '../services/interaction_service.dart';
import '../services/moderation_service.dart';
import '../services/supabase_auth_service.dart';
import '../utils/time_formatter.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onPostUpdated; // Reintroducing this field
  final bool refreshOnSave; // Whether to refresh parent when post is saved/unsaved

  const PostCard({Key? key, required this.post, this.onPostUpdated, this.refreshOnSave = false}) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool? _userVote;
  late int _upvotes;
  late int _downvotes;
  late bool _isSaved;
  late bool _isReported;
  late int _reportCount;
  late bool _userHasCommented;

  @override
  void initState() {
    super.initState();
    _userVote = widget.post.userVote;
    _upvotes = widget.post.upvotes;
    _downvotes = widget.post.downvotes;
    _isSaved = widget.post.isSaved;
    _isReported = widget.post.isReported;
    _reportCount = widget.post.reportCount;
    _userHasCommented = widget.post.userHasCommented;
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post != oldWidget.post) {
      _userVote = widget.post.userVote;
      _upvotes = widget.post.upvotes;
      _downvotes = widget.post.downvotes;
      _isSaved = widget.post.isSaved;
      _isReported = widget.post.isReported;
      _reportCount = widget.post.reportCount;
      _userHasCommented = widget.post.userHasCommented;
    }
  }

  Future<void> _onVote(bool isUpvote) async {
    final originalVote = _userVote;
    final originalUpvotes = _upvotes;
    final originalDownvotes = _downvotes;

    setState(() {
      if (_userVote == isUpvote) {
        _userVote = null;
        isUpvote ? _upvotes-- : _downvotes--;
      } else {
        if (_userVote != null) { // Changing vote
          isUpvote ? _downvotes-- : _upvotes--;
        }
        isUpvote ? _upvotes++ : _downvotes++;
        _userVote = isUpvote;
      }
    });

    try {
      await InteractionService.toggleVote(widget.post.id, _userVote);
      // No need to refresh feed for vote changes
    } catch (e) {
      setState(() {
        _userVote = originalVote;
        _upvotes = originalUpvotes;
        _downvotes = originalDownvotes;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _onReport() async {
    // If user has already reported this post, ignore the click silently
    if (_isReported) {
      return;
    }

    final originalReportCount = _reportCount;

    setState(() {
      _reportCount++;
      _isReported = true;
    });

    try {
      await InteractionService.reportPost(widget.post.id);
      // No need to refresh feed for report actions
    } catch (e) {
      setState(() {
        _reportCount = originalReportCount;
        _isReported = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _onSave() async {
    final originalIsSaved = _isSaved;

    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      await InteractionService.savePost(widget.post.id, _isSaved);
      // Only refresh if explicitly requested (e.g., from saved posts screen)
      if (widget.refreshOnSave) {
        widget.onPostUpdated?.call();
      }
    } catch (e) {
      setState(() {
        _isSaved = originalIsSaved;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _onCommentsUpdated() async {
    // When the user returns from comments screen, refresh the post data
    // to get updated comment count and user comment status
    widget.onPostUpdated?.call();
  }

  Future<void> _handleMenuAction(String action) async {
    try {
      switch (action) {
        case 'hide_post':
          await ModerationService.hidePost(widget.post.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post hidden from your feed')),
            );
            widget.onPostUpdated?.call();
          }
          break;
        case 'block_user':
          await _showBlockUserDialog();
          break;
        case 'delete_post':
          await _showDeletePostDialog();
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _showBlockUserDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block @${widget.post.username}? You will no longer see their posts and they cannot follow you.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ModerationService.blockUser(widget.post.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Blocked @${widget.post.username}')),
          );
          widget.onPostUpdated?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to block user: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDeletePostDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ModerationService.deletePost(widget.post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
          widget.onPostUpdated?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete post: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark 
        ? Theme.of(context).colorScheme.surface
        : Colors.white;
    final borderColor = isDark 
        ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
        : Colors.grey.shade900;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
              : Colors.grey.shade300,
          width: isDark ? 1 : 1.5,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and metadata
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Avatar with "You" indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(
                              userId: widget.post.userId,
                              customUserId: widget.post.username,
                            ),
                          ),
                        );
                      },
                      child: _buildUserAvatar(),
                    ),
                    // "You" indicator badge
                    if (widget.post.userId == SupabaseAuthService.currentUser?.id)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark 
                                  ? Theme.of(context).colorScheme.surface
                                  : Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? Colors.black : Colors.grey.shade600)
                                    .withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            'YOU',
                            style: TextStyle(
                              color: isDark ? Colors.black : Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                
                // User info - cleaner hierarchy
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display name (larger, primary)
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(
                                userId: widget.post.userId,
                                customUserId: widget.post.username,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          widget.post.nickname ?? 'Anonymous',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: isDark 
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.grey.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      
                      // Username (smaller, secondary)
                      Text(
                        '@${widget.post.username}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: isDark 
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                              : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Metadata row (time • location • category)
                      Row(
                        children: [
                          // Time
                          Text(
                            TimeFormatter.formatRelativeTime(widget.post.createdAt),
                            style: TextStyle(
                              color: isDark 
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                                  : Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          // Dot separator
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark 
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                                  : Colors.grey.shade500,
                            ),
                          ),
                          
                          // Location
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.post.zipcode,
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          
                          // Dot separator
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark 
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                                  : Colors.grey.shade500,
                            ),
                          ),
                          
                          // Category (compact)
                          Flexible(
                            child: _buildCompactCategoryTag(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Menu button (separated from content)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz,
                    size: 20,
                    color: isDark 
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                        : Colors.grey.shade500,
                  ),
                  onSelected: (value) => _handleMenuAction(value),
                  itemBuilder: (context) {
                    final currentUser = SupabaseAuthService.currentUser;
                    final isOwnPost = currentUser?.id == widget.post.userId;
                    
                    return [
                      if (isOwnPost)
                        PopupMenuItem(
                          value: 'delete_post',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              const Text('Delete post'),
                            ],
                          ),
                        ),
                      if (!isOwnPost) ...[
                        PopupMenuItem(
                          value: 'hide_post',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_off_outlined, size: 16, color: Colors.orange),
                              const SizedBox(width: 8),
                              const Text('Hide this post'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block_user',
                          child: Row(
                            children: [
                              Icon(Icons.block_outlined, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              const Text('Block user'),
                            ],
                          ),
                        ),
                      ],
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Post content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.3)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark 
                      ? Theme.of(context).colorScheme.outline.withOpacity(0.15)
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Text(
                widget.post.content,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                  color: isDark 
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.grey.shade800,
                ),
              ),
            ),
            
            // Post image
            if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Theme.of(context).colorScheme.surface.withOpacity(0.3)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / 
                                loadingProgress.expectedTotalBytes!
                              : null,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Theme.of(context).colorScheme.surface.withOpacity(0.3)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
                if (widget.post.tag == PostTag.events && widget.post.eventDetails != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Event Details:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ...widget.post.eventDetails!.entries
                            .where((e) => e.value?.toString().isNotEmpty == true)
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '${_capitalize(e.key)}: ${e.value}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                )),
                      ],
                    ),
                  ),
                ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              decoration: BoxDecoration(
                color: isDark 
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.2)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark 
                      ? Theme.of(context).colorScheme.outline.withOpacity(0.15)
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: _userVote == true ? Icons.favorite : Icons.favorite_border,
                      count: _upvotes,
                      isActive: _userVote == true,
                      activeColor: Colors.red,
                      onPressed: () => _onVote(true),
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _ActionButton(
                      icon: _userVote == false ? Icons.thumb_down : Icons.thumb_down_outlined,
                      count: _downvotes,
                      isActive: _userVote == false,
                      activeColor: Colors.amber,
                      onPressed: () => _onVote(false),
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _ActionButton(
                      icon: _userHasCommented 
                          ? Icons.chat_bubble 
                          : Icons.chat_bubble_outline,
                      count: widget.post.commentCount,
                      isActive: _userHasCommented,
                      activeColor: AppTheme.primary,
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CommentsScreen(
                              postId: widget.post.id,
                              initialCommentCount: widget.post.commentCount,
                            ),
                          ),
                        );
                        // Refresh post data when returning from comments
                        _onCommentsUpdated();
                      },
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _ReportButton(
                      reportCount: _reportCount,
                      isReported: _isReported,
                      onPressed: _onReport,
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _ActionButton(
                      icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                      isActive: _isSaved,
                      activeColor: AppTheme.primary,
                      onPressed: _onSave,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Build improved user avatar with better visual design
  Widget _buildUserAvatar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark 
            ? Theme.of(context).colorScheme.surface.withOpacity(0.8)
            : Colors.grey.shade100,
        border: Border.all(
          color: isDark 
              ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
              : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.person_outline,
        color: isDark 
            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
            : Colors.grey.shade600,
        size: 20,
      ),
    );
  }

  // Build compact category tag for metadata row
  Widget _buildCompactCategoryTag() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getTagIcon(widget.post.tag),
          size: 10,
          color: _getTagColor(widget.post.tag),
        ),
        const SizedBox(width: 3),
        Text(
          widget.post.tagDisplay,
          style: TextStyle(
            color: _getTagColor(widget.post.tag),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getTagColor(PostTag tag) {
    switch (tag) {
      case PostTag.news:
        return Colors.red.shade600;
      case PostTag.funFacts:
        return Colors.purple.shade600;
      case PostTag.events:
        return Colors.green.shade600;
      case PostTag.random:
        return Colors.blue.shade600;
    }
  }

  IconData _getTagIcon(PostTag tag) {
    switch (tag) {
      case PostTag.news:
        return Icons.article_outlined;
      case PostTag.funFacts:
        return Icons.lightbulb_outline;
      case PostTag.events:
        return Icons.event_outlined;
      case PostTag.random:
        return Icons.shuffle;
    }
  }

  String _capitalize(String text) {
    return text.split('_').map((word) => 
        word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }
}

// Prominent report button component
class _ReportButton extends StatelessWidget {
  final int reportCount;
  final bool isReported;
  final VoidCallback onPressed;
  final bool isDark;

  const _ReportButton({
    required this.reportCount,
    required this.isReported,
    required this.onPressed,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasReports = reportCount > 0;
    final color = isReported || hasReports ? Colors.red : (isDark 
        ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
        : Colors.grey.shade600);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isReported || hasReports 
                ? Colors.red.withOpacity(0.1)
                : Colors.transparent,
            border: isReported || hasReports 
                ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isReported || hasReports ? Icons.flag : Icons.flag_outlined,
                size: 20, // Slightly larger than other buttons
                color: color,
              ),
              if (isReported || hasReports) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$reportCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int? count;
  final bool isActive;
  final VoidCallback onPressed;
  final Color? activeColor;
  final bool isDark;

  const _ActionButton({
    required this.icon,
    this.count,
    this.isActive = false,
    required this.onPressed,
    this.activeColor,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive 
        ? (activeColor ?? AppTheme.primary) 
        : (isDark 
            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
            : Colors.grey.shade600);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isActive 
                ? (activeColor ?? AppTheme.primary).withOpacity(0.1)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              if (count != null && count! > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
