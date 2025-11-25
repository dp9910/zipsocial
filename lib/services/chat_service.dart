import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/message_request.dart';
import '../models/user.dart';
import 'supabase_auth_service.dart';
import 'moderation_service.dart';
import '../services/notification_service.dart';

class ChatService {
  static final _client = Supabase.instance.client;

  // Get all conversations for the current user
  static Future<List<Conversation>> getConversations() async {
    try {
      final currentUser = SupabaseAuthService.currentUser;
      if (currentUser == null) return [];

      final response = await _client
          .from('conversations')
          .select('''
            *,
            conversation_participants!inner(
              *,
              users!conversation_participants_user_id_fkey(
                id,
                nickname,
                custom_user_id
              )
            )
          ''')
          .order('last_message_at', ascending: false);

      // Filter conversations where current user is a participant
      final userConversations = response.where((conv) {
        final participants = conv['conversation_participants'] as List;
        return participants.any((p) => p['user_id'] == currentUser.id);
      }).toList();

      List<Conversation> conversations = [];
      for (var convData in userConversations) {
        try {
          // Calculate unread count
          final unreadCount = await _getUnreadMessageCount(
            convData['id'] as String,
            currentUser.id,
          );

          // Process participants with user data
          final participantsData = convData['conversation_participants'] as List;
          final participants = participantsData.map((p) {
            final userData = p['users'] as Map<String, dynamic>?;
            return ConversationParticipant(
              id: p['id'] as String,
              conversationId: p['conversation_id'] as String,
              userId: p['user_id'] as String,
              joinedAt: DateTime.parse(p['joined_at'] as String),
              lastReadAt: DateTime.parse(p['last_read_at'] as String),
              nickname: userData?['nickname'] as String?,
              customUserId: userData?['custom_user_id'] as String?,
            );
          }).toList();

          // Check if current user and other participant still follow each other
          final otherParticipant = participants.firstWhere(
            (p) => p.userId != currentUser.id,
            orElse: () => participants.first,
          );
          
          final hasPermission = await _hasMessagingPermission(
            currentUser.id,
            otherParticipant.userId,
          );
          
          // Only include conversations where both users still follow each other
          if (hasPermission) {
            final conversation = Conversation(
              id: convData['id'] as String,
              createdAt: DateTime.parse(convData['created_at'] as String),
              updatedAt: DateTime.parse(convData['updated_at'] as String),
              lastMessageAt: DateTime.parse(convData['last_message_at'] as String),
              lastMessage: convData['last_message'] as String?,
              lastMessageSenderId: convData['last_message_sender_id'] as String?,
              participants: participants,
              unreadCount: unreadCount,
            );
            conversations.add(conversation);
          }
        } catch (e) {
        }
      }

      return conversations;
    } catch (e) {
      return [];
    }
  }

  // Get or create a conversation between two users
  static Future<String?> getOrCreateConversation(String otherUserId) async {
    try {
      final currentUser = SupabaseAuthService.currentUser;
      if (currentUser == null) return null;

      // Check if users are blocked from messaging each other
      final isBlocked = await ModerationService.areUsersBlockedFromMessaging(
        currentUser.id, 
        otherUserId
      );
      
      if (isBlocked) {
        throw Exception('Unable to start conversation. One of the users has blocked the other.');
      }

      // Check if current user follows the other user (required to send message request)
      final isFollowing = await SupabaseAuthService.isFollowing(currentUser.id, otherUserId);
      
      if (!isFollowing) {
        throw Exception('You need to follow this user to start a conversation.');
      }

      // Check if there's an accepted message request or existing conversation
      final hasPermission = await _hasMessagingPermission(currentUser.id, otherUserId);
      if (!hasPermission) {
        throw Exception('Send a message request first.');
      }

      final response = await _client.rpc('get_or_create_conversation', params: {
        'user1_id': currentUser.id,
        'user2_id': otherUserId,
      });

      return response as String?;
    } catch (e) {
      return null;
    }
  }

  // Get messages for a conversation
  static Future<List<Message>> getMessages(String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select('''
            *,
            users!messages_sender_id_fkey(
              nickname,
              custom_user_id
            )
          ''')
          .eq('conversation_id', conversationId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((messageData) {
        final userData = messageData['users'] as Map<String, dynamic>?;
        return Message(
          id: messageData['id'] as String,
          conversationId: messageData['conversation_id'] as String,
          senderId: messageData['sender_id'] as String,
          content: messageData['content'] as String,
          messageType: MessageType.fromString(messageData['message_type'] as String? ?? 'text'),
          createdAt: DateTime.parse(messageData['created_at'] as String),
          updatedAt: DateTime.parse(messageData['updated_at'] as String),
          isEdited: messageData['is_edited'] as bool? ?? false,
          isDeleted: messageData['is_deleted'] as bool? ?? false,
          senderNickname: userData?['nickname'] as String?,
          senderCustomUserId: userData?['custom_user_id'] as String?,
        );
      }).toList().reversed.toList(); // Reverse to show oldest first
    } catch (e) {
      return [];
    }
  }

  // Send a message
  static Future<Message?> sendMessage({
    required String conversationId,
    required String content,
    MessageType messageType = MessageType.text,
    String? otherUserId,
  }) async {
    try {
      final currentUser = SupabaseAuthService.currentUser;
      if (currentUser == null) return null;

      // If otherUserId is provided, check if users are blocked and follow each other
      if (otherUserId != null) {
        final isBlocked = await ModerationService.areUsersBlockedFromMessaging(
          currentUser.id, 
          otherUserId
        );
        
        if (isBlocked) {
          throw Exception('Cannot send message. One of the users has blocked the other.');
        }

        // Check messaging permission (accepted message request or existing conversation)
        final hasPermission = await _hasMessagingPermission(currentUser.id, otherUserId);
        if (!hasPermission) {
          throw Exception('Message request not accepted yet.');
        }
      }

      final response = await _client
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': currentUser.id,
            'content': content,
            'message_type': messageType.value,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('''
            *,
            users!messages_sender_id_fkey(
              nickname,
              custom_user_id
            )
          ''')
          .single();

      final userData = response['users'] as Map<String, dynamic>?;
      
      // Send notification if otherUserId is provided
      if (otherUserId != null) {
        try {
          final notificationService = NotificationService(_client);
          await notificationService.notifyMessageSent(otherUserId, content);
        } catch (e) {
          print('Failed to send message notification: $e');
        }
      }
      
      return Message(
        id: response['id'] as String,
        conversationId: response['conversation_id'] as String,
        senderId: response['sender_id'] as String,
        content: response['content'] as String,
        messageType: MessageType.fromString(response['message_type'] as String? ?? 'text'),
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
        isEdited: response['is_edited'] as bool? ?? false,
        isDeleted: response['is_deleted'] as bool? ?? false,
        senderNickname: userData?['nickname'] as String?,
        senderCustomUserId: userData?['custom_user_id'] as String?,
      );
    } catch (e) {
      return null;
    }
  }

  // Mark conversation as read
  static Future<void> markConversationAsRead(String conversationId) async {
    try {
      final currentUser = SupabaseAuthService.currentUser;
      if (currentUser == null) return;

      await _client.rpc('mark_conversation_as_read', params: {
        'conv_id': conversationId,
        'p_user_id': currentUser.id,  // Changed from 'user_id' to 'p_user_id'
      });
    } catch (e) {
    }
  }

  // Get unread message count for a conversation
  static Future<int> _getUnreadMessageCount(String conversationId, String userId) async {
    try {
      // Get user's last read timestamp
      final participantResponse = await _client
          .from('conversation_participants')
          .select('last_read_at')
          .eq('conversation_id', conversationId)
          .eq('user_id', userId)
          .single();

      final lastReadAt = DateTime.parse(participantResponse['last_read_at'] as String);

      // Count messages sent after last read time by other users (not including own messages)
      final countResponse = await _client
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)  // Only count messages from others
          .eq('is_deleted', false)   // Only count non-deleted messages
          .gt('created_at', lastReadAt.toIso8601String());

      final unreadCount = countResponse.length;
      return unreadCount;
    } catch (e) {
      return 0;
    }
  }

  // Subscribe to real-time messages for a conversation
  static RealtimeChannel subscribeToMessages(String conversationId, Function(Message) onMessage) {
    final currentUser = SupabaseAuthService.currentUser;
    
    final channel = _client
        .channel('messages_$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            try {
              final messageData = payload.newRecord;
              
              // Process all new messages, including our own for consistency
              final message = Message(
                id: messageData['id'] as String,
                conversationId: messageData['conversation_id'] as String,
                senderId: messageData['sender_id'] as String,
                content: messageData['content'] as String,
                messageType: MessageType.fromString(messageData['message_type'] as String? ?? 'text'),
                createdAt: DateTime.parse(messageData['created_at'] as String),
                updatedAt: DateTime.parse(messageData['updated_at'] as String),
                isEdited: messageData['is_edited'] as bool? ?? false,
                isDeleted: messageData['is_deleted'] as bool? ?? false,
              );
              
              // Only notify for messages from other users to avoid duplicates
              if (messageData['sender_id'] != currentUser?.id) {
                onMessage(message);
              } else {
              }
            } catch (e) {
            }
          },
        );
    
    // Subscribe and handle the subscription status
    channel.subscribe((status, [error]) {
      if (error != null) {
      }
    });
    
    return channel;
  }

  // Subscribe to real-time conversation updates
  static RealtimeChannel subscribeToConversations(Function() onConversationUpdate) {
    
    final channel = _client
        .channel('conversations_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            try {
              // Instead of parsing the conversation here, just trigger a refresh
              // This is simpler and more reliable
              onConversationUpdate();
            } catch (e) {
            }
          },
        );
    
    // Subscribe and handle the subscription status
    channel.subscribe((status, [error]) {
      if (error != null) {
      }
    });
    
    return channel;
  }

  // Get users that the current user can chat with (following users)
  static Future<List<AppUser>> getChatableUsers() async {
    try {
      final following = await SupabaseAuthService.getFollowing();
      return following;
    } catch (e) {
      return [];
    }
  }

  // Send a message request
  static Future<MessageRequest?> sendMessageRequest({
    required String recipientId,
    required String messageContent,
  }) async {
    try {
      final currentUser = SupabaseAuthService.currentUser;
      if (currentUser == null) return null;

      // Check if user is blocked
      final isBlocked = await ModerationService.areUsersBlockedFromMessaging(
        currentUser.id, 
        recipientId
      );
      
      if (isBlocked) {
        throw Exception('Unable to send message request. One of the users has blocked the other.');
      }

      // Check if current user follows the recipient
      final isFollowing = await SupabaseAuthService.isFollowing(currentUser.id, recipientId);
      if (!isFollowing) {
        throw Exception('You need to follow this user to send a message request.');
      }

      // Check if there's already a pending or accepted request
      final existingRequest = await _getMessageRequest(currentUser.id, recipientId);
      if (existingRequest != null) {
        if (existingRequest.status == MessageRequestStatus.pending) {
          throw Exception('Message request already sent.');
        } else if (existingRequest.status == MessageRequestStatus.accepted) {
          throw Exception('You can already message this user.');
        } else if (existingRequest.status == MessageRequestStatus.declined) {
          // Update the declined request with new message content
          return await _updateMessageRequest(existingRequest.id, messageContent);
        }
      }

      // Create new message request
      final response = await _client
          .from('message_requests')
          .insert({
            'sender_id': currentUser.id,
            'recipient_id': recipientId,
            'message_content': messageContent,
            'status': 'pending',
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select('''
            *,
            users!message_requests_sender_id_fkey(
              nickname,
              custom_user_id
            )
          ''')
          .single();

      // Send notification
      try {
        final notificationService = NotificationService(_client);
        await notificationService.notifyMessageRequestReceived(recipientId, currentUser.id);
      } catch (e) {
        print('Failed to send message request notification: $e');
      }

      return MessageRequest.fromJson(response);
    } catch (e) {
      print('Error sending message request: $e');
      return null;
    }
  }

  // Get message requests for current user (received)
  static Future<List<MessageRequest>> getMessageRequests() async {
    try {
      final currentUser = SupabaseAuthService.currentUser;
      if (currentUser == null) return [];

      final response = await _client
          .from('message_requests')
          .select('''
            *,
            users!message_requests_sender_id_fkey(
              nickname,
              custom_user_id
            )
          ''')
          .eq('recipient_id', currentUser.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return response.map((data) => MessageRequest.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  // Handle message request (accept/decline)
  static Future<bool> handleMessageRequest(String requestId, bool accept) async {
    try {
      final status = accept ? 'accepted' : 'declined';
      
      // Update the message request status
      await _client
          .from('message_requests')
          .update({
            'status': status,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', requestId);

      // If accepted, create a conversation and send the initial message
      if (accept) {
        // Get the message request details
        final request = await _client
            .from('message_requests')
            .select('sender_id, recipient_id, message_content')
            .eq('id', requestId)
            .single();

        final senderId = request['sender_id'] as String;
        final recipientId = request['recipient_id'] as String;
        final messageContent = request['message_content'] as String;

        // Create conversation between sender and recipient using database function
        try {
          final conversationId = await _client.rpc('get_or_create_conversation', params: {
            'user1_id': senderId,
            'user2_id': recipientId,
          });

          // Send the initial message from the request to the conversation
          if (conversationId != null) {
            await _client
                .from('messages')
                .insert({
                  'conversation_id': conversationId,
                  'sender_id': senderId,
                  'content': messageContent,
                  'message_type': 'text',
                  'created_at': DateTime.now().toUtc().toIso8601String(),
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                });
          }
        } catch (e) {
          print('Failed to create conversation/send message after accepting request: $e');
        }
      }

      return true;
    } catch (e) {
      print('Error handling message request: $e');
      return false;
    }
  }

  // Check if users can message each other (private helper)
  static Future<bool> _hasMessagingPermission(String userId1, String userId2) async {
    try {
      // Check if there's an accepted message request in either direction
      final request1 = await _getMessageRequest(userId1, userId2);
      final request2 = await _getMessageRequest(userId2, userId1);
      
      final hasAcceptedRequest = (request1?.status == MessageRequestStatus.accepted) ||
                                 (request2?.status == MessageRequestStatus.accepted);
      
      if (!hasAcceptedRequest) return false;
      
      // Additionally check if both users still follow each other
      // If either user unfollows, chat permission is revoked
      final user1FollowsUser2 = await SupabaseAuthService.isFollowing(userId1, userId2);
      final user2FollowsUser1 = await SupabaseAuthService.isFollowing(userId2, userId1);
      
      return user1FollowsUser2 && user2FollowsUser1;
    } catch (e) {
      return false;
    }
  }

  // Get message request between two users (private helper)
  static Future<MessageRequest?> _getMessageRequest(String senderId, String recipientId) async {
    try {
      final response = await _client
          .from('message_requests')
          .select('''
            *,
            users!message_requests_sender_id_fkey(
              nickname,
              custom_user_id
            )
          ''')
          .eq('sender_id', senderId)
          .eq('recipient_id', recipientId)
          .maybeSingle();

      if (response == null) return null;
      return MessageRequest.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Update existing message request (private helper)
  static Future<MessageRequest?> _updateMessageRequest(String requestId, String newMessageContent) async {
    try {
      final response = await _client
          .from('message_requests')
          .update({
            'message_content': newMessageContent,
            'status': 'pending',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', requestId)
          .select('''
            *,
            users!message_requests_sender_id_fkey(
              nickname,
              custom_user_id
            )
          ''')
          .single();

      return MessageRequest.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}