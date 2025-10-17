import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'socket_service.dart';
import '../models/chat_models.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  // Initialize chat service
  Future<void> initialize(String userId) async {
    try {
      // Connect to socket for real-time messaging
      await _socketService.connect(userId);
    } catch (e) {
      print('Failed to initialize chat service: $e');
    }
  }

  // Get user chats
  Future<Map<String, dynamic>> getUserChats(String userId) async {
    try {
      final result = await _apiService.getUserChats();
      
      if (result['success']) {
        // Cache chats locally
        await _cacheChats(result['data']);
      }
      
      return result;
    } catch (e) {
      // Fallback to local cache
      final localChats = await _getLocalChats();
      return {
        'success': true,
        'data': localChats,
        'message': 'Loaded from cache (Demo Mode)',
      };
    }
  }

  // Get chat messages
  Future<Map<String, dynamic>> getChatMessages(String chatId, String userId) async {
    try {
      final result = await _apiService.getChatMessages(chatId);
      
      if (result['success']) {
        // Cache messages locally
        await _cacheMessages(chatId, result['data']);
      }
      
      return result;
    } catch (e) {
      // Fallback to local cache
      final localMessages = await _getLocalMessages(chatId);
      return localMessages;
    }
  }

  // Send message
  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String message,
    required String type,
  }) async {
    try {
      final result = await _apiService.sendMessage(chatId, message, type);
      
      if (result['success']) {
        // Send via socket
        final messageObj = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          chatId: chatId,
          senderId: senderId,
          content: message,
          type: MessageType.values.firstWhere(
            (e) => e.toString().split('.').last == type,
            orElse: () => MessageType.text,
          ),
          timestamp: DateTime.now(),
          isRead: false,
        );
        _socketService.sendMessage(messageObj);
        
        // Cache message locally
        await _addLocalMessage(chatId, result['data']['message']);
      }
      
      return result;
    } catch (e) {
      // Fallback to demo mode
      return await _sendMessageFallback(chatId, senderId, receiverId, message, type);
    }
  }

  // Mark messages as read
  Future<Map<String, dynamic>> markMessagesAsRead(String chatId, String userId) async {
    try {
      final result = await _apiService.markMessagesAsRead(chatId, []);
      
      if (result['success']) {
        // Update local messages
        await _markLocalMessagesAsRead(chatId, userId);
        
        // Notify via socket
        _socketService.markMessagesAsRead(chatId, []);
      }
      
      return result;
    } catch (e) {
      // Fallback to local update
      await _markLocalMessagesAsRead(chatId, userId);
      _socketService.markMessagesAsRead(chatId, []);
      
      return {
        'success': true,
        'message': 'Messages marked as read (Demo Mode)',
      };
    }
  }

  // Create new chat
  Future<Map<String, dynamic>> createChat({
    required String userId,
    required String vendorId,
    required String type,
  }) async {
    try {
      final result = await _apiService.createChat([userId, vendorId], type);
      
      if (result['success']) {
        // Join chat room via socket
        _socketService.joinChat(result['data']['chat']['id']);
        
        // Cache chat locally
        await _addLocalChat(result['data']['chat']);
      }
      
      return result;
    } catch (e) {
      // Fallback to demo mode
      final demoChat = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type,
        'participants': [userId, vendorId],
        'createdAt': DateTime.now().toIso8601String(),
        'lastMessage': null,
        'unreadCount': 0,
      };
      
      await _addLocalChat(demoChat);
      
      return {
        'success': true,
        'data': {'chat': demoChat},
        'message': 'Chat created successfully (Demo Mode)',
      };
    }
  }

  // Delete chat
  Future<Map<String, dynamic>> deleteChat(String chatId) async {
    try {
      // Leave chat room via socket
      _socketService.leaveChat(chatId);
      
      // Remove from local storage
      await _removeLocalChat(chatId);
      
      return {
        'success': true,
        'message': 'Chat deleted successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to delete chat: $e',
      };
    }
  }

  // Listen to socket events
  void listenToMessages(Function(Map<String, dynamic>) onMessageReceived) {
    _socketService.onMessageReceived = (message) {
      final data = message.toJson();
      onMessageReceived(data);
      // Cache received message
      _addLocalMessage(data['chatId'], data);
    };
  }

  void listenToUserStatus(Function(String, bool) onUserStatusChanged) {
    _socketService.onUserStatusChanged = onUserStatusChanged;
  }

  // Disconnect
  Future<void> disconnect() async {
    _socketService.dispose();
  }

  // Private helper methods
  Future<void> _cacheChats(List<dynamic> chats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_chats', jsonEncode(chats));
  }

  Future<List<dynamic>> _getLocalChats() async {
    final prefs = await SharedPreferences.getInstance();
    final chatsJson = prefs.getString('user_chats');
    
    if (chatsJson != null) {
      return jsonDecode(chatsJson) as List;
    }
    
    // Return sample chats if no cache
    return _createSampleChats();
  }

  Future<void> _cacheMessages(String chatId, List<dynamic> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_messages_$chatId', jsonEncode(messages));
  }

  Future<Map<String, dynamic>> _getLocalMessages(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('chat_messages_$chatId');
    
    if (messagesJson != null) {
      final messages = jsonDecode(messagesJson) as List;
      return {
        'success': true,
        'data': messages,
        'message': 'Loaded from cache',
      };
    }
    
    // Return sample messages
    final sampleMessages = _createSampleMessages(chatId);
    await prefs.setString('chat_messages_$chatId', jsonEncode(sampleMessages));
    
    return {
      'success': true,
      'data': sampleMessages,
      'message': 'Sample messages loaded',
    };
  }

  Future<void> _addLocalMessage(String chatId, Map<String, dynamic> message) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('chat_messages_$chatId');
    List<dynamic> messages = [];
    
    if (messagesJson != null) {
      messages = jsonDecode(messagesJson) as List;
    }
    
    messages.add(message);
    await prefs.setString('chat_messages_$chatId', jsonEncode(messages));
  }

  Future<Map<String, dynamic>> _sendMessageFallback(
    String chatId,
    String senderId,
    String receiverId,
    String message,
    String type,
  ) async {
    final messageData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    };
    
    // Send via socket
    final messageObj = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: chatId,
      senderId: senderId,
      content: message,
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == type,
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.now(),
      isRead: false,
    );
    _socketService.sendMessage(messageObj);
    
    // Cache locally
    await _addLocalMessage(chatId, messageData);
    
    return {
      'success': true,
      'message': 'Message sent successfully (Demo Mode)',
      'data': {'message': messageData}
    };
  }

  Future<void> _markLocalMessagesAsRead(String chatId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('chat_messages_$chatId');
    
    if (messagesJson != null) {
      List<dynamic> messages = jsonDecode(messagesJson) as List;
      
      for (var message in messages) {
        if (message['receiverId'] == userId) {
          message['isRead'] = true;
        }
      }
      
      await prefs.setString('chat_messages_$chatId', jsonEncode(messages));
    }
  }

  Future<void> _addLocalChat(Map<String, dynamic> chat) async {
    final prefs = await SharedPreferences.getInstance();
    final chatsJson = prefs.getString('user_chats');
    List<dynamic> chats = [];
    
    if (chatsJson != null) {
      chats = jsonDecode(chatsJson) as List;
    }
    
    chats.add(chat);
    await prefs.setString('user_chats', jsonEncode(chats));
  }

  Future<void> _removeLocalChat(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final chatsJson = prefs.getString('user_chats');
    
    if (chatsJson != null) {
      List<dynamic> chats = jsonDecode(chatsJson) as List;
      chats.removeWhere((chat) => chat['id'] == chatId);
      await prefs.setString('user_chats', jsonEncode(chats));
    }
    
    // Also remove messages
    await prefs.remove('chat_messages_$chatId');
  }

  List<dynamic> _createSampleChats() {
    return [
      {
        'id': 'chat_1',
        'type': 'user_vendor',
        'participants': ['user_1', 'vendor_1'],
        'vendor': {
          'id': 'vendor_1',
          'name': 'TechStore Pro',
          'avatar': null,
          'isOnline': true,
        },
        'lastMessage': {
          'content': 'Hello! How can I help you today?',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
          'senderId': 'vendor_1',
        },
        'unreadCount': 2,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'chat_2',
        'type': 'user_vendor',
        'participants': ['user_1', 'vendor_2'],
        'vendor': {
          'id': 'vendor_2',
          'name': 'Fashion Hub',
          'avatar': null,
          'isOnline': false,
        },
        'lastMessage': {
          'content': 'Thank you for your order!',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'senderId': 'vendor_2',
        },
        'unreadCount': 0,
        'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
    ];
  }

  List<dynamic> _createSampleMessages(String chatId) {
    return [
      {
        'id': 'msg_1',
        'chatId': chatId,
        'senderId': 'vendor_1',
        'receiverId': 'user_1',
        'content': 'Hello! Welcome to our store. How can I assist you today?',
        'type': 'text',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'isRead': false,
      },
      {
        'id': 'msg_2',
        'chatId': chatId,
        'senderId': 'user_1',
        'receiverId': 'vendor_1',
        'content': 'Hi! I\'m looking for a new smartphone. What do you recommend?',
        'type': 'text',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'isRead': false,
      },
    ];
  }
}