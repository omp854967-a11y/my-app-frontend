import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../../widgets/gradient_header.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notification_provider.dart';
import '../chat/message_screen.dart';
import '../notifications/notification_page.dart';
import '../profile/blookit_profile_page.dart';
import '../profile/vendor_profile_page.dart';
import '../profile/new_vendor_profile_page.dart';
import '../create_post/create_post_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = false;
  int _currentIndex = 0;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _loadInitialPosts();
    _scrollController.addListener(_onScroll);
    
    // Initialize FAB animation
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _loadInitialPosts() async {
    final userPosts = await _loadUserPosts();
    final dummyPosts = _generateDummyPosts();
    
    setState(() {
      _posts = [...userPosts, ...dummyPosts];
      // Sort by timestamp (newest first)
      _posts.sort((a, b) {
        final aTime = DateTime.parse(a['timestamp']);
        final bTime = DateTime.parse(b['timestamp']);
        return bTime.compareTo(aTime);
      });
    });
  }

  Future<List<Map<String, dynamic>>> _loadUserPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final postsJson = prefs.getStringList('user_posts') ?? [];
      return postsJson.map((postJson) {
        final post = Map<String, dynamic>.from(jsonDecode(postJson));
        return {
          'id': post['id'],
          'userName': 'You',
          'userHandle': '@you',
          'userAvatar': '👤',
          'isVerified': false,
          'content': post['caption'] ?? '',
          'timestamp': post['timestamp'],
          'likes': post['likes'] ?? 0,
          'comments': post['comments'] ?? 0,
          'shares': 0,
          'imageUrl': post['hasImage'] == true ? 'user_image' : null,
          'imageData': post['imageData'],
          'hasImage': post['hasImage'] ?? false,
          'isWeb': post['isWeb'] ?? false,
          'isUserPost': true,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMorePosts();
    }
  }

  void _loadMorePosts() {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
      
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _posts.addAll(_generateDummyPosts());
          _isLoading = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5), // Android Material background
      
      // Android Material AppBar
      appBar: AppBar(
        elevation: 4,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: true,
        automaticallyImplyLeading: false, // Remove back button
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Blookit Logo
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'b',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Blookit Text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6F00), Color(0xFFFF4081)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Text(
                'blookit',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          _buildAppBarNotificationIcon(),
        ],
      ),

      // Android Navigation Drawer
      drawer: _buildAndroidDrawer(),

      // Android Material Body
      body: RefreshIndicator(
        onRefresh: () async {
          _loadInitialPosts();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Search Bar as Sliver
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search posts, users, hashtags...',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            Icons.tune,
                            color: Colors.grey[600],
                            size: 24,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Filter options coming soon!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                      onTap: _showSearchDialog,
                      readOnly: true,
                    ),
                  ),
                ),
              ),
            ),
            
            // Posts List
            _posts.isEmpty && !_isLoading
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.post_add_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No posts yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first post to get started!',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < _posts.length) {
                          return _buildAndroidPostCard(_posts[index]);
                        } else if (_isLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return null;
                      },
                      childCount: _posts.length + (_isLoading ? 1 : 0),
                    ),
                  ),
          ],
        ),
      ),

      // Android Material FAB
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreatePostScreen(),
              ),
            );
          },
          backgroundColor: const Color(0xFFFF6F00),
          foregroundColor: Colors.white,
          elevation: 6,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Android Bottom Navigation
      bottomNavigationBar: _buildAndroidBottomNavBar(),
    );
  }

  // Android Material Post Card
  Widget _buildAndroidPostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFFF6F00),
                      child: Text(
                        post['userAvatar'] ?? '👤',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                post['userName'] ?? 'Anonymous',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              if (post['isVerified'] == true) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${post['userHandle'] ?? ''} • ${_formatTimestamp(post['timestamp'])}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onPressed: () => _showPostOptions(post),
                    ),
                  ],
                ),
              ),

              // Post Content
              if (post['content']?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    post['content'],
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ),

              // Post Image
              if (post['hasImage'] == true || post['imageUrl'] != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: post['isUserPost'] == true && post['hasImage'] == true && post['imageData'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: post['isWeb'] == true
                              ? Image.memory(
                                  base64Decode(post['imageData']),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 50,
                                        color: Colors.grey[400],
                                      ),
                                    );
                                  },
                                )
                              : Image.file(
                                  File(post['imageData']),
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 50,
                                        color: Colors.grey[400],
                                      ),
                                    );
                                  },
                                ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_outlined,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.favorite_border,
                      label: post['likes']?.toString() ?? '0',
                      onTap: () => _likePost(post),
                    ),
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: post['comments']?.toString() ?? '0',
                      onTap: () => _showComments(post),
                    ),
                    _buildActionButton(
                      icon: Icons.share_outlined,
                      label: post['shares']?.toString() ?? '0',
                      onTap: () => _sharePost(post),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.bookmark_border, color: Colors.grey),
                      onPressed: () => _bookmarkPost(post),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Android Navigation Drawer
  Widget _buildAndroidDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6F00), Color(0xFFFF4081)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: Color(0xFFFF6F00),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Welcome to blookit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Discover amazing content',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.home, 'Home', () => Navigator.pop(context)),
                _buildDrawerItem(Icons.person, 'Profile', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BlookitProfilePage()),
                  );
                }),
                _buildDrawerItem(Icons.store, 'Vendor Profile', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NewVendorProfilePage()),
                  );
                }),
                _buildDrawerItem(Icons.message, 'Messages', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MessageScreen()),
                  );
                }),
                _buildDrawerItem(Icons.notifications, 'Notifications', () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationPage()),
                  );
                }),
                const Divider(),
                _buildDrawerItem(Icons.settings, 'Settings', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon!')),
                  );
                }),
                _buildDrawerItem(Icons.help, 'Help & Support', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help & Support coming soon!')),
                  );
                }),
                _buildDrawerItem(Icons.info, 'About', () {
                  Navigator.pop(context);
                  _showAboutDialog();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  // Android Bottom Navigation Bar
  Widget _buildAndroidBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.message_outlined, 'Messages', 1),
              _buildNavItem(Icons.add_circle_outline, 'Post', 2),
              _buildNavItem(Icons.notifications_outlined, 'Notifications', 3),
              _buildNavItem(Icons.person_outline, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF6F00).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  icon,
                  color: isActive ? const Color(0xFFFF6F00) : Colors.grey[600],
                  size: 24,
                ),
                if (index == 1) // Messages
                  Consumer<ChatProvider>(
                    builder: (context, chatProvider, child) {
                      final unreadCount = chatProvider.totalUnreadCount;
                      if (unreadCount > 0) {
                        return Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                if (index == 3) // Notifications
                  Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, child) {
                      final unreadCount = notificationProvider.unreadCount;
                      if (unreadCount > 0) {
                        return Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? const Color(0xFFFF6F00) : Colors.grey[600],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationNavItem() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationPage()),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 20,
                color: const Color(0xFF8E8E93),
              ),
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  final unreadCount = notificationProvider.unreadCount;
                  if (unreadCount > 0) {
                    return Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B35),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 9,
              color: Color(0xFF8E8E93),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingAddButton() {
    return GestureDetector(
      onTap: () async {
        // Navigate to create post screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreatePostScreen(),
          ),
        );
        
        // If post was created successfully, refresh the feed
        if (result == true) {
          _loadInitialPosts();
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6B6B),
              Color(0xFFFF8E53),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildAppBarNotificationIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationPage()),
              );
            },
          ),
          Positioned(
            right: 6,
            top: 6,
            child: Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                final unreadCount = notificationProvider.unreadCount;
                if (unreadCount > 0) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B35),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 12,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const Center(
          child: Text(
            'Create Post Modal\n(To be implemented)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6C6C6C),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onNavItemTapped(int index) async {
    setState(() {
      _currentIndex = index;
    });
    
    switch (index) {
      case 0: // Home - already here
        break;
      case 1: // Messages
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MessageScreen()),
        );
        break;
      case 2: // Post - Create new post
        {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreatePostScreen(),
            ),
          );
          if (result == true) {
            _loadInitialPosts();
          }
        }
        break;
      case 3: // Notifications
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationPage()),
        );
        break;
      case 4: // Profile
        {
          final role = await AuthService().getUserRole();
          if (role == 'vendor') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VendorProfilePage()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BlookitProfilePage()),
            );
          }
        }
        break;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search for posts, users, or hashtags...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFFF6F00)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF6F00)),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                autofocus: true,
                onSubmitted: (value) {
                  Navigator.pop(context);
                  if (value.trim().isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Searching for: $value'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildSearchChip('#flutter'),
                  _buildSearchChip('#android'),
                  _buildSearchChip('Rajesh Kumar'),
                  _buildSearchChip('#technology'),
                  _buildSearchChip('#design'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchChip(String text) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Searching for: $text'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Chip(
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFFF6F00),
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFFF6F00).withOpacity(0.1),
        side: const BorderSide(color: Color(0xFFFF6F00), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _likePost(Map<String, dynamic> post) {
    setState(() {
      final isCurrentlyLiked = post['isLiked'] == true;
      post['isLiked'] = !isCurrentlyLiked;
      
      if (isCurrentlyLiked) {
        post['likes'] = (post['likes'] ?? 0) - 1;
      } else {
        post['likes'] = (post['likes'] ?? 0) + 1;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(post['isLiked'] == true ? 'Post liked!' : 'Like removed'),
        duration: const Duration(seconds: 1),
        backgroundColor: post['isLiked'] == true ? const Color(0xFFFF6F00) : Colors.grey,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showComments(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(),
                
                // Comments list
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildCommentItem(
                        'John Doe',
                        'Great post! Really enjoyed reading this.',
                        '2h ago',
                      ),
                      _buildCommentItem(
                        'Jane Smith',
                        'Thanks for sharing this valuable information.',
                        '1h ago',
                      ),
                      _buildCommentItem(
                        'Mike Johnson',
                        'Very insightful! Looking forward to more content like this.',
                        '30m ago',
                      ),
                    ],
                  ),
                ),
                
                // Comment input
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFFF6F00),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Comment added!'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6F00),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Comment posted!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(String name, String comment, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFFF6F00),
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Comment liked!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Like',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reply feature coming soon!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sharePost(Map<String, dynamic> post) {
    setState(() {
      post['shares'] = (post['shares'] ?? 0) + 1;
    });
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Share Post',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(Icons.link, 'Copy Link', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Link copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }),
                _buildShareOption(Icons.share, 'Share', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Shared successfully!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }),
                _buildShareOption(Icons.bookmark, 'Save', () {
                  Navigator.pop(context);
                  _bookmarkPost(post);
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6F00).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF6F00),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _bookmarkPost(Map<String, dynamic> post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post bookmarked!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPostOptions(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border, color: Color(0xFFFF6F00)),
              title: const Text('Save Post'),
              onTap: () {
                Navigator.pop(context);
                _bookmarkPost(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Color(0xFFFF6F00)),
              title: const Text('Share Post'),
              onTap: () {
                Navigator.pop(context);
                _sharePost(post);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Post reported!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6F00), Color(0xFFFF4081)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'blookit',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'A modern social media platform built with Flutter.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '© 2024 blookit. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFFFF6F00)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    } catch (e) {
      return '';
    }
  }

  List<Map<String, dynamic>> _generateDummyPosts() {
    final now = DateTime.now();
    return [
      {
        'id': 'dummy_${now.millisecondsSinceEpoch}_1',
        'userName': 'Rahul Kumar',
        'userHandle': '@rahul_dev',
        'userAvatar': '👨‍💻',
        'isVerified': true,
        'content': 'Just finished building an amazing Flutter app! The new widgets are incredible. 🚀 #Flutter #Android #Development',
        'timestamp': now.subtract(const Duration(minutes: 30)).toIso8601String(),
        'likes': 42,
        'comments': 8,
        'shares': 3,
      },
      {
        'id': 'dummy_${now.millisecondsSinceEpoch}_2',
        'userName': 'Priya Sharma',
        'userHandle': '@priya_design',
        'userAvatar': '👩‍🎨',
        'isVerified': false,
        'content': 'Beautiful sunset today! Nature never fails to inspire my designs. 🌅 #Design #Nature #Inspiration',
        'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'likes': 156,
        'comments': 23,
        'shares': 12,
        'imageUrl': 'sunset.jpg',
      },
      {
        'id': 'dummy_${now.millisecondsSinceEpoch}_3',
        'userName': 'Tech News',
        'userHandle': '@tech_updates',
        'userAvatar': '📱',
        'isVerified': true,
        'content': 'Breaking: New AI breakthrough announced! This could change everything we know about machine learning. 🤖 #AI #Technology #Innovation',
        'timestamp': now.subtract(const Duration(hours: 4)).toIso8601String(),
        'likes': 892,
        'comments': 156,
        'shares': 234,
      },
      {
        'id': 'dummy_${now.millisecondsSinceEpoch}_4',
        'userName': 'Android Dev',
        'userHandle': '@android_official',
        'userAvatar': '🤖',
        'isVerified': true,
        'content': 'New Material Design 3 components are now available! Check out the latest updates for a more modern Android experience. #MaterialDesign #Android',
        'timestamp': now.subtract(const Duration(hours: 6)).toIso8601String(),
        'likes': 567,
        'comments': 89,
        'shares': 45,
      },
    ];
  }
}