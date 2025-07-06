import '../models/quest_model.dart';
import '../models/achievement_model.dart';
import '../models/language_model.dart';
import '../models/quest_stop_model.dart';
import 'dart:convert';
import '../../core/services/storage_service.dart';
import '../../core/services/supabase_service.dart'; // Import the new SupabaseService

class City {
  final String id;
  final String name;
  final String description;
  final String? countryId;
  final double latitude;
  final double longitude;
  final String? coverImageUrl;
  final int questCount;
  final int totalPoints;
  final double difficulty;
  final bool featured;
  final String languageCode;

  const City({
    required this.id,
    required this.name,
    required this.description,
    this.countryId,
    required this.latitude,
    required this.longitude,
    this.coverImageUrl,
    required this.questCount,
    required this.totalPoints,
    required this.difficulty,
    required this.featured,
    required this.languageCode,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      countryId: json['country_id'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      coverImageUrl: json['cover_image_url'] as String?,
      questCount: json['quest_count'] as int? ?? 0, // Handle nullable quest_count
      totalPoints: json['total_points'] as int? ?? 0, // Handle nullable total_points
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 1.0, // Handle nullable difficulty
      featured: json['featured'] as bool? ?? false, // Handle nullable featured
      languageCode: json['language_code'] as String? ?? 'en', // Handle nullable language_code
    );
  }
}

class QuestCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String color;
  final bool isActive;
  final int sortOrder;

  const QuestCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.sortOrder,
  });

  factory QuestCategory.fromJson(Map<String, dynamic> json) {
    return QuestCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      isActive: json['is_active'] as bool,
      sortOrder: json['sort_order'] as int,
    );
  }
}

class AppDataService {
  static final AppDataService _instance = AppDataService._internal();
  factory AppDataService() => _instance;
  AppDataService._internal();

  static AppDataService get instance => _instance;

  final SupabaseService _supabaseService = SupabaseService(); // Use the new service
  final StorageService _storageService = StorageService();
  
  // Cache for data with language support
  final Map<String, List<City>> _citiesCache = {};
  final Map<String, List<Quest>> _questsCache = {};
  final Map<String, List<QuestStop>> _questStopsCache = {};
  List<QuestCategory>? _categoriesCache;
  List<Achievement>? _achievementsCache;
  List<Language>? _languagesCache;
  final Map<String, dynamic> _appConfigCache = {};
  
  DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 15);

  /// Get available languages
  Future<List<Language>> getAvailableLanguages({bool forceRefresh = false}) async {
    if (!forceRefresh && _languagesCache != null) {
      return _languagesCache!;
    }

    try {
      final response = await _supabaseService.callRpc('get_available_languages');
      final languagesJson = response as List;
      
      _languagesCache = languagesJson
          .map((lang) => Language.fromJson(lang as Map<String, dynamic>))
          .toList();
      
      return _languagesCache!;
    } catch (e) {
      print('Error fetching languages: $e');
      return _languagesCache ?? [
        const Language(
          code: 'en',
          name: 'English',
          nativeName: 'English',
          flagEmoji: '🇺🇸',
          isDefault: true,
        )
      ];
    }
  }

  /// Get cities with language support
  Future<List<City>> getCities({
    String languageCode = 'en', 
    bool forceRefresh = false
  }) async {
    if (!forceRefresh && _citiesCache.containsKey(languageCode)) {
      return _citiesCache[languageCode]!;
    }

    try {
      final response = await _supabaseService.callRpc('get_cities_i18n', params: {
        'p_language_code': languageCode,
      });
      
      final citiesJson = response as List;
      final cities = citiesJson
          .map((city) => City.fromJson(city as Map<String, dynamic>))
          .toList();
      
      _citiesCache[languageCode] = cities;
      _lastCacheUpdate = DateTime.now();
      
      return cities;
    } catch (e) {
      print('Error fetching cities: $e');
      // Return cached data or fallback data if no cache exists
      if (_citiesCache.containsKey(languageCode)) {
        return _citiesCache[languageCode]!;
      }
      return _getFallbackCities();
    }
  }

  /// Get fallback cities when backend fails
  List<City> _getFallbackCities() {
    return [
      const City(
        id: 'demo-city-1',
        name: 'Demo City',
        description: 'A sample city for testing UrbanQuest features',
        latitude: 40.7128,
        longitude: -74.0060,
        coverImageUrl: 'https://via.placeholder.com/600x400?text=Demo+City',
        questCount: 2,
        totalPoints: 150,
        difficulty: 1.5,
        featured: true,
        languageCode: 'en',
      ),
    ];
  }

  /// Get quests by city ID
  Future<List<Quest>> getQuestsByCity(String cityId, {String languageCode = 'en'}) async {
    return await getQuests(cityId: cityId, languageCode: languageCode);
  }

  /// Get quests with language support
  Future<List<Quest>> getQuests({
    String? cityId,
    String languageCode = 'en',
    String? categoryId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${languageCode}_${cityId ?? 'all'}_${categoryId ?? 'all'}';
    
    if (!forceRefresh && _questsCache.containsKey(cacheKey) && _isCacheValid()) {
      return _questsCache[cacheKey]!;
    }

    try {
      final userId = _supabaseService.currentUser?.id;
      final response = await _supabaseService.callRpc('get_quests_with_details', params: {
        'p_city_id': cityId,
        'p_language_code': languageCode,
        'p_category_id': categoryId,
        'p_user_id': userId,
      });
      print('Supabase RPC get_quests_with_details response: $response');
      
      final questsJson = response as List;
      final quests = questsJson
          .map((quest) => Quest.fromJson(quest as Map<String, dynamic>))
          .toList();
      
      _questsCache[cacheKey] = quests;
      _lastCacheUpdate = DateTime.now();
      
      // Save to local storage
      await _storageService.saveData('quests_$cacheKey', questsJson);
      
      return quests;
    } catch (e) {
      print('Error fetching quests: $e');
      // Try to load from local storage
      final localData = await _storageService.getData('quests_$cacheKey');
      if (localData != null) {
        final quests = (localData as List)
            .map((quest) => Quest.fromJson(quest as Map<String, dynamic>))
            .toList();
        _questsCache[cacheKey] = quests;
        return quests;
      }
      throw Exception('Failed to load quests: $e');
    }
  }

  /// Get a single quest by its ID
  Future<Quest?> getQuestById(String questId, {String languageCode = 'en'}) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      final response = await _supabaseService.callRpc('get_quests_with_details', params: {
        'p_quest_id': questId,
        'p_language_code': languageCode,
        'p_user_id': userId,
      });
      print('Supabase RPC get_quests_with_details (single) response: $response');

      if (response == null || (response as List).isEmpty) {
        print('Quest with ID $questId not found.');
        return null;
      }
      
      return Quest.fromJson((response).first as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching quest by ID: $e');
      return null;
    }
  }

  /// Get quest stops with language support
  Future<List<QuestStop>> getQuestStops({
    required String questId,
    String languageCode = 'en',
    bool forceRefresh = false,
  }) async {
    final cacheKey = '${questId}_$languageCode';
    
    if (!forceRefresh && _questStopsCache.containsKey(cacheKey)) {
      return _questStopsCache[cacheKey]!;
    }

    try {
      final response = await _supabaseService.fetchFromTable(
        'quest_stops',
        select: '*',
        eq: {'quest_id': questId},
        order: 'order_index',
      );

      final stopsJson = response as List;
      final stops = stopsJson
          .map((stop) => QuestStop.fromJson(stop as Map<String, dynamic>))
          .toList();
      
      _questStopsCache[cacheKey] = stops;
      
      // Cache locally for offline access
      await _storageService.saveData('quest_stops_$cacheKey', stopsJson);
      
      return stops;
    } catch (e) {
      print('Error fetching quest stops: $e');
      
      // Try to load from local cache
      final cachedData = await _storageService.getData('quest_stops_$cacheKey');
      if (cachedData != null) {
        final stops = (cachedData as List)
            .map((stop) => QuestStop.fromJson(stop as Map<String, dynamic>))
            .toList();
        return stops;
      }
      
      rethrow;
    }
  }

  /// Get quest categories
  Future<List<QuestCategory>> getQuestCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _categoriesCache != null) {
      return _categoriesCache!;
    }

    try {
      final response = await _supabaseService.fetchFromTable(
        'quest_categories',
        select: '*',
        eq: {'is_active': true},
        order: 'sort_order',
      );
      
      _categoriesCache = (response as List)
          .map((category) => QuestCategory.fromJson(category))
          .toList();
      
      return _categoriesCache!;
    } catch (e) {
      print('Error fetching quest categories: $e');
      return _categoriesCache ?? [];
    }
  }

  /// Get achievements
  Future<List<Achievement>> getAchievements({bool forceRefresh = false}) async {
    if (!forceRefresh && _achievementsCache != null) {
      return _achievementsCache!;
    }

    try {
      final response = await _supabaseService.fetchFromTable(
        'achievements',
        select: '*',
        eq: {'is_active': true},
      );
      
      _achievementsCache = (response as List)
          .map((achievement) => Achievement.fromJson(achievement))
          .toList();
      
      return _achievementsCache!;
    } catch (e) {
      print('Error fetching achievements: $e');
      return _achievementsCache ?? [];
    }
  }

  /// Get app configuration
  Future<Map<String, dynamic>> getAppConfig({bool forceRefresh = false}) async {
    if (!forceRefresh && _appConfigCache.isNotEmpty && _isCacheValid()) {
      return _appConfigCache;
    }

    try {
      final response = await _supabaseService.fetchFromTable(
        'app_config',
        select: '*',
        eq: {'is_public': true},
      );

      final config = <String, dynamic>{};
      for (final item in response as List) {
        config[item['key']] = item['value'];
      }

      _appConfigCache.clear();
      _appConfigCache.addAll(config);
      _lastCacheUpdate = DateTime.now();
      
      // Save to local storage
      await _storageService.saveData('app_config', config);
      
      return config;
    } catch (e) {
      print('Error getting app config: $e');
      // Try to load from local storage
      final localConfig = await _storageService.getData('app_config');
      if (localConfig != null) {
        _appConfigCache.clear();
        _appConfigCache.addAll(Map<String, dynamic>.from(localConfig));
        return _appConfigCache;
      }
      return {};
    }
  }

  /// Check if test mode is enabled for location verification
  Future<bool> isTestModeEnabled() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return false;

      // Check app config for test mode
      final config = await _supabaseService.fetchFromTable(
        'app_config',
        select: 'value',
        eq: {'key': 'enable_test_mode'},
        maybeSingle: true,
      );
      
      final testModeEnabled = config.isNotEmpty ? config.first['value']['enabled'] as bool? ?? false : false;
      
      if (!testModeEnabled) return false;

      // Check if current user is in test users list
      final testUsersConfig = await _supabaseService.fetchFromTable(
        'app_config', 
        select: 'value',
        eq: {'key': 'test_user_emails'},
        maybeSingle: true,
      );
      
      final testEmails = testUsersConfig.isNotEmpty ? testUsersConfig.first['value']['emails'] as List? ?? [] : [];
      final userEmail = _supabaseService.currentUser?.email;
      
      return testEmails.contains(userEmail);
    } catch (e) {
      print('Error checking test mode: $e');
      return false;
    }
  }

  /// Submit a challenge answer
  Future<Map<String, dynamic>> submitChallengeAnswer({
    required String questId,
    required String questStopId,
    required String challengeType,
    required dynamic answer,
    Map<String, dynamic>? locationData,
    List<int>? photoData,
  }) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseService.callRpc('submit_challenge_answer', params: {
        'p_user_id': userId,
        'p_quest_id': questId,
        'p_quest_stop_id': questStopId,
        'p_challenge_type': challengeType,
        'p_answer': answer.toString(),
        'p_location_data': locationData != null ? jsonEncode(locationData) : null,
        'p_photo_data': photoData != null ? jsonEncode(photoData) : null,
      });

      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error submitting challenge answer: $e');
      return {
        'success': false,
        'message': 'Failed to submit answer: $e',
      };
    }
  }

  /// Periodic cache sync
  Future<void> syncCacheWithServer() async {
    try {
      print('Syncing cache with server...');
      
      // Clear cache and force refresh
      _questsCache.clear();
      _questStopsCache.clear();
      _appConfigCache.clear();
      
      // Reload most recent data
      await getAppConfig(forceRefresh: true);
      await getQuests(forceRefresh: true);
      
      print('Cache sync completed');
    } catch (e) {
      print('Error during cache sync: $e');
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheExpiry;
  }

  /// Clear all caches
  void clearCache() {
    _questsCache.clear();
    _questStopsCache.clear();
    _appConfigCache.clear();
    _lastCacheUpdate = null;
  }

  /// Start periodic sync timer
  void startPeriodicSync() {
    // Sync every 5 minutes in background
    Stream.periodic(const Duration(minutes: 5)).listen((_) async {
      await syncCacheWithServer();
    });
  }
}
 