import 'package:flutter/material.dart';
import '../models/post.dart';
import '../config/theme.dart';
import '../screens/user_profile_screen.dart';
import '../screens/comments_screen.dart';
import '../services/interaction_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getTagColor(widget.post.tag).withOpacity(0.7),
                  _getTagColor(widget.post.tag).withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Icon(
                _getTagIcon(widget.post.tag),
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTagColor(widget.post.tag),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.post.tagDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '@${widget.post.username}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8CE830),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      ' · ${TimeFormatter.formatRelativeTime(widget.post.createdAt)} · ${widget.post.zipcode}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.post.content,
                  style: Theme.of(context).textTheme.bodyMedium,
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
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.primary.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ActionButton(
                  icon: _userVote == true ? Icons.favorite : Icons.favorite_border,
                  count: _upvotes,
                  isActive: _userVote == true,
                  activeColor: Colors.red,
                  onPressed: () => _onVote(true),
                ),
                _ActionButton(
                  icon: _userVote == false ? Icons.thumb_down : Icons.thumb_down_outlined,
                  count: _downvotes,
                  isActive: _userVote == false,
                  activeColor: Colors.amber,
                  onPressed: () => _onVote(false),
                ),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: widget.post.commentCount,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CommentsScreen(postId: widget.post.id),
                      ),
                    );
                  },
                ),
                _ActionButton(
                  icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  isActive: _isSaved,
                  activeColor: Colors.blue,
                  onPressed: _onSave,
                ),
              ],
            ),
          ),
        ],
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int? count;
  final bool isActive;
  final VoidCallback onPressed;
  final Color? activeColor;

  const _ActionButton({
    required this.icon,
    this.count,
    this.isActive = false,
    required this.onPressed,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive 
      ? (activeColor ?? AppTheme.primary) 
      : Theme.of(context).colorScheme.secondary;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
