import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../atoms/custom_card.dart';
import '../../atoms/custom_button.dart';
import '../../atoms/progress_indicator.dart';
import '../../organisms/top_navigation_bar.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/models/quest_stop_model.dart';
import '../../../data/models/quest_review_model.dart';
import '../../../data/repositories/quest_repository.dart';
import '../../../data/repositories/quest_review_repository.dart';
import '../../atoms/custom_avatar.dart';
import '../../../core/services/supabase_service.dart';
import '../../templates/app_template.dart';
import '../../../core/constants/app_colors.dart';

class QuestDetailView extends StatefulWidget {
  final String questId;
  final Function(AppView, [NavigationData?])? onNavigate;
  final VoidCallback? onBack;
  final Function(String)? onStartQuest;

  const QuestDetailView({
    super.key,
    required this.questId,
    this.onNavigate,
    this.onBack,
    this.onStartQuest,
  });

  @override
  State<QuestDetailView> createState() => _QuestDetailViewState();
}

class _QuestDetailViewState extends State<QuestDetailView> {
  final QuestRepository _questRepository = QuestRepository();
  final QuestReviewRepository _reviewRepository = QuestReviewRepository();
  final SupabaseService _supabaseService = SupabaseService();
  
  Quest? _quest;
  List<QuestStop> _questStops = [];
  List<QuestReview> _reviews = [];
  bool _isLoading = true;
  bool _canUserReview = false;
  QuestReview? _userReview;
  
  // Mock leaderboard data
  final List<Map<String, dynamic>> _leaderboardData = [
    {
      'rank': 1,
      'name': 'Sarah Johnson',
      'avatar': 'https://images.unsplash.com/photo-1494790108755-2616b612b402?w=150',
      'time': '45:23',
      'score': 2450,
    },
    {
      'rank': 2,
      'name': 'Mike Chen',
      'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      'time': '47:12',
      'score': 2380,
    },
    {
      'rank': 3,
      'name': 'Emily Davis',
      'avatar': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
      'time': '48:45',
      'score': 2310,
    },
    {
      'rank': 4,
      'name': 'Alex Rivera',
      'avatar': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
      'time': '52:30',
      'score': 2180,
    },
    {
      'rank': 5,
      'name': 'Taylor Swift',
      'avatar': 'https://images.unsplash.com/photo-1489424731084-a5d8b219a5bb?w=150',
      'time': '55:18',
      'score': 2050,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadQuestDetails();
  }

  Future<void> _loadQuestDetails() async {
    try {
      setState(() => _isLoading = true);
      
      // Load quest data, stops, and reviews in parallel
      final results = await Future.wait([
        _questRepository.getQuestById(widget.questId),
        _questRepository.getQuestStops(widget.questId),
        _reviewRepository.getQuestReviews(widget.questId, limit: 10),
      ]);

      final quest = results[0] as Quest?;
      final stops = results[1] as List<QuestStop>;
      final reviews = results[2] as List<QuestReview>;

      // Check if user can review (has completed quest)
      bool canReview = false;
      QuestReview? userReview;
      
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        // Check if user has completed this quest
        final progress = await _questRepository.getUserQuestProgress(widget.questId);
        canReview = progress != null && progress['status'] == 'completed';
        
        // Check if user already reviewed this quest
        final userReviews = await _reviewRepository.getUserReviews(currentUser.id);
        userReview = userReviews.firstWhere(
          (review) => review.questId == widget.questId,
          orElse: () => QuestReview(
            id: '',
            questId: '',
            userId: '',
            userName: '',
            userAvatar: '',
            rating: 0,
            comment: '',
            photos: const [],
            createdAt: DateTime.now(),
            helpfulVotes: 0,
          ),
        );
        
        if (userReview.id.isEmpty) {
          userReview = null;
        }
      }

      if (mounted) {
        setState(() {
          _quest = quest;
          _questStops = stops;
          _reviews = reviews;
          _canUserReview = canReview;
          _userReview = userReview;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading quest details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = Colors.green;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'hard':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                SizedBox(height: 24),
                Text(
                  'Loading quest details...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_quest == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              TopNavigationBar(
                title: 'Quest Not Found',
                onBackPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                showBackButton: true,
              ),
              Expanded(
                child: Center(
                  child: CustomCard(
                    margin: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Quest not found',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The quest you\'re looking for doesn\'t exist or has been removed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: (isDark ? Colors.white : Colors.black87).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          // Hero Image with Overlay (Edge-to-Edge)
          SizedBox(
            height: 280,
            child: Stack(
              children: [
                // Image (Full Width)
                CachedNetworkImage(
                  imageUrl: _quest!.coverImageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
                
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                
                // Top Navigation Overlay
                SafeArea(
                  child: TopNavigationBar(
                    title: '',
                    onBackPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                    showBackButton: true,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                
                // Text Overlay
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _quest!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _quest!.city,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Category Badge
                Positioned(
                  top: 100,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _quest!.category ?? 'Adventure',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                // Rating Badge
                Positioned(
                  top: 100,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.orange,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _quest!.rating.toString(),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Description and Stats Section (merged with image)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    transform: Matrix4.translationValues(0, -25, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '4.6',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_quest!.points} pts',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Description
                        Text(
                          _quest!.description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                        
                        const SizedBox(height: 28),
                        
                        // Stats Row (improved design)
                        Row(
                          children: [
                            _buildModernStatItem(
                              icon: Icons.access_time_outlined,
                              label: 'Duration',
                              value: _quest!.estimatedDuration,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 20),
                            _buildModernStatItem(
                              icon: Icons.trending_up,
                              label: 'Difficulty',
                              value: _quest!.difficulty,
                              color: _getDifficultyColor(_quest!.difficulty),
                            ),
                            const SizedBox(width: 20),
                            _buildModernStatItem(
                              icon: Icons.location_on_outlined,
                              label: 'Stops',
                              value: '${_questStops.length}',
                              color: Colors.green,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // What You'll Need Section (improved)
                        const Row(
                          children: [
                            Icon(
                              Icons.backpack_outlined,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'What you\'ll need:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Row(
                          children: [
                            _buildNeedItemModern(
                              icon: Icons.directions_walk,
                              label: 'Good Shoes',
                              color: Colors.brown,
                            ),
                            const SizedBox(width: 20),
                            _buildNeedItemModern(
                              icon: Icons.water_drop,
                              label: 'Water',
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 20),
                            _buildNeedItemModern(
                              icon: Icons.smartphone,
                              label: 'Charged Phone',
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Quest Stops Section (if any)
                  if (_questStops.isNotEmpty) 
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _buildQuestStopsSection(),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Leaderboard Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _buildLeaderboardSection(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Reviews Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _buildReviewsSection(),
                  ),
                  
                  const SizedBox(height: 120), // Space for fixed button
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Fixed Start Button
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: CustomButton(
          text: 'Start Adventure!',
          icon: Icons.play_arrow,
          onPressed: () => widget.onStartQuest?.call(_quest!.id),
          size: ButtonSize.large,
          isFullWidth: true,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    bool isCustom = false,
    Widget? customWidget,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        if (isCustom && customWidget != null)
          customWidget
        else
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildNeedItem({
    required IconData icon,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Modern stat item widget
  Widget _buildModernStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
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

  // Modern need item widget
  Widget _buildNeedItemModern({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper to get difficulty color
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildQuestStopsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Quest Stops',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                '${_questStops.length} stops',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _questStops.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final stop = _questStops[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
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
                          stop.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (stop.clue?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            stop.clue!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87.withOpacity(0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${stop.points} pts',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const Spacer(),
            if (_reviews.isNotEmpty)
              Text(
                '${_reviews.length} reviews',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
          
          // User can review section
          if (_canUserReview && _userReview == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.rate_review, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'You completed this quest! Share your experience with others.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  CustomButton(
                    text: 'Review',
                    size: ButtonSize.small,
                    onPressed: () => _showReviewDialog(),
                  ),
                ],
              ),
            ),
          
          if (_canUserReview && _userReview == null) const SizedBox(height: 16),
          
          // User's existing review
          if (_userReview != null) ...[
            _buildReviewItem(_userReview!, isUserReview: true),
            const SizedBox(height: 16),
          ],
          
          // Other reviews
          if (_reviews.isEmpty && _userReview == null)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.star_border,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Complete this quest to be the first to review!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.take(5).length, // Show first 5 reviews
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final review = _reviews[index];
                // Don't show user's review again if already shown above
                if (_userReview != null && review.userId == _userReview!.userId) {
                  return const SizedBox.shrink();
                }
                return _buildReviewItem(review);
              },
            ),
          
          if (_reviews.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Text(
                  'And ${_reviews.length - 5} more reviews...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
    );
  }

  Widget _buildReviewItem(QuestReview review, {bool isUserReview = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUserReview 
          ? AppColors.primary.withOpacity(0.05)
          : (isDark ? Colors.grey[800] : Colors.grey[50]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUserReview 
            ? AppColors.primary.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomAvatar(
                imageUrl: review.userAvatar,
                initials: review.userName.isNotEmpty ? review.userName[0] : 'U',
                size: AvatarSize.small,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isUserReview ? 'Your Review' : review.userName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (isUserReview) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) => Icon(
                          Icons.star,
                          size: 14,
                          color: index < review.rating ? Colors.orange : Colors.grey[300],
                        )),
                        const SizedBox(width: 8),
                        Text(
                          '${review.rating}/5',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  void _showReviewDialog() {
    showDialog(
      context: context,
      builder: (context) => _ReviewDialog(
        questId: widget.questId,
        onSubmitted: () {
          _loadQuestDetails(); // Reload to show new review
        },
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'Top ${_leaderboardData.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Podium for top 3 (if available)
        if (_leaderboardData.length >= 3) ...[
          _buildPodium(),
          const SizedBox(height: 24),
        ],
        
        // Full leaderboard list
        Column(
          children: _leaderboardData.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            
            // Skip top 3 if podium is shown
            if (_leaderboardData.length >= 3 && index < 3) {
              return const SizedBox.shrink();
            }
            
            return _buildLeaderboardItem(player, index);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPodium() {
    final top3 = _leaderboardData.take(3).toList();
    
    return SizedBox(
      height: 140,
      child: Stack(
        children: [
          // Podium platforms
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd place
                if (top3.length > 1) _buildPodiumPlatform(top3[1], 2, 60, Colors.grey),
                // 1st place
                _buildPodiumPlatform(top3[0], 1, 80, Colors.amber),
                // 3rd place
                if (top3.length > 2) _buildPodiumPlatform(top3[2], 3, 40, Colors.brown),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPlatform(Map<String, dynamic> player, int rank, double height, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with rank overlay
        Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: player['avatar'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.person, color: Colors.grey[600]),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.person, color: Colors.grey[600]),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          player['name'].toString().split(' ')[0], // First name only
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          player['time'],
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Platform
        Container(
          width: 60,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                rank == 1 ? Icons.emoji_events : 
                rank == 2 ? Icons.military_tech : 
                Icons.workspace_premium,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                '${player['score']}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> player, int index) {
    final rank = player['rank'] as int;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3 ? _getRankColor(rank).withOpacity(0.1) : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: rank <= 3 ? _getRankColor(rank) : Colors.grey,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? _getRankColor(rank) : Colors.grey[700],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Avatar with rank overlay
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: rank <= 3 ? _getRankColor(rank) : Colors.grey,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: player['avatar'],
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.grey[600], size: 20),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.grey[600], size: 20),
                    ),
                  ),
                ),
              ),
              if (rank <= 3)
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getRankColor(rank),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Completed in ${player['time']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${player['score']} pts',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  // ...existing code...
}

class _ReviewDialog extends StatefulWidget {
  final String questId;
  final VoidCallback onSubmitted;

  const _ReviewDialog({
    required this.questId,
    required this.onSubmitted,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final TextEditingController _commentController = TextEditingController();
  final QuestReviewRepository _reviewRepository = QuestReviewRepository();
  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      final success = await _reviewRepository.submitReview(
        questId: widget.questId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      
      if (success) {
        Navigator.of(context).pop();
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to submit review');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate this Quest'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How was your experience?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = starValue.toDouble()),
                child: Icon(
                  Icons.star,
                  size: 32,
                  color: starValue <= _rating ? Colors.orange : Colors.grey[300],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Share your experience... (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: _isSubmitting ? 'Submitting...' : 'Submit Review',
          onPressed: _isSubmitting ? null : _submitReview,
          size: ButtonSize.small,
        ),
      ],
    );
  }
}