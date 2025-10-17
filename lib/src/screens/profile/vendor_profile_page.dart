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
import '../settings/settings_page.dart';
import '../home/home_screen.dart';

class VendorProfilePage extends StatefulWidget {
  const VendorProfilePage({super.key});

  @override
  State<VendorProfilePage> createState() => _VendorProfilePageState();
}

class _VendorProfilePageState extends State<VendorProfilePage> {
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
    }
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
        'name': 'Fine Dining Experience',
        'description': 'Premium multi-course dining with wine pairing',
        'price': '₹2500',
        'duration': '2-3 hours',
        'category': 'Dining',
        'isActive': true,
      },
      {
        'id': '2',
        'name': 'Private Chef Service',
        'description': 'Personal chef for special occasions',
        'price': '₹5000',
        'duration': '4-5 hours',
        'category': 'Catering',
        'isActive': true,
      },
      {
        'id': '3',
        'name': 'Cooking Classes',
        'description': 'Learn authentic recipes from expert chefs',
        'price': '₹1500',
        'duration': '2 hours',
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
        'name': 'John Smith',
        'username': '@john_foodie',
        'avatar': '👨',
        'isVerified': true,
        'followedAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': '2',
        'name': 'Sarah Wilson',
        'username': '@sarah_chef',
        'avatar': '👩‍🍳',
        'isVerified': false,
        'followedAt': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
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
        'name': 'Food Network',
        'username': '@food_network_official',
        'avatar': '📺',
        'isVerified': true,
        'followedAt': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      },
    ];

    final prefs = await SharedPreferences.getInstance();
    final followingJson = sampleFollowing.map((following) => jsonEncode(following)).toList();
    await prefs.setStringList('vendor_following', followingJson);
  }

  Future<void> _pickAvatar() async {
    if (_vendorId == null) return;
    
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery, 
        maxWidth: 1024, 
        maxHeight: 1024,
        imageQuality: 85
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        setState(() => _saving = true);
        
        // Update via backend service
        final result = await _vendorService.updateVendorProfile(
          vendorId: _vendorId!,
          profileImage: base64Image,
        );
        
        setState(() => _saving = false);
        
        if (result['success']) {
          setState(() => _avatarBytes = bytes);
          
          // Also save locally as backup
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('vendor_avatar', base64Image);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to update profile picture'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
                      if (newName.isNotEmpty && _vendorId != null) {
                        setState(() => _saving = true);
                        
                        try {
                          // Update via backend service
                          final result = await _vendorService.updateVendorProfile(
                            vendorId: _vendorId!,
                            businessName: newName,
                          );
                          
                          setState(() => _saving = false);
                          
                          if (result['success']) {
                            setState(() => _businessName = newName);
                            
                            // Also save locally as backup
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
                          } else {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? 'Failed to update business name'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          setState(() => _saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating business name: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
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
                      if (newBio.isNotEmpty && _vendorId != null) {
                        setState(() => _saving = true);
                        
                        try {
                          // Update via backend service
                          final result = await _vendorService.updateVendorProfile(
                            vendorId: _vendorId!,
                            bio: newBio,
                          );
                          
                          setState(() => _saving = false);
                          
                          if (result['success']) {
                            setState(() => _bio = newBio);
                            
                            // Also save locally as backup
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
                          } else {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? 'Failed to update bio'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          setState(() => _saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating bio: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🌈 Gradient Header (220px) - User Profile Colors
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)], // User profile gradient (Pink to Orange)
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Blookit Logo (120x120) - Larger and more prominent
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF5F6D),
                          Color(0xFFFFC371),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'b',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Blookit Text
                  const Text(
                    'blookit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // Profile image removed as requested
            const SizedBox(height: 20),

            // Profile Information
            Transform.translate(
              offset: const Offset(0, -30),
              child: Column(
                children: [
                  // Business Name
                  Text(
                    _businessName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Bio
                  Text(
                    _bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),

                  const SizedBox(height: 12),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Follow/Following Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFollowing ? Colors.grey[600] : const Color(0xFFFF69B4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                      const SizedBox(width: 12),
                      
                      // Message Button
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          side: const BorderSide(color: Color(0xFFFF69B4)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                              actionText: 'received a message',
                              targetId: 'chat:vendor',
                              timestamp: DateTime.now(),
                              isRead: false,
                            ),
                          );
                          
                          Navigator.pushNamed(context, '/messages');
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening messages...'),
                              backgroundColor: Colors.blue,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Icon(Icons.message_outlined, color: Color(0xFFFF69B4)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 📊 Stats Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatItem(
                          label: "Follow", 
                          value: "0",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FollowersPage()),
                            );
                          },
                        ),
                        _StatItem(
                          label: "Following", 
                          value: "0",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FollowingPage()),
                            );
                          },
                        ),
                        _StatItem(
                          label: "Rating", 
                          value: _rating.toString(),
                          subtitle: "($_ratingCount reviews)",
                          onTap: () {
                            _showRatingPage();
                          },
                        ),
                        _StatItem(
                          label: "Posts", 
                          value: "${_posts.length}",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 📁 Navigation Tabs
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _TabItem(
                          title: "My Service", 
                          active: _selectedTabIndex == 0,
                          onTap: () => setState(() => _selectedTabIndex = 0),
                        ),
                        _TabItem(
                          title: "Posts",
                          active: _selectedTabIndex == 1,
                          onTap: () => setState(() => _selectedTabIndex = 1),
                        ),
                        _TabItem(
                          title: "About",
                          active: _selectedTabIndex == 2,
                          onTap: () => setState(() => _selectedTabIndex = 2),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

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

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // My Service
        return _buildMyServiceContent();
      case 1: // Posts
        return _buildPostsContent();
      case 2: // About
        return _buildAboutContent();
      default:
        return _buildMyServiceContent();
    }
  }

  Widget _buildMyServiceContent() {
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
        // Service Flowchart Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Service Flowchart',
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
        border: Border.all(color: const Color(0xFFFF69B4).withOpacity(0.3)),
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
          // Service Header with Step Number
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF69B4),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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
                        color: Color(0xFFFF69B4),
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
                      'Duration',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      service['duration'] ?? '',
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
                      content: Text('Payment initiated for ${service['name'] ?? 'Service'}'),
                      backgroundColor: const Color(0xFFFF69B4),
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
                  backgroundColor: const Color(0xFFFF69B4),
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
          
          // Arrow to next step (except for last item)
          if (index < _services.length - 1)
            Container(
              margin: const EdgeInsets.only(top: 16),
              child: const Center(
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFFFF69B4),
                  size: 24,
                ),
              ),
            ),
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

    // Separate posts by type
    final textPosts = _posts.where((post) => post['type'] == 'text').toList();
    final videoPosts = _posts.where((post) => post['type'] == 'video').toList();
    final photoPosts = _posts.where((post) => post['type'] == 'photo').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Tabs
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPostCategoryTab('All Posts', 0, _posts.length),
                const SizedBox(width: 12),
                _buildPostCategoryTab('Text', 1, textPosts.length),
                const SizedBox(width: 12),
                _buildPostCategoryTab('Video', 2, videoPosts.length),
                const SizedBox(width: 12),
                _buildPostCategoryTab('Photo', 3, photoPosts.length),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Posts Content based on selected category
        _buildPostCategoryContent(textPosts, videoPosts, photoPosts),
      ],
    );
  }

  Widget _buildPostCategoryTab(String title, int index, int count) {
    final isSelected = _selectedPostCategory == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPostCategory = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF69B4) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF69B4) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCategoryContent(List<Map<String, dynamic>> textPosts, 
                                   List<Map<String, dynamic>> videoPosts, 
                                   List<Map<String, dynamic>> photoPosts) {
    switch (_selectedPostCategory) {
      case 0: // All Posts
        return _buildAllPostsGrid();
      case 1: // Text Posts
        return _buildVerticalPostsList(textPosts, 'text');
      case 2: // Video Posts
        return _buildVerticalPostsList(videoPosts, 'video');
      case 3: // Photo Posts
        return _buildVerticalPostsList(photoPosts, 'photo');
      default:
        return _buildAllPostsGrid();
    }
  }

  Widget _buildAllPostsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return _buildPostGridItem(post);
      },
    );
  }

  Widget _buildVerticalPostsList(List<Map<String, dynamic>> posts, String type) {
    if (posts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              type == 'text' ? Icons.text_fields : 
              type == 'video' ? Icons.videocam : Icons.photo,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type} posts yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildPostListItem(post);
      },
    );
  }

  Widget _buildPostGridItem(Map<String, dynamic> post) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF69B4).withOpacity(0.2)),
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
          // Post Type Icon
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Icon(
                  post['type'] == 'text' ? Icons.text_fields :
                  post['type'] == 'video' ? Icons.videocam : Icons.photo,
                  color: const Color(0xFFFF69B4),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  post['type']?.toString().toUpperCase() ?? '',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF69B4),
                  ),
                ),
              ],
            ),
          ),
          
          // Content Preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                post['content'] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // Timestamp
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              _formatTimestamp(post['timestamp']),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostListItem(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF69B4).withOpacity(0.2)),
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
          // Post Header with vendor info
          Row(
            children: [
              // Vendor Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFFF69B4),
                child: Text(
                  _businessName.isNotEmpty ? _businessName[0].toUpperCase() : 'V',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Vendor name and post type
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
                    Row(
                      children: [
                        Icon(
                          post['type'] == 'text' ? Icons.text_fields :
                          post['type'] == 'video' ? Icons.videocam : Icons.photo,
                          color: const Color(0xFFFF69B4),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post['type']?.toString().toUpperCase() ?? '',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF69B4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Timestamp
              Text(
                _formatTimestamp(post['timestamp']),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Post Content
          if (post['content'] != null && post['content'].isNotEmpty) ...[
            Text(
              post['content'],
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Media Content (if any)
          if (post['type'] == 'photo' || post['type'] == 'video') ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: post['type'] == 'video'
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            color: Colors.black12,
                            child: const Icon(
                              Icons.videocam,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Video',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.photo, color: Colors.grey, size: 48),
                        ),
                      ),
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
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                onPressed: () => _showPostOptions(post),
              ),
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

  void _showPostOptions(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFFFF69B4)),
              title: const Text('Edit Post'),
              onTap: () {
                Navigator.pop(context);
                // Add edit functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Post'),
              onTap: () {
                Navigator.pop(context);
                // Add delete functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutContent() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Our Business',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _bio,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Business Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          _buildAboutItem('Established', '2020'),
          _buildAboutItem('Category', 'Restaurant & Catering'),
          _buildAboutItem('Location', 'Mumbai, India'),
          _buildAboutItem('Contact', '+91 98765 43210'),
          _buildAboutItem('Email', 'info@deliciousbites.com'),
        ],
      ),
    );
  }

  Widget _buildAboutItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
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

  void _showRatingPage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Customer Reviews & Ratings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Rating Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _rating.toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF69B4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < _rating.floor() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 24,
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_ratingCount reviews',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Reviews List
            Expanded(
              child: _buildVendorReviewsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorReviewsList() {
    // Sample reviews data
    final reviews = [
      {
        'customerName': 'Priya Sharma',
        'customerImage': 'https://images.unsplash.com/photo-1494790108755-2616b612b786',
        'rating': 5,
        'date': '2024-01-15',
        'service': 'Wedding Photography',
        'comment': 'Amazing service! The photos turned out absolutely beautiful. Highly professional and creative work.',
        'helpful': 12,
      },
      {
        'customerName': 'Rahul Kumar',
        'customerImage': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
        'rating': 4,
        'date': '2024-01-10',
        'service': 'Birthday Party Catering',
        'comment': 'Great food quality and timely service. The presentation was excellent. Will definitely book again.',
        'helpful': 8,
      },
      {
        'customerName': 'Anjali Patel',
        'customerImage': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
        'rating': 5,
        'date': '2024-01-08',
        'service': 'Home Cleaning',
        'comment': 'Very thorough cleaning service. The team was punctual and professional. House looks spotless!',
        'helpful': 15,
      },
      {
        'customerName': 'Vikash Singh',
        'customerImage': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e',
        'rating': 4,
        'date': '2024-01-05',
        'service': 'AC Repair',
        'comment': 'Quick and efficient repair work. Fair pricing and good customer service. Recommended!',
        'helpful': 6,
      },
    ];

    return ListView.builder(
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
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
              // Customer Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(review['customerImage'] as String),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['customerName'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          review['date'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rating Stars
                  Row(
                    children: List.generate(5, (starIndex) {
                      return Icon(
                        starIndex < (review['rating'] as int) ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Service Name
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 105, 105).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  review['service'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 255, 115, 105),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Review Comment
              Text(
                review['comment'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              
              // Helpful Count
              Row(
                children: [
                  Icon(
                    Icons.thumb_up_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${review['helpful']} found this helpful',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}

// 🧩 Reusable Widget for Stats
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  const _StatItem({
    required this.label, 
    required this.value, 
    this.subtitle,
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

// 🧩 Reusable Widget for Tabs
class _TabItem extends StatelessWidget {
  final String title;
  final bool active;
  final VoidCallback? onTap;

  const _TabItem({required this.title, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? const Color(0xFFFF69B4) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? const Color(0xFFFF69B4) : Colors.grey[600],
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}