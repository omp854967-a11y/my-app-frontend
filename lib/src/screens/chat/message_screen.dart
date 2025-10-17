import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/blookit_logo.dart';
import '../../models/chat_models.dart';
import '../../providers/chat_provider.dart';
import 'chat_detail_screen.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize chat provider if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (!chatProvider.isConnected) {
        // Use a mock user ID for now - in real app this would come from auth
        chatProvider.initialize('user1', role: 'user');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35), // Blookit brand color
        elevation: 0,
        title: const BlookitLogo(size: 32, borderRadius: 8),
        centerTitle: true,
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          // Combine all chats instead of separating by tabs
          final allChats = [...chatProvider.getUserChats(), ...chatProvider.getVendorChats()];
          return _buildChatList(allChats, chatProvider);
        },
      ),

    );
  }

  Widget _buildChatList(List<Chat> chats, ChatProvider chatProvider) {
    if (chats.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        final unreadCount = chatProvider.getUnreadCountForChat(chat.id);
        final isOnline = _getParticipantOnlineStatus(chat, chatProvider);
        
        return _buildChatTile(chat, unreadCount, isOnline, chatProvider);
      },
    );
  }

  Widget _buildChatTile(Chat chat, int unreadCount, bool isOnline, ChatProvider chatProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFFF6B35),
              child: Text(
                _getChatInitials(chat),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(
                       color: Colors.white,
                       width: 2,
                     ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
           _getChatTitle(chat),
           style: const TextStyle(
             color: Colors.black87,
             fontSize: 16,
             fontWeight: FontWeight.w600,
           ),
           overflow: TextOverflow.ellipsis,
         ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
               chat.lastMessage?.content ?? 'No messages yet',
               style: TextStyle(
                 color: Colors.grey[600],
                 fontSize: 14,
               ),
               maxLines: 2,
               overflow: TextOverflow.ellipsis,
             ),
             const SizedBox(height: 4),
             Text(
               _formatTime(chat.lastActivity),
               style: TextStyle(
                 color: Colors.grey[500],
                 fontSize: 12,
               ),
             ),
          ],
        ),
        trailing: unreadCount > 0
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B35),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(chatId: chat.id),
            ),
          );
        },
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
             'No conversations yet',
             style: TextStyle(
               color: Colors.grey[600],
               fontSize: 18,
               fontWeight: FontWeight.w500,
             ),
           ),
           const SizedBox(height: 8),
           Text(
             'Start a new conversation to get started',
             style: TextStyle(
               color: Colors.grey[500],
               fontSize: 14,
             ),
           ),
        ],
      ),
    );
  }

  String _getChatInitials(Chat chat) {
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

  String _getChatTitle(Chat chat) {
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

  bool _getParticipantOnlineStatus(Chat chat, ChatProvider chatProvider) {
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

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showNewChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        title: const Text(
          'New Chat',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFFFF6B35)),
              title: const Text(
                'Chat with User',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _createNewChat(ChatType.userToUser);
              },
            ),
            ListTile(
              leading: const Icon(Icons.store, color: Color(0xFFFF6B35)),
              title: const Text(
                'Chat with Vendor',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _createNewChat(ChatType.userToVendor);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNewChat(ChatType type) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Mock participant IDs - in real app, this would come from user selection
    final participantIds = type == ChatType.userToUser 
        ? ['user${DateTime.now().millisecondsSinceEpoch % 1000}']
        : ['vendor${DateTime.now().millisecondsSinceEpoch % 1000}'];
    
    final title = type == ChatType.userToUser 
        ? 'New User Chat'
        : 'New Vendor Chat';
    
    chatProvider.createChat(type, participantIds, title: title);
  }
}