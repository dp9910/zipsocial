import '../services/supabase_auth_service.dart';

enum PostTag { news, funFacts, events, random }

class Post {
  final String id;
  final String userId;
  final String username;
  final String zipcode;
  final String content;
  final PostTag tag;
  final Map<String, dynamic>? eventDetails;
  final DateTime createdAt;
  final int reportCount;
  final bool isActive;
  final int upvotes;
  final int downvotes;
  final bool? userVote;
  final bool isSaved;
  final int commentCount;

  Post({
    required this.id,
    required this.userId,
    required this.username,
    required this.zipcode,
    required this.content,
    required this.tag,
    this.eventDetails,
    required this.createdAt,
    this.reportCount = 0,
    this.isActive = true,
    this.upvotes = 0,
    this.downvotes = 0,
    this.userVote,
    this.isSaved = false,
    this.commentCount = 0,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? interactions = json['post_interactions'];
    bool? currentUserVote;
    bool isSavedByCurrentUser = false;

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
      }
    }

    return Post(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'],
      zipcode: json['zipcode'],
      content: json['content'],
      tag: _stringToTag(json['tag']),
      eventDetails: json['event_details'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      reportCount: json['report_count'] ?? 0,
      isActive: json['is_active'] ?? true,
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      userVote: currentUserVote,
      isSaved: isSavedByCurrentUser,
      commentCount: json['comment_count'] ?? 0,
    );
  }

  // Add copyWith method
  Post copyWith({
    String? id,
    String? userId,
    String? username,
    String? zipcode,
    String? content,
    PostTag? tag,
    Map<String, dynamic>? eventDetails,
    DateTime? createdAt,
    int? reportCount,
    bool? isActive,
    int? upvotes,
    int? downvotes,
    bool? userVote,
    bool? isSaved,
    int? commentCount,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      zipcode: zipcode ?? this.zipcode,
      content: content ?? this.content,
      tag: tag ?? this.tag,
      eventDetails: eventDetails ?? this.eventDetails,
      createdAt: createdAt ?? this.createdAt,
      reportCount: reportCount ?? this.reportCount,
      isActive: isActive ?? this.isActive,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      userVote: userVote ?? this.userVote,
      isSaved: isSaved ?? this.isSaved,
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
