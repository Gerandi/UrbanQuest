import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/language_model.dart';
import '../../data/services/app_data_service.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'en';
  
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  final AppDataService _appDataService = AppDataService();
  
  Language? _currentLanguage;
  List<Language>? _availableLanguages;

  /// Get current selected language
  Language? get currentLanguage => _currentLanguage;
  
  /// Get available languages
  List<Language>? get availableLanguages => _availableLanguages;

  /// Initialize language service - call this at app startup
  Future<void> initialize() async {
    try {
      // Load available languages from backend
      _availableLanguages = await _appDataService.getAvailableLanguages();
      
      // Get stored language preference
      final prefs = await SharedPreferences.getInstance();
      final storedLanguageCode = prefs.getString(_languageKey);
      
      if (storedLanguageCode != null) {
        // Find the stored language in available languages
        _currentLanguage = _availableLanguages?.firstWhere(
          (lang) => lang.code == storedLanguageCode,
          orElse: () => _getDefaultLanguage(),
        );
      } else {
        // Use device locale or default language
        _currentLanguage = await _getDeviceLanguageOrDefault();
      }
      
      // Save the selected language
      await _saveLanguagePreference(_currentLanguage!.code);
    } catch (e) {
      print('Error initializing language service: $e');
      _currentLanguage = _getDefaultLanguage();
    }
  }

  /// Change the app language
  Future<bool> changeLanguage(String languageCode) async {
    try {
      final newLanguage = _availableLanguages?.firstWhere(
        (lang) => lang.code == languageCode,
        orElse: () => _getDefaultLanguage(),
      );
      
      if (newLanguage != null) {
        _currentLanguage = newLanguage;
        await _saveLanguagePreference(languageCode);
        
        // Clear app data cache to reload with new language
        _appDataService.clearCache();
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error changing language: $e');
      return false;
    }
  }

  /// Get current language code
  String get currentLanguageCode => _currentLanguage?.code ?? _defaultLanguage;
  
  /// Get current language code for async operations
  Future<String> getCurrentLanguage() async {
    if (_currentLanguage != null) {
      return _currentLanguage!.code;
    }
    
    // If not initialized, try to initialize
    await initialize();
    return currentLanguageCode;
  }

  /// Check if a language is supported
  bool isLanguageSupported(String languageCode) {
    return _availableLanguages?.any((lang) => lang.code == languageCode) ?? false;
  }

  /// Get language by code
  Language? getLanguageByCode(String code) {
    return _availableLanguages?.firstWhere(
      (lang) => lang.code == code,
      orElse: () => _getDefaultLanguage(),
    );
  }

  /// Get default language
  Language _getDefaultLanguage() {
    return _availableLanguages?.firstWhere(
      (lang) => lang.isDefault,
      orElse: () => const Language(
        code: _defaultLanguage,
        name: 'English',
        nativeName: 'English',
        flagEmoji: '🇺🇸',
        isDefault: true,
      ),
    ) ?? const Language(
      code: _defaultLanguage,
      name: 'English',
      nativeName: 'English',
      flagEmoji: '🇺🇸',
      isDefault: true,
    );
  }

  /// Try to get device language or fall back to default
  Future<Language> _getDeviceLanguageOrDefault() async {
    try {
      // Get device locale
      final deviceLocale = ui.window.locale;
      final deviceLanguageCode = deviceLocale.languageCode;
      
      // Check if device language is available
      final deviceLanguage = _availableLanguages?.firstWhere(
        (lang) => lang.code == deviceLanguageCode,
        orElse: () => _getDefaultLanguage(),
      );
      
      return deviceLanguage ?? _getDefaultLanguage();
    } catch (e) {
      print('Error getting device language: $e');
      return _getDefaultLanguage();
    }
  }

  /// Save language preference to local storage
  Future<void> _saveLanguagePreference(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  /// Get language display name in current language
  String getLanguageDisplayName(Language language) {
    // For now, return native name
    // In a full implementation, this would return translated names
    return language.nativeName;
  }

  /// Get formatted language option for UI
  String getLanguageOption(Language language) {
    return '${language.flagEmoji} ${language.nativeName}';
  }

  /// Reload available languages from backend
  Future<void> refreshAvailableLanguages() async {
    try {
      _availableLanguages = await _appDataService.getAvailableLanguages(forceRefresh: true);
    } catch (e) {
      print('Error refreshing available languages: $e');
    }
  }

  /// Get languages sorted by name
  List<Language> get sortedLanguages {
    if (_availableLanguages == null) return [];
    
    final sorted = List<Language>.from(_availableLanguages!);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    
    // Put default language first
    final defaultLang = sorted.firstWhere(
      (lang) => lang.isDefault,
      orElse: () => sorted.first,
    );
    sorted.remove(defaultLang);
    sorted.insert(0, defaultLang);
    
    return sorted;
  }

  /// Check if current language is RTL (right-to-left)
  bool get isCurrentLanguageRTL {
    // Add RTL language codes as needed
    const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
    return rtlLanguages.contains(currentLanguageCode);
  }

  /// Get text direction for current language
  String get textDirection => isCurrentLanguageRTL ? 'rtl' : 'ltr';
} 