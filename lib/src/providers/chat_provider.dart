import 'dart:developer';
import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../services/socket_service.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final SocketService _socketService = SocketService();
  final ChatService _chatService = ChatService();
  
  // Chat data
  List<Chat> _chats = [];
  Map<String, List<Message>> _chatMessages = {};
  Map<String, int> _unreadCounts = {};
  Map<String, bool> _userStatuses = {};
  
  // Current state
  String? _currentUserId;
  String? _currentChatId;
  bool _isConnected = false;
  
  // Getters
  List<Chat> get chats => _chats;
  Map<String, List<Message>> get chatMessages => _chatMessages;
  Map<String, int> get unreadCounts => _unreadCounts;
  Map<String, bool> get userStatuses => _userStatuses;
  String? get currentUserId => _currentUserId;
  String? get currentChatId => _currentChatId;
  bool get isConnected => _isConnected;
  
  // Get total unread count for red dot indicator
  int get totalUnreadCount {
    return _unreadCounts.values.fold(0, (sum, count) => sum + count);
  }
  
  // Get messages for a specific chat
  List<Message> getMessagesForChat(String chatId) {
    return _chatMessages[chatId] ?? [];
  }
  
  // Get unread count for a specific chat
  int getUnreadCountForChat(String chatId) {
    return _unreadCounts[chatId] ?? 0;
  }
  
  // Initialize chat provider
  Future<void> initialize(String userId, {String? role}) async {
    _currentUserId = userId;
    
    // Setup socket event callbacks
    _socketService.setEventCallbacks(
      onMessageReceived: _handleNewMessage,
      onChatUpdated: _handleChatUpdate,
      onUserStatusChanged: _handleUserStatusChange,
      onUnreadCountChanged: _handleUnreadCountChange,
    );
    
    // Connect to socket
    await _socketService.connect(userId, role: role);
    _isConnected = _socketService.isConnected;
    
    // Load initial chat data
    await _loadInitialData();
    
    notifyListeners();
  }
  
  // Load initial chat data from backend
  Future<void> _loadInitialData() async {
    if (_currentUserId == null) return;
    
    try {
      // Initialize chat service
      await _chatService.initialize(_currentUserId!);
      
      // Load user chats from backend
      final chatsResult = await _chatService.getUserChats(_currentUserId!);
      if (chatsResult['success']) {
        _chats = (chatsResult['chats'] as List<dynamic>)
            .map((chatData) => Chat.fromJson(chatData))
            .toList();
      } else {
        // Fallback to mock data if backend fails
        _chats = _generateMockChats();
      }
      
      // Load messages for each chat
      for (final chat in _chats) {
        final messagesResult = await _chatService.getChatMessages(chat.id, _currentUserId!);
        if (messagesResult['success']) {
          _chatMessages[chat.id] = (messagesResult['messages'] as List<dynamic>)
              .map((messageData) => Message.fromJson(messageData))
              .toList();
        } else {
          // Fallback to mock messages
          _chatMessages[chat.id] = _generateMockMessagesForChat(chat.id);
        }
        
        // Calculate unread count
        _unreadCounts[chat.id] = _chatMessages[chat.id]!
            .where((msg) => !msg.isRead && msg.senderId != _currentUserId)
            .length;
      }
      
      // Load user statuses (fallback to mock for now)
      _userStatuses = _generateMockUserStatuses();
      
    } catch (e) {
      log('Error loading initial chat data: $e');
      // Fallback to mock data
      _chats = _generateMockChats();
      _chatMessages = _generateMockMessages();
      _unreadCounts = _generateMockUnreadCounts();
      _userStatuses = _generateMockUserStatuses();
    }
  }
  
  // Handle new message received
  void _handleNewMessage(Message message) {
    log('Handling new message: ${message.content}');
    
    // Add message to chat messages
    if (_chatMessages[message.chatId] == null) {
      _chatMessages[message.chatId] = [];
    }
    _chatMessages[message.chatId]!.add(message);
    
    // Update chat's last message
    final chatIndex = _chats.indexWhere((chat) => chat.id == message.chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(
        lastMessage: message,
        lastActivity: message.timestamp,
      );
    }
    
    // Update unread count if not in current chat
    if (_currentChatId != message.chatId && message.senderId != _currentUserId) {
      _unreadCounts[message.chatId] = (_unreadCounts[message.chatId] ?? 0) + 1;
    }
    
    // Sort chats by last activity time
    _chats.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    
    notifyListeners();
  }
  
  // Handle chat update
  void _handleChatUpdate(Chat chat) {
    log('Handling chat update: ${chat.id}');
    
    final index = _chats.indexWhere((c) => c.id == chat.id);
    if (index != -1) {
      _chats[index] = chat;
    } else {
      _chats.add(chat);
    }
    
    notifyListeners();
  }
  
  // Handle user status change
  void _handleUserStatusChange(String userId, bool isOnline) {
    log('User status changed: $userId - $isOnline');
    _userStatuses[userId] = isOnline;
    notifyListeners();
  }
  
  // Handle unread count change
  void _handleUnreadCountChange(String chatId, int count) {
    log('Unread count changed: $chatId - $count');
    _unreadCounts[chatId] = count;
    notifyListeners();
  }
  
  // Send a message
  Future<void> sendMessage(String chatId, String content, MessageType type) async {
    if (_currentUserId == null) return;
    
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final message = Message(
      id: tempId,
      chatId: chatId,
      senderId: _currentUserId!,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
    );
    
    // Add message locally first for immediate UI update
    if (_chatMessages[chatId] == null) {
      _chatMessages[chatId] = [];
    }
    _chatMessages[chatId]!.add(message);
    
    // Update chat's last message
    final chatIndex = _chats.indexWhere((chat) => chat.id == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(
        lastMessage: message,
        lastActivity: message.timestamp,
      );
    }
    
    notifyListeners();
    
    try {
      // Send via backend service
      final result = await _chatService.sendMessage(
        chatId: chatId,
        senderId: _currentUserId!,
        receiverId: 'temp_receiver', // TODO: Get actual receiver ID from chat
        message: content,
        type: type.toString().split('.').last,
      );
      
      if (result['success']) {
        // Update message with server-generated ID if available
        final serverMessage = result['message'];
        if (serverMessage != null) {
          final messageIndex = _chatMessages[chatId]!
              .indexWhere((msg) => msg.id == tempId);
          if (messageIndex != -1) {
            _chatMessages[chatId]![messageIndex] = Message.fromJson(serverMessage);
            notifyListeners();
          }
        }
        
        // Also send via socket for real-time updates
        _socketService.sendMessage(message);
      } else {
        log('Failed to send message via backend: ${result['message']}');
        // Still send via socket as fallback
        _socketService.sendMessage(message);
      }
    } catch (e) {
      log('Error sending message via backend: $e');
      // Fallback to socket only
      _socketService.sendMessage(message);
    }
  }
  
  // Join a chat
  void joinChat(String chatId) {
    _currentChatId = chatId;
    _socketService.joinChat(chatId);
    
    // Mark messages as read
    markChatAsRead(chatId);
  }
  
  // Leave a chat
  void leaveChat(String chatId) {
    if (_currentChatId == chatId) {
      _currentChatId = null;
    }
    _socketService.leaveChat(chatId);
  }
  
  // Mark chat as read
  void markChatAsRead(String chatId) {
    final messages = _chatMessages[chatId] ?? [];
    final unreadMessages = messages.where((m) => !m.isRead && m.senderId != _currentUserId).toList();
    
    if (unreadMessages.isNotEmpty) {
      // Mark messages as read locally
      for (final message in unreadMessages) {
        final index = messages.indexOf(message);
        if (index != -1) {
          messages[index] = message.copyWith(isRead: true);
        }
      }
      
      // Reset unread count
      _unreadCounts[chatId] = 0;
      
      // Send to server
      _socketService.markMessagesAsRead(chatId, unreadMessages.map((m) => m.id).toList());
      
      notifyListeners();
    }
  }
  
  // Create a new chat
  Future<void> createChat(ChatType type, List<String> participantIds, {String? title}) async {
    if (_currentUserId == null) return;
    
    final chat = Chat(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      participantIds: [_currentUserId!, ...participantIds],
      lastActivity: DateTime.now(),
    );
    
    _chats.insert(0, chat);
    _chatMessages[chat.id] = [];
    _unreadCounts[chat.id] = 0;
    
    notifyListeners();
    
    // Send to server
    _socketService.createChat(type, participantIds);
  }
  
  // Get chat by ID
  Chat? getChatById(String chatId) {
    try {
      return _chats.firstWhere((chat) => chat.id == chatId);
    } catch (e) {
      return null;
    }
  }
  
  // Get user/vendor chats separately
  List<Chat> getUserChats() {
    return _chats.where((chat) => chat.type == ChatType.userToUser).toList();
  }
  
  List<Chat> getVendorChats() {
    return _chats.where((chat) => chat.type == ChatType.userToVendor).toList();
  }
  
  // Dispose
  @override
  void dispose() {
    _socketService.dispose();
    super.dispose();
  }
  
  // Mock data generators (for testing)
  List<Chat> _generateMockChats() {
    return [
      Chat(
        id: 'chat1',
        type: ChatType.userToUser,
        participantIds: ['user1', 'user2'],
        user: User(
          id: 'user2',
          name: 'John Doe',
          email: 'john@example.com',
          profileImage: null,
          isOnline: true,
        ),
        lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
        lastMessage: Message(
          id: 'msg1',
          chatId: 'chat1',
          senderId: 'user2',
          content: 'Hey! How are you?',
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
        ),
        unreadCount: 1,
      ),
      Chat(
        id: 'chat2',
        type: ChatType.userToVendor,
        participantIds: ['user1', 'vendor1'],
        vendor: Vendor(
          id: 'vendor1',
          businessName: 'Blookit Store',
          email: 'store@blookit.com',
          profileImage: null,
          category: 'Electronics',
          isVerified: true,
          isOnline: false,
        ),
        lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
        lastMessage: Message(
          id: 'msg2',
          chatId: 'chat2',
          senderId: 'vendor1',
          content: 'Your order is ready for pickup!',
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: false,
        ),
        unreadCount: 2,
      ),
    ];
  }
  
  Map<String, List<Message>> _generateMockMessages() {
    return {
      'chat1': [
        Message(
          id: 'msg1',
          chatId: 'chat1',
          senderId: 'user2',
          content: 'Hey! How are you?',
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
        ),
      ],
      'chat2': [
        Message(
          id: 'msg2',
          chatId: 'chat2',
          senderId: 'vendor1',
          content: 'Your order is ready for pickup!',
          type: MessageType.text,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          isRead: false,
        ),
      ],
    };
  }
  
  Map<String, int> _generateMockUnreadCounts() {
    return {
      'chat1': 1,
      'chat2': 1,
    };
  }
  
  Map<String, bool> _generateMockUserStatuses() {
    return {
      'user2': true,
      'vendor1': false,
    };
  }
  
  List<Message> _generateMockMessagesForChat(String chatId) {
    // Generate some mock messages for the specific chat
    return [
      Message(
        id: 'mock_${chatId}_1',
        chatId: chatId,
        senderId: 'other_user',
        content: 'Hello! This is a mock message.',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
      ),
    ];
  }
}