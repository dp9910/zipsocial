class Conversation {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastMessageAt;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final List<ConversationParticipant> participants;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
    this.lastMessage,
    this.lastMessageSenderId,
    this.participants = const [],
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      lastMessage: json['last_message'] as String?,
      lastMessageSenderId: json['last_message_sender_id'] as String?,
      participants: (json['conversation_participants'] as List<dynamic>?)
          ?.map((p) => ConversationParticipant.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message_at': lastMessageAt.toIso8601String(),
      'last_message': lastMessage,
      'last_message_sender_id': lastMessageSenderId,
      'conversation_participants': participants.map((p) => p.toJson()).toList(),
      'unread_count': unreadCount,
    };
  }

  Conversation copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    String? lastMessage,
    String? lastMessageSenderId,
    List<ConversationParticipant>? participants,
    int? unreadCount,
  }) {
    return Conversation(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      participants: participants ?? this.participants,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ConversationParticipant {
  final String id;
  final String conversationId;
  final String userId;
  final DateTime joinedAt;
  final DateTime lastReadAt;
  final String? nickname;
  final String? customUserId;

  ConversationParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.joinedAt,
    required this.lastReadAt,
    this.nickname,
    this.customUserId,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      lastReadAt: DateTime.parse(json['last_read_at'] as String),
      nickname: json['nickname'] as String?,
      customUserId: json['custom_user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
      'last_read_at': lastReadAt.toIso8601String(),
      'nickname': nickname,
      'custom_user_id': customUserId,
    };
  }
}