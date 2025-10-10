import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation.dart';
import '../services/chat_service.dart';
import '../services/supabase_auth_service.dart';
import '../utils/user_colors.dart';
import 'chat_conversation_screen.dart';
import 'new_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  bool _hasError = false;
  RealtimeChannel? _conversationSubscription;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeToConversationUpdates();
  }

  @override
  void dispose() {
    _conversationSubscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final conversations = await ChatService.getConversations();
      if (mounted) {
        setState(() {
          _conversations = conversations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _refreshConversations() async {
    await _loadConversations();
  }

  void _subscribeToConversationUpdates() {
    _conversationSubscription = ChatService.subscribeToConversations(() {
      if (mounted) {
        _loadConversations();
      }
    });
  }

  void _navigateToNewChat() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NewChatScreen(),
      ),
    );

    if (result == true) {
      _refreshConversations();
    }
  }

  void _navigateToConversation(Conversation conversation) async {
    // Find the other participant (not the current user)
    final currentUser = SupabaseAuthService.currentUser;
    final otherParticipant = conversation.participants.firstWhere(
      (p) => p.userId != currentUser?.id,
      orElse: () => conversation.participants.first,
    );

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatConversationScreen(
          conversationId: conversation.id,
          otherUserNickname: otherParticipant.nickname ?? otherParticipant.customUserId ?? 'Unknown',
          otherUserId: otherParticipant.userId,
        ),
      ),
    );

    if (result == true) {
      _refreshConversations();
    }
  }

  String _getOtherParticipantName(Conversation conversation) {
    final currentUser = SupabaseAuthService.currentUser;
    final otherParticipant = conversation.participants.firstWhere(
      (p) => p.userId != currentUser?.id,
      orElse: () => conversation.participants.first,
    );

    return otherParticipant.nickname ?? otherParticipant.customUserId ?? 'Unknown User';
  }

  String _formatLastMessageTime(DateTime lastMessageAt) {
    final now = DateTime.now();
    final difference = now.difference(lastMessageAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
        ),
      );
    }

    if (_hasError) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final iconColor = isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400;
      final primaryTextColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;
      final secondaryTextColor = isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500;
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  color: primaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load your chats',
                style: TextStyle(
                  fontSize: 16,
                  color: secondaryTextColor,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _refreshConversations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Try Again',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _conversations.isEmpty
          ? RefreshIndicator(
              onRefresh: _refreshConversations,
              color: const Color(0xFF4ECDC4),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey.shade800 
                                : Colors.grey.shade100,
                            border: Border.all(
                              color: const Color(0xFF4ECDC4).withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: const Color(0xFF4ECDC4).withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No chats yet',
                          style: TextStyle(
                            fontSize: 22,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey.shade300 
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Start a conversation with someone you follow!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey.shade500 
                                : Colors.grey.shade500,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pull down to refresh',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF4ECDC4).withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _navigateToNewChat,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4ECDC4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text(
                            'Start New Chat',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshConversations,
              color: const Color(0xFF4ECDC4),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  return _buildConversationItem(conversation);
                },
              ),
            ),
      floatingActionButton: _conversations.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToNewChat,
              backgroundColor: const Color(0xFF4ECDC4),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildConversationItem(Conversation conversation) {
    final otherParticipantName = _getOtherParticipantName(conversation);
    final hasUnread = conversation.unreadCount > 0;
    final currentUser = SupabaseAuthService.currentUser;
    final isLastMessageFromMe = conversation.lastMessageSenderId == currentUser?.id;
    
    // Get the other participant to determine their color
    final otherParticipant = conversation.participants.firstWhere(
      (p) => p.userId != currentUser?.id,
      orElse: () => conversation.participants.first,
    );
    final otherUserColor = UserColors.getUserColor(otherParticipant.userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToConversation(conversation),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasUnread 
                  ? otherUserColor.withOpacity(0.05)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasUnread 
                    ? otherUserColor.withOpacity(0.3)
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: hasUnread ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        otherUserColor,
                        otherUserColor.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 25,
                    color: UserColors.getTextColorForBackground(otherUserColor),
                  ),
                ),
                const SizedBox(width: 12),

                // Conversation details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherParticipantName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatLastMessageTime(conversation.lastMessageAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread 
                                  ? otherUserColor
                                  : Colors.grey.shade500,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isLastMessageFromMe)
                            Icon(
                              Icons.reply,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                          if (isLastMessageFromMe) const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              conversation.lastMessage ?? 'No messages yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: hasUnread 
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.grey.shade600,
                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Unread indicator - only show if there are actually unread messages
                if (hasUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: otherUserColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      conversation.unreadCount > 99 ? '99+' : '${conversation.unreadCount}',
                      style: TextStyle(
                        color: UserColors.getTextColorForBackground(otherUserColor),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}