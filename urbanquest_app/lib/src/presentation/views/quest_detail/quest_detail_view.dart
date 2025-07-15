import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../atoms/custom_button.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/models/quest_stop_model.dart';
import '../../../data/models/quest_review_model.dart';
import '../../../data/repositories/quest_repository.dart';
import '../../../data/repositories/quest_review_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../atoms/custom_avatar.dart';
import '../../../core/services/supabase_service.dart';
import '../../templates/app_template.dart';
import '../../../core/constants/app_colors.dart';
import '../quest_gameplay/quest_gameplay_view.dart';

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
  final UserRepository _userRepository = UserRepository();
  final SupabaseService _supabaseService = SupabaseService();
  
  Quest? _quest;
  List<QuestStop> _questStops = [];
  List<QuestReview> _reviews = [];
  Map<String, dynamic>? _questProgress;
  Map<String, dynamic>? _questStats;
  bool _isLoading = true;
  bool _isLoadingStats = true;
  bool _canUserReview = false;
  bool _isFavorited = false;
  bool _hasStartedQuest = false;
  QuestReview? _userReview;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _loadQuestDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestDetails() async {
    try {
      setState(() => _isLoading = true);
      
      // Load quest data, stops, and reviews in parallel
      final results = await Future.wait([
        _questRepository.getQuestById(widget.questId),
        _questRepository.getQuestStops(widget.questId),
        _reviewRepository.getQuestReviews(widget.questId, limit: 10),
        _loadUserSpecificData(),
        _loadQuestStats(),
      ]);

      final quest = results[0] as Quest?;
      final stops = results[1] as List<QuestStop>;
      final reviews = results[2] as List<QuestReview>;

      if (mounted) {
        setState(() {
          _quest = quest;
          _questStops = stops;
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading quest: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadQuestDetails,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadUserSpecificData() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) return;

    try {
      // Load user-specific data in parallel
      final results = await Future.wait([
        _questRepository.getUserQuestProgress(widget.questId),
        _checkIfFavorited(),
        _checkUserReviewStatus(),
      ]);

      final progress = results[0] as Map<String, dynamic>?;
      final isFavorited = results[1] as bool;
      final reviewData = results[2] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _questProgress = progress;
          _hasStartedQuest = progress != null;
          _canUserReview = reviewData['canReview'] as bool;
          _userReview = reviewData['userReview'] as QuestReview?;
          _isFavorited = isFavorited;
        });
      }
    } catch (e) {
      print('Error loading user-specific data: $e');
    }
  }

  Future<void> _loadQuestStats() async {
    try {
      setState(() => _isLoadingStats = true);
      
      // Get comprehensive quest statistics from database
      final stats = await _supabaseService.callRpc('get_quest_statistics', params: {
        'quest_id': widget.questId,
      });

      if (mounted) {
        setState(() {
          _questStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Error loading quest stats: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<bool> _checkIfFavorited() async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return false;

      final favorites = await _supabaseService.fetchFromTable(
        'user_favorites',
        select: 'id',
        eq: {'user_id': currentUser.id, 'quest_id': widget.questId},
        limit: 1,
      );

      return favorites.isNotEmpty;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _checkUserReviewStatus() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      return {'canReview': false, 'userReview': null};
    }

    try {
      // Check if user has completed this quest
      final progress = await _questRepository.getUserQuestProgress(widget.questId);
      final canReview = progress != null && progress['status'] == 'completed';
      
      QuestReview? userReview;
      if (canReview) {
        // Check if user already reviewed this quest
        final userReviews = await _reviewRepository.getUserReviews(currentUser.id);
        userReview = userReviews.isNotEmpty 
          ? userReviews.firstWhere(
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
            )
          : null;
          
        if (userReview?.id.isEmpty == true) {
          userReview = null;
        }
      }

      return {'canReview': canReview, 'userReview': userReview};
    } catch (e) {
      print('Error checking review status: $e');
      return {'canReview': false, 'userReview': null};
    }
  }

  Future<void> _toggleFavorite() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save favorites')),
      );
      return;
    }

    try {
      if (_isFavorited) {
        // Remove from favorites
        await _supabaseService.deleteFromTable(
          'user_favorites',
          {'user_id': currentUser.id, 'quest_id': widget.questId},
        );
      } else {
        // Add to favorites
        await _supabaseService.insertIntoTable(
          'user_favorites',
          {
            'user_id': currentUser.id,
            'quest_id': widget.questId,
            'created_at': DateTime.now().toIso8601String(),
          },
        );
      }

      setState(() {
        _isFavorited = !_isFavorited;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorited ? 'Added to favorites' : 'Removed from favorites'),
          backgroundColor: _isFavorited ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating favorites: $e')),
      );
    }
  }

  Future<void> _shareQuest() async {
    if (_quest == null) return;

    try {
      final shareText = '''
Check out this amazing quest: ${_quest!.title}
${_quest!.description}

🌟 Rating: ${_quest!.rating.toStringAsFixed(1)}/5
📍 Location: ${_quest!.city}
⏱️ Duration: ${_quest!.estimatedDuration} minutes
🎯 ${_quest!.numberOfStops} stops to explore

Download UrbanQuest to start your adventure!
''';

      await Share.share(
        shareText,
        subject: 'Urban Quest: ${_quest!.title}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing quest: $e')),
      );
    }
  }

  void _startQuest() async {
    if (_quest == null) return;

    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to start quests')),
      );
      return;
    }

    try {
      if (!_hasStartedQuest) {
        // Start the quest in the database
        final success = await _questRepository.startQuest(_quest!.id);
        if (!success) {
          throw Exception('Failed to start quest');
        }
        
        setState(() {
          _hasStartedQuest = true;
        });
      }

      if (widget.onStartQuest != null) {
        widget.onStartQuest!(_quest!.id);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestGameplayView(
              quest: _quest!,
              onBack: () {
                Navigator.pop(context);
                // Refresh data when returning from gameplay
                _loadQuestDetails();
              },
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting quest: $e')),
      );
    }
  }

  String _getQuestStatusText() {
    if (_questProgress == null) return 'Start Quest';
    
    final status = _questProgress!['status'] as String?;
    switch (status) {
      case 'completed':
        return 'Quest Completed';
      case 'in_progress':
        final currentStop = _questProgress!['current_stop_index'] as int? ?? 0;
        return 'Continue Quest (Stop ${currentStop + 1}/${_questStops.length})';
      default:
        return 'Start Quest';
    }
  }

  bool _canStartQuest() {
    final status = _questProgress?['status'] as String?;
    return status != 'completed';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Loading quest details...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_quest == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Quest not found',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This quest may have been removed or is no longer available.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Go Back',
                  onPressed: () {
                    widget.onBack?.call();
                    Navigator.pop(context);
                  },
                  variant: ButtonVariant.outline,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadQuestDetails,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Enhanced hero section with better animations
            SliverAppBar(
              expandedHeight: 320.0,
              floating: false,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  widget.onBack?.call();
                  Navigator.pop(context);
                },
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorited ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _shareQuest,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image with hero animation
                    Hero(
                      tag: 'quest-image-${_quest!.id}',
                      child: _quest!.coverImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _quest!.coverImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [AppColors.primary, AppColors.secondary],
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.image_not_supported, 
                                           size: 64, color: Colors.white),
                              ),
                            ),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [AppColors.primary, AppColors.secondary],
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.explore, size: 64, color: Colors.white),
                            ),
                          ),
                    ),
                    
                    // Enhanced gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                    
                    // Enhanced title section with more info
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quest status badge
                          if (_questProgress != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _questProgress!['status'] == 'completed' 
                                    ? Colors.green 
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _questProgress!['status'] == 'completed' 
                                    ? 'Completed' 
                                    : 'In Progress',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          
                          Text(
                            _quest!.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.white70, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _quest!.city,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _quest!.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${_quest!.completions})',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Category and difficulty tags
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _quest!.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getDifficultyColor(_quest!.difficulty).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _quest!.difficulty,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
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
              ),
            ),
            
            // Quest details content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced stats with real-time data
                    _buildEnhancedStats(),
                    
                    const SizedBox(height: 24),
                    
                    // Requirements section
                    if (_quest!.requirements.isNotEmpty) ...[
                      _buildRequirements(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Description
                    _buildDescription(),
                    
                    const SizedBox(height: 24),
                    
                    // Quest stops preview with enhanced info
                    _buildEnhancedQuestStops(),
                    
                    const SizedBox(height: 24),
                    
                    // Enhanced reviews section with filtering
                    _buildEnhancedReviewsSection(),
                    
                    const SizedBox(height: 100), // Space for floating button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Enhanced floating action button
      floatingActionButton: Container(
        width: MediaQuery.of(context).size.width - 40,
        height: 56,
        margin: const EdgeInsets.only(left: 30),
        child: CustomButton(
          text: _getQuestStatusText(),
          onPressed: _canStartQuest() ? _startQuest : null,
                     variant: _canStartQuest() ? ButtonVariant.primary : ButtonVariant.outline,
          size: ButtonSize.large,
          icon: _questProgress?['status'] == 'completed' 
              ? Icons.check_circle 
              : _hasStartedQuest 
                  ? Icons.play_arrow 
                  : Icons.play_arrow,
          isFullWidth: true,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEnhancedStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.timer,
                '${_quest!.estimatedDuration}min',
                'Duration',
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[300],
              ),
              _buildStatItem(
                Icons.directions_walk,
                '${_questStops.length} stops',
                'Stops',
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[300],
              ),
              _buildStatItem(
                Icons.emoji_events,
                '${_quest!.points}',
                'Points',
              ),
            ],
          ),
          
          // Additional stats if available
          if (_questStats != null && !_isLoadingStats) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.people,
                  '${_questStats!['total_completions'] ?? 0}',
                  'Completed',
                ),
                _buildStatItem(
                  Icons.timeline,
                  '${_questStats!['avg_completion_time'] ?? 0}min',
                  'Avg Time',
                ),
                _buildStatItem(
                  Icons.star_rate,
                  (_questStats!['avg_rating'] as double?)?.toStringAsFixed(1) ?? '0.0',
                  'Rating',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requirements',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._quest!.requirements.map((req) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                                 Icon(
                   req.type.id == 'age' ? Icons.child_friendly : Icons.info,
                   color: AppColors.primary,
                   size: 24,
                 ),
                const SizedBox(width: 12),
                                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         req.type.displayName,
                         style: const TextStyle(
                           fontSize: 14,
                           fontWeight: FontWeight.w600,
                           color: AppColors.textPrimary,
                         ),
                       ),
                       if (req.customNote != null) ...[
                         const SizedBox(height: 2),
                         Text(
                           req.customNote!,
                           style: const TextStyle(
                             fontSize: 12,
                             color: AppColors.textSecondary,
                           ),
                         ),
                       ],
                     ],
                   ),
                 ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About this quest',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _quest!.description,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        
        // Quest tags
        if (_quest!.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quest!.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildEnhancedQuestStops() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quest Stops',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${_questStops.length} stops',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_questStops.take(3).length, (index) {
          final stop = _questStops[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stop.clue ?? 'Discover this location',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
        }),
        if (_questStops.length > 3)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              'And ${_questStops.length - 3} more stops to discover...',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildEnhancedReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reviews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (_reviews.isNotEmpty)
              Text(
                '${_reviews.length} reviews',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_reviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Column(
              children: [
                Icon(Icons.rate_review, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No reviews yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Be the first to complete this quest and leave a review!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...List.generate(_reviews.take(3).length, (index) {
            final review = _reviews[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CustomAvatar(
                        imageUrl: review.userAvatar,
                        size: AvatarSize.small,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.userName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Row(
                              children: [
                                ...List.generate(5, (starIndex) {
                                  return Icon(
                                    starIndex < review.rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (review.comment.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      review.comment,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }


}