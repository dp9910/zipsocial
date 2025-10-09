import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/supabase_auth_service.dart';

class ChatConversationScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserNickname;
  final String otherUserId;

  const ChatConversationScreen({
    super.key,
    required this.conversationId,
    required this.otherUserNickname,
    required this.otherUserId,
  });

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  RealtimeChannel? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeToMessages();
    _markAsRead();
    
    // Set current user ID for message ownership checks
    final currentUser = SupabaseAuthService.currentUser;
    Message.setCurrentUserId(currentUser?.id);
  }

  @override
  void dispose() {
    _messageSubscription?.unsubscribe();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await ChatService.getMessages(widget.conversationId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _subscribeToMessages() {
    print('ChatConversation: Setting up real-time subscription for ${widget.conversationId}');
    _messageSubscription = ChatService.subscribeToMessages(
      widget.conversationId,
      (Message message) {
        print('ChatConversation: Received real-time message: ${message.content}');
        if (mounted) {
          // Check if message already exists to avoid duplicates
          final messageExists = _messages.any((m) => m.id == message.id);
          if (!messageExists) {
            setState(() {
              _messages.add(message);
            });
            _scrollToBottom();
            _markAsRead();
            print('ChatConversation: Added message to UI, total messages: ${_messages.length}');
          } else {
            print('ChatConversation: Message already exists, skipping');
          }
        }
      },
    );
  }

  Future<void> _markAsRead() async {
    await ChatService.markConversationAsRead(widget.conversationId);
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final message = await ChatService.sendMessage(
        conversationId: widget.conversationId,
        content: content,
      );

      if (message != null && mounted) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF8CE830),
                    const Color(0xFF8CE830).withOpacity(0.8),
                  ],
                ),
              ),
              child: const Icon(
                Icons.person,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserNickname,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8CE830)),
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start the conversation',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Send a message to ${widget.otherUserNickname}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message.isMine;
                          final showTimestamp = index == 0 ||
                              _messages[index - 1].createdAt.difference(message.createdAt).inMinutes.abs() > 5;

                          return Column(
                            children: [
                              if (showTimestamp)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    _formatMessageTime(message.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              _buildMessageBubble(message, isMe),
                            ],
                          );
                        },
                      ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFF8CE830)),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF8CE830),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF8CE830),
                    const Color(0xFF8CE830).withOpacity(0.8),
                  ],
                ),
              ),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe 
                    ? const Color(0xFF8CE830)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
                border: isMe 
                    ? null
                    : Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 16,
                  color: isMe 
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF8CE830),
                    const Color(0xFF8CE830).withOpacity(0.8),
                  ],
                ),
              ),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}