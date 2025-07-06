import '../models/quest_review_model.dart';
import '../../core/services/supabase_service.dart'; // Import the new service

class QuestReviewRepository {
  final SupabaseService _supabaseService = SupabaseService();

  /// Submit a new review for a quest
  Future<bool> submitReview({
    required String questId,
    required double rating,
    required String comment,
    List<String>? photoUrls,
    List<String>? tags,
  }) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data for review
      final userResponse = await _supabaseService.fetchFromTable(
        'profiles',
        select: 'display_name, avatar_url',
        eq: {'id': user.id},
        single: true,
      );

      final review = QuestReview(
        id: '', // Will be set by Supabase
        questId: questId,
        userId: user.id,
        userName: userResponse.isNotEmpty ? userResponse.first['display_name'] ?? 'Anonymous' : 'Anonymous',
        userAvatar: userResponse.isNotEmpty ? userResponse.first['avatar_url'] ?? '' : '',
        rating: rating,
        comment: comment,
        photos: photoUrls ?? [],
        createdAt: DateTime.now(),
        helpfulVotes: 0,
        tags: tags ?? [],
      );

      // Add review to Supabase
      await _supabaseService.insertIntoTable('quest_reviews', review.toJson());

      // Update quest rating
      await _updateQuestRating(questId);

      return true;
    } catch (e) {
      print('Error submitting review: $e');
      return false;
    }
  }

  /// Get reviews for a specific quest
  Future<List<QuestReview>> getQuestReviews(String questId, {
    int limit = 20,
    String? orderBy = 'created_at',
    bool descending = true,
  }) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'quest_reviews',
        select: '*',
        eq: {'quest_id': questId},
        limit: limit,
        order: orderBy,
        ascending: !descending,
      );

      return response
          .map((data) => QuestReview.fromJson(data))
          .toList();
    } catch (e) {
      print('Error getting quest reviews: $e');
      return [];
    }
  }

  /// Get reviews by a specific user
  Future<List<QuestReview>> getUserReviews(String userId, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'quest_reviews',
        select: '*',
        eq: {'user_id': userId},
        order: 'created_at',
        ascending: false,
        limit: limit,
      );

      return response
          .map((data) => QuestReview.fromJson(data))
          .toList();
    } catch (e) {
      print('Error getting user reviews: $e');
      return [];
    }
  }

  /// Vote on a review as helpful
  Future<bool> voteReviewHelpful(String reviewId, bool isHelpful) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (isHelpful) {
        // Add helpful vote
        await _supabaseService.insertIntoTable(
          'review_votes',
          {
            'user_id': user.id,
            'review_id': reviewId,
            'is_helpful': true,
            'created_at': DateTime.now().toIso8601String(),
          },
        );

        // Increment helpful count
        await _supabaseService.callRpc('increment_review_helpful_votes', params: {
          'review_id': reviewId,
          'increment': 1,
        });
      } else {
        // Remove helpful vote
        await _supabaseService.deleteFromTable(
          'review_votes',
          {'user_id': user.id, 'review_id': reviewId},
        );

        // Decrement helpful count
        await _supabaseService.callRpc('increment_review_helpful_votes', params: {
          'review_id': reviewId,
          'increment': -1,
        });
      }

      return true;
    } catch (e) {
      print('Error voting on review: $e');
      return false;
    }
  }

  /// Check if user has voted on a review
  Future<bool> hasUserVotedOnReview(String reviewId) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) return false;

      final response = await _supabaseService.fetchFromTable(
        'review_votes',
        select: 'id',
        eq: {'user_id': user.id, 'review_id': reviewId},
        maybeSingle: true,
      );

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking review vote: $e');
      return false;
    }
  }

  /// Get featured/highlighted reviews
  Future<List<QuestReview>> getFeaturedReviews({
    int limit = 10,
  }) async {
    try {
      // Use RPC function to get featured reviews with helpful_votes >= 5
      final response = await _supabaseService.callRpc(
        'get_featured_reviews',
        params: {'min_helpful_votes': 5, 'limit_count': limit},
      );

      if (response is List) {
        return response
            .map((data) => QuestReview.fromJson(data))
            .toList();
      }

      return [];
    } catch (e) {
      print('Error getting featured reviews: $e');
      // Fallback: get all reviews ordered by helpful_votes
      try {
      final response = await _supabaseService.fetchFromTable(
        'quest_reviews',
        select: '*',
        order: 'helpful_votes',
        ascending: false,
        limit: limit,
      );

        // Filter reviews with helpful_votes >= 5 on the client side
      return response
            .where((data) => (data['helpful_votes'] as int? ?? 0) >= 5)
          .map((data) => QuestReview.fromJson(data))
          .toList();
      } catch (e2) {
        print('Error in fallback featured reviews: $e2');
      return [];
      }
    }
  }

  /// Get review statistics for a quest
  Future<Map<String, dynamic>> getReviewStatistics(String questId) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'quest_reviews',
        select: 'rating',
        eq: {'quest_id': questId},
      );

      final reviews = response;
      
      if (reviews.isEmpty) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': [0, 0, 0, 0, 0],
        };
      }

      double totalRating = 0;
      List<int> distribution = [0, 0, 0, 0, 0]; // 1-5 stars

      for (var review in reviews) {
        final rating = (review['rating'] as num).toDouble();
        totalRating += rating;
        
        // Add to distribution (rating 1-5 maps to index 0-4)
        final index = (rating - 1).clamp(0, 4).toInt();
        distribution[index]++;
      }

      return {
        'totalReviews': reviews.length,
        'averageRating': totalRating / reviews.length,
        'ratingDistribution': distribution,
      };
    } catch (e) {
      print('Error getting review statistics: $e');
      return {
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingDistribution': [0, 0, 0, 0, 0],
      };
    }
  }

  /// Private method to update quest rating
  Future<void> _updateQuestRating(String questId) async {
    try {
      final stats = await getReviewStatistics(questId);
      final averageRating = stats['averageRating'] as double;

      await _supabaseService.updateTable(
        'quests',
        {'rating': averageRating},
        {'id': questId},
      );
    } catch (e) {
      print('Error updating quest rating: $e');
    }
  }

  /// Delete a review (for moderation or user request)
  Future<bool> deleteReview(String reviewId) async {
    try {
      final user = _supabaseService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get the review to check ownership and quest ID
      final reviewResponse = await _supabaseService.fetchFromTable(
        'quest_reviews',
        select: 'user_id, quest_id',
        eq: {'id': reviewId},
        single: true,
      );

      if (reviewResponse.isEmpty) {
        throw Exception('Review not found');
      }

      // Only allow user to delete their own reviews
      if (reviewResponse.first['user_id'] != user.id) {
        throw Exception('Not authorized to delete this review');
      }

      // Delete the review
      await _supabaseService.deleteFromTable(
        'quest_reviews',
        {'id': reviewId},
      );

      // Update quest rating after deletion
      await _updateQuestRating(reviewResponse.first['quest_id']);

      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }
} 