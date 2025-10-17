import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../chat/chat_detail_screen.dart';
import '../chat/message_screen.dart';
import '../../widgets/blookit_logo.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            );
          }

          if (notificationProvider.notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: notificationProvider.refreshNotifications,
            color: const Color(0xFFFF6B35),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notificationProvider.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationProvider.notifications[index];
                return _buildNotificationCard(
                  context,
                  notification,
                  notificationProvider,
                );
              },
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFF6B35),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const BlookitLogo(size: 28, borderRadius: 8),
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            if (notificationProvider.unreadCount > 0) {
              return IconButton(
                icon: const Icon(Icons.done_all, color: Colors.white),
                onPressed: () {
                  notificationProvider.markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                      backgroundColor: Color(0xFFFF6B35),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you get notifications, they\'ll show up here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? Colors.grey[200]! : const Color(0xFFE3F2FD),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _handleNotificationTap(context, notification, provider),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileImage(notification),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNotificationContent(notification),
                      const SizedBox(height: 4),
                      _buildTimestamp(notification),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B35),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(NotificationModel notification) {
    if (notification.userProfileImage != null) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(notification.userProfileImage!),
        backgroundColor: Colors.grey[200],
      );
    } else {
      // For system notifications or users without profile images
      if (notification.type == NotificationType.system) {
        return const BlookitLogo(size: 40, circular: true);
      } else {
        return CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFFF6B35),
          child: Text(
            notification.username[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        );
      }
    }
  }

  Widget _buildNotificationContent(NotificationModel notification) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.3,
        ),
        children: [
          TextSpan(
            text: notification.username,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: ' ${notification.actionText}',
            style: const TextStyle(
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestamp(NotificationModel notification) {
    return Text(
      notification.timeAgo,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[500],
        fontWeight: FontWeight.w400,
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider provider,
  ) {
    // Mark as read if not already read
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.message:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MessageScreen(),
          ),
        );
        break;
      case NotificationType.like:
      case NotificationType.comment:
      case NotificationType.mention:
        // Navigate to post detail (placeholder for now)
        _showComingSoonDialog(context, 'Post Detail');
        break;
      case NotificationType.booking:
        // Navigate to booking detail (placeholder for now)
        _showComingSoonDialog(context, 'Booking Detail');
        break;
      case NotificationType.follow:
        // Navigate to user profile (placeholder for now)
        _showComingSoonDialog(context, 'User Profile');
        break;
      case NotificationType.system:
        // Handle system notifications (placeholder for now)
        _showComingSoonDialog(context, 'System Settings');
        break;
    }
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature'),
        content: Text('$feature screen is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFFF6B35)),
            ),
          ),
        ],
      ),
    );
  }
}