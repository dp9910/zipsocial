enum MessageType {
  text,
  image,
  file;

  String get value {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.file:
        return 'file';
    }
  }

  static MessageType fromString(String value) {
    switch (value) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType messageType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;
  final bool isDeleted;
  final String? senderNickname;
  final String? senderCustomUserId;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.createdAt,
    required this.updatedAt,
    required this.isEdited,
    required this.isDeleted,
    this.senderNickname,
    this.senderCustomUserId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      messageType: MessageType.fromString(json['message_type'] as String? ?? 'text'),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isEdited: json['is_edited'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      senderNickname: json['sender_nickname'] as String?,
      senderCustomUserId: json['sender_custom_user_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_edited': isEdited,
      'is_deleted': isDeleted,
      'sender_nickname': senderNickname,
      'sender_custom_user_id': senderCustomUserId,
    };
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    MessageType? messageType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEdited,
    bool? isDeleted,
    String? senderNickname,
    String? senderCustomUserId,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      senderNickname: senderNickname ?? this.senderNickname,
      senderCustomUserId: senderCustomUserId ?? this.senderCustomUserId,
    );
  }

  bool get isMine => senderId == _currentUserId;
  
  static String? _currentUserId;
  
  static void setCurrentUserId(String? userId) {
    _currentUserId = userId;
  }
}