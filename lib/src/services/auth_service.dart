import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userRoleKey = 'user_role';
  static const String _userDataKey = 'user_data';
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Save authentication token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Get authentication token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Save user role (user/vendor)
  Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  // Get user role
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  // Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, json.encode(userData));
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return json.decode(userDataString);
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Login user
  Future<Map<String, dynamic>> loginUser({
    required String emailOrMobile,
    required String password,
  }) async {
    try {
      // Simulate API response delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Check against registered users in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Get all registered users
      final userKeys = prefs.getKeys().where((key) => key.startsWith('registered_user_')).toList();
      final vendorKeys = prefs.getKeys().where((key) => key.startsWith('registered_vendor_')).toList();
      
      // Check user accounts
      for (String key in userKeys) {
        final userDataString = prefs.getString(key);
        if (userDataString != null) {
          final userData = json.decode(userDataString);
          if ((userData['email'] == emailOrMobile || userData['mobile'] == emailOrMobile) && 
              userData['password'] == password) {
            
            // Save token and user data for login session
            await saveToken('mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}');
            await saveUserRole('user');
            await saveUserData({
              'id': userData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              'name': userData['name'],
              'email': userData['email'],
              'mobile': userData['mobile'],
              'role': 'user',
            });
            
            return {
              'success': true,
              'message': 'Login successful',
              'user': {
                'id': userData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                'name': userData['name'],
                'email': userData['email'],
                'mobile': userData['mobile'],
                'role': 'user',
              },
            };
          }
        }
      }
      
      // Check vendor accounts
      for (String key in vendorKeys) {
        final vendorDataString = prefs.getString(key);
        if (vendorDataString != null) {
          final vendorData = json.decode(vendorDataString);
          if ((vendorData['email'] == emailOrMobile || vendorData['mobile'] == emailOrMobile) && 
              vendorData['password'] == password) {
            
            // Save token and user data for login session
            await saveToken('mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}');
            await saveUserRole('vendor');
            await saveUserData({
              'id': vendorData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              'name': vendorData['businessName'],
              'email': vendorData['email'],
              'mobile': vendorData['mobile'],
              'role': 'vendor',
            });
            
            return {
              'success': true,
              'message': 'Login successful',
              'user': {
                'id': vendorData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                'name': vendorData['businessName'],
                'email': vendorData['email'],
                'mobile': vendorData['mobile'],
                'role': 'vendor',
              },
            };
          }
        }
      }
      
      // If no match found, return error
      return {
        'success': false,
        'message': 'Invalid email/mobile or password',
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}',
      };
    }
  }

  // Register user
  Future<Map<String, dynamic>> registerUser({
    required Map<String, dynamic> userData,
    required String role, // 'user' or 'vendor'
  }) async {
    try {
      final endpoint = role == 'user' 
          ? '/api/user/register' 
          : '/api/vendor/register';
      
      // In a real app, replace with your actual API endpoint
      // final response = await http.post(
      //   Uri.parse('YOUR_API_BASE_URL$endpoint'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode({...userData, 'role': role}),
      // );

      // Simulate API response
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock successful response
      final mockResponse = {
        'success': true,
        'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
        'user': {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          ...userData,
          'role': role,
        },
      };

      if (mockResponse['success'] == true) {
        // Save registered user data for login validation
        final prefs = await SharedPreferences.getInstance();
        final userId = DateTime.now().millisecondsSinceEpoch.toString();
        final userDataWithId = {...userData, 'id': userId, 'role': role};
        
        if (role == 'user') {
          await prefs.setString('registered_user_$userId', json.encode(userDataWithId));
        } else {
          await prefs.setString('registered_vendor_$userId', json.encode(userDataWithId));
        }
        
        // Save token and user data for current session
        await saveToken(mockResponse['token'] as String);
        await saveUserRole(role);
        await saveUserData(mockResponse['user'] as Map<String, dynamic>);
        
        return {
          'success': true,
          'message': 'Registration successful',
          'user': mockResponse['user'],
        };
      } else {
        return {
          'success': false,
          'message': 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Registration failed: ${e.toString()}',
      };
    }
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userDataKey);
  }

  // Validate token (check if still valid)
  Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      // In a real app, you would validate the token with your API
      // final response = await http.get(
      //   Uri.parse('YOUR_API_BASE_URL/api/auth/validate'),
      //   headers: {
      //     'Authorization': 'Bearer $token',
      //     'Content-Type': 'application/json',
      //   },
      // );

      // For now, just check if token exists
      return token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get authorization headers for API calls
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}