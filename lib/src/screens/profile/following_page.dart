import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FollowingPage extends StatefulWidget {
  const FollowingPage({super.key});

  @override
  State<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage> {
  List<Map<String, dynamic>> _following = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    final prefs = await SharedPreferences.getInstance();
    final followingJson = prefs.getStringList('following') ?? [];
    
    // If no following exist, create some sample data
    if (followingJson.isEmpty) {
      await _createSampleFollowing();
      final updatedFollowingJson = prefs.getStringList('following') ?? [];
      setState(() {
        _following = updatedFollowingJson.map((followingJson) {
          return Map<String, dynamic>.from(jsonDecode(followingJson));
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _following = followingJson.map((followingJson) {
          return Map<String, dynamic>.from(jsonDecode(followingJson));
        }).toList();
        _isLoading = false;
      });
    }
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

  Future<void> _unfollowUser(String userId) async {
    setState(() {
      _following.removeWhere((user) => user['id'] == userId);
    });

    final prefs = await SharedPreferences.getInstance();
    final followingJson = _following.map((user) => jsonEncode(user)).toList();
    await prefs.setStringList('following', followingJson);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unfollowed successfully'),
          backgroundColor: Color(0xFFFF6B35),
        ),
      );
    }
  }

  String _getTimeAgo(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Following',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B35),
              ),
            )
          : _following.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Not following anyone yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'When you follow people, they\'ll appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Text(
                            '${_following.length} following',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _following.length,
                        itemBuilder: (context, index) {
                          final user = _following[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Card(
                              elevation: 0,
                              color: Colors.grey[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFFFF6B35).withOpacity(0.1),
                                  child: Text(
                                    user['avatar'] ?? '👤',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (user['isVerified'] == true)
                                      const Icon(
                                        Icons.verified,
                                        color: Color(0xFFFF6B35),
                                        size: 18,
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['username'] ?? '@unknown',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (user['bio'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        user['bio'],
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      'Following since ${_getTimeAgo(user['followedAt'] ?? DateTime.now().toIso8601String())}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _unfollowUser(user['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    'Following',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  // Navigate to user profile (can be implemented later)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('View ${user['name']}\'s profile'),
                                      backgroundColor: const Color(0xFFFF6B35),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}