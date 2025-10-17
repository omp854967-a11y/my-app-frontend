import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../../services/vendor_service.dart';
import 'followers_page.dart';
import 'following_page.dart';
import '../settings/vendor_settings_page.dart';
import '../home/home_screen.dart';
import 'rating_reviews_page.dart';

class NewVendorProfilePage extends StatefulWidget {
  const NewVendorProfilePage({super.key});

  @override
  State<NewVendorProfilePage> createState() => _NewVendorProfilePageState();
}

class _NewVendorProfilePageState extends State<NewVendorProfilePage> {
  final VendorService _vendorService = VendorService();
  Uint8List? _avatarBytes;
  String _businessName = 'My Business';
  String _bio = 'Welcome to my business profile!';
  String? _vendorId;
  bool _saving = false;
  bool _loading = true;
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  int _selectedTabIndex = 0;
  int _selectedPostCategory = 0;
  double _rating = 4.5;
  int _ratingCount = 127;
  bool _isFollowing = false;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeVendorProfile();
  }

  Future<void> _initializeVendorProfile() async {
    _vendorId = 'vendor123'; // Simplified vendor ID
    await _loadVendorData();
    await _loadServices();
    await _loadPosts();
    await _loadFollowersAndFollowing();
    
    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadVendorData() async {
    if (_vendorId == null) return;
    
    try {
      final result = await _vendorService.getVendorProfile(_vendorId!);
      
      if (result['success']) {
        final vendorData = result['data']['vendor'];
        
        setState(() {
          _businessName = vendorData['businessName'] ?? _businessName;
          _bio = vendorData['bio'] ?? _bio;
          _rating = (vendorData['rating'] ?? _rating).toDouble();
          _ratingCount = vendorData['totalRatings'] ?? _ratingCount;
          
          // Handle profile image
          if (vendorData['profileImage'] != null) {
            try {
              _avatarBytes = base64Decode(vendorData['profileImage']);
            } catch (e) {
              print('Error decoding profile image: $e');
            }
          }
        });
      }
    } catch (e) {
      print('Error loading vendor data: $e');
      // Fallback to local data
      await _loadLocalVendorData();
    } catch (e) {
      print('Error loading vendor data: $e');
      // Fallback to local data
      await _loadLocalVendorData();
    }
  }

  Future<void> _pickAvatar() async {
    // For now, just show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avatar picker feature coming soon!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadLocalVendorData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // First try to load from signup data
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        if (userData['name'] != null && userData['name'].isNotEmpty) {
          _businessName = userData['name'];
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
    
    // Then load custom vendor data
    final businessName = prefs.getString('vendor_business_name');
    final bio = prefs.getString('vendor_bio');
    final avatarBase64 = prefs.getString('vendor_avatar');
    final rating = prefs.getDouble('vendor_rating');
    final ratingCount = prefs.getInt('vendor_rating_count');
    
    setState(() {
      if (businessName != null && businessName.isNotEmpty) _businessName = businessName;
      if (bio != null && bio.isNotEmpty) _bio = bio;
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        _avatarBytes = base64Decode(avatarBase64);
      }
      if (rating != null) _rating = rating;
      if (ratingCount != null) _ratingCount = ratingCount;
    });
  }

  Future<void> _loadServices() async {
    if (_vendorId == null) return;
    
    try {
      final result = await _vendorService.getVendorServices(_vendorId!);
      
      if (result['success']) {
        setState(() {
          _services = List<Map<String, dynamic>>.from(result['data']['services']);
        });
      }
    } catch (e) {
      print('Error loading services: $e');
      // Fallback to local services
      await _loadLocalServices();
    }
  }

  Future<void> _loadLocalServices() async {
    final prefs = await SharedPreferences.getInstance();
    final servicesJson = prefs.getStringList('vendor_services') ?? [];
    
    if (servicesJson.isEmpty) {
      await _createSampleServices();
      final updatedServicesJson = prefs.getStringList('vendor_services') ?? [];
      setState(() {
        _services = updatedServicesJson.map((serviceJson) {
          return Map<String, dynamic>.from(jsonDecode(serviceJson));
        }).toList();
      });
    } else {
      setState(() {
        _services = servicesJson.map((serviceJson) {
          return Map<String, dynamic>.from(jsonDecode(serviceJson));
        }).toList();
      });
    }
  }

  Future<void> _createSampleServices() async {
    final sampleServices = [
      {
        'id': '1',
        'name': 'Premium Consultation',
        'description': 'One-on-one consultation with expert guidance',
        'price': '₹3000',
        'duration': '1 hour',
        'timing': '9:00 AM - 6:00 PM',
        'category': 'Consultation',
        'isActive': true,
      },
      {
        'id': '2',
        'name': 'Custom Solution',
        'description': 'Tailored solutions for your specific needs',
        'price': '₹8000',
        'duration': '3-4 hours',
        'timing': '10:00 AM - 5:00 PM',
        'category': 'Development',
        'isActive': true,
      },
      {
        'id': '3',
        'name': 'Training Workshop',
        'description': 'Comprehensive training sessions',
        'price': '₹2000',
        'duration': '2 hours',
        'timing': '2:00 PM - 8:00 PM',
        'category': 'Education',
        'isActive': true,
      },
    ];

    final prefs = await SharedPreferences.getInstance();
    final servicesJson = sampleServices.map((service) => jsonEncode(service)).toList();
    await prefs.setStringList('vendor_services', servicesJson);
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = prefs.getStringList('vendor_posts') ?? [];
    
    setState(() {
      _posts = postsJson.map((postJson) {
        return Map<String, dynamic>.from(jsonDecode(postJson));
      }).toList();
      
      _posts.sort((a, b) => 
        DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp']))
      );
    });
  }

  Future<void> _loadFollowersAndFollowing() async {
    final prefs = await SharedPreferences.getInstance();
    
    final followersJson = prefs.getStringList('vendor_followers') ?? [];
    if (followersJson.isEmpty) {
      await _createSampleFollowers();
      final updatedFollowersJson = prefs.getStringList('vendor_followers') ?? [];
      setState(() {
        _followers = updatedFollowersJson.map((followerJson) {
          return Map<String, dynamic>.from(jsonDecode(followerJson));
        }).toList();
      });
    } else {
      setState(() {
        _followers = followersJson.map((followerJson) {
          return Map<String, dynamic>.from(jsonDecode(followerJson));
        }).toList();
      });
    }
    
    final followingJson = prefs.getStringList('vendor_following') ?? [];
    if (followingJson.isEmpty) {
      await _createSampleFollowing();
      final updatedFollowingJson = prefs.getStringList('vendor_following') ?? [];
      setState(() {
        _following = updatedFollowingJson.map((followingJson) {
          return Map<String, dynamic>.from(jsonDecode(followingJson));
        }).toList();
      });
    } else {
      setState(() {
        _following = followingJson.map((followingJson) {
          return Map<String, dynamic>.from(jsonDecode(followingJson));
        }).toList();
      });
    }
  }

  Future<void> _createSampleFollowers() async {
    final sampleFollowers = [
      {
        'id': '1',
        'name': 'Rahul Sharma',
        'username': '@rahul_tech',
        'avatar': '👨‍💻',
        'isVerified': true,
        'followedAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'id': '2',
        'name': 'Priya Singh',
        'username': '@priya_design',
        'avatar': '👩‍🎨',
        'isVerified': false,
        'followedAt': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
      },
    ];

    final prefs = await SharedPreferences.getInstance();
    final followersJson = sampleFollowers.map((follower) => jsonEncode(follower)).toList();
    await prefs.setStringList('vendor_followers', followersJson);
  }

  Future<void> _createSampleFollowing() async {
    final sampleFollowing = [
      {
        'id': '1',
        'name': 'Tech Hub',
        'username': '@tech_hub_official',
        'avatar': '🏢',
        'isVerified': true,
        'followedAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      },
    ];

    final prefs = await SharedPreferences.getInstance();
    final followingJson = sampleFollowing.map((following) => jsonEncode(following)).toList();
    await prefs.setStringList('vendor_following', followingJson);
  }

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    
    setState(() {
      _followLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));
      
      setState(() {
        _isFollowing = !_isFollowing;
        if (_isFollowing) {
          // Add to followers count (simulate)
          _followers.add({
            'id': 'current_user',
            'name': 'Current User',
            'avatar': null,
          });
        } else {
          // Remove from followers count (simulate)
          _followers.removeWhere((follower) => follower['id'] == 'current_user');
        }
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFollowing ? 'Following vendor!' : 'Unfollowed vendor'),
          backgroundColor: _isFollowing ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _followLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VendorSettingsPage()),
                  );
              // Refresh data when returning from settings
              if (result == true || result == null) {
                await _loadLocalVendorData();
              }
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🌈 Gradient Header (User Profile Style)
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)], // User profile colors
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Blookit Logo (same as user profile)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF5F6D), // Pink from gradient
                          Color(0xFFFFC371), // Orange from gradient
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'b',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Profile Picture positioned at bottom center with 56px offset
            Transform.translate(
              offset: const Offset(0, -56),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55, // 110px diameter (55px radius)
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _avatarBytes != null
                          ? MemoryImage(_avatarBytes!)
                          : null,
                      backgroundColor: const Color(0xFFFF6B35),
                      child: _avatarBytes == null
                          ? const Icon(Icons.business, color: Colors.white, size: 40)
                          : null,
                    ),
                  ),
                  // Edit button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B35),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 90), // Increased spacing after profile picture

            // Business Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Business Name
                  Text(
                    _businessName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12), // Increased spacing after business name
                  
                  // Bio
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      _bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16, 
                        color: Colors.black54,
                        height: 1.4,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24), // Increased spacing after bio

                  // Rating Section
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RatingReviewsPage(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < _rating.floor() ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 18,
                              );
                            }),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_rating ($_ratingCount reviews)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28), // Increased spacing before action buttons

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Follow/Following Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing ? Colors.grey[600] : const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: _followLoading ? null : _toggleFollow,
                        child: _followLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(_isFollowing ? "Following" : "Follow"),
                      ),
                      const SizedBox(width: 16),
                      
                      // Message Button
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: const BorderSide(color: Color(0xFF667eea)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
                          notificationProvider.addNotification(
                            NotificationModel(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              userId: 'vendor',
                              username: _businessName,
                              userProfileImage: null,
                              type: NotificationType.message,
                              actionText: 'sent you a message',
                              timestamp: DateTime.now(),
                            ),
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Message sent to vendor!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text(
                          "Message",
                          style: TextStyle(color: Color(0xFF667eea)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36), // Increased spacing before stats

                  // Stats Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem('Followers', _followers.length.toString()),
                        _buildStatDivider(),
                        _buildStatItem('Following', _following.length.toString()),
                        _buildStatDivider(),
                        _buildStatItem('Rating', _rating.toStringAsFixed(1)),
                        _buildStatDivider(),
                        _buildStatItem('Posts', _posts.length.toString()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36), // Increased spacing after stats

                  // Navigation Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton('My Service', 0),
                        _buildTabButton('Post', 1),
                        _buildTabButton('About', 2),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28), // Increased spacing after tabs

                  // Tab Content
                  _buildTabContent(),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return GestureDetector(
      onTap: () {
        if (label == 'Followers') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FollowersPage(),
            ),
          );
        } else if (label == 'Following') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FollowingPage(),
            ),
          );
        }
      },
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF6B35) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // Services
        return _buildServicesContent();
      case 1: // Posts
        return _buildPostsContent();
      case 2: // About
        return _buildAboutContent();
      default:
        return _buildServicesContent();
    }
  }

  Widget _buildServicesContent() {
    if (_services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No services yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first service to get started!',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Services Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Our Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        
        // Services List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _services.length,
          itemBuilder: (context, index) {
            final service = _services[index];
            return _buildServiceCard(service, index);
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B35),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.business_center,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      service['category'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: service['isActive'] == true ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service['isActive'] == true ? 'Active' : 'Inactive',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Service Description
          Text(
            service['description'] ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Service Details with Pay button on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                fit: FlexFit.tight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      service['price'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                fit: FlexFit.tight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timing',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      service['timing'] ?? service['duration'] ?? '1-2 hours',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment initiated for ${service['name']}'),
                      backgroundColor: const Color(0xFFFF6B35),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.payment, size: 18),
                label: const Text(
                  'Pay',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Removed full-width Pay button; placed Pay button on right in details row
        ],
      ),
    );
  }

  Widget _buildPostsContent() {
    if (_posts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.post_add_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your first post to get started!',
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildPostCard(post);
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF667eea).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: _avatarBytes != null
                    ? MemoryImage(_avatarBytes!)
                    : null,
                backgroundColor: const Color(0xFF667eea),
                child: _avatarBytes == null
                    ? const Icon(Icons.business, color: Colors.white, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _businessName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      post['type']?.toString().toUpperCase() ?? 'POST',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF667eea),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Post Content
          if (post['caption'] != null && post['caption'].isNotEmpty) ...[
            Text(
              post['caption'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Post Actions
          Row(
            children: [
              _buildPostAction(Icons.favorite_border, post['likes']?.toString() ?? '0'),
              const SizedBox(width: 20),
              _buildPostAction(Icons.chat_bubble_outline, post['comments']?.toString() ?? '0'),
              const SizedBox(width: 20),
              _buildPostAction(Icons.share_outlined, '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Business',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Business Name', _businessName),
          _buildInfoRow('Description', _bio),
          _buildInfoRow('Rating', '$_rating ($_ratingCount reviews)'),
          _buildInfoRow('Total Services', _services.length.toString()),
          _buildInfoRow('Total Posts', _posts.length.toString()),
          
          const SizedBox(height: 20),
          
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow('Email', 'business@example.com'),
          _buildInfoRow('Phone', '+91 98765 43210'),
          _buildInfoRow('Location', 'Mumbai, India'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return GestureDetector(
      onTap: () {
        if (label == 'Followers') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FollowersPage(),
            ),
          );
        } else if (label == 'Following') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FollowingPage(),
            ),
          );
        } else if (label == 'Rating') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RatingReviewsPage(),
            ),
          );
        }
      },
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[300],
    );
  }

  Future<void> _editBusinessName() async {
    final controller = TextEditingController(text: _businessName);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Business Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLength: 50,
                decoration: const InputDecoration(
                  hintText: 'Enter your business name',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final newName = controller.text.trim();
                      if (newName.isNotEmpty) {
                        setState(() => _businessName = newName);
                        
                        // Save locally
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('vendor_business_name', newName);
                        
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Business name updated successfully!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editBio() async {
    final controller = TextEditingController(text: _bio);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Bio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLength: 150,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tell people about your business...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final newBio = controller.text.trim();
                      if (newBio.isNotEmpty) {
                        setState(() => _bio = newBio);
                        
                        // Save locally
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('vendor_bio', newBio);
                        
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bio updated successfully!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}