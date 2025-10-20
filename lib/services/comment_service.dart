import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment.dart';
import 'supabase_auth_service.dart';
import 'content_filter_service.dart';
import '../services/notification_service.dart';

class CommentService {
  static final _supabase = Supabase.instance.client;

  /// Get threaded comments for a post using recursive query
  static Future<List<Comment>> getThreadedComments(String postId) async {
    try {
      
      // Use the database function for recursive comment fetching
      final response = await _supabase
          .rpc('get_threaded_comments', params: {'post_uuid': postId});

      if (response == null || response.isEmpty) {
        return [];
      }

      
      // Convert to Comment objects
      final flatComments = response
          .map<Comment>((data) => Comment.fromJson(data))
          .toList();

      // Build the threaded structure
      return CommentThreadBuilder.buildThreads(flatComments);
    } catch (e) {
      return [];
    }
  }

  /// Get flat list of comments (for simple displays)
  static Future<List<Comment>> getComments(String postId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('''
            *,
            comment_interactions!left(user_id, vote)
          ''')
          .eq('post_id', postId)
          .eq('is_deleted', false)
          .order('created_at', ascending: true);

      if (response.isEmpty) {
        return [];
      }

      return response.map((data) => Comment.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Add a new comment or reply
  static Future<Comment> addComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    try {
      final user = SupabaseAuthService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userProfile = await SupabaseAuthService.getUserProfile();
      if (userProfile == null) throw Exception('User profile not found');

      // Check if user is spamming
      final isSpamming = await ContentFilterService.isUserSpamming(user.id);
      if (isSpamming) {
        throw Exception('Please wait before commenting again. Your account has been flagged for potential spam.');
      }

      // Filter content before posting
      final filterResult = ContentFilterService.filterContent(content, 'comment');
      
      // Reject content if it's too inappropriate
      if (filterResult.action == FilterAction.rejected) {
        throw Exception(filterResult.message ?? 'Comment cannot be posted due to inappropriate language.');
      }

      // Calculate depth for replies
      int depth = 0;
      if (parentId != null) {
        final parentComment = await _getCommentById(parentId);
        if (parentComment != null) {
          depth = parentComment.depth + 1;
          // Limit maximum depth to prevent excessive nesting
          if (depth > 10) {
            throw Exception('Maximum comment depth reached');
          }
        }
      }


      final response = await _supabase
          .from('comments')
          .insert({
            'post_id': postId,
            'user_id': user.id,
            'parent_id': parentId,
            'content': content,
            'depth': depth,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('''
            *,
            comment_interactions!left(user_id, vote)
          ''')
          .single();

      final commentId = response['id'];

      // Log content filtering result
      await ContentFilterService.logFilterResult(
        contentType: 'comment',
        contentId: commentId,
        userId: user.id,
        result: filterResult,
      );

      // The comment count will be automatically updated by the database trigger
      final comment = Comment.fromJson(response);

      // Send notification to post owner about new comment
      try {
        // Get post details
        final post = await _supabase
            .from('posts')
            .select('user_id, content')
            .eq('id', postId)
            .single();

        final notificationService = NotificationService(_supabase);
        await notificationService.notifyPostCommented(
          postId,
          post['user_id'],
          post['content'],
          content,
        );
      } catch (e) {
        print('Failed to send comment notification: $e');
      }

      // If content was flagged but not rejected, inform the user
      if (filterResult.action == FilterAction.flagged) {
        throw Exception('Comment posted but flagged for review: ${filterResult.message}');
      } else if (filterResult.action == FilterAction.autoHidden) {
        throw Exception('Comment posted but hidden due to inappropriate content. It will be reviewed by moderators.');
      }

      return comment;
    } catch (e) {
      rethrow;
    }
  }

  /// Helper method to get a comment by ID
  static Future<Comment?> _getCommentById(String commentId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select()
          .eq('id', commentId)
          .eq('is_deleted', false)
          .maybeSingle();

      if (response == null) return null;

      return Comment.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Delete a comment (soft delete)
  static Future<void> deleteComment(String commentId) async {
    try {
      final user = SupabaseAuthService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user owns the comment
      final comment = await _getCommentById(commentId);
      if (comment == null) throw Exception('Comment not found');
      if (comment.userId != user.id) throw Exception('Not authorized to delete this comment');

      await _supabase
          .from('comments')
          .update({'is_deleted': true, 'content': '[deleted]'})
          .eq('id', commentId);

    } catch (e) {
      rethrow;
    }
  }

  /// Update a comment
  static Future<Comment> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      final user = SupabaseAuthService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user owns the comment
      final existingComment = await _getCommentById(commentId);
      if (existingComment == null) throw Exception('Comment not found');
      if (existingComment.userId != user.id) throw Exception('Not authorized to edit this comment');

      final response = await _supabase
          .from('comments')
          .update({
            'content': content,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', commentId)
          .select('''
            *,
            comment_interactions!left(user_id, vote)
          ''')
          .single();

      return Comment.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}

/// Service for handling comment interactions (votes)
class CommentInteractionService {
  static final _supabase = Supabase.instance.client;

  /// Vote on a comment (upvote/downvote)
  static Future<void> voteComment(String commentId, bool isUpvote) async {
    try {
      final user = SupabaseAuthService.currentUser;
      if (user == null) throw Exception('User not authenticated');


      final newVote = isUpvote ? 'up' : 'down';

      // Use a database function to handle the vote logic atomically
      await _supabase.rpc('vote_comment', params: {
        'comment_uuid': commentId,
        'user_uuid': user.id,
        'vote_type': newVote,
        'previous_vote': null, // Let the function determine current vote
      });

    } catch (e) {
      rethrow;
    }
  }

  /// Remove vote from a comment
  static Future<void> removeVote(String commentId) async {
    try {
      final user = SupabaseAuthService.currentUser;
      if (user == null) throw Exception('User not authenticated');


      // Use the same vote function with null vote type to remove vote
      await _supabase.rpc('vote_comment', params: {
        'comment_uuid': commentId,
        'user_uuid': user.id,
        'vote_type': null,
        'previous_vote': null,
      });

    } catch (e) {
      rethrow;
    }
  }

  /// Report a comment
  static Future<void> reportComment(String commentId) async {
    try {
      final user = SupabaseAuthService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.rpc('report_comment', params: {
        'comment_uuid': commentId,
        'user_uuid': user.id,
      });

    } catch (e) {
      rethrow;
    }
  }
}