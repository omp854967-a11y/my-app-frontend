import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'submit_rating_page.dart';

class RatingReviewsPage extends StatefulWidget {
  const RatingReviewsPage({super.key});

  @override
  State<RatingReviewsPage> createState() => _RatingReviewsPageState();
}

class _RatingReviewsPageState extends State<RatingReviewsPage> {
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;
  Map<int, int> _ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final prefs = await SharedPreferences.getInstance();
    final reviewsJson = prefs.getString('vendor_reviews');
    
    if (reviewsJson != null && reviewsJson.isNotEmpty) {
      try {
        final List<dynamic> reviewsList = jsonDecode(reviewsJson);
        _reviews = reviewsList.map((review) => Map<String, dynamic>.from(review)).toList();
      } catch (e) {
        _reviews = [];
      }
    }
    
    // If no reviews exist, create sample data
    if (_reviews.isEmpty) {
      await _createSampleReviews();
    }
    
    _calculateRatingStats();
    setState(() {});
  }

  Future<void> _createSampleReviews() async {
    final sampleReviews = [
      {
        'id': '1',
        'customerName': 'Priya Sharma',
        'customerAvatar': '👩',
        'rating': 5,
        'comment': 'Excellent service! Very professional and timely. The quality of work exceeded my expectations. Highly recommended!',
        'service': 'Hair Styling',
        'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'isVerified': true,
      },
      {
        'id': '2',
        'customerName': 'Rahul Kumar',
        'customerAvatar': '👨',
        'rating': 4,
        'comment': 'Good service overall. The staff was friendly and the work was done well. Just took a bit longer than expected.',
        'service': 'Facial Treatment',
        'date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
        'isVerified': true,
      },
      {
        'id': '3',
        'customerName': 'Anjali Patel',
        'customerAvatar': '👩‍🦱',
        'rating': 5,
        'comment': 'Amazing experience! The ambiance was great and the service was top-notch. Will definitely come back.',
        'service': 'Manicure & Pedicure',
        'date': DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
        'isVerified': false,
      },
      {
        'id': '4',
        'customerName': 'Vikash Singh',
        'customerAvatar': '👨‍💼',
        'rating': 3,
        'comment': 'Average service. The work was okay but nothing special. Room for improvement in customer service.',
        'service': 'Massage Therapy',
        'date': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
        'isVerified': true,
      },
      {
        'id': '5',
        'customerName': 'Sneha Gupta',
        'customerAvatar': '👩‍💻',
        'rating': 5,
        'comment': 'Outstanding service! Very clean environment and skilled professionals. Worth every penny!',
        'service': 'Hair Cut & Styling',
        'date': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        'isVerified': true,
      },
      {
        'id': '6',
        'customerName': 'Arjun Mehta',
        'customerAvatar': '👨‍🎓',
        'rating': 4,
        'comment': 'Great service and reasonable prices. The staff was very accommodating and professional.',
        'service': 'Beard Trimming',
        'date': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
        'isVerified': false,
      },
    ];
    
    _reviews = sampleReviews;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vendor_reviews', jsonEncode(_reviews));
  }

  void _calculateRatingStats() {
    if (_reviews.isEmpty) {
      _averageRating = 0.0;
      _totalReviews = 0;
      _ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      return;
    }

    _totalReviews = _reviews.length;
    double totalRating = 0.0;
    _ratingCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (var review in _reviews) {
      int rating = review['rating'] ?? 0;
      totalRating += rating;
      _ratingCounts[rating] = (_ratingCounts[rating] ?? 0) + 1;
    }

    _averageRating = totalRating / _totalReviews;
  }

  String _getTimeAgo(String dateString) {
    try {
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
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ratings & Reviews'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubmitRatingPage(
                    vendorId: 'current_vendor',
                    vendorName: 'Vendor Name',
                  ),
                ),
              );
              
              // Refresh reviews if rating was submitted
              if (result == true) {
                _loadReviews();
              }
            },
            tooltip: 'Submit Rating',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Rating Summary Section
            _buildRatingSummary(),
            
            // Reviews List
            _buildReviewsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Overall Rating
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      _averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B35),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < _averageRating.floor()
                              ? Icons.star
                              : index < _averageRating
                                  ? Icons.star_half
                                  : Icons.star_border,
                          color: Colors.amber,
                          size: 24,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalReviews reviews',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  children: List.generate(5, (index) {
                    int starCount = 5 - index;
                    int count = _ratingCounts[starCount] ?? 0;
                    double percentage = _totalReviews > 0 ? count / _totalReviews : 0.0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$starCount',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$count',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Customer Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF6B35),
              ),
            ),
          ),
          if (_reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Customer reviews will appear here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final review = _reviews[index];
                return _buildReviewCard(review);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Info and Rating
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review['customerAvatar'] ?? '👤',
                    style: const TextStyle(fontSize: 20),
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
                          review['customerName'] ?? 'Anonymous',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (review['isVerified'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _getTimeAgo(review['date'] ?? DateTime.now().toIso8601String()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < (review['rating'] ?? 0)
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  if (review['service'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      review['service'],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Review Comment
          Text(
            review['comment'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}