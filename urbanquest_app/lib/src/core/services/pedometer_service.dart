import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PedometerService {
  static final PedometerService _instance = PedometerService._internal();
  factory PedometerService() => _instance;
  PedometerService._internal();

  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;

  int _initialStepCount = 0;
  int _currentStepCount = 0;
  int _questSteps = 0;
  bool _isTracking = false;
  String? _activeQuestId;
  DateTime? _trackingStartTime;
  DateTime? _questStartTime;
  PedestrianStatus? _pedestrianStatus;

  // Typical step length for adults (meters)
  static const double _averageStepLength = 0.762;

  // Getters for real-time access
  bool get isTracking => _isTracking;
  String? get activeQuestId => _activeQuestId;
  PedestrianStatus? get pedestrianStatus => _pedestrianStatus;
  DateTime? get questStartTime => _questStartTime;

  /// Start tracking steps for a quest
  Future<bool> startTracking(String questId) async {
    try {
      if (_isTracking) {
        await stopTracking();
      }

      _activeQuestId = questId;
      _isTracking = true;
      _trackingStartTime = DateTime.now();
      _questStartTime = DateTime.now();
      _questSteps = 0;

      // Skip pedometer initialization on web platform
      if (kIsWeb) {
        print('Pedometer tracking started for quest: $questId (Web mode - using mock data)');
        await _saveTrackingState();
        return true;
      }

      await _initializeStepCount();

      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
      );

      _pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
      );

      await _saveTrackingState();
      print('Pedometer tracking started for quest: $questId');
      return true;
    } catch (e) {
      print('Error starting pedometer tracking: $e');
      return false;
    }
  }

  /// Stop tracking steps
  Future<void> stopTracking() async {
    try {
      _stepCountStream?.cancel();
      _pedestrianStatusStream?.cancel();
      
      if (_isTracking && _activeQuestId != null) {
        await _saveQuestData();
      }

      _isTracking = false;
      _activeQuestId = null;
      _initialStepCount = 0;
      _currentStepCount = 0;
      _questSteps = 0;
      _trackingStartTime = null;
      _questStartTime = null;
      _pedestrianStatus = null;

      await _clearTrackingState();
      print('Pedometer tracking stopped');
    } catch (e) {
      print('Error stopping pedometer tracking: $e');
    }
  }

  void _onStepCount(StepCount event) {
    if (!_isTracking || kIsWeb) return;

    _currentStepCount = event.steps;
    
    if (_initialStepCount == 0) {
      _initialStepCount = _currentStepCount;
    }
    
    _questSteps = _currentStepCount - _initialStepCount;
    
    _saveTrackingState();
    print('Steps update: Total: $_currentStepCount, Quest steps: $_questSteps');
  }

  void _onStepCountError(error) {
    print('Pedometer step count error: $error');
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    _pedestrianStatus = event;
    print('Pedestrian status: $_pedestrianStatus');
  }

  void _onPedestrianStatusError(error) {
    print('Pedometer status error: $error');
  }

  double getCurrentDistance() {
    if (!_isTracking) return 0.0;
    return _questSteps * _averageStepLength;
  }

  double getCurrentDistanceKm() {
    return getCurrentDistance() / 1000;
  }

  int getCurrentSteps() {
    // Return mock data for web platform during tracking
    if (kIsWeb && _isTracking && _questStartTime != null) {
      final minutes = DateTime.now().difference(_questStartTime!).inMinutes;
      return (minutes * 50).clamp(0, 2000); // Mock ~50 steps per minute
    }
    return _questSteps;
  }

  int getQuestDurationMinutes() {
    if (_questStartTime == null) return 0;
    return DateTime.now().difference(_questStartTime!).inMinutes;
  }

  int getQuestDurationSeconds() {
    if (_questStartTime == null) return 0;
    return DateTime.now().difference(_questStartTime!).inSeconds;
  }

  String getFormattedDuration() {
    if (_questStartTime == null) return '00:00';
    
    final duration = DateTime.now().difference(_questStartTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  double getAverageSpeed() {
    if (_questStartTime == null || _questSteps == 0) return 0.0;
    
    final durationHours = DateTime.now().difference(_questStartTime!).inMilliseconds / (1000 * 60 * 60);
    final distanceKm = getCurrentDistanceKm();
    
    if (durationHours <= 0) return 0.0;
    return distanceKm / durationHours;
  }

  int getCaloriesBurned() {
    return (_questSteps * 0.04).round();
  }

  Future<void> _initializeStepCount() async {
    if (kIsWeb) {
      // Mock initialization for web platform
      _initialStepCount = 0;
      _currentStepCount = 0;
      _questSteps = 0;
      print('Initial step count: $_initialStepCount (Web mode)');
      return;
    }
    
    try {
      final stepCountStream = Pedometer.stepCountStream;
      final stepCount = await stepCountStream.first.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Failed to get initial step count'),
      );
      
      _initialStepCount = stepCount.steps;
      _currentStepCount = stepCount.steps;
      _questSteps = 0;
      
      print('Initial step count: $_initialStepCount');
    } catch (e) {
      print('Error initializing step count: $e');
      _initialStepCount = 0;
      _currentStepCount = 0;
      _questSteps = 0;
    }
  }

  Future<void> _saveQuestData() async {
    if (_activeQuestId == null || _questStartTime == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final distance = getCurrentDistanceKm();
      final steps = getCurrentSteps();
      final durationMinutes = getQuestDurationMinutes();
      final calories = getCaloriesBurned();
      final averageSpeed = getAverageSpeed();

      await prefs.setDouble('quest_${_activeQuestId}_distance', distance);
      await prefs.setInt('quest_${_activeQuestId}_steps', steps);
      await prefs.setInt('quest_${_activeQuestId}_duration', durationMinutes);
      await prefs.setInt('quest_${_activeQuestId}_calories', calories);
      await prefs.setDouble('quest_${_activeQuestId}_speed', averageSpeed);
      await prefs.setString('quest_${_activeQuestId}_completed', DateTime.now().toIso8601String());

      print('Saved quest data: ${distance.toStringAsFixed(2)} km, $steps steps, ${durationMinutes}min');
    } catch (e) {
      print('Error saving quest data: $e');
    }
  }

  Future<double> getSavedQuestDistance(String questId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('quest_${questId}_distance') ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<int> getSavedQuestSteps(String questId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('quest_${questId}_steps') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getSavedQuestDuration(String questId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('quest_${questId}_duration') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getSavedQuestCalories(String questId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('quest_${questId}_calories') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _saveTrackingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pedometer_tracking', _isTracking);
      await prefs.setString('active_quest_id', _activeQuestId ?? '');
      await prefs.setInt('initial_step_count', _initialStepCount);
      await prefs.setInt('current_step_count', _currentStepCount);
      await prefs.setInt('quest_steps', _questSteps);
      if (_trackingStartTime != null) {
        await prefs.setString('tracking_start_time', _trackingStartTime!.toIso8601String());
      }
      if (_questStartTime != null) {
        await prefs.setString('quest_start_time', _questStartTime!.toIso8601String());
      }
    } catch (e) {
      print('Error saving tracking state: $e');
    }
  }

  Future<void> _clearTrackingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pedometer_tracking');
      await prefs.remove('active_quest_id');
      await prefs.remove('initial_step_count');
      await prefs.remove('current_step_count');
      await prefs.remove('quest_steps');
      await prefs.remove('tracking_start_time');
      await prefs.remove('quest_start_time');
    } catch (e) {
      print('Error clearing tracking state: $e');
    }
  }

  Future<void> restoreTrackingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isTracking = prefs.getBool('pedometer_tracking') ?? false;
      _activeQuestId = prefs.getString('active_quest_id');
      _initialStepCount = prefs.getInt('initial_step_count') ?? 0;
      _currentStepCount = prefs.getInt('current_step_count') ?? 0;
      _questSteps = prefs.getInt('quest_steps') ?? 0;
      
      final trackingStartString = prefs.getString('tracking_start_time');
      if (trackingStartString != null) {
        _trackingStartTime = DateTime.parse(trackingStartString);
      }
      
      final questStartString = prefs.getString('quest_start_time');
      if (questStartString != null) {
        _questStartTime = DateTime.parse(questStartString);
      }

      if (_isTracking && _activeQuestId != null && _activeQuestId!.isNotEmpty) {
        if (!kIsWeb) {
          _stepCountStream = Pedometer.stepCountStream.listen(
            _onStepCount,
            onError: _onStepCountError,
          );

          _pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen(
            _onPedestrianStatusChanged,
            onError: _onPedestrianStatusError,
          );
        }

        print('Restored tracking state for quest: $_activeQuestId${kIsWeb ? ' (Web mode)' : ''}');
      }
    } catch (e) {
      print('Error restoring tracking state: $e');
    }
  }

  Future<bool> isPedometerAvailable() async {
    if (kIsWeb) {
      return false; // Pedometer not available on web
    }
    
    try {
      await Pedometer.stepCountStream.first.timeout(const Duration(seconds: 3));
      return true;
    } catch (e) {
      print('Pedometer not available: $e');
      return false;
    }
  }

  Future<int> getTotalDailySteps() async {
    if (kIsWeb) {
      return 0; // No daily steps available on web
    }
    
    try {
      final stepCount = await Pedometer.stepCountStream.first.timeout(const Duration(seconds: 3));
      return stepCount.steps;
    } catch (e) {
      return 0;
    }
  }

  Future<void> resetQuestData(String questId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('quest_${questId}_distance');
      await prefs.remove('quest_${questId}_steps');
      await prefs.remove('quest_${questId}_duration');
      await prefs.remove('quest_${questId}_calories');
      await prefs.remove('quest_${questId}_speed');
      await prefs.remove('quest_${questId}_completed');
      print('Reset data for quest: $questId');
    } catch (e) {
      print('Error resetting quest data: $e');
    }
  }
} 