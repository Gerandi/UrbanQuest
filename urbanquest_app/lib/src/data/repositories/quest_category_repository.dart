import '../models/quest_category_model.dart';
import '../../core/services/supabase_service.dart';

class QuestCategoryRepository {
  final SupabaseService _supabaseService = SupabaseService();

  /// Fetches all active quest categories ordered by sort_order
  Future<List<QuestCategory>> getAllCategories() async {
    try {
      final data = await _supabaseService.fetchFromTable(
        'quest_categories',
        select: '*',
        eq: {'is_active': true},
        order: 'sort_order',
        ascending: true,
      );

      return data.map((item) => QuestCategory.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching quest categories: $e');
      return [];
    }
  }

  /// Fetches a specific category by ID
  Future<QuestCategory?> getCategoryById(String id) async {
    try {
      final data = await _supabaseService.fetchFromTable(
        'quest_categories',
        select: '*',
        eq: {'id': id},
        single: true,
      );

      if (data.isNotEmpty) {
        return QuestCategory.fromJson(data.first);
      }
      return null;
    } catch (e) {
      print('Error fetching quest category by ID: $e');
      return null;
    }
  }

  /// Creates a new quest category
  Future<bool> createCategory(QuestCategory category) async {
    try {
      return await _supabaseService.insertIntoTable(
        'quest_categories',
        category.toJson(),
      );
    } catch (e) {
      print('Error creating quest category: $e');
      return false;
    }
  }

  /// Updates an existing quest category
  Future<bool> updateCategory(String id, QuestCategory category) async {
    try {
      return await _supabaseService.updateTable(
        'quest_categories',
        category.toJson(),
        {'id': id},
      );
    } catch (e) {
      print('Error updating quest category: $e');
      return false;
    }
  }

  /// Deletes a quest category (sets is_active to false)
  Future<bool> deleteCategory(String id) async {
    try {
      return await _supabaseService.updateTable(
        'quest_categories',
        {'is_active': false},
        {'id': id},
      );
    } catch (e) {
      print('Error deleting quest category: $e');
      return false;
    }
  }
}