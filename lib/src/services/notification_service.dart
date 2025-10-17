import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiService _apiService = ApiService();
  static const String _notificationsKey = 'user_notifications';

  // Get user notifications
  Future<Map<String, dynamic>> getUserNotifications({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await _apiService.getUserNotifications(
        userId: userId,
        page: page,
        limit: limit,
      );
      
      if (result['success']) {
        // Cache notifications locally
        await _cacheNotifications(result['data']['notifications']);
      }
      
      return result;
    } catch (e) {
      // Fallback to local notifications
      return await _getLocalNotifications();
    }
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    try {
      final result = await _apiService.markNotificationAsRead(notificationId);
      
      if (result['success']) {
        // Update local notification
        await _markLocalNotificationAsRead(notificationId);
      }
      
      return result;
    } catch (e) {
      // Fallback to local update
      await _markLocalNotificationAsRead(notificationId);
      return {
        'success': true,
        'message': 'Notification marked as read (Demo Mode)',
      };
    }
  }

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllNotificationsAsRead(String userId) async {
    try {
      final result = await _apiService.markAllNotificationsAsRead(userId);
      
      if (result['success']) {
        // Update local notifications
        await _markAllLocalNotificationsAsRead();
      }
      
      return result;
    } catch (e) {
      // Fallback to local update
      await _markAllLocalNotificationsAsRead();
      return {
        'success': true,
        'message': 'All notifications marked as read (Demo Mode)',
      };
    }
  }

  // Delete notification
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final result = await _apiService.deleteNotification(notificationId);
      
      if (result['success']) {
        // Remove from local storage
        await _removeLocalNotification(notificationId);
      }
      
      return result;
    } catch (e) {
      // Fallback to local removal
      await _removeLocalNotification(notificationId);
      return {
        'success': true,
        'message': 'Notification deleted successfully (Demo Mode)',
      };
    }
  }

  // Clear all notifications
  Future<Map<String, dynamic>> clearAllNotifications(String userId) async {
    try {
      final result = await _apiService.clearAllNotifications(userId);
      
      if (result['success']) {
        // Clear local notifications
        await _clearLocalNotifications();
      }
      
      return result;
    } catch (e) {
      // Fallback to local clear
      await _clearLocalNotifications();
      return {
        'success': true,
        'message': 'All notifications cleared (Demo Mode)',
      };
    }
  }

  // Get unread notification count
  Future<Map<String, dynamic>> getUnreadNotificationCount(String userId) async {
    try {
      final result = await _apiService.getUnreadNotificationCount(userId);
      return result;
    } catch (e) {
      // Fallback to local count
      return await _getLocalUnreadCount();
    }
  }

  // Send notification (for vendors/admin)
  Future<Map<String, dynamic>> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      final result = await _apiService.sendNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        data: data,
      );
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send notification',
      };
    }
  }

  // Subscribe to push notifications
  Future<Map<String, dynamic>> subscribeToPushNotifications({
    required String userId,
    required String deviceToken,
    String platform = 'android',
  }) async {
    try {
      final result = await _apiService.subscribeToPushNotifications(
        userId: userId,
        deviceToken: deviceToken,
        platform: platform,
      );
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to subscribe to push notifications',
      };
    }
  }

  // Unsubscribe from push notifications
  Future<Map<String, dynamic>> unsubscribeFromPushNotifications({
    required String userId,
    required String deviceToken,
  }) async {
    try {
      final result = await _apiService.unsubscribeFromPushNotifications(
        userId: userId,
        deviceToken: deviceToken,
      );
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to unsubscribe from push notifications',
      };
    }
  }

  // Update notification preferences
  Future<Map<String, dynamic>> updateNotificationPreferences({
    required String userId,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    Map<String, bool>? categoryPreferences,
  }) async {
    try {
      final result = await _apiService.updateNotificationPreferences(
        userId: userId,
        pushEnabled: pushEnabled,
        emailEnabled: emailEnabled,
        smsEnabled: smsEnabled,
        categoryPreferences: categoryPreferences,
      );
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update notification preferences',
      };
    }
  }

  // Private helper methods
  Future<void> _cacheNotifications(List<dynamic> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationsKey, jsonEncode(notifications));
  }

  Future<Map<String, dynamic>> _getLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);
    
    if (notificationsJson != null) {
      final notifications = jsonDecode(notificationsJson) as List;
      return {
        'success': true,
        'data': {'notifications': notifications}
      };
    }
    
    // Return sample notifications
    final sampleNotifications = _createSampleNotifications();
    await prefs.setString(_notificationsKey, jsonEncode(sampleNotifications));
    
    return {
      'success': true,
      'data': {'notifications': sampleNotifications}
    };
  }

  Future<void> _markLocalNotificationAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);
    
    if (notificationsJson != null) {
      List<dynamic> notifications = jsonDecode(notificationsJson) as List;
      
      for (var notification in notifications) {
        if (notification['id'] == notificationId) {
          notification['isRead'] = true;
          notification['readAt'] = DateTime.now().toIso8601String();
          break;
        }
      }
      
      await prefs.setString(_notificationsKey, jsonEncode(notifications));
    }
  }

  Future<void> _markAllLocalNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);
    
    if (notificationsJson != null) {
      List<dynamic> notifications = jsonDecode(notificationsJson) as List;
      
      for (var notification in notifications) {
        notification['isRead'] = true;
        notification['readAt'] = DateTime.now().toIso8601String();
      }
      
      await prefs.setString(_notificationsKey, jsonEncode(notifications));
    }
  }

  Future<void> _removeLocalNotification(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);
    
    if (notificationsJson != null) {
      List<dynamic> notifications = jsonDecode(notificationsJson) as List;
      notifications.removeWhere((n) => n['id'] == notificationId);
      await prefs.setString(_notificationsKey, jsonEncode(notifications));
    }
  }

  Future<void> _clearLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }

  Future<Map<String, dynamic>> _getLocalUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);
    
    if (notificationsJson != null) {
      List<dynamic> notifications = jsonDecode(notificationsJson) as List;
      final unreadCount = notifications.where((n) => !n['isRead']).length;
      
      return {
        'success': true,
        'data': {'unreadCount': unreadCount}
      };
    }
    
    return {
      'success': true,
      'data': {'unreadCount': 0}
    };
  }

  List<Map<String, dynamic>> _createSampleNotifications() {
    final now = DateTime.now();
    
    return [
      {
        'id': 'notif_1',
        'title': 'New Message',
        'message': 'You have received a new message from John Vendor',
        'type': 'message',
        'isRead': false,
        'createdAt': now.subtract(const Duration(minutes: 30)).toIso8601String(),
        'data': {
          'chatId': 'chat_1',
          'senderId': 'vendor_1',
          'senderName': 'John Vendor',
        },
      },
      {
        'id': 'notif_2',
        'title': 'Service Booking Confirmed',
        'message': 'Your home cleaning service booking has been confirmed',
        'type': 'booking',
        'isRead': false,
        'createdAt': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'data': {
          'bookingId': 'booking_1',
          'serviceTitle': 'Home Cleaning',
          'vendorName': 'Clean Pro Services',
        },
      },
      {
        'id': 'notif_3',
        'title': 'Payment Successful',
        'message': 'Payment of ₹500 for home cleaning service was successful',
        'type': 'payment',
        'isRead': true,
        'createdAt': now.subtract(const Duration(hours: 5)).toIso8601String(),
        'readAt': now.subtract(const Duration(hours: 4)).toIso8601String(),
        'data': {
          'paymentId': 'payment_1',
          'amount': 500,
          'serviceTitle': 'Home Cleaning',
        },
      },
      {
        'id': 'notif_4',
        'title': 'New Follower',
        'message': 'Sarah Service started following you',
        'type': 'follow',
        'isRead': true,
        'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
        'readAt': now.subtract(const Duration(hours: 20)).toIso8601String(),
        'data': {
          'followerId': 'vendor_2',
          'followerName': 'Sarah Service',
        },
      },
      {
        'id': 'notif_5',
        'title': 'Service Review',
        'message': 'You received a 5-star review for your plumbing service',
        'type': 'review',
        'isRead': true,
        'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        'readAt': now.subtract(const Duration(days: 1, hours: 12)).toIso8601String(),
        'data': {
          'reviewId': 'review_1',
          'rating': 5,
          'serviceTitle': 'Plumbing Service',
          'reviewerName': 'Happy Customer',
        },
      },
      {
        'id': 'notif_6',
        'title': 'Welcome to BlookIt!',
        'message': 'Welcome to BlookIt! Start exploring services in your area.',
        'type': 'welcome',
        'isRead': true,
        'createdAt': now.subtract(const Duration(days: 7)).toIso8601String(),
        'readAt': now.subtract(const Duration(days: 6)).toIso8601String(),
        'data': {},
      },
    ];
  }
}