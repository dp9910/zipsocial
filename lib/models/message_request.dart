enum MessageRequestStatus { pending, accepted, declined }

class MessageRequest {
  final String id;
  final String senderId;
  final String recipientId;
  final String messageContent;
  final MessageRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? senderNickname;
  final String? senderCustomUserId;

  MessageRequest({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.messageContent,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.senderNickname,
    this.senderCustomUserId,
  });

  factory MessageRequest.fromJson(Map<String, dynamic> json) {
    // Get sender info from joined users table
    String? senderNickname;
    String? senderCustomUserId;
    if (json['users'] != null && json['users'] is Map) {
      senderNickname = json['users']['nickname'];
      senderCustomUserId = json['users']['custom_user_id'];
    }

    return MessageRequest(
      id: json['id'],
      senderId: json['sender_id'],
      recipientId: json['recipient_id'],
      messageContent: json['message_content'],
      status: _stringToStatus(json['status']),
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
      senderNickname: senderNickname,
      senderCustomUserId: senderCustomUserId,
    );
  }

  static MessageRequestStatus _stringToStatus(String status) {
    switch (status) {
      case 'pending':
        return MessageRequestStatus.pending;
      case 'accepted':
        return MessageRequestStatus.accepted;
      case 'declined':
        return MessageRequestStatus.declined;
      default:
        return MessageRequestStatus.pending;
    }
  }

  String get statusString {
    switch (status) {
      case MessageRequestStatus.pending:
        return 'pending';
      case MessageRequestStatus.accepted:
        return 'accepted';
      case MessageRequestStatus.declined:
        return 'declined';
    }
  }

  String get senderDisplayName {
    return senderNickname ?? senderCustomUserId ?? 'Unknown User';
  }
}