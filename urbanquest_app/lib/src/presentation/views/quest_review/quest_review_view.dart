import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../atoms/custom_button.dart';
import '../../atoms/custom_text_field.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/services/quest_completion_service.dart';
import '../../../core/services/supabase_service.dart';

class QuestReviewView extends StatefulWidget {
  final Quest quest;
  final Map<String, dynamic> questStats;

  const QuestReviewView({
    Key? key,
    required this.quest,
    required this.questStats,
  }) : super(key: key);

  @override
  State<QuestReviewView> createState() => _QuestReviewViewState();
}

class _QuestReviewViewState extends State<QuestReviewView> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Quest'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quest completion celebration
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.celebration,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quest Completed!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.quest.title,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quest statistics
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Quest Stats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Time',
                          _formatDuration(widget.questStats['duration_minutes'] ?? 0),
                          Icons.timer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Points',
                          '${widget.questStats['points_earned'] ?? 0}',
                          Icons.stars,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Distance',
                          '${(widget.questStats['distance_walked'] ?? 0).toStringAsFixed(1)} km',
                          Icons.directions_walk,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Steps',
                          '${widget.questStats['steps_count'] ?? 0}',
                          Icons.star,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Rating section
            const Text(
              'Rate This Quest',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How would you rate your overall experience?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: index < _rating ? Colors.amber : Colors.grey,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),
            Center(
              child: Text(
                _getRatingText(_rating),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Review text
            const Text(
              'Write a Review (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share your thoughts to help other explorers!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _reviewController,
              labelText: 'Share your experience',
              hintText: 'Tell others about your quest experience...',
            ),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _skipReview(),
                    child: const Text('Skip for Now'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: _isSubmitting ? 'Submitting...' : 'Submit Review',
                    onPressed: _rating > 0 && !_isSubmitting ? _submitReview : null,
                    isLoading: _isSubmitting,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Social sharing buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Share Your Achievement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSocialButton(
                        'Share',
                        Icons.share,
                        () => _shareQuest(),
                      ),
                      _buildSocialButton(
                        'Photo',
                        Icons.camera_alt,
                        () => _sharePhoto(),
                      ),
                      _buildSocialButton(
                        'Stats',
                        Icons.bar_chart,
                        () => _shareStats(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap a star to rate';
    }
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
  }

  void _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get the current user ID from Supabase
      final userId = SupabaseService().currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await QuestCompletionService().submitQuestReview(
        questId: widget.quest.id,
        userId: userId,
        rating: _rating,
        comment: _reviewController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _skipReview() {
    Navigator.of(context).pop(false);
  }

  void _shareQuest() async {
    try {
      final shareText = 'I just completed "${widget.quest.title}" on UrbanQuest! '
          '🏆 Points: ${widget.questStats['points_earned'] ?? 0} '
          '⏱️ Time: ${_formatDuration(widget.questStats['duration_minutes'] ?? 0)} '
          '🚶 Distance: ${(widget.questStats['distance_walked'] ?? 0).toStringAsFixed(1)} km\n\n'
          'Join me on UrbanQuest and explore amazing cities!';
      
      await Share.share(
        shareText,
        subject: 'UrbanQuest Achievement',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing quest: $e')),
        );
      }
    }
  }

  void _sharePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final shareText = 'Check out my UrbanQuest adventure in "${widget.quest.title}"! 📸\n\n'
            'Join me on UrbanQuest and explore amazing cities!';
        
        await Share.shareXFiles(
          [image],
          text: shareText,
          subject: 'UrbanQuest Photo',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing photo: $e')),
        );
      }
    }
  }

  void _shareStats() async {
    try {
      final stats = widget.questStats;
      final shareText = '🏆 My UrbanQuest Stats for "${widget.quest.title}":\n\n'
          '⭐ Rating: ${_rating > 0 ? '$_rating/5 stars' : 'Not rated yet'}\n'
          '🏅 Points Earned: ${stats['points_earned'] ?? 0}\n'
          '⏱️ Completion Time: ${_formatDuration(stats['duration_minutes'] ?? 0)}\n'
          '🚶 Distance Walked: ${(stats['distance_walked'] ?? 0).toStringAsFixed(1)} km\n'
          '👣 Steps Taken: ${stats['steps_count'] ?? 0}\n\n'
          'Join me on UrbanQuest and start your own adventure! 🌟';
      
      await Share.share(
        shareText,
        subject: 'UrbanQuest Achievement Stats',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing stats: $e')),
        );
      }
    }
  }
} 