import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/blookit_logo.dart';
import '../../models/chat_models.dart';
import '../../providers/chat_provider.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatProvider _chatProvider;
  Chat? _currentChat;

  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _currentChat = _chatProvider.getChatById(widget.chatId);
    
    // Join the chat room
    _chatProvider.joinChat(widget.chatId);
    
    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _chatProvider.leaveChat(widget.chatId);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final messages = chatProvider.getMessagesForChat(widget.chatId);
          _currentChat = chatProvider.getChatById(widget.chatId);
          
          // Auto-scroll when new messages arrive
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
          
          return Column(
            children: [
              Expanded(
                child: _buildMessageList(messages, chatProvider),
              ),
              _buildMessageInput(chatProvider),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFF6B35), // Blookit brand color
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const BlookitLogo(size: 32, borderRadius: 8),
      centerTitle: true,
    );
  }

  Widget _buildMessageList(List<Message> messages, ChatProvider chatProvider) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == chatProvider.currentUserId;
        final showAvatar = index == messages.length - 1 || 
                          messages[index + 1].senderId != message.senderId;
        
        return _buildMessageBubble(message, isMe, showAvatar);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool showAvatar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFFF6B35),
              child: Text(
                message.senderId[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (!isMe)
            const SizedBox(width: 32),
          
          const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFFF6B35) : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: !isMe ? Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: message.isRead ? const Color(0xFF4CAF50) : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          if (isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFFF6B35),
              child: Text(
                message.senderId[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (isMe)
            const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(chatProvider),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B35),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _sendMessage(chatProvider),
              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(ChatProvider chatProvider) {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      chatProvider.sendMessage(widget.chatId, content, MessageType.text);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  String _getChatInitials(Chat? chat) {
    if (chat == null) return 'C';
    
    if (chat.type == ChatType.userToVendor && chat.vendor != null) {
      final businessName = chat.vendor!.businessName;
      if (businessName.isNotEmpty) {
        final words = businessName.split(' ');
        if (words.length >= 2) {
          return '${words[0][0]}${words[1][0]}'.toUpperCase();
        } else {
          return businessName[0].toUpperCase();
        }
      }
      return 'V';
    } else if (chat.user != null) {
      final name = chat.user!.name;
      if (name.isNotEmpty) {
        final words = name.split(' ');
        if (words.length >= 2) {
          return '${words[0][0]}${words[1][0]}'.toUpperCase();
        } else {
          return name[0].toUpperCase();
        }
      }
      return 'U';
    }
    
    return chat.type == ChatType.userToVendor ? 'V' : 'U';
  }

  bool _getParticipantOnlineStatus(Chat? chat, ChatProvider chatProvider) {
    if (chat == null) return false;
    
    // Get the other participant's status (not current user)
    final currentUserId = chatProvider.currentUserId;
    final otherParticipant = chat.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    
    if (otherParticipant.isNotEmpty) {
      return chatProvider.userStatuses[otherParticipant] ?? false;
    }
    
    return false;
  }

  String _getChatTitle(Chat? chat) {
    if (chat == null) return 'Unknown';
    
    if (chat.type == ChatType.userToVendor && chat.vendor != null) {
      return chat.vendor!.businessName.isNotEmpty 
          ? chat.vendor!.businessName 
          : 'Vendor';
    } else if (chat.user != null) {
      return chat.user!.name.isNotEmpty 
          ? chat.user!.name 
          : 'User';
    }
    return 'Unknown';
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      // Today - show time only
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      // Older - show date
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}