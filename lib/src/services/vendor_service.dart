import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class VendorService {
  static final VendorService _instance = VendorService._internal();
  factory VendorService() => _instance;
  VendorService._internal();

  final ApiService _apiService = ApiService();
  static const String _servicesKey = 'vendor_services';

  // Get vendor profile
  Future<Map<String, dynamic>> getVendorProfile(String vendorId) async {
    try {
      final result = await _apiService.getVendorProfile(vendorId);
      return result;
    } catch (e) {
      // Fallback to local data
      return await _getFallbackProfile(vendorId);
    }
  }

  // Update vendor profile
  Future<Map<String, dynamic>> updateVendorProfile({
    required String vendorId,
    String? businessName,
    String? bio,
    String? profileImage,
    String? category,
    String? address,
    String? city,
    String? pincode,
  }) async {
    try {
      final result = await _apiService.updateVendorProfile({
        'vendorId': vendorId,
        'businessName': businessName,
        'bio': bio,
        'profileImage': profileImage,
        'category': category,
        'address': address,
        'city': city,
        'pincode': pincode,
      });
      
      if (result['success']) {
        // Update local data
        await _updateLocalProfile(result['data']['vendor']);
      }
      
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update profile. Please try again.',
      };
    }
  }

  // Get vendor services
  Future<Map<String, dynamic>> getVendorServices(String vendorId) async {
    try {
      final result = await _apiService.getVendorServices(vendorId);
      return result;
    } catch (e) {
      // Fallback to local services
      return await _getLocalServices();
    }
  }

  // Add vendor service
  Future<Map<String, dynamic>> addVendorService({
    required String vendorId,
    required String title,
    required String description,
    required double price,
    required String category,
    List<String>? images,
    String? duration,
    bool isAvailable = true,
  }) async {
    try {
      final result = await _apiService.createVendorService({
        'vendorId': vendorId,
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'images': images,
        'duration': duration,
        'isAvailable': isAvailable,
      });
      
      if (result['success']) {
        // Update local services
        await _addLocalService(result['data']['service']);
      }
      
      return result;
    } catch (e) {
      // Fallback to local storage
      return await _addLocalServiceFallback(
        title: title,
        description: description,
        price: price,
        category: category,
        images: images,
        duration: duration,
        isAvailable: isAvailable,
      );
    }
  }

  // Update vendor service
  Future<Map<String, dynamic>> updateVendorService({
    required String serviceId,
    String? title,
    String? description,
    double? price,
    String? category,
    List<String>? images,
    String? duration,
    bool? isAvailable,
  }) async {
    try {
      final result = await _apiService.updateVendorService(serviceId, {
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'images': images,
        'duration': duration,
        'isAvailable': isAvailable,
      });
      
      if (result['success']) {
        // Update local services
        await _updateLocalService(result['data']['service']);
      }
      
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update service. Please try again.',
      };
    }
  }

  // Delete vendor service
  Future<Map<String, dynamic>> deleteVendorService(String serviceId) async {
    try {
      final result = await _apiService.deleteVendorService(serviceId);
      
      if (result['success']) {
        // Remove from local storage
        await _removeLocalService(serviceId);
      }
      
      return result;
    } catch (e) {
      // Fallback to local removal
      await _removeLocalService(serviceId);
      return {
        'success': true,
        'message': 'Service deleted successfully (Demo Mode)',
      };
    }
  }

  // Get vendor stats
  Future<Map<String, dynamic>> getVendorStats(String vendorId) async {
    try {
      final result = await _apiService.getVendorStats(vendorId);
      return result;
    } catch (e) {
      // Fallback stats
      return {
        'success': true,
        'data': {
          'followers': 150,
          'following': 75,
          'rating': 4.5,
          'totalRatings': 89,
          'totalServices': 12,
          'totalBookings': 45,
        }
      };
    }
  }

  // Follow/Unfollow vendor
  Future<Map<String, dynamic>> toggleFollowVendor(String vendorId, bool follow) async {
    try {
      final result = follow 
          ? await _apiService.followVendor(vendorId)
          : await _apiService.unfollowVendor(vendorId);
      return result;
    } catch (e) {
      return {
        'success': true,
        'message': follow ? 'Following vendor (Demo Mode)' : 'Unfollowed vendor (Demo Mode)',
      };
    }
  }

  // Private helper methods
  Future<Map<String, dynamic>> _getFallbackProfile(String vendorId) async {
    // Return demo profile data
    return {
      'success': true,
      'data': {
        'vendor': {
          'id': vendorId,
          'businessName': 'Demo Business',
          'ownerName': 'Demo Owner',
          'bio': 'This is a demo vendor profile for testing purposes.',
          'category': 'Home Services',
          'profileImage': null,
          'address': 'Demo Address',
          'city': 'Demo City',
          'pincode': '123456',
          'rating': 4.5,
          'totalRatings': 89,
          'isVerified': true,
        }
      }
    };
  }

  Future<void> _updateLocalProfile(Map<String, dynamic> vendorData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vendor_profile', jsonEncode(vendorData));
  }

  Future<Map<String, dynamic>> _getLocalServices() async {
    final prefs = await SharedPreferences.getInstance();
    final servicesJson = prefs.getString(_servicesKey);
    
    if (servicesJson != null) {
      final services = jsonDecode(servicesJson) as List;
      return {
        'success': true,
        'data': {'services': services}
      };
    }
    
    // Return sample services
    final sampleServices = _createSampleServices();
    await prefs.setString(_servicesKey, jsonEncode(sampleServices));
    
    return {
      'success': true,
      'data': {'services': sampleServices}
    };
  }

  Future<void> _addLocalService(Map<String, dynamic> service) async {
    final prefs = await SharedPreferences.getInstance();
    final servicesJson = prefs.getString(_servicesKey);
    List<dynamic> services = [];
    
    if (servicesJson != null) {
      services = jsonDecode(servicesJson) as List;
    }
    
    services.add(service);
    await prefs.setString(_servicesKey, jsonEncode(services));
  }

  Future<Map<String, dynamic>> _addLocalServiceFallback({
    required String title,
    required String description,
    required double price,
    required String category,
    List<String>? images,
    String? duration,
    bool isAvailable = true,
  }) async {
    final service = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'images': images ?? [],
      'duration': duration ?? '1 hour',
      'isAvailable': isAvailable,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    await _addLocalService(service);
    
    return {
      'success': true,
      'message': 'Service added successfully (Demo Mode)',
      'data': {'service': service}
    };
  }

  Future<void> _updateLocalService(Map<String, dynamic> updatedService) async {
    final prefs = await SharedPreferences.getInstance();
    final servicesJson = prefs.getString(_servicesKey);
    
    if (servicesJson != null) {
      List<dynamic> services = jsonDecode(servicesJson) as List;
      final index = services.indexWhere((s) => s['id'] == updatedService['id']);
      
      if (index != -1) {
        services[index] = updatedService;
        await prefs.setString(_servicesKey, jsonEncode(services));
      }
    }
  }

  Future<void> _removeLocalService(String serviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final servicesJson = prefs.getString(_servicesKey);
    
    if (servicesJson != null) {
      List<dynamic> services = jsonDecode(servicesJson) as List;
      services.removeWhere((s) => s['id'] == serviceId);
      await prefs.setString(_servicesKey, jsonEncode(services));
    }
  }

  List<Map<String, dynamic>> _createSampleServices() {
    return [
      {
        'id': '1',
        'title': 'Home Cleaning',
        'description': 'Complete home cleaning service including all rooms',
        'price': 500.0,
        'category': 'Cleaning',
        'images': [],
        'duration': '2-3 hours',
        'isAvailable': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '2',
        'title': 'AC Repair',
        'description': 'Professional AC repair and maintenance service',
        'price': 800.0,
        'category': 'Repair',
        'images': [],
        'duration': '1-2 hours',
        'isAvailable': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': '3',
        'title': 'Plumbing Service',
        'description': 'All types of plumbing work and pipe repairs',
        'price': 600.0,
        'category': 'Plumbing',
        'images': [],
        'duration': '1-3 hours',
        'isAvailable': true,
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];
  }
}