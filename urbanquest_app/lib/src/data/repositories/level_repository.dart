import '../models/level_model.dart';
import '../../core/services/supabase_service.dart'; // Import the new service

class LevelRepository {
  final SupabaseService _supabaseService = SupabaseService();

  Future<List<Level>> getLevels() async {
    try {
      final response = await _supabaseService.fetchFromTable(
        'levels',
        select: '*',
        order: 'level_number',
      );
      
      return response.map<Level>((json) => Level.fromJson(json)).toList();
    } catch (e) {
      print('Error getting levels: \$e');
      return [];
    }
  }
}
