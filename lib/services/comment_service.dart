import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment.dart';
import 'supabase_auth_service.dart';

class CommentService {
  static final _supabase = Supabase.instance.client;

  /// Get threaded comments for a post using recursive query
  static Future<List<Comment>> getThreadedComments(String postId) async {
    try {
      print('getThreadedComments: Fetching comments for post $postId');
      
      // Use the database function for recursive comment fetching
      final response = await _supabase
          .rpc('get_threaded_comments', params: {'post_uuid': postId});

      if (response == null || response.isEmpty) {
        print('getThreadedComments: No comments found');
        return [];
      }

      print('getThreadedComments: Found ${response.length} comments');
      
      // Convert to Comment objects
      final flatComments = response
          .map<Comment>((data) => Comment.fromJson(data))
          .toList();

      // Build the threaded structure
      return CommentThreadBuilder.buildThreads(flatComments);
    } catch (e) {
      print('Error fetching threaded comments: $e');
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
      print('Error fetching comments: $e');
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

      print('addComment: Creating comment with depth $depth');

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

      print('addComment: Comment created successfully');
      
      // The comment count will be automatically updated by the database trigger
      return Comment.fromJson(response);
    } catch (e) {
      print('Error adding comment: $e');
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
      print('Error fetching comment by ID: $e');
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

      print('deleteComment: Comment deleted successfully');
    } catch (e) {
      print('Error deleting comment: $e');
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

      print('updateComment: Comment updated successfully');
      return Comment.fromJson(response);
    } catch (e) {
      print('Error updating comment: $e');
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

      print('voteComment: ${isUpvote ? 'Upvoting' : 'Downvoting'} comment $commentId');

      final newVote = isUpvote ? 'up' : 'down';

      // Use a database function to handle the vote logic atomically
      await _supabase.rpc('vote_comment', params: {
        'comment_uuid': commentId,
        'user_uuid': user.id,
        'vote_type': newVote,
        'previous_vote': null, // Let the function determine current vote
      });

      print('voteComment: Vote registered successfully');
    } catch (e) {
      print('Error voting on comment: $e');
      rethrow;
    }
  }

  /// Remove vote from a comment
  static Future<void> removeVote(String commentId) async {
    try {
      final user = SupabaseAuthService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      print('removeVote: Removing vote from comment $commentId');

      // Use the same vote function with null vote type to remove vote
      await _supabase.rpc('vote_comment', params: {
        'comment_uuid': commentId,
        'user_uuid': user.id,
        'vote_type': null,
        'previous_vote': null,
      });

      print('removeVote: Vote removed successfully');
    } catch (e) {
      print('Error removing vote: $e');
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

      print('reportComment: Comment reported successfully');
    } catch (e) {
      print('Error reporting comment: $e');
      rethrow;
    }
  }
}