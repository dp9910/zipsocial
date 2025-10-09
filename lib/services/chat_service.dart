import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'supabase_auth_service.dart';

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
        } catch (e) {
          print('Error processing conversation: $e');
        }
      }

      return conversations;
    } catch (e) {
      print('Error fetching conversations: $e');
      return [];
    }
  }

  // Get or create a conversation between two users
  static Future<String?> getOrCreateConversation(String otherUserId) async {
    try {
      final currentUser = SupabaseAuthService.currentUser;
      if (currentUser == null) return null;

      final response = await _client.rpc('get_or_create_conversation', params: {
        'user1_id': currentUser.id,
        'user2_id': otherUserId,
      });

      return response as String?;
    } catch (e) {
      print('Error getting/creating conversation: $e');
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
      print('Error fetching messages: $e');
      return [];
    }
  }

  // Send a message
  static Future<Message?> sendMessage({
    required String conversationId,
    required String content,
    MessageType messageType = MessageType.text,
  }) async {
    try {
      final currentUser = SupabaseAuthService.currentUser;
      if (currentUser == null) return null;

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
      print('Error sending message: $e');
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
        'user_id': currentUser.id,
      });
    } catch (e) {
      print('Error marking conversation as read: $e');
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

      // Count messages sent after last read time by other users
      final countResponse = await _client
          .from('messages')
          .select('id')
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .gt('created_at', lastReadAt.toIso8601String());

      return countResponse.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Subscribe to real-time messages for a conversation
  static RealtimeChannel subscribeToMessages(String conversationId, Function(Message) onMessage) {
    final currentUser = SupabaseAuthService.currentUser;
    
    return _client
        .channel('messages:$conversationId')
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
              if (messageData['sender_id'] != currentUser?.id) {
                // Only notify for messages from other users
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
                onMessage(message);
              }
            } catch (e) {
              print('Error processing real-time message: $e');
            }
          },
        )
        .subscribe();
  }

  // Subscribe to real-time conversation updates
  static RealtimeChannel subscribeToConversations(Function(Conversation) onConversationUpdate) {
    return _client
        .channel('conversations')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            try {
              final convData = payload.newRecord;
              final conversation = Conversation(
                id: convData['id'] as String,
                createdAt: DateTime.parse(convData['created_at'] as String),
                updatedAt: DateTime.parse(convData['updated_at'] as String),
                lastMessageAt: DateTime.parse(convData['last_message_at'] as String),
                lastMessage: convData['last_message'] as String?,
                lastMessageSenderId: convData['last_message_sender_id'] as String?,
              );
              onConversationUpdate(conversation);
            } catch (e) {
              print('Error processing real-time conversation update: $e');
            }
          },
        )
        .subscribe();
  }

  // Get users that the current user can chat with (following users)
  static Future<List<AppUser>> getChatableUsers() async {
    try {
      final following = await SupabaseAuthService.getFollowing();
      return following;
    } catch (e) {
      print('Error fetching chatable users: $e');
      return [];
    }
  }
}