import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/chat_models.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId;
  String serverUrl = const String.fromEnvironment('SOCKET_URL', defaultValue: 'http://localhost:5000');

  // Event callbacks
  Function(Message)? onMessageReceived;
  Function(Chat)? onChatUpdated;
  Function(String, bool)? onUserStatusChanged;
  Function(String, int)? onUnreadCountChanged;

  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;

  // Connect to Socket.IO server
  Future<void> connect(String userId, {String? role}) async {
    try {
      _currentUserId = userId;
      
      _socket?.dispose();
      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setQuery({'userId': userId, 'role': role ?? 'user'})
            .build(),
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        log('Socket connected for user: $userId');
        _setupEventListeners();
        // Join a common room for user-vendor chat
        _socket!.emit('join', {'room': 'global'});
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        log('Socket disconnected');
      });

      _socket!.onError((error) {
        log('Socket error: $error');
      });

    } catch (e) {
      log('Socket connection error: $e');
    }
  }

  // Setup event listeners
  void _setupEventListeners() {
    // Listen for new messages
    _socket!.on('newMessage', (data) {
      try {
        final message = Message.fromJson(data);
        onMessageReceived?.call(message);
        log('New message received: ${message.content}');
      } catch (e) {
        log('Error parsing new message: $e');
      }
    });

    // Listen for legacy message format
    _socket!.on('message', (data) {
      try {
        if (data is Map<String, dynamic>) {
          // Convert legacy format to new Message model
          final message = Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            chatId: 'legacy',
            senderId: data['fromId'] ?? '',
            content: data['text'] ?? '',
            type: MessageType.text,
            timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
            isRead: false,
          );
          onMessageReceived?.call(message);
        }
      } catch (e) {
        log('Error parsing legacy message: $e');
      }
    });

    // Listen for chat updates
    _socket!.on('chatUpdated', (data) {
      try {
        final chat = Chat.fromJson(data);
        onChatUpdated?.call(chat);
        log('Chat updated: ${chat.id}');
      } catch (e) {
        log('Error parsing chat update: $e');
      }
    });

    // Listen for user status changes
    _socket!.on('userStatusChanged', (data) {
      try {
        final userId = data['userId'] as String;
        final isOnline = data['isOnline'] as bool;
        onUserStatusChanged?.call(userId, isOnline);
        log('User status changed: $userId - $isOnline');
      } catch (e) {
        log('Error parsing user status: $e');
      }
    });

    // Listen for unread count changes
    _socket!.on('unreadCountChanged', (data) {
      try {
        final chatId = data['chatId'] as String;
        final count = data['count'] as int;
        onUnreadCountChanged?.call(chatId, count);
        log('Unread count changed: $chatId - $count');
      } catch (e) {
        log('Error parsing unread count: $e');
      }
    });
  }

  // Send a message (new format)
  void sendMessage(Message message) {
    if (_isConnected && _socket != null) {
      _socket!.emit('sendMessage', message.toJson());
      log('Message sent: ${message.content}');
    } else {
      log('Socket not connected, cannot send message');
    }
  }

  // Send message (legacy format for backward compatibility)
  void sendLegacyMessage({required String fromId, required String toRole, required String text}) {
    if (_isConnected && _socket != null) {
      _socket!.emit('message', {
        'fromId': fromId,
        'toRole': toRole,
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
      });
      log('Legacy message sent: $text');
    }
  }

  // Join a chat room
  void joinChat(String chatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('joinChat', {'chatId': chatId, 'userId': _currentUserId});
      log('Joined chat: $chatId');
    }
  }

  // Leave a chat room
  void leaveChat(String chatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('leaveChat', {'chatId': chatId, 'userId': _currentUserId});
      log('Left chat: $chatId');
    }
  }

  // Mark messages as read
  void markMessagesAsRead(String chatId, List<String> messageIds) {
    if (_isConnected && _socket != null) {
      _socket!.emit('markAsRead', {
        'chatId': chatId,
        'messageIds': messageIds,
        'userId': _currentUserId,
      });
      log('Marked messages as read in chat: $chatId');
    }
  }

  // Update user status
  void updateUserStatus(bool isOnline) {
    if (_isConnected && _socket != null) {
      _socket!.emit('updateStatus', {
        'userId': _currentUserId,
        'isOnline': isOnline,
      });
      log('Updated user status: $isOnline');
    }
  }

  // Create new chat
  void createChat(ChatType type, List<String> participantIds) {
    if (_isConnected && _socket != null) {
      _socket!.emit('createChat', {
        'type': type.toString().split('.').last,
        'participantIds': participantIds,
        'createdBy': _currentUserId,
      });
      log('Creating new chat with participants: $participantIds');
    }
  }

  // Set event callbacks
  void setEventCallbacks({
    Function(Message)? onMessageReceived,
    Function(Chat)? onChatUpdated,
    Function(String, bool)? onUserStatusChanged,
    Function(String, int)? onUnreadCountChanged,
  }) {
    this.onMessageReceived = onMessageReceived;
    this.onChatUpdated = onChatUpdated;
    this.onUserStatusChanged = onUserStatusChanged;
    this.onUnreadCountChanged = onUnreadCountChanged;
  }

  // Legacy message handler for backward compatibility
  void onMessage(void Function(Map<String, dynamic> data) handler) {
    _socket?.off('message');
    _socket?.on('message', (data) {
      if (data is Map<String, dynamic>) {
        handler(data);
      }
    });
  }

  // Disconnect socket
  void dispose() {
    if (_socket != null) {
      updateUserStatus(false); // Set user offline before disconnecting
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _currentUserId = null;
      log('Socket disconnected');
    }
  }
}