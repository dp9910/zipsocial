import 'package:flutter/material.dart';
import '../models/post.dart';
import '../config/theme.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image (placeholder for now)
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getTagColor(post.tag).withOpacity(0.7),
                  _getTagColor(post.tag).withOpacity(0.9),
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
                _getTagIcon(post.tag),
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with tag
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTagColor(post.tag),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        post.tagDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '@${post.username}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      ' · ${_formatTime(post.createdAt)} · ${post.zipcode}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Content
                Text(
                  post.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                
                // Event Details
                if (post.tag == PostTag.events && post.eventDetails != null) ...[
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
                        ...post.eventDetails!.entries
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
          
          // Action Bar
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
                  icon: Icons.keyboard_arrow_up,
                  count: post.upvotes,
                  isActive: post.userVote == true,
                  onPressed: () {},
                ),
                _ActionButton(
                  icon: Icons.keyboard_arrow_down,
                  count: post.downvotes,
                  isActive: post.userVote == false,
                  onPressed: () {},
                ),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  count: 0, // Comments not implemented yet
                  onPressed: () {},
                ),
                _ActionButton(
                  icon: post.isSaved ? Icons.flag : Icons.flag_outlined,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
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

  const _ActionButton({
    required this.icon,
    this.count,
    this.isActive = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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
              color: isActive 
                ? AppTheme.primary 
                : Theme.of(context).colorScheme.secondary,
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive 
                    ? AppTheme.primary 
                    : Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}