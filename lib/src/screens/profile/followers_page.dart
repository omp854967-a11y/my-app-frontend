import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FollowersPage extends StatefulWidget {
  const FollowersPage({super.key});

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  List<Map<String, dynamic>> _followers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    final prefs = await SharedPreferences.getInstance();
    final followersJson = prefs.getStringList('followers') ?? [];
    
    // If no followers exist, create some sample data
    if (followersJson.isEmpty) {
      await _createSampleFollowers();
      final updatedFollowersJson = prefs.getStringList('followers') ?? [];
      setState(() {
        _followers = updatedFollowersJson.map((followerJson) {
          return Map<String, dynamic>.from(jsonDecode(followerJson));
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _followers = followersJson.map((followerJson) {
          return Map<String, dynamic>.from(jsonDecode(followerJson));
        }).toList();
        _isLoading = false;
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

  Future<void> _removeFollower(String followerId) async {
    setState(() {
      _followers.removeWhere((follower) => follower['id'] == followerId);
    });

    final prefs = await SharedPreferences.getInstance();
    final followersJson = _followers.map((follower) => jsonEncode(follower)).toList();
    await prefs.setStringList('followers', followersJson);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Follower removed'),
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
          'Followers',
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
          : _followers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No followers yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'When people follow you, they\'ll appear here',
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
                            '${_followers.length} followers',
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
                        itemCount: _followers.length,
                        itemBuilder: (context, index) {
                          final follower = _followers[index];
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
                                    follower['avatar'] ?? '👤',
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        follower['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (follower['isVerified'] == true)
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
                                      follower['username'] ?? '@unknown',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Followed ${_getTimeAgo(follower['followedAt'] ?? DateTime.now().toIso8601String())}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                                  onSelected: (value) {
                                    if (value == 'remove') {
                                      _removeFollower(follower['id']);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'remove',
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_remove, color: Colors.red, size: 20),
                                          SizedBox(width: 8),
                                          Text('Remove follower'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Navigate to user profile (can be implemented later)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('View ${follower['name']}\'s profile'),
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