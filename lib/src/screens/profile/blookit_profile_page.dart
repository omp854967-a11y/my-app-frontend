import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'followers_page.dart';
import 'following_page.dart';
import '../settings/settings_page.dart';
import '../home/home_screen.dart';

class BlookitProfilePage extends StatefulWidget {
  const BlookitProfilePage({super.key});

  @override
  State<BlookitProfilePage> createState() => _BlookitProfilePageState();
}

class _BlookitProfilePageState extends State<BlookitProfilePage> {
  bool _isFollowing = false;
  Uint8List? _avatarBytes;
  String _bio = 'Welcome to my profile!';
  String _fullName = 'User';
  String _username = '@user';
  bool _saving = false;
  List<Map<String, dynamic>> _userPosts = [];
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];
  int _selectedTabIndex = 0;
  int _selectedPostCategory = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadUserPosts();
    _loadFollowersAndFollowing();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // First try to load from AuthService user data
    final userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString);
        setState(() {
          // Load name from signup data
          if (userData['name'] != null && userData['name'].isNotEmpty) {
            _fullName = userData['name'];
          }
          // Generate username from name if not set
          if (userData['name'] != null) {
            final nameParts = userData['name'].toString().toLowerCase().split(' ');
            _username = '@${nameParts.join('_')}';
          }
          // Set default bio
          _bio = 'Welcome to my profile!';
        });
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
    
    // Then load any custom profile settings that override the defaults
    final bio = prefs.getString('profile_bio');
    final fullName = prefs.getString('profile_fullname');
    final username = prefs.getString('profile_username');
    final avatarBase64 = prefs.getString('profile_avatar');
    
    setState(() {
      if (bio != null && bio.isNotEmpty) _bio = bio;
      if (fullName != null && fullName.isNotEmpty) _fullName = fullName;
      if (username != null && username.isNotEmpty) _username = username;
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        _avatarBytes = base64Decode(avatarBase64);
      }
    });
  }

  Future<void> _loadUserPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = prefs.getStringList('user_posts') ?? [];
    
    setState(() {
      _userPosts = postsJson.map((postJson) {
        return Map<String, dynamic>.from(jsonDecode(postJson));
      }).toList();
      
      // Sort by timestamp (newest first)
      _userPosts.sort((a, b) => 
        DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp']))
      );
    });
  }

  Future<void> _loadFollowersAndFollowing() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load followers
    final followersJson = prefs.getStringList('followers') ?? [];
    if (followersJson.isEmpty) {
      // Create sample followers if none exist
      await _createSampleFollowers();
      final updatedFollowersJson = prefs.getStringList('followers') ?? [];
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
    
    // Load following
    final followingJson = prefs.getStringList('following') ?? [];
    if (followingJson.isEmpty) {
      // Create sample following if none exist
      await _createSampleFollowing();
      final updatedFollowingJson = prefs.getStringList('following') ?? [];
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
        'name': 'Priya Sharma',
        'username': '@priya_sharma',
        'avatar': '👩‍💼',
        'isVerified': true,
        'followedAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      },
      {
        'id': '2',
        'name': 'Rahul Kumar',
        'username': '@rahul_dev',
        'avatar': '👨‍💻',
        'isVerified': false,
        'followedAt': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
      },
      {
        'id': '3',
        'name': 'Anita Singh',
        'username': '@anita_design',
        'avatar': '👩‍🎨',
        'isVerified': true,
        'followedAt': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      },
      {
        'id': '4',
        'name': 'Vikash Gupta',
        'username': '@vikash_photo',
        'avatar': '📸',
        'isVerified': false,
        'followedAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      },
      {
        'id': '5',
        'name': 'Sneha Patel',
        'username': '@sneha_travel',
        'avatar': '✈️',
        'isVerified': true,
        'followedAt': DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
      },
    ];

    final prefs = await SharedPreferences.getInstance();
    final followersJson = sampleFollowers.map((follower) => jsonEncode(follower)).toList();
    await prefs.setStringList('followers', followersJson);
  }

  Future<void> _createSampleFollowing() async {
    final sampleFollowing = [
      {
        'id': '1',
        'name': 'Tech Guru',
        'username': '@tech_guru_official',
        'avatar': '💻',
        'isVerified': true,
        'followedAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'bio': 'Latest tech news and reviews',
      },
      {
        'id': '2',
        'name': 'Food Blogger',
        'username': '@foodie_adventures',
        'avatar': '🍕',
        'isVerified': false,
        'followedAt': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
        'bio': 'Exploring delicious food around the world',
      },
      {
        'id': '3',
        'name': 'Travel Diaries',
        'username': '@travel_diaries',
        'avatar': '🌍',
        'isVerified': true,
        'followedAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        'bio': 'Beautiful destinations and travel tips',
      },
      {
        'id': '4',
        'name': 'Fitness Coach',
        'username': '@fitness_coach_raj',
        'avatar': '💪',
        'isVerified': false,
        'followedAt': DateTime.now().subtract(const Duration(days: 25)).toIso8601String(),
        'bio': 'Your daily dose of fitness motivation',
      },
      {
        'id': '5',
        'name': 'Art Studio',
        'username': '@creative_art_studio',
        'avatar': '🎨',
        'isVerified': true,
        'followedAt': DateTime.now().subtract(const Duration(days: 35)).toIso8601String(),
        'bio': 'Digital art and creative inspiration',
      },
      {
        'id': '6',
        'name': 'Music Lover',
        'username': '@music_beats_daily',
        'avatar': '🎵',
        'isVerified': false,
        'followedAt': DateTime.now().subtract(const Duration(days: 42)).toIso8601String(),
        'bio': 'Latest music trends and playlists',
      },
    ];

    final prefs = await SharedPreferences.getInstance();
    final followingJson = sampleFollowing.map((following) => jsonEncode(following)).toList();
    await prefs.setStringList('following', followingJson);
  }

  Future<void> _pickAvatar() async {
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
        setState(() => _avatarBytes = bytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_avatar', base64Encode(bytes));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
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

  Future<void> _editFullName() async {
    final controller = TextEditingController(text: _fullName);
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
              const Text('Edit Full Name', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLength: 50,
                decoration: const InputDecoration(
                  hintText: 'Enter your full name',
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
                      if (newName.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name cannot be empty')),
                        );
                        return;
                      }
                      setState(() => _saving = true);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('profile_fullname', newName);
                      setState(() {
                        _fullName = newName;
                        _saving = false;
                      });
                      if (mounted) Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Full name updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
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

  Future<void> _editUsername() async {
    final controller = TextEditingController(text: _username.replaceFirst('@', ''));
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
              const Text('Edit Username', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLength: 30,
                decoration: const InputDecoration(
                  hintText: 'Enter username (without @)',
                  border: OutlineInputBorder(),
                  prefixText: '@',
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
                      final newUsername = controller.text.trim().toLowerCase();
                      if (newUsername.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Username cannot be empty')),
                        );
                        return;
                      }
                      if (!RegExp(r'^[a-z0-9._]+$').hasMatch(newUsername)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Username can only contain letters, numbers, dots and underscores')),
                        );
                        return;
                      }
                      setState(() => _saving = true);
                      final prefs = await SharedPreferences.getInstance();
                      final formattedUsername = '@$newUsername';
                      await prefs.setString('profile_username', formattedUsername);
                      setState(() {
                        _username = formattedUsername;
                        _saving = false;
                      });
                      if (mounted) Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Username updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
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
                maxLines: 3,
                maxLength: 150,
                decoration: const InputDecoration(
                  hintText: 'Tell people about yourself...',
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
                      setState(() => _saving = true);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('profile_bio', newBio);
                      setState(() {
                        _bio = newBio.isEmpty ? 'No bio added yet' : newBio;
                        _saving = false;
                      });
                      if (mounted) Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bio updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
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
            // 🌈 Gradient Header
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFFFF3C8F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Blookit Logo (same as auth and splash screens)
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
              offset: const Offset(0, 56),
              child: CircleAvatar(
                radius: 55, // 110px diameter (55px radius)
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _avatarBytes != null
                      ? MemoryImage(_avatarBytes!)
                      : null,
                  backgroundColor: const Color(0xFFFF6B6B),
                  child: _avatarBytes == null
                      ? const Icon(Icons.person, color: Colors.white, size: 50)
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 76), // Adjusted spacing for profile picture

            // 📝 Name & Username
            Text(
              _fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _username,
              style: const TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              _bio,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),

            const SizedBox(height: 12),

            // 🔘 Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing ? const Color(0xFFFF6B9D) : Colors.white,
                    foregroundColor: _isFollowing ? Colors.white : Colors.black,
                    side: BorderSide(color: _isFollowing ? const Color(0xFFFF6B9D) : Colors.black12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 10),
                  ),
                  onPressed: () {
                    setState(() {
                      _isFollowing = !_isFollowing;
                    });

                    // Add a notification for follow/unfollow action
                    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
                    final actionText = _isFollowing ? 'followed Kate Silver' : 'unfollowed Kate Silver';
                    notificationProvider.addNotification(
                      NotificationModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        userId: 'you',
                        username: 'You',
                        userProfileImage: null,
                        type: NotificationType.follow,
                        actionText: actionText,
                        targetId: 'user:kate_silver',
                        timestamp: DateTime.now(),
                        isRead: false,
                      ),
                    );
                    
                    // Navigate to notifications page to show follow activity
                    Future.delayed(const Duration(milliseconds: 500), () {
                      Navigator.pushNamed(context, '/notifications');
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isFollowing 
                          ? 'Following Kate Silver! Check notifications for updates.' 
                          : 'Unfollowed Kate Silver.'),
                        backgroundColor: _isFollowing ? Colors.green : Colors.orange,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(_isFollowing ? "Following" : "Follow"),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: const BorderSide(color: Colors.black26),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 10),
                  ),
                  onPressed: () {
                    // Add a notification for message action
                    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
                    notificationProvider.addNotification(
                      NotificationModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        userId: 'you',
                        username: 'You',
                        userProfileImage: null,
                        type: NotificationType.message,
                        actionText: 'messaged Kate Silver',
                        targetId: 'chat:kate_silver',
                        timestamp: DateTime.now(),
                        isRead: false,
                      ),
                    );
                    
                    // Navigate to message screen directly
                    Navigator.pushNamed(context, '/messages');
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening messages with Kate Silver...'),
                        backgroundColor: Colors.blue,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Icon(Icons.message_outlined, color: Colors.black87),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 📊 Stats Row (Followers, Following, Posts)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    label: "Followers", 
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
                  _StatItem(label: "Posts", value: "${_userPosts.length}"),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 📁 Navigation Tabs (Posts, Booking History, About)
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
                    title: "Posts", 
                    active: _selectedTabIndex == 0,
                    onTap: () => setState(() => _selectedTabIndex = 0),
                  ),
                  _TabItem(
                    title: "Booking History",
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
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // Posts
        return _buildPostsContent();
      case 1: // Booking History
        return _buildBookingHistoryContent();
      case 2: // About
        return _buildAboutContent();
      default:
        return _buildPostsContent();
    }
  }

  Widget _buildPostsContent() {
    if (_userPosts.isEmpty) {
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
    final textPosts = _userPosts.where((post) => post['hasImage'] != true).toList();
    final photoPosts = _userPosts.where((post) => post['hasImage'] == true && post['isVideo'] != true).toList();
    final videoPosts = _userPosts.where((post) => post['isVideo'] == true).toList();

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
                _buildCategoryTab('All Posts', 0, _userPosts.length),
                const SizedBox(width: 12),
                _buildCategoryTab('Text', 1, textPosts.length),
                const SizedBox(width: 12),
                _buildCategoryTab('Photo', 2, photoPosts.length),
                const SizedBox(width: 12),
                _buildCategoryTab('Video', 3, videoPosts.length),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Posts Content based on selected category
        Expanded(
          child: _buildCategoryContent(textPosts, photoPosts, videoPosts),
        ),
      ],
    );
  }

  Widget _buildCategoryTab(String title, int index, int count) {
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
          color: isSelected ? const Color(0xFFFF6B6B) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF6B6B) : Colors.grey[300]!,
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

  Widget _buildCategoryContent(List<Map<String, dynamic>> textPosts, List<Map<String, dynamic>> photoPosts, List<Map<String, dynamic>> videoPosts) {
    switch (_selectedPostCategory) {
      case 0: // All Posts
        return _buildVerticalPostsList([..._userPosts], 'all');
      case 1: // Text Posts Only
        return _buildVerticalPostsList(textPosts, 'text');
      case 2: // Photo Posts Only
        return _buildVerticalPostsList(photoPosts, 'photo');
      case 3: // Video Posts Only
        return _buildVerticalPostsList(videoPosts, 'video');
      default:
        return Container();
    }
  }

  Widget _buildVerticalPostsList(List<Map<String, dynamic>> posts, String type) {
    if (posts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              type == 'text' ? Icons.text_fields : 
              type == 'video' ? Icons.videocam : 
              type == 'photo' ? Icons.photo : Icons.post_add_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'all' ? 'No posts yet' : 'No ${type} posts yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
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
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildVerticalPostCard(post);
      },
    );
  }

  Widget _buildVerticalPostCard(Map<String, dynamic> post) {
    final postType = post['hasImage'] == true ? 
                    (post['isVideo'] == true ? 'video' : 'photo') : 'text';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.2)),
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
          // Post Header with user info and type
          Row(
            children: [
              // User Avatar
              CircleAvatar(
                radius: 20,
                backgroundImage: _avatarBytes != null
                    ? MemoryImage(_avatarBytes!)
                    : null,
                backgroundColor: const Color(0xFFFF6B6B),
                child: _avatarBytes == null
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              // User name and post type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          postType == 'text' ? Icons.text_fields :
                          postType == 'video' ? Icons.videocam : Icons.photo,
                          color: const Color(0xFFFF6B6B),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          postType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF6B6B),
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
          
          // Media Content (if any)
          if (post['hasImage'] == true && post['imageData'] != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: post['isWeb'] == true
                  ? Image.memory(
                      base64Decode(post['imageData']),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.error, color: Colors.grey),
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.grey, size: 48),
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
              leading: const Icon(Icons.edit, color: Color(0xFFFF6B6B)),
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
  
  Widget _buildEmptyPostsMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.post_add_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
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

  Widget _buildTextPostCard(Map<String, dynamic> post) {
    final content = post['caption'] ?? '';
    final contentLength = content.length;
    
    // Determine card size based on content length
    double cardWidth;
    double cardHeight = 180;
    
    if (contentLength < 50) {
      cardWidth = 140; // Small card for short text
    } else if (contentLength < 150) {
      cardWidth = 180; // Medium card for medium text
    } else {
      cardWidth = 220; // Large card for long text
    }

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFF6B6B).withOpacity(0.1),
            const Color(0xFFFF8E53).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.2),
          width: 1,
        ),
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
          // User info header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: _avatarBytes != null
                      ? MemoryImage(_avatarBytes!)
                      : null,
                  backgroundColor: const Color(0xFFFF6B6B),
                  child: _avatarBytes == null
                      ? const Icon(Icons.person, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFFFF6B6B),
                            size: 12,
                          ),
                        ],
                      ),
                      Text(
                        _username,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: contentLength < 50 ? 14 : (contentLength < 150 ? 12 : 11),
                  color: Colors.black87,
                  height: 1.3,
                ),
                maxLines: contentLength < 50 ? 4 : (contentLength < 150 ? 6 : 8),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // Timestamp
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _formatTimestamp(post['timestamp']),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPostCard(Map<String, dynamic> post) {
    return Container(
      width: 200,
      height: 230,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: _avatarBytes != null
                      ? MemoryImage(_avatarBytes!)
                      : null,
                  backgroundColor: const Color(0xFFFF6B6B),
                  child: _avatarBytes == null
                      ? const Icon(Icons.person, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFFFF6B6B),
                            size: 12,
                          ),
                        ],
                      ),
                      Text(
                        _username,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Media content
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: post['isWeb'] == true
                    ? Image.memory(
                        base64Decode(post['imageData']),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFFF6B35).withOpacity(0.1),
                            child: const Icon(
                              Icons.image,
                              color: Color(0xFFFF6B35),
                              size: 32,
                            ),
                          );
                        },
                      )
                    : Image.file(
                        File(post['imageData']),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFFF6B35).withOpacity(0.1),
                            child: const Icon(
                              Icons.image,
                              color: Color(0xFFFF6B35),
                              size: 32,
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          
          // Caption and timestamp
          if (post['caption'] != null && post['caption'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['caption'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(post['timestamp']),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _formatTimestamp(post['timestamp']),
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingHistoryContent() {
    // Sample booking data - in real app, this would come from API
    final List<Map<String, dynamic>> bookings = [
      {
        'id': 'BK001',
        'serviceName': 'Hair Cut & Styling',
        'vendorName': 'Style Studio',
        'vendorImage': '💇‍♀️',
        'date': '2024-01-15',
        'time': '10:30 AM',
        'status': 'Completed',
        'amount': '₹500',
        'rating': 4.5,
        'category': 'Beauty',
      },
      {
        'id': 'BK002',
        'serviceName': 'Facial Treatment',
        'vendorName': 'Beauty Parlour',
        'vendorImage': '✨',
        'date': '2024-01-10',
        'time': '2:00 PM',
        'status': 'Completed',
        'amount': '₹800',
        'rating': 5.0,
        'category': 'Beauty',
      },
      {
        'id': 'BK003',
        'serviceName': 'Massage Therapy',
        'vendorName': 'Wellness Center',
        'vendorImage': '💆‍♀️',
        'date': '2024-01-08',
        'time': '4:30 PM',
        'status': 'Cancelled',
        'amount': '₹1200',
        'rating': null,
        'category': 'Wellness',
      },
      {
        'id': 'BK004',
        'serviceName': 'Home Cleaning',
        'vendorName': 'Clean Pro Services',
        'vendorImage': '🧹',
        'date': '2024-01-05',
        'time': '9:00 AM',
        'status': 'Completed',
        'amount': '₹600',
        'rating': 4.0,
        'category': 'Home Services',
      },
      {
        'id': 'BK005',
        'serviceName': 'AC Repair',
        'vendorName': 'Tech Fix Solutions',
        'vendorImage': '🔧',
        'date': '2024-01-03',
        'time': '11:00 AM',
        'status': 'Pending',
        'amount': '₹1500',
        'rating': null,
        'category': 'Repair',
      },
    ];

    if (bookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No booking history',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booking history will appear here',
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
        // Header with stats
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Bookings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${bookings.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${bookings.where((b) => b['status'] == 'Completed').length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.history,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Bookings List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _buildBookingCard(booking);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    Color statusColor;
    IconData statusIcon;
    
    switch (booking['status']) {
      case 'Completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Header Row
          Row(
            children: [
              // Service Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    booking['vendorImage'],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Service Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['serviceName'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking['vendorName'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      booking['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Details Row
          Row(
            children: [
              // Date & Time
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${booking['date']} • ${booking['time']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Amount
              Text(
                booking['amount'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
          
          // Rating (if completed)
          if (booking['status'] == 'Completed' && booking['rating'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${booking['rating']} rating',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                if (booking['status'] == 'Completed')
                  TextButton(
                    onPressed: () => _showBookingDetails(booking),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          
          // Action buttons for pending bookings
          if (booking['status'] == 'Pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _cancelBooking(booking),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rescheduleBooking(booking),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Reschedule',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    booking['vendorImage'],
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['serviceName'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          booking['vendorName'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Booking ID', booking['id']),
                    _buildDetailRow('Date & Time', '${booking['date']} at ${booking['time']}'),
                    _buildDetailRow('Amount', booking['amount']),
                    _buildDetailRow('Status', booking['status']),
                    _buildDetailRow('Category', booking['category']),
                    if (booking['rating'] != null)
                      _buildDetailRow('Rating', '${booking['rating']} ⭐'),
                    
                    const SizedBox(height: 20),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Contacting vendor...'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Contact'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Booking again...'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Book Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B6B),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelBooking(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text('Are you sure you want to cancel the booking for ${booking['serviceName']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking cancelled successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _rescheduleBooking(Map<String, dynamic> booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reschedule feature coming soon!'),
        backgroundColor: Colors.orange,
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
            'About',
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
            'Joined',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'December 2023',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showPostDetails(Map<String, dynamic> post) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: _avatarBytes != null
                      ? MemoryImage(_avatarBytes!)
                      : null,
                  child: _avatarBytes == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (post['location'] != null && post['location'].isNotEmpty)
                        Text(
                          post['location'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              post['caption'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              _formatTimestamp(post['timestamp']),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

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
      return 'Unknown';
    }
  }
}

// 🧩 Reusable Widget for Stats
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatItem({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
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
              color: active ? const Color(0xFFFF6B35) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: active ? const Color(0xFFFF6B35) : Colors.grey[600],
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}