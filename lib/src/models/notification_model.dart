enum NotificationType {
  like,
  comment,
  message,
  booking,
  follow,
  mention,
  system,
}

class NotificationModel {
  final String id;
  final String userId;
  final String username;
  final String? userProfileImage;
  final NotificationType type;
  final String actionText;
  final String? targetId; // ID of the related post, message, booking, etc.
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.username,
    this.userProfileImage,
    required this.type,
    required this.actionText,
    this.targetId,
    required this.timestamp,
    this.isRead = false,
  });

  // Create a copy with updated fields
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userProfileImage,
    NotificationType? type,
    String? actionText,
    String? targetId,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      type: type ?? this.type,
      actionText: actionText ?? this.actionText,
      targetId: targetId ?? this.targetId,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'type': type.toString().split('.').last,
      'actionText': actionText,
      'targetId': targetId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  // Create from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['userId'],
      username: json['username'],
      userProfileImage: json['userProfileImage'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      actionText: json['actionText'],
      targetId: json['targetId'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }

  // Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  // Get notification icon based on type
  String get iconPath {
    switch (type) {
      case NotificationType.like:
        return 'assets/icons/heart.svg';
      case NotificationType.comment:
        return 'assets/icons/comment.svg';
      case NotificationType.message:
        return 'assets/icons/message.svg';
      case NotificationType.booking:
        return 'assets/icons/calendar.svg';
      case NotificationType.follow:
        return 'assets/icons/user_plus.svg';
      case NotificationType.mention:
        return 'assets/icons/at.svg';
      case NotificationType.system:
        return 'assets/icons/bell.svg';
    }
  }
}