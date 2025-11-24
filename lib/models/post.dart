import '../services/supabase_auth_service.dart';

enum PostTag { news, funFacts, events, random }

class Post {
  final String id;
  final String userId;
  final String username;
  final String? nickname;
  final String zipcode;
  final String content;
  final String? imageUrl;
  final PostTag tag;
  final List<String> contentTags;
  final Map<String, dynamic>? eventDetails;
  final DateTime createdAt;
  final int reportCount;
  final bool isActive;
  final int upvotes;
  final int downvotes;
  final bool? userVote;
  final bool isSaved;
  final bool isReported; // has current user reported this post
  final bool userHasCommented; // has current user commented on this post
  final int commentCount;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    this.nickname,
    required this.zipcode,
    required this.content,
    this.imageUrl,
    required this.tag,
    this.contentTags = const [],
    this.eventDetails,
    required this.createdAt,
    this.reportCount = 0,
    this.isActive = true,
    this.upvotes = 0,
    this.downvotes = 0,
    this.userVote,
    this.isSaved = false,
    this.isReported = false,
    this.userHasCommented = false,
    this.commentCount = 0,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? interactions = json['post_interactions'];
    bool? currentUserVote;
    bool isSavedByCurrentUser = false;
    bool isReportedByCurrentUser = false;
    bool currentUserHasCommented = false;

    if (interactions != null && interactions.isNotEmpty) {
      final userInteraction = interactions.firstWhere(
        (interaction) => interaction['user_id'] == SupabaseAuthService.currentUser?.id,
        orElse: () => null,
      );

      if (userInteraction != null) {
        if (userInteraction['vote'] == 'up') {
          currentUserVote = true;
        } else if (userInteraction['vote'] == 'down') {
          currentUserVote = false;
        } else {
          currentUserVote = null;
        }
        isSavedByCurrentUser = userInteraction['is_saved'] ?? false;
        isReportedByCurrentUser = userInteraction['is_reported'] ?? false;
        currentUserHasCommented = userInteraction['has_commented'] ?? false;
      }
    }

    // Get nickname from joined users table
    String? nickname;
    if (json['users'] != null && json['users'] is Map) {
      nickname = json['users']['nickname'];
    }

    // Parse content tags
    List<String> contentTags = [];
    if (json['content_tags'] != null) {
      if (json['content_tags'] is List) {
        contentTags = List<String>.from(json['content_tags']);
      }
    }

    // Calculate actual comment count from comments data (excluding deleted ones)
    int actualCommentCount = 0;
    if (json['comments'] != null && json['comments'] is List) {
      final comments = json['comments'] as List;
      actualCommentCount = comments.where((comment) => 
          comment['is_deleted'] == false || comment['is_deleted'] == null
      ).length;
    }

    return Post(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'],
      nickname: nickname,
      zipcode: json['zipcode'],
      content: json['content'],
      imageUrl: json['image_url'],
      tag: _stringToTag(json['tag']),
      contentTags: contentTags,
      eventDetails: json['event_details'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      reportCount: json['report_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      userVote: currentUserVote,
      isSaved: isSavedByCurrentUser,
      isReported: isReportedByCurrentUser,
      userHasCommented: currentUserHasCommented,
      commentCount: actualCommentCount,
    );
  }

  // Add copyWith method
  Post copyWith({
    String? id,
    String? userId,
    String? username,
    String? nickname,
    String? zipcode,
    String? content,
    String? imageUrl,
    PostTag? tag,
    List<String>? contentTags,
    Map<String, dynamic>? eventDetails,
    DateTime? createdAt,
    int? reportCount,
    bool? isActive,
    int? upvotes,
    int? downvotes,
    bool? userVote,
    bool? isSaved,
    bool? isReported,
    bool? userHasCommented,
    int? commentCount,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      zipcode: zipcode ?? this.zipcode,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      tag: tag ?? this.tag,
      contentTags: contentTags ?? this.contentTags,
      eventDetails: eventDetails ?? this.eventDetails,
      createdAt: createdAt ?? this.createdAt,
      reportCount: reportCount ?? this.reportCount,
      isActive: isActive ?? this.isActive,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      userVote: userVote ?? this.userVote,
      isSaved: isSaved ?? this.isSaved,
      isReported: isReported ?? this.isReported,
      userHasCommented: userHasCommented ?? this.userHasCommented,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  static PostTag _stringToTag(String tag) {
    switch (tag) {
      case 'news': return PostTag.news;
      case 'fun_facts': return PostTag.funFacts;
      case 'events': return PostTag.events;
      case 'random': return PostTag.random;
      default: return PostTag.random;
    }
  }

  String get tagString {
    switch (tag) {
      case PostTag.news: return 'news';
      case PostTag.funFacts: return 'fun_facts';
      case PostTag.events: return 'events';
      case PostTag.random: return 'random';
    }
  }

  String get tagDisplay {
    switch (tag) {
      case PostTag.news: return 'News';
      case PostTag.funFacts: return 'Fun Facts';
      case PostTag.events: return 'Events';
      case PostTag.random: return 'Random';
    }
  }
}
