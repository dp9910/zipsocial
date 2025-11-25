import 'package:flutter/material.dart';
import '../models/message_request.dart';
import '../services/chat_service.dart';
import '../utils/user_colors.dart';

class MessageRequestCard extends StatefulWidget {
  final MessageRequest request;
  final VoidCallback? onRequestHandled;

  const MessageRequestCard({
    super.key,
    required this.request,
    this.onRequestHandled,
  });

  @override
  State<MessageRequestCard> createState() => _MessageRequestCardState();
}

class _MessageRequestCardState extends State<MessageRequestCard> {
  bool _isProcessing = false;

  Future<void> _handleRequest(bool accept) async {
    setState(() => _isProcessing = true);

    try {
      final success = await ChatService.handleMessageRequest(widget.request.id, accept);
      
      if (success && mounted) {
        final action = accept ? 'accepted' : 'declined';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept 
                ? 'Message request accepted! You can now chat.' 
                : 'Message request declined'),
            backgroundColor: accept ? Colors.green : Colors.orange,
          ),
        );
        
        widget.onRequestHandled?.call();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey.shade800 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4ECDC4).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Row(
            children: [
              // User avatar placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: UserColors.getUserColor(widget.request.senderId),
                ),
                child: Center(
                  child: Text(
                    widget.request.senderDisplayName.isNotEmpty 
                        ? widget.request.senderDisplayName[0].toUpperCase() 
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.request.senderDisplayName,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'wants to message you',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ECDC4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4ECDC4).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'REQUEST',
                  style: TextStyle(
                    color: const Color(0xFF4ECDC4),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Message preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              ),
            ),
            child: Text(
              widget.request.messageContent,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          if (_isProcessing)
            Center(
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                strokeWidth: 2,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleRequest(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleRequest(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ECDC4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}