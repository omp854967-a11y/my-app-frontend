enum ChatType { userToUser, userToVendor }

enum MessageType { text, image, file }

class User {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final bool isOnline;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    this.isOnline = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'isOnline': isOnline,
    };
  }
}

class Vendor {
  final String id;
  final String businessName;
  final String email;
  final String? profileImage;
  final String category;
  final bool isVerified;
  final bool isOnline;

  Vendor({
    required this.id,
    required this.businessName,
    required this.email,
    this.profileImage,
    required this.category,
    this.isVerified = false,
    this.isOnline = false,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] ?? '',
      businessName: json['businessName'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'],
      category: json['category'] ?? '',
      isVerified: json['isVerified'] ?? false,
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'email': email,
      'profileImage': profileImage,
      'category': category,
      'isVerified': isVerified,
      'isOnline': isOnline,
    };
  }
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? replyToId;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.replyToId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      chatId: json['chatId'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      replyToId: json['replyToId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'replyToId': replyToId,
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    String? replyToId,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      replyToId: replyToId ?? this.replyToId,
    );
  }
}

class Chat {
  final String id;
  final ChatType type;
  final List<String> participantIds;
  final User? user;
  final Vendor? vendor;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime lastActivity;
  final bool isActive;

  Chat({
    required this.id,
    required this.type,
    required this.participantIds,
    this.user,
    this.vendor,
    this.lastMessage,
    this.unreadCount = 0,
    required this.lastActivity,
    this.isActive = true,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] ?? '',
      type: ChatType.values.firstWhere(
        (e) => e.toString() == 'ChatType.${json['type']}',
        orElse: () => ChatType.userToUser,
      ),
      participantIds: List<String>.from(json['participantIds'] ?? []),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      vendor: json['vendor'] != null ? Vendor.fromJson(json['vendor']) : null,
      lastMessage: json['lastMessage'] != null 
          ? Message.fromJson(json['lastMessage']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      lastActivity: DateTime.parse(json['lastActivity']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'participantIds': participantIds,
      'user': user?.toJson(),
      'vendor': vendor?.toJson(),
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'lastActivity': lastActivity.toIso8601String(),
      'isActive': isActive,
    };
  }

  String get displayName {
    if (type == ChatType.userToVendor && vendor != null) {
      return vendor!.businessName;
    } else if (user != null) {
      return user!.name;
    }
    return 'Unknown';
  }

  String? get displayImage {
    if (type == ChatType.userToVendor && vendor != null) {
      return vendor!.profileImage;
    } else if (user != null) {
      return user!.profileImage;
    }
    return null;
  }

  bool get isOnline {
    if (type == ChatType.userToVendor && vendor != null) {
      return vendor!.isOnline;
    } else if (user != null) {
      return user!.isOnline;
    }
    return false;
  }

  Chat copyWith({
    String? id,
    ChatType? type,
    List<String>? participantIds,
    User? user,
    Vendor? vendor,
    Message? lastMessage,
    int? unreadCount,
    DateTime? lastActivity,
    bool? isActive,
  }) {
    return Chat(
      id: id ?? this.id,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      user: user ?? this.user,
      vendor: vendor ?? this.vendor,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastActivity: lastActivity ?? this.lastActivity,
      isActive: isActive ?? this.isActive,
    );
  }
}