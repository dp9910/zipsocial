
import '../utils/time_formatter.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String? parentId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;
  final int upvotes;
  final int downvotes;
  final int replyCount;
  final int reportCount;
  final int depth;
  final bool? userVote; // null: no vote, true: upvote, false: downvote
  final bool isReported; // has current user reported this comment
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.parentId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
    this.upvotes = 0,
    this.downvotes = 0,
    this.replyCount = 0,
    this.reportCount = 0,
    this.depth = 0,
    this.userVote,
    this.isReported = false,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    bool? currentUserVote;
    
    // Parse user vote if present
    if (json['user_vote'] != null) {
      if (json['user_vote'] == 'up') {
        currentUserVote = true;
      } else if (json['user_vote'] == 'down') {
        currentUserVote = false;
      }
    }

    // Check if current user has reported this comment
    bool isReportedByUser = false;
    if (json['user_reported'] != null) {
      isReportedByUser = json['user_reported'] == true;
    }

    return Comment(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      username: json['username'] ?? 'Anonymous',
      parentId: json['parent_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']).toLocal() 
          : null,
      isDeleted: json['is_deleted'] ?? false,
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      replyCount: json['reply_count'] ?? 0,
      reportCount: json['report_count'] ?? 0,
      depth: json['depth'] ?? 0,
      userVote: currentUserVote,
      isReported: isReportedByUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'parent_id': parentId,
      'content': content,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
      'is_deleted': isDeleted,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'reply_count': replyCount,
      'depth': depth,
    };
  }

  // Helper method to create a new comment for database insertion
  Map<String, dynamic> toInsertJson() {
    final Map<String, dynamic> insertData = {
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'depth': depth,
    };
    
    if (parentId != null) {
      insertData['parent_id'] = parentId!;
    }
    
    return insertData;
  }

  // Create a copy with updated values
  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? username,
    String? parentId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    int? upvotes,
    int? downvotes,
    int? replyCount,
    int? reportCount,
    int? depth,
    bool? userVote,
    bool? isReported,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      replyCount: replyCount ?? this.replyCount,
      reportCount: reportCount ?? this.reportCount,
      depth: depth ?? this.depth,
      userVote: userVote ?? this.userVote,
      isReported: isReported ?? this.isReported,
      replies: replies ?? this.replies,
    );
  }

  // Check if this comment is a top-level comment (not a reply)
  bool get isTopLevel => parentId == null;

  // Check if this comment has replies
  bool get hasReplies => replyCount > 0 || replies.isNotEmpty;

  // Calculate net score (upvotes - downvotes)
  int get score => upvotes - downvotes;

  // Get formatted time ago string
  String get timeAgo {
    return TimeFormatter.formatCommentTime(createdAt);
  }

  @override
  String toString() {
    return 'Comment(id: $id, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}..., depth: $depth, replies: ${replies.length})';
  }
}

// Helper class for organizing flat comment list into threaded structure
class CommentThreadBuilder {
  static List<Comment> buildThreads(List<Comment> flatComments) {
    final Map<String, Comment> commentMap = {};
    final List<Comment> topLevelComments = [];

    // First pass: Create map of all comments
    for (final comment in flatComments) {
      commentMap[comment.id] = comment;
    }

    // Second pass: Build the tree structure
    for (final comment in flatComments) {
      if (comment.parentId == null) {
        // Top-level comment
        topLevelComments.add(comment);
      } else {
        // Reply - add to parent's replies list
        final parent = commentMap[comment.parentId];
        if (parent != null) {
          // Create new parent with updated replies list
          final updatedReplies = List<Comment>.from(parent.replies)..add(comment);
          final updatedParent = parent.copyWith(replies: updatedReplies);
          commentMap[parent.id] = updatedParent;
          
          // Update in top-level list if it's a top-level comment
          if (parent.parentId == null) {
            final index = topLevelComments.indexWhere((c) => c.id == parent.id);
            if (index != -1) {
              topLevelComments[index] = updatedParent;
            }
          }
        }
      }
    }

    // Sort top-level comments by creation time (newest first)
    topLevelComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return topLevelComments;
  }
}
