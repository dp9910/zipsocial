import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../config/theme.dart';
import '../screens/user_profile_screen.dart';
import '../services/comment_service.dart';

class CommentWidget extends StatefulWidget {
  final Comment comment;
  final Function(Comment)? onReply;
  final Function(Comment)? onVoteChanged;
  final Function(String)? onDelete;
  final int maxDepth;
  final String currentUserId;

  const CommentWidget({
    Key? key,
    required this.comment,
    this.onReply,
    this.onVoteChanged,
    this.onDelete,
    this.maxDepth = 5,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  late bool? _userVote;
  late int _upvotes;
  late int _downvotes;
  late int _reportCount;
  late bool _isReported;
  bool _showReplies = false;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _userVote = widget.comment.userVote;
    _upvotes = widget.comment.upvotes;
    _downvotes = widget.comment.downvotes;
    _reportCount = widget.comment.reportCount;
    _isReported = widget.comment.isReported;
    _showReplies = widget.comment.depth < 2; // Auto-expand first 2 levels
  }

  @override
  void didUpdateWidget(covariant CommentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.comment != oldWidget.comment) {
      _userVote = widget.comment.userVote;
      _upvotes = widget.comment.upvotes;
      _downvotes = widget.comment.downvotes;
      _reportCount = widget.comment.reportCount;
      _isReported = widget.comment.isReported;
    }
  }

  Future<void> _onVote(bool isUpvote) async {
    if (_isVoting) return;
    
    // Prevent clicking the same vote type (no toggle off)
    if (_userVote == isUpvote) {
      // Already voted this way, do nothing
      return;
    }
    
    final originalVote = _userVote;
    final originalUpvotes = _upvotes;
    final originalDownvotes = _downvotes;

    // Optimistic UI update
    setState(() {
      _isVoting = true;
      
      // Handle vote change logic
      if (_userVote == true) {
        // Was upvoted, now downvoting
        _upvotes--;
        _downvotes++;
      } else if (_userVote == false) {
        // Was downvoted, now upvoting
        _downvotes--;
        _upvotes++;
      } else {
        // No previous vote, new vote
        if (isUpvote) {
          _upvotes++;
        } else {
          _downvotes++;
        }
      }
      _userVote = isUpvote;
    });

    try {
      // The database function handles all the logic
      await CommentInteractionService.voteComment(widget.comment.id, isUpvote);
      
      // Notify parent of vote change
      final updatedComment = widget.comment.copyWith(
        userVote: _userVote,
        upvotes: _upvotes,
        downvotes: _downvotes,
      );
      widget.onVoteChanged?.call(updatedComment);
    } catch (e) {
      // Revert on error
      setState(() {
        _userVote = originalVote;
        _upvotes = originalUpvotes;
        _downvotes = originalDownvotes;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to vote: $e')),
        );
      }
    } finally {
      setState(() {
        _isVoting = false;
      });
    }
  }

  void _toggleReplies() {
    setState(() {
      _showReplies = !_showReplies;
    });
  }

  Color get _indentColor {
    final colors = [
      AppTheme.primary.withOpacity(0.3),
      Colors.blue.withOpacity(0.3),
      Colors.purple.withOpacity(0.3),
      Colors.orange.withOpacity(0.3),
      Colors.green.withOpacity(0.3),
    ];
    return colors[widget.comment.depth.clamp(0, colors.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.comment.userId == widget.currentUserId;
    final canReply = widget.comment.depth < widget.maxDepth;
    final hasReplies = widget.comment.hasReplies;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.only(
        left: widget.comment.depth * 16.0,
        top: 8.0,
        bottom: 4.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main comment container
          Container(
            decoration: BoxDecoration(
              color: widget.comment.depth > 0 
                  ? (isDark 
                      ? Theme.of(context).colorScheme.surface.withOpacity(0.3)
                      : Colors.grey.shade800)
                  : (isDark 
                      ? Theme.of(context).colorScheme.surface.withOpacity(0.7)
                      : Colors.grey.shade900),
              borderRadius: BorderRadius.circular(12),
              border: widget.comment.depth > 0 
                  ? Border.all(color: _indentColor, width: 2)
                  : (isDark 
                      ? Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3))
                      : null),
              boxShadow: isDark 
                ? null 
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: User info and timestamp
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(
                                userId: widget.comment.userId,
                                customUserId: widget.comment.username,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, 
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '@${widget.comment.username}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.comment.timeAgo,
                        style: TextStyle(
                          color: isDark 
                            ? Theme.of(context).colorScheme.secondary
                            : Colors.grey.shade300,
                          fontSize: 12,
                        ),
                      ),
                      if (widget.comment.depth > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6, 
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _indentColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Reply',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (isOwner)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_horiz,
                            size: 18,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _showDeleteDialog();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 16),
                                  SizedBox(width: 8),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Comment content
                  Text(
                    widget.comment.content,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark 
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Action buttons
                  Row(
                    children: [
                      // Upvote button (Heart)
                      _CommentActionButton(
                        icon: _userVote == true 
                            ? Icons.favorite 
                            : Icons.favorite_border,
                        count: _upvotes,
                        isActive: _userVote == true,
                        activeColor: Colors.red,
                        onPressed: _isVoting ? null : () => _onVote(true),
                        size: 18,
                      ),
                      const SizedBox(width: 16),
                      
                      // Downvote button (Thumbs down)
                      _CommentActionButton(
                        icon: _userVote == false 
                            ? Icons.thumb_down 
                            : Icons.thumb_down_outlined,
                        count: _downvotes,
                        isActive: _userVote == false,
                        activeColor: Colors.orange,
                        onPressed: _isVoting ? null : () => _onVote(false),
                        size: 18,
                      ),
                      const SizedBox(width: 16),
                      
                      // Reply button
                      if (canReply)
                        _CommentActionButton(
                          icon: Icons.reply,
                          onPressed: () => widget.onReply?.call(widget.comment),
                          size: 16,
                        ),
                      
                      const SizedBox(width: 16),
                      
                      // Report button
                      _CommentActionButton(
                        icon: _isReported ? Icons.flag : Icons.flag_outlined,
                        count: _reportCount > 0 ? _reportCount : null,
                        isActive: _isReported,
                        activeColor: Colors.red,
                        onPressed: () => _showReportDialog(),
                        size: 16,
                      ),
                      
                      const Spacer(),
                      
                      // Toggle replies button
                      if (hasReplies)
                        _CommentActionButton(
                          icon: _showReplies 
                              ? Icons.expand_less 
                              : Icons.expand_more,
                          count: widget.comment.replyCount,
                          onPressed: _toggleReplies,
                          size: 18,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Replies
          if (_showReplies && widget.comment.replies.isNotEmpty)
            ...widget.comment.replies.map(
              (reply) => CommentWidget(
                comment: reply,
                onReply: widget.onReply,
                onVoteChanged: widget.onVoteChanged,
                onDelete: widget.onDelete,
                maxDepth: widget.maxDepth,
                currentUserId: widget.currentUserId,
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop();
              widget.onDelete?.call(widget.comment.id);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    if (_isReported) {
      // Already reported, show message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already reported this comment')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Comment'),
        content: const Text('This comment will be reported for review. Do you want to continue?'),
        actions: [
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              FocusScope.of(context).unfocus();
              Navigator.of(context).pop();
              
              // Optimistic update
              setState(() {
                _isReported = true;
                _reportCount++;
              });

              try {
                await CommentInteractionService.reportComment(widget.comment.id);
                
                // Notify parent of change
                final updatedComment = widget.comment.copyWith(
                  isReported: _isReported,
                  reportCount: _reportCount,
                );
                widget.onVoteChanged?.call(updatedComment);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comment reported successfully')),
                  );
                }
              } catch (e) {
                // Revert on error
                setState(() {
                  _isReported = false;
                  _reportCount--;
                });
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to report comment: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Report',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentActionButton extends StatelessWidget {
  final IconData icon;
  final int? count;
  final bool isActive;
  final VoidCallback? onPressed;
  final Color? activeColor;
  final double size;

  const _CommentActionButton({
    required this.icon,
    this.count,
    this.isActive = false,
    this.onPressed,
    this.activeColor,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive 
        ? (activeColor ?? AppTheme.primary) 
        : (isDark 
            ? Theme.of(context).colorScheme.secondary.withOpacity(0.7)
            : Colors.grey.shade400);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: size,
              color: color,
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Comment input widget for replies
class CommentInput extends StatefulWidget {
  final String? parentId;
  final String postId;
  final Function(Comment)? onCommentAdded;
  final VoidCallback? onCancel;
  final String? placeholder;

  const CommentInput({
    Key? key,
    this.parentId,
    required this.postId,
    this.onCommentAdded,
    this.onCancel,
    this.placeholder,
  }) : super(key: key);

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus for replies
    if (widget.parentId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final comment = await CommentService.addComment(
        postId: widget.postId,
        content: content,
        parentId: widget.parentId,
      );
      
      _controller.clear();
      widget.onCommentAdded?.call(comment);
      
      if (widget.parentId != null) {
        // Cancel reply mode after successful submission
        widget.onCancel?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: widget.parentId != null ? 16.0 : 0,
        top: 8.0,
        bottom: 8.0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.parentId != null 
            ? AppTheme.primary.withOpacity(0.05)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.parentId != null 
              ? AppTheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          if (widget.parentId != null)
            Row(
              children: [
                Icon(
                  Icons.reply,
                  size: 16,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Replying to comment',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: 3,
            minLines: 1,
            enabled: !_isSubmitting,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: widget.placeholder ?? 'Write a comment...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) => _submitComment(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSubmitting ? null : _submitComment,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}