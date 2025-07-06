import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../atoms/custom_card.dart';
import '../../atoms/custom_button.dart';
import '../../atoms/custom_text_field.dart';
import '../../atoms/progress_indicator.dart';
import '../../organisms/top_navigation_bar.dart';
import '../../organisms/bottom_navigation_bar.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/models/quest_stop_model.dart';
import '../../../data/repositories/quest_repository.dart';
import '../../../data/services/quest_completion_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../templates/app_template.dart';
import '../../../core/services/pedometer_service.dart';
import '../../../core/services/location_verification_service.dart';
import '../../../core/services/photo_upload_service.dart';
import '../../../core/services/realtime_service.dart';
import '../../../core/services/language_service.dart';
import '../quest_complete/quest_complete_view.dart';
import '../../../data/services/app_data_service.dart';
import '../../../logic/quest_bloc/quest_bloc.dart';

class QuestGameplayView extends StatefulWidget {
  final Quest quest;
  final VoidCallback? onBack;
  final Function(AppView, [NavigationData?])? onNavigate;

  const QuestGameplayView({
    Key? key, 
    required this.quest,
    this.onBack,
    this.onNavigate,
  }) : super(key: key);

  @override
  State<QuestGameplayView> createState() => _QuestGameplayViewState();
}

class _QuestGameplayViewState extends State<QuestGameplayView> 
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _answerController = TextEditingController();
  
  List<QuestStop> _questStops = [];
  int _currentStopIndex = 0;
  bool _isLoading = true;
  bool _isTestMode = false;
  int? _selectedChoiceIndex;
  final bool _isSubmittingAnswer = false;
  Map<String, dynamic>? _currentUserProgress;
  final bool _hasArrived = false;
  Map<String, dynamic> _feedback = { 'show': false, 'correct': false, 'text': '' };
  
  // Time tracking
  DateTime? _questStartTime;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  
  // Pedometer tracking
  int _steps = 0;
  final int _questStartSteps = 0;
  StreamSubscription? _stepCountStream;
  
  // Location tracking
  bool _isAtLocation = false;
  double _distanceToTarget = 0.0;
  
  // Animation controllers
  late AnimationController _progressAnimationController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadQuestData();
    _startTimeTracking();
    _initializePedometer();
  }

  void _initializeAnimations() {
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _startTimeTracking() {
    _questStartTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_questStartTime!);
        });
      }
    });
  }

  Future<void> _initializePedometer() async {
    try {
      // Start real pedometer tracking for this quest
      final success = await PedometerService().startTracking(widget.quest.id);
      if (success) {
        print('Pedometer tracking started for quest: ${widget.quest.id}');
        // Update steps every second
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _steps = PedometerService().getCurrentSteps();
            });
          }
        });
      } else {
        print('Failed to start pedometer tracking');
        // Fallback: simulate steps if pedometer is not available
        _simulateSteps();
      }
    } catch (e) {
      print('Error initializing pedometer: $e');
      // Fallback: simulate steps if pedometer is not available
      _simulateSteps();
    }
  }

  void _simulateSteps() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _steps += 3; // Simulate 3 steps every 5 seconds
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _answerController.dispose();
    _timer?.cancel();
    _stepCountStream?.cancel();
    _progressAnimationController.dispose();
    
    // Stop pedometer tracking when leaving the quest
    PedometerService().stopTracking();
    
    super.dispose();
  }

  Future<void> _loadQuestData() async {
    try {
      final appDataService = AppDataService.instance;
      
      // Check if test mode is enabled
      _isTestMode = await appDataService.isTestModeEnabled();
      
      // Load quest stops
      final languageService = LanguageService();
      final userLanguage = await languageService.getCurrentLanguage();
      final stops = await appDataService.getQuestStops(
        questId: widget.quest.id,
        languageCode: userLanguage,
      );
      
      setState(() {
        _questStops = stops;
        _isLoading = false;
      });
      
      // Start progress animation
      _progressAnimationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quest: $e')),
        );
      }
    }
  }

  Widget _buildGlassmorphicButton({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CustomProgressIndicator(
            progress: 0.5,
            label: 'Loading quest...',
          ),
        ),
      );
    }

    if (_questStops.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              TopNavigationBar(
                title: 'Quest Error',
                onBackPressed: widget.onBack,
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
                          color: Colors.orange.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No quest stops found',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This quest doesn\'t have any stops configured.',
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

    final currentStop = _questStops.isNotEmpty ? _questStops[_currentStopIndex] : null;
    final progressPercentage = _questStops.isNotEmpty 
        ? ((_currentStopIndex + 1) / _questStops.length) * 100 
        : 0.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Back and Map buttons
            _buildTopBar(),
            
            // Full-width Progress Card with glassmorphic stats
            _buildProgressCard(progressPercentage, isDark),
            
            // Quest Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: currentStop != null 
                    ? _buildQuestStopContent(currentStop)
                    : const SizedBox.shrink(),
              ),
            ),
            
            // Bottom Action Bar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  // Helper method to build top bar with back and map buttons
  Widget _buildTopBar() {
    return Container(
      height: 70,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ),
          
          // Title
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.quest.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Quest in Progress',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Map button
          GestureDetector(
            onTap: _openGoogleMaps,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.map_outlined,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build progress card with glassmorphic stats
  Widget _buildProgressCard(double progressPercentage, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress tracking section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Progress text and percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentStopIndex + 1} of ${_questStops.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${progressPercentage.toInt()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Progress bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercentage / 100,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Glassmorphic stats icons
                _buildGlassmorphicStatsRow(),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2);
  }

  // Helper method to build glassmorphic stats row with dividers
  Widget _buildGlassmorphicStatsRow() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Steps stat
              Expanded(
                child: _buildGlassmorphicStatIcon(
                  icon: Icons.directions_walk,
                  label: 'Steps',
                  value: '$_steps',
                ),
              ),
              
              // Glass divider
              _buildGlassDivider(),
              
              // Time stat
              Expanded(
                child: _buildGlassmorphicStatIcon(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: _formatDuration(_elapsedTime),
                ),
              ),
              
              // Glass divider
              _buildGlassDivider(),
              
              // GPS stat
              Expanded(
                child: _buildGlassmorphicStatIcon(
                  icon: _isAtLocation ? Icons.location_on : Icons.location_searching,
                  label: 'GPS',
                  value: _isAtLocation ? 'Locked' : 'Searching',
                  isGpsLocked: !_isAtLocation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build glass divider
  Widget _buildGlassDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  // Helper method to build glassmorphic stat icon
  Widget _buildGlassmorphicStatIcon({
    required IconData icon,
    required String label,
    required String value,
    bool isGpsLocked = false,
  }) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            if (isGpsLocked)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.white,
                    size: 8,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Helper method to open Google Maps
  void _openGoogleMaps() async {
    if (_questStops.isNotEmpty && _currentStopIndex < _questStops.length) {
      final currentStop = _questStops[_currentStopIndex];
      if (currentStop.longitude != null) {
        final lat = currentStop.latitude;
        final lng = currentStop.longitude;
        final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
        
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          } else {
            throw Exception('Could not launch $url');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open Google Maps: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location coordinates not available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  Widget _buildQuestStopContent(QuestStop stop) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stop Header with modern design
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Stop number with modern design
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${_currentStopIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.orange, Colors.deepOrange],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${stop.points} pts',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              stop.challengeType.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
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
          
          const SizedBox(height: 24),
          
          // Clue Section with improved styling
          if (stop.clue?.isNotEmpty == true) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CLUE FOR: ${stop.title.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    stop.clue!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Challenge Content with improved container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: _buildChallengeContent(stop),
          ),
          
          // Add some bottom padding for the bottom navigation
          const SizedBox(height: 20),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildChallengeContent(QuestStop stop) {
    switch (stop.challengeType.toLowerCase()) {
      case 'photo':
        return _buildPhotoChallenge(stop);
      case 'trivia':
        return _buildTriviaChallenge(stop);
      case 'text':
        return _buildTextChallenge(stop);
      case 'find':
      case 'location_check':
        return _buildLocationChallenge(stop);
      default:
        return Container();
    }
  }

  Widget _buildPhotoChallenge(QuestStop stop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon and title
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.purpleAccent],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photo Challenge',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Capture the moment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Challenge description
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Text(
            stop.challengeText ?? 'Take a photo at this location to complete this challenge.',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Action button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.purple, Colors.purpleAccent],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handlePhotoChallenge(stop),
              borderRadius: BorderRadius.circular(28),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Take Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTriviaChallenge(QuestStop stop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon and title
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.lightBlueAccent],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.quiz,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trivia Question',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Test your knowledge',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Question
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.lightBlueAccent.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
          child: Text(
            stop.challengeText ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        if (stop.multipleChoiceOptions?.isNotEmpty == true) ...[
          const Text(
            'Choose your answer:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          ...List.generate(stop.multipleChoiceOptions!.length, (index) {
            final option = stop.multipleChoiceOptions![index];
            final isSelected = _selectedChoiceIndex == index;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedChoiceIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
                          )
                        : null,
                    color: isSelected ? null : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.blue : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isSelected 
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 24),
          
          // Submit button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: _selectedChoiceIndex != null
                  ? const LinearGradient(
                      colors: [Colors.blue, Colors.lightBlueAccent],
                    )
                  : null,
              color: _selectedChoiceIndex != null ? null : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(28),
              boxShadow: _selectedChoiceIndex != null
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _selectedChoiceIndex != null 
                  ? () => _handleTriviaAnswer(stop, stop.multipleChoiceOptions![_selectedChoiceIndex!].toString())
                  : null,
                borderRadius: BorderRadius.circular(28),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send,
                        color: _selectedChoiceIndex != null ? Colors.white : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Submit Answer',
                        style: TextStyle(
                          color: _selectedChoiceIndex != null ? Colors.white : Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextChallenge(QuestStop stop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon and title
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Text Answer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Type your response',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Question
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Text(
            stop.challengeText ?? '',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Text input
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _answerController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Type your answer here...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(20),
            ),
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Submit button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.green, Colors.lightGreen],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleTextAnswer(stop, _answerController.text),
              borderRadius: BorderRadius.circular(28),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Submit Answer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationChallenge(QuestStop stop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon and title
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.redAccent],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location Check',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Get to the right spot',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Challenge description
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Text(
            stop.challengeText ?? 'Get to the location to continue your quest.',
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Location Status Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isAtLocation 
                  ? [Colors.green.withOpacity(0.1), Colors.lightGreen.withOpacity(0.05)]
                  : [Colors.orange.withOpacity(0.1), Colors.deepOrange.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isAtLocation ? Colors.green : Colors.orange,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (_isAtLocation ? Colors.green : Colors.orange).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isAtLocation ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isAtLocation ? Icons.location_on : Icons.location_searching,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAtLocation ? 'Location Found!' : 'Searching...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isAtLocation ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isAtLocation 
                        ? 'You\'re at the correct location!'
                        : 'Distance: ${_distanceToTarget.toStringAsFixed(0)}m away',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Action button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isAtLocation 
                  ? [Colors.green, Colors.lightGreen]
                  : [Colors.red, Colors.redAccent],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (_isAtLocation ? Colors.green : Colors.red).withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleLocationCheck(stop),
              borderRadius: BorderRadius.circular(28),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isAtLocation ? Icons.arrow_forward : Icons.my_location,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isAtLocation ? 'Continue Quest' : 'Check My Location',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePhotoChallenge(QuestStop stop) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Uploading photo...'),
              ],
            ),
          ),
        );
        
        try {
          // Upload photo to Supabase
          final photoService = PhotoUploadService();
          final uploadResult = await photoService.uploadQuestPhoto(
            questId: widget.quest.id,
            stopId: stop.id,
            imageBytes: await image.readAsBytes(),
            fileName: 'quest_${widget.quest.id}_stop_${stop.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          
          if (mounted) Navigator.of(context).pop(); // Close loading dialog
          
          if (uploadResult != null) {
            // Save photo reference to user progress
            await QuestCompletionService().recordPhotoChallenge(
              userId: SupabaseService().currentUserId!,
              questId: widget.quest.id,
              stopId: stop.id,
              photoUrl: uploadResult,
            );
            
            _showChallengeComplete(stop, 'Photo uploaded successfully! Great shot!');
          } else {
            throw Exception('Failed to upload photo');
          }
        } catch (uploadError) {
          if (mounted) Navigator.of(context).pop(); // Close loading dialog
          throw uploadError;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error with photo challenge: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleTriviaAnswer(QuestStop stop, String answer) async {
    final isCorrect = answer.toLowerCase() == stop.challengeAnswer?.toLowerCase();
    _showChallengeComplete(stop, isCorrect ? stop.infoText ?? 'Correct!' : 'Try again!');
  }

  Future<void> _handleTextAnswer(QuestStop stop, String answer) async {
    final isCorrect = answer.toLowerCase() == stop.challengeAnswer?.toLowerCase();
    _showChallengeComplete(stop, isCorrect ? stop.infoText ?? 'Correct!' : 'Try again!');
  }

  Future<void> _handleLocationCheck(QuestStop stop) async {
    try {
      // Get current location
      final locationService = LocationVerificationService();
      final position = await locationService.getCurrentLocation();
      
      if (position != null) {
        // Verify location against stop coordinates
        final result = await locationService.verifyStopLocation(
          stopId: stop.id,
          userLatitude: position.latitude,
          userLongitude: position.longitude,
          radiusMeters: 50.0, // 50 meter radius
        );
        
        setState(() {
          _isAtLocation = result.isVerified;
          _distanceToTarget = result.distance;
        });
        
        if (result.isVerified) {
          _showChallengeComplete(stop, result.message);
        } else {
          // Show distance feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error checking location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to verify location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChallengeComplete(QuestStop stop, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Challenge Complete!'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _goToNextStop();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _goToNextStop() async {
    if (_currentStopIndex < _questStops.length - 1) {
      setState(() {
        _currentStopIndex++;
        _answerController.clear();
        _selectedChoiceIndex = null;
        _feedback = { 'show': false, 'correct': false, 'text': '' };
      });
    } else {
      // Quest complete - get final pedometer data
      final pedometerService = PedometerService();
      final finalSteps = pedometerService.getCurrentSteps();
      final distance = pedometerService.getCurrentDistanceKm();
      final calories = pedometerService.getCaloriesBurned();
      
      // Stop tracking before navigation
      await pedometerService.stopTracking();
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => QuestCompleteView(
            questId: widget.quest.id,
            duration: _elapsedTime,
            stats: {
              'steps_walked': finalSteps,
              'distance_km': distance,
              'calories_burned': calories,
              'quest_stops_completed': _questStops.length,
            },
          ),
        ),
      );
    }
  }

  // Helper method to build bottom action bar
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous Stop button (only show if not on first stop)
            if (_currentStopIndex > 0) ...[
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _goToPreviousStop,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          color: Colors.grey,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Previous',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            
            // Hint button
            Expanded(
              flex: _currentStopIndex > 0 ? 3 : 1,
              child: GestureDetector(
                onTap: _showHint,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Need a Hint?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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

  // Helper method to go to previous stop
  void _goToPreviousStop() {
    if (_currentStopIndex > 0) {
      setState(() {
        _currentStopIndex--;
        _selectedChoiceIndex = null;
        _answerController.clear();
        _feedback = {'show': false, 'correct': false, 'text': ''};
      });
    }
  }

  // Helper method to show hint
  void _showHint() {
    final currentStop = _questStops[_currentStopIndex];
    final hints = currentStop.hints;
    
    String hintText;
    if (hints != null && hints.isNotEmpty) {
      // If multiple hints, show them as a numbered list
      if (hints.length == 1) {
        hintText = hints.first;
      } else {
        hintText = hints.asMap().entries
            .map((entry) => '${entry.key + 1}. ${entry.value}')
            .join('\n\n');
      }
    } else {
      hintText = 'No hints available for this challenge.';
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: AppColors.primary,
                size: 24,
              ),
              SizedBox(width: 8),
              Text('Hint'),
            ],
          ),
          content: Text(
            hintText,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}