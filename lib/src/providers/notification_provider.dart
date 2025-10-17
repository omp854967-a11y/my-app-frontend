import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _currentUserId;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  // Get unread notifications count
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Get unread notifications
  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  // Initialize with user ID
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await loadNotifications();
  }

  // Load notifications from backend
  Future<void> loadNotifications() async {
    if (_currentUserId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await _notificationService.getUserNotifications(userId: _currentUserId!);
      
      if (result['success']) {
        _notifications = (result['data']['notifications'] as List<dynamic>)
            .map((notificationData) => NotificationModel.fromJson(notificationData))
            .toList();
      } else {
        // Fallback to sample data if backend fails
        _loadSampleNotifications();
      }
    } catch (e) {
      // Fallback to sample data on error
      _loadSampleNotifications();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  void _loadSampleNotifications() {
    _notifications = [
      NotificationModel(
        id: '1',
        userId: 'user1',
        username: 'Sarah Johnson',
        userProfileImage: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150',
        type: NotificationType.like,
        actionText: 'liked your post',
        targetId: 'post1',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      NotificationModel(
        id: '2',
        userId: 'user2',
        username: 'Mike Chen',
        userProfileImage: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        type: NotificationType.comment,
        actionText: 'commented on your post',
        targetId: 'post1',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      NotificationModel(
        id: '3',
        userId: 'user3',
        username: 'Emma Wilson',
        userProfileImage: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
        type: NotificationType.message,
        actionText: 'sent you a message',
        targetId: 'chat1',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: '4',
        userId: 'user4',
        username: 'David Brown',
        userProfileImage: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        type: NotificationType.booking,
        actionText: 'confirmed your booking',
        targetId: 'booking1',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      NotificationModel(
        id: '5',
        userId: 'user5',
        username: 'Lisa Garcia',
        userProfileImage: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
        type: NotificationType.follow,
        actionText: 'started following you',
        targetId: 'user5',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      NotificationModel(
        id: '6',
        userId: 'user6',
        username: 'Alex Thompson',
        userProfileImage: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        type: NotificationType.mention,
        actionText: 'mentioned you in a comment',
        targetId: 'post2',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
      ),
      NotificationModel(
        id: '7',
        userId: 'system',
        username: 'Blookit',
        userProfileImage: null,
        type: NotificationType.system,
        actionText: 'Your profile has been verified',
        targetId: null,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
    notifyListeners();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      // Update locally first for immediate UI response
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
      
      // Update via backend service
      try {
        await _notificationService.markNotificationAsRead(notificationId);
      } catch (e) {
        // If backend fails, revert the local change
        _notifications[index] = _notifications[index].copyWith(isRead: false);
        notifyListeners();
      }
    }
  }

  // Mark all notifications as read
  void markAllAsRead() {
    bool hasChanges = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        hasChanges = true;
      }
    }
    if (hasChanges) {
      notifyListeners();
    }
  }

  // Add new notification
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  // Remove notification
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }

  // Clear all notifications
  void clearAllNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  // Refresh notifications from backend
  Future<void> refreshNotifications() async {
    await loadNotifications();
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get recent notifications (last 24 hours)
  List<NotificationModel> get recentNotifications {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _notifications.where((n) => n.timestamp.isAfter(yesterday)).toList();
  }
}