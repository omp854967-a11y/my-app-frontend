import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000'; // Backend server URL
  static const String _tokenKey = 'auth_token';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Get auth token from storage
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Save auth token to storage
  Future<void> _saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Remove auth token from storage
  Future<void> _removeAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Generic HTTP request method
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final uriWithQuery = queryParams != null 
          ? uri.replace(queryParameters: queryParams)
          : uri;
      
      final headers = await _getHeaders();
      
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uriWithQuery, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uriWithQuery,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uriWithQuery,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uriWithQuery, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': responseData,
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Request failed',
          'statusCode': response.statusCode,
        };
      }
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: $e',
      };
    }
  }

  // ==================== AUTH ENDPOINTS ====================
  
  // User login
  Future<Map<String, dynamic>> login(String emailOrMobile, String password) async {
    final result = await _makeRequest('POST', '/auth/login', body: {
      'emailOrMobile': emailOrMobile,
      'password': password,
    });
    
    if (result['success'] && result['data']['token'] != null) {
      await _saveAuthToken(result['data']['token']);
    }
    
    return result;
  }

  // User signup
  Future<Map<String, dynamic>> signupUser({
    required String fullName,
    required String email,
    required String mobile,
    required String city,
    required String pincode,
    required String address,
    required String password,
  }) async {
    final result = await _makeRequest('POST', '/auth/signup/user', body: {
      'fullName': fullName,
      'email': email,
      'mobile': mobile,
      'city': city,
      'pincode': pincode,
      'address': address,
      'password': password,
      'role': 'user',
    });
    
    if (result['success'] && result['data']['token'] != null) {
      await _saveAuthToken(result['data']['token']);
    }
    
    return result;
  }

  // Vendor signup
  Future<Map<String, dynamic>> signupVendor({
    required String businessName,
    required String ownerName,
    required String email,
    required String mobile,
    required String category,
    required String city,
    required String pincode,
    required String address,
    required String licenseNumber,
    required String password,
    String? licenseDocument,
  }) async {
    final result = await _makeRequest('POST', '/auth/signup/vendor', body: {
      'businessName': businessName,
      'ownerName': ownerName,
      'email': email,
      'mobile': mobile,
      'category': category,
      'city': city,
      'pincode': pincode,
      'address': address,
      'licenseNumber': licenseNumber,
      'password': password,
      'role': 'vendor',
      if (licenseDocument != null) 'licenseDocument': licenseDocument,
    });
    
    if (result['success'] && result['data']['token'] != null) {
      await _saveAuthToken(result['data']['token']);
    }
    
    return result;
  }

  // Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await _makeRequest('POST', '/auth/forgot-password', body: {
      'email': email,
    });
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    return await _makeRequest('POST', '/auth/reset-password', body: {
      'token': token,
      'newPassword': newPassword,
    });
  }

  // Logout
  Future<Map<String, dynamic>> logout() async {
    final result = await _makeRequest('POST', '/auth/logout');
    await _removeAuthToken();
    return result;
  }

  // Get current user
  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _makeRequest('GET', '/auth/me');
  }

  // ==================== USER PROFILE ENDPOINTS ====================
  
  // Get user profile
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return await _makeRequest('GET', '/users/$userId');
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    return await _makeRequest('PUT', '/users/profile', body: profileData);
  }

  // Upload profile picture
  Future<Map<String, dynamic>> uploadProfilePicture(String imagePath) async {
    // This would typically use multipart/form-data
    // For now, we'll simulate with base64
    return await _makeRequest('POST', '/users/profile/picture', body: {
      'image': imagePath,
    });
  }

  // ==================== VENDOR ENDPOINTS ====================
  
  // Get vendor profile
  Future<Map<String, dynamic>> getVendorProfile(String vendorId) async {
    return await _makeRequest('GET', '/vendors/$vendorId');
  }

  // Update vendor profile
  Future<Map<String, dynamic>> updateVendorProfile(Map<String, dynamic> profileData) async {
    return await _makeRequest('PUT', '/vendors/profile', body: profileData);
  }

  // Get vendor services
  Future<Map<String, dynamic>> getVendorServices(String vendorId) async {
    return await _makeRequest('GET', '/vendors/$vendorId/services');
  }

  // Create vendor service
  Future<Map<String, dynamic>> createVendorService(Map<String, dynamic> serviceData) async {
    return await _makeRequest('POST', '/vendors/services', body: serviceData);
  }

  // Update vendor service
  Future<Map<String, dynamic>> updateVendorService(String serviceId, Map<String, dynamic> serviceData) async {
    return await _makeRequest('PUT', '/vendors/services/$serviceId', body: serviceData);
  }

  // Delete vendor service
  Future<Map<String, dynamic>> deleteVendorService(String serviceId) async {
    return await _makeRequest('DELETE', '/vendors/services/$serviceId');
  }

  // ==================== POSTS ENDPOINTS ====================
  
  // Get posts feed
  Future<Map<String, dynamic>> getPostsFeed({int page = 1, int limit = 10}) async {
    return await _makeRequest('GET', '/posts', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }

  // Get user posts
  Future<Map<String, dynamic>> getUserPosts(String userId, {int page = 1, int limit = 10}) async {
    return await _makeRequest('GET', '/posts/user/$userId', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }

  // Create post
  Future<Map<String, dynamic>> createPost(Map<String, dynamic> postData) async {
    return await _makeRequest('POST', '/posts', body: postData);
  }

  // Like post
  Future<Map<String, dynamic>> likePost(String postId) async {
    return await _makeRequest('POST', '/posts/$postId/like');
  }

  // Unlike post
  Future<Map<String, dynamic>> unlikePost(String postId) async {
    return await _makeRequest('DELETE', '/posts/$postId/like');
  }

  // Comment on post
  Future<Map<String, dynamic>> commentOnPost(String postId, String comment) async {
    return await _makeRequest('POST', '/posts/$postId/comments', body: {
      'comment': comment,
    });
  }

  // ==================== CHAT ENDPOINTS ====================
  
  // Get user chats
  Future<Map<String, dynamic>> getUserChats() async {
    return await _makeRequest('GET', '/chats');
  }

  // Get chat messages
  Future<Map<String, dynamic>> getChatMessages(String chatId, {int page = 1, int limit = 50}) async {
    return await _makeRequest('GET', '/chats/$chatId/messages', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }

  // Create chat
  Future<Map<String, dynamic>> createChat(List<String> participantIds, String chatType) async {
    return await _makeRequest('POST', '/chats', body: {
      'participantIds': participantIds,
      'type': chatType,
    });
  }

  // Send message
  Future<Map<String, dynamic>> sendMessage(String chatId, String content, String messageType) async {
    return await _makeRequest('POST', '/chats/$chatId/messages', body: {
      'content': content,
      'type': messageType,
    });
  }

  // Mark messages as read
  Future<Map<String, dynamic>> markMessagesAsRead(String chatId, List<String> messageIds) async {
    return await _makeRequest('PUT', '/chats/$chatId/read', body: {
      'messageIds': messageIds,
    });
  }

  // ==================== NOTIFICATIONS ENDPOINTS ====================
  
  // Get notifications
  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    return await _makeRequest('GET', '/notifications', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }





  // ==================== FOLLOW ENDPOINTS ====================
  
  // Follow user/vendor
  Future<Map<String, dynamic>> followUser(String userId) async {
    return await _makeRequest('POST', '/users/$userId/follow');
  }

  // Unfollow user/vendor
  Future<Map<String, dynamic>> unfollowUser(String userId) async {
    return await _makeRequest('DELETE', '/users/$userId/follow');
  }

  // Get followers
  Future<Map<String, dynamic>> getFollowers(String userId, {int page = 1, int limit = 20}) async {
    return await _makeRequest('GET', '/users/$userId/followers', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }

  // Get following
  Future<Map<String, dynamic>> getFollowing(String userId, {int page = 1, int limit = 20}) async {
    return await _makeRequest('GET', '/users/$userId/following', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }

  // ==================== SEARCH ENDPOINTS ====================
  
  // Search users/vendors
  Future<Map<String, dynamic>> searchUsers(String query, {String? type, int page = 1, int limit = 20}) async {
    return await _makeRequest('GET', '/search/users', queryParams: {
      'q': query,
      if (type != null) 'type': type,
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }

  // Search services
  Future<Map<String, dynamic>> searchServices(String query, {String? category, int page = 1, int limit = 20}) async {
    return await _makeRequest('GET', '/search/services', queryParams: {
      'q': query,
      if (category != null) 'category': category,
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }

  // ==================== BOOKING ENDPOINTS ====================
  
  // Create booking
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    return await _makeRequest('POST', '/bookings', body: bookingData);
  }

  // Get user bookings
  Future<Map<String, dynamic>> getUserBookings({int page = 1, int limit = 20}) async {
    return await _makeRequest('GET', '/bookings', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }

  // Get vendor bookings
  Future<Map<String, dynamic>> getVendorBookings({int page = 1, int limit = 20}) async {
    return await _makeRequest('GET', '/bookings/vendor', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }

  // Update booking status
  Future<Map<String, dynamic>> updateBookingStatus(String bookingId, String status) async {
    return await _makeRequest('PUT', '/bookings/$bookingId/status', body: {
      'status': status,
    });
  }

  // ==================== NOTIFICATION ENDPOINTS ====================
  
  // Get user notifications
  Future<Map<String, dynamic>> getUserNotifications({
    required String userId,
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    return await _makeRequest('GET', '/notifications', queryParams: {
      'userId': userId,
      'page': page.toString(),
      'limit': limit.toString(),
      if (type != null) 'type': type,
    });
  }

  // Mark notification as read
  Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    return await _makeRequest('PUT', '/notifications/$notificationId/read');
  }

  // Mark all notifications as read
  Future<Map<String, dynamic>> markAllNotificationsAsRead(String userId) async {
    return await _makeRequest('PUT', '/notifications/read-all', body: {
      'userId': userId,
    });
  }

  // Delete notification
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    return await _makeRequest('DELETE', '/notifications/$notificationId');
  }

  // Clear all notifications
  Future<Map<String, dynamic>> clearAllNotifications(String userId) async {
    return await _makeRequest('DELETE', '/notifications/clear-all', body: {
      'userId': userId,
    });
  }

  // Get unread notification count
  Future<Map<String, dynamic>> getUnreadNotificationCount(String userId) async {
    return await _makeRequest('GET', '/notifications/unread-count', queryParams: {
      'userId': userId,
    });
  }

  // Send notification
  Future<Map<String, dynamic>> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    return await _makeRequest('POST', '/notifications/send', body: {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      if (data != null) 'data': data,
    });
  }

  // Subscribe to push notifications
  Future<Map<String, dynamic>> subscribeToPushNotifications({
    required String userId,
    required String deviceToken,
    String platform = 'android',
  }) async {
    return await _makeRequest('POST', '/notifications/subscribe', body: {
      'userId': userId,
      'deviceToken': deviceToken,
      'platform': platform,
    });
  }

  // Unsubscribe from push notifications
  Future<Map<String, dynamic>> unsubscribeFromPushNotifications({
    required String userId,
    required String deviceToken,
  }) async {
    return await _makeRequest('POST', '/notifications/unsubscribe', body: {
      'userId': userId,
      'deviceToken': deviceToken,
    });
  }

  // Update notification preferences
  Future<Map<String, dynamic>> updateNotificationPreferences({
    required String userId,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    Map<String, bool>? categoryPreferences,
  }) async {
    return await _makeRequest('PUT', '/notifications/preferences', body: {
      'userId': userId,
      if (pushEnabled != null) 'pushEnabled': pushEnabled,
      if (emailEnabled != null) 'emailEnabled': emailEnabled,
      if (smsEnabled != null) 'smsEnabled': smsEnabled,
      if (categoryPreferences != null) 'categoryPreferences': categoryPreferences,
    });
  }

  // Get vendor stats
  Future<Map<String, dynamic>> getVendorStats(String vendorId) async {
    return await _makeRequest('GET', '/vendors/$vendorId/stats');
  }

  // Follow vendor
  Future<Map<String, dynamic>> followVendor(String vendorId) async {
    return await _makeRequest('POST', '/vendors/$vendorId/follow');
  }

  // Unfollow vendor
  Future<Map<String, dynamic>> unfollowVendor(String vendorId) async {
    return await _makeRequest('DELETE', '/vendors/$vendorId/follow');
  }
}