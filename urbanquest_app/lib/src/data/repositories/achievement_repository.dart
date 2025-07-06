import '../models/achievement_model.dart';
import '../../core/services/supabase_service.dart'; // Import the new service

class AchievementRepository {
  final SupabaseService _supabaseService = SupabaseService();

  Future<List<Achievement>> getAllAchievements() async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'achievements',
        select: '*',
        order: 'created_at',
      );
      
      return response.map<Achievement>((json) => Achievement.fromJson(json)).toList();
    } catch (e) {
      print('Error getting achievements: $e');
      return [];
    }
  }

  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'user_achievements',
        select: '*, achievements(*)',
        eq: {'user_id': userId},
      );
      
      return response.map<Achievement>((json) => Achievement.fromJson(json['achievements'])).toList();
    } catch (e) {
      print('Error getting user achievements: $e');
      return [];
    }
  }
}
