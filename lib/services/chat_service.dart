import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'supabase_auth_service.dart';
import 'moderation_service.dart';

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

          // Check if users follow each other bidirectionally (required for chat access)
          final otherParticipant = participants.firstWhere(
            (p) => p.userId != currentUser.id,
            orElse: () => participants.first,
          );
          
          final areMutuallyFollowing = await SupabaseAuthService.areUsersMutuallyFollowing(
            currentUser.id,
            otherParticipant.userId,
          );
          
          // Only include conversations where users follow each other bidirectionally
          if (areMutuallyFollowing) {
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

      // Check if users follow each other bidirectionally (required for chat access)
      final areMutuallyFollowing = await SupabaseAuthService.areUsersMutuallyFollowing(
        currentUser.id,
        otherUserId,
      );
      
      if (!areMutuallyFollowing) {
        throw Exception('You need to follow each other to start a conversation.');
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

        // Check if users follow each other bidirectionally
        final areMutuallyFollowing = await SupabaseAuthService.areUsersMutuallyFollowing(
          currentUser.id,
          otherUserId,
        );
        
        if (!areMutuallyFollowing) {
          throw Exception('You need to follow each other to send messages.');
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
}