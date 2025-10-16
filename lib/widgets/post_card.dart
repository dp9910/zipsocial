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

  const PostCard({Key? key, required this.post, this.onPostUpdated}) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool? _userVote;
  late int _upvotes;
  late int _downvotes;
  late bool _isSaved;
  late int _reportCount;

  @override
  void initState() {
    super.initState();
    _userVote = widget.post.userVote;
    _upvotes = widget.post.upvotes;
    _downvotes = widget.post.downvotes;
    _isSaved = widget.post.isSaved;
    _reportCount = widget.post.reportCount;
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post != oldWidget.post) {
      _userVote = widget.post.userVote;
      _upvotes = widget.post.upvotes;
      _downvotes = widget.post.downvotes;
      _isSaved = widget.post.isSaved;
      _reportCount = widget.post.reportCount;
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
      widget.onPostUpdated?.call(); // Invoke callback
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
    final originalReportCount = _reportCount;

    setState(() {
      _reportCount++;
    });

    try {
      await InteractionService.reportPost(widget.post.id);
      widget.onPostUpdated?.call(); // Invoke callback
    } catch (e) {
      setState(() {
        _reportCount = originalReportCount;
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
      widget.onPostUpdated?.call(); // Invoke callback
    } catch (e) {
      setState(() {
        _isSaved = originalIsSaved;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
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
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isDark ? 1.5 : 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                // User Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary,
                        AppTheme.primary.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // User info and metadata
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User name and handle
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
                        child: RichText(
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: widget.post.nickname ?? 'Anonymous',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: isDark 
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.grey.shade900,
                                ),
                              ),
                              TextSpan(
                                text: ' @${widget.post.username}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Time and location
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isDark 
                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              TimeFormatter.formatRelativeTime(widget.post.createdAt),
                              style: TextStyle(
                                color: isDark 
                                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                    : Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.post.zipcode,
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Category chip and menu
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category chip
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTagColor(widget.post.tag).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getTagColor(widget.post.tag).withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getTagIcon(widget.post.tag),
                              size: 12,
                              color: _getTagColor(widget.post.tag),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.post.tagDisplay,
                                style: TextStyle(
                                  color: _getTagColor(widget.post.tag),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Three-dot menu
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: isDark 
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                            : Colors.grey.shade600,
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
                                  Icon(Icons.delete, size: 16, color: Colors.red),
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
                                  Icon(Icons.visibility_off, size: 16, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  const Text('Hide this post'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'block_user',
                              child: Row(
                                children: [
                                  Icon(Icons.block, size: 16, color: Colors.red),
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
              ],
            ),
            const SizedBox(height: 16),
            
            // Post content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                      ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
                      : Colors.grey.shade400,
                  width: isDark ? 1 : 1.5,
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
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.3)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark 
                      ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
                      : Colors.grey.shade400,
                  width: isDark ? 1 : 1.5,
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
                      icon: Icons.chat_bubble_outline,
                      count: widget.post.commentCount,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CommentsScreen(postId: widget.post.id),
                          ),
                        );
                      },
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _ReportButton(
                      reportCount: _reportCount,
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
        return Icons.newspaper;
      case PostTag.funFacts:
        return Icons.lightbulb;
      case PostTag.events:
        return Icons.event;
      case PostTag.random:
        return Icons.casino;
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
  final VoidCallback onPressed;
  final bool isDark;

  const _ReportButton({
    required this.reportCount,
    required this.onPressed,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasReports = reportCount > 0;
    final color = hasReports ? Colors.red : (isDark 
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
            color: hasReports 
                ? Colors.red.withOpacity(0.1)
                : Colors.transparent,
            border: hasReports 
                ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasReports ? Icons.flag : Icons.flag_outlined,
                size: 20, // Slightly larger than other buttons
                color: color,
              ),
              if (hasReports) ...[
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
