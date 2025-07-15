import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/quest_model.dart';
import '../../../data/models/quest_stop_model.dart';
import '../../../data/repositories/quest_repository.dart';
import '../../../core/services/location_verification_service.dart';
import '../../../core/services/pedometer_service.dart';
import '../../templates/app_template.dart';
import '../../molecules/challenge_text_widget.dart';
import '../../molecules/challenge_multiple_choice_widget.dart';
import '../../molecules/challenge_photo_widget.dart';
import '../../molecules/challenge_location_widget.dart';
import '../../molecules/challenge_qr_code_widget.dart';
import '../../molecules/challenge_audio_widget.dart';
import '../../molecules/challenge_regex_widget.dart';

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

class _QuestGameplayViewState extends State<QuestGameplayView> {
  // Quest state
  List<QuestStop> _questStops = [];
  int _currentStopIndex = 0;
  bool _isLoading = true;
  bool _hasArrived = false;
  bool _showHints = false;
  int _currentHintIndex = 0;
  
  // Challenge state
  final TextEditingController _answerController = TextEditingController();
  int? _selectedChoiceIndex;
  String? _feedback;
  bool _isCorrect = false;
  bool _isSubmitting = false;
  
  // Location state
  bool _isAtLocation = false;
  double _distanceToTarget = 0.0;
  
  // Stats
  int _stepCount = 0;
  String _elapsedTime = "00:00";
  Timer? _timer;
  Timer? _stepTimer;
  
  // Services
  late final LocationVerificationService _locationService;
  late final PedometerService _pedometerService;
  StreamSubscription? _locationSubscription;
  
  @override
  void initState() {
    super.initState();
    _loadQuestStops();
    _startTimer();
    _initializeLocation();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _timer?.cancel();
    _stepTimer?.cancel();
    _locationSubscription?.cancel();
    _pedometerService.stopTracking();
    super.dispose();
  }

  void _loadQuestStops() async {
    try {
      final questRepository = QuestRepository();
      final stops = await questRepository.getQuestStops(widget.quest.id);
      setState(() {
        _questStops = stops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading quest: $e')),
      );
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final minutes = timer.tick ~/ 60;
      final seconds = timer.tick % 60;
      setState(() {
        _elapsedTime = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      });
    });
  }

  void _initializeLocation() async {
    // Initialize location services
    _locationService = LocationVerificationService();
    _pedometerService = PedometerService();
    
    // Start pedometer tracking
    await _pedometerService.startTracking(widget.quest.id);
    
    // Location service is already initialized
    
    // Listen for location updates
    _locationSubscription = _locationService.getLocationStream().listen((location) {
      if (_questStops.isNotEmpty && mounted) {
        final currentStop = _questStops[_currentStopIndex];
        final distance = _locationService.calculateDistance(
          location.latitude,
          location.longitude,
          currentStop.latitude,
          currentStop.longitude,
        );
        
        setState(() {
          _distanceToTarget = distance;
          _isAtLocation = distance <= currentStop.radius;
        });
      }
    });
    
    // Update step count periodically
    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _stepCount = _pedometerService.getCurrentSteps();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questStops.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('No quest stops found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final currentStop = _questStops[_currentStopIndex];
    final progress = (_currentStopIndex + 1) / _questStops.length;

    return WillPopScope(
      onWillPop: () async {
        return await _showQuestCancelConfirmation(context);
      },
      child: Scaffold(
        body: Column(
          children: [
            // Header with progress
            _buildHeader(context, progress),
            
            // Main content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Clue section
                    _buildClueSection(context, currentStop),
                    
                    const SizedBox(height: 16),
                    
                    // Hints section (expandable)
                    if (currentStop.hints?.isNotEmpty == true)
                      _buildHintsSection(context, currentStop),
                  ],
                ),
              ),
            ),
            
            // Challenge footer
            _buildChallengeFooter(context, currentStop),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double progress) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.secondary],
        ),
      ),
      child: Column(
        children: [
          // App bar
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  if (await _showQuestCancelConfirmation(context)) {
                    if (mounted) {
                      widget.onBack?.call();
                      Navigator.pop(context);
                    }
                  }
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  widget.quest.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () {
                  // Quest options menu
                },
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats row - single glassmorphism card with dividers
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(Icons.directions_walk, '$_stepCount', 'Steps'),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildStatItem(Icons.timer, _elapsedTime, 'Time'),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        _isAtLocation ? Icons.location_on : Icons.location_searching,
                        _isAtLocation ? 'Found' : '${_distanceToTarget.toInt()}m',
                        'Location',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Metro line progress tracker
          _buildMetroLineProgress(),
        ],
      ),
    );
  }

  Widget _buildMetroLineProgress() {
    if (_questStops.isEmpty) return const SizedBox.shrink();
    
    // Calculate responsive dimensions based on number of stops
    final stopCount = _questStops.length;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32; // Account for padding
    
    // Calculate bubble size and line width based on available space
    double bubbleSize = 32.0;
    double lineWidth = 24.0;
    
    if (stopCount > 6) {
      // For many stops, make elements smaller
      bubbleSize = 28.0;
      lineWidth = 16.0;
    } else if (stopCount > 10) {
      // For very many stops, make even smaller
      bubbleSize = 24.0;
      lineWidth = 12.0;
    }
    
    // If still too wide, make it scrollable
    final totalWidth = (bubbleSize * stopCount) + (lineWidth * (stopCount - 1));
    final needsScroll = totalWidth > availableWidth;
    
    Widget progressWidget = Row(
      mainAxisAlignment: needsScroll ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        // Build stop bubbles with connecting lines
        for (int i = 0; i < stopCount; i++) ...[
          // Stop bubble
          Container(
            width: bubbleSize,
            height: bubbleSize,
            decoration: BoxDecoration(
              color: i <= _currentStopIndex ? Colors.white : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: i <= _currentStopIndex ? Colors.white : Colors.white.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: i <= _currentStopIndex
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: i == _currentStopIndex
                  ? Icon(
                      _isAtLocation ? Icons.location_on : Icons.location_searching,
                      color: AppColors.primary,
                      size: bubbleSize * 0.5,
                    )
                  : i < _currentStopIndex
                      ? Icon(
                          Icons.check,
                          color: AppColors.primary,
                          size: bubbleSize * 0.5,
                        )
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: bubbleSize * 0.375, // Responsive font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
            ),
          ),
          
          // Connecting line (except for last stop)
          if (i < stopCount - 1) ...[
            Container(
              width: lineWidth,
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i < _currentStopIndex ? Colors.white : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
                boxShadow: i < _currentStopIndex
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ],
      ],
    );
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: needsScroll 
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: progressWidget,
            )
          : progressWidget,
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClueSection(BuildContext context, QuestStop currentStop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLUE FOR: ${currentStop.title.toUpperCase()}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currentStop.clue ?? 'No clue available',
            style: const TextStyle(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2);
  }

  Widget _buildHintsSection(BuildContext context, QuestStop currentStop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Hint header
          InkWell(
            onTap: () {
              setState(() {
                _showHints = !_showHints;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Need a hint?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showHints ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          
          // Hints content
          if (_showHints) ...[
            const Divider(height: 1, color: Colors.blue),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...currentStop.hints!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final hint = entry.value;
                    final isVisible = index <= _currentHintIndex;
                    
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: isVisible ? null : 0,
                      child: isVisible ? Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                hint,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ) : const SizedBox.shrink(),
                    );
                  }).toList(),
                  
                  // Next hint button
                  if (_currentHintIndex < currentStop.hints!.length - 1)
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentHintIndex++;
                          });
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Show Next Hint'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChallengeFooter(BuildContext context, QuestStop currentStop) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: _hasArrived ? MediaQuery.of(context).size.height * 0.6 : MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: !_hasArrived
                  ? _buildLocationCheck(context, currentStop)
                  : _buildChallenge(context, currentStop),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCheck(BuildContext context, QuestStop currentStop) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isAtLocation ? Icons.location_on : Icons.location_searching,
          size: 64,
          color: _isAtLocation ? Colors.green : Colors.orange,
        ),
        const SizedBox(height: 16),
        Text(
          _isAtLocation ? 'Location Found!' : 'Getting closer...',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _isAtLocation ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isAtLocation 
            ? 'You\'re at the right location!'
            : 'Distance: ${_distanceToTarget.toInt()}m away',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isAtLocation ? () {
              setState(() {
                _hasArrived = true;
              });
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isAtLocation ? Colors.green : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isAtLocation ? 'I\'m Here!' : 'Get to Location',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChallenge(BuildContext context, QuestStop currentStop) {
    return Column(
      children: [
        // Challenge header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                _getChallengeIcon(currentStop.challengeType),
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getChallengeTitle(currentStop.challengeType),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${currentStop.points} points',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Challenge content
        Expanded(
          child: _buildChallengeContent(context, currentStop),
        ),
        
        // Feedback
        if (_feedback != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isCorrect ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isCorrect ? Icons.check_circle : Icons.error,
                  color: _isCorrect ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _feedback!,
                    style: TextStyle(
                      color: _isCorrect ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Action button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isCorrect ? () => _handleNextStop() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCorrect ? Colors.green : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting 
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _isCorrect ? 'Continue Quest' : 'Submit Answer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeContent(BuildContext context, QuestStop currentStop) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenge question
          if (currentStop.challengeText?.isNotEmpty == true) ...[
            Text(
              currentStop.challengeText!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Challenge widget based on type
          _buildChallengeWidget(currentStop),
        ],
      ),
    );
  }

  IconData _getChallengeIcon(String challengeType) {
    switch (challengeType) {
      case 'text':
        return Icons.edit;
      case 'multiple_choice':
        return Icons.quiz;
      case 'photo':
        return Icons.camera_alt;
      case 'location_only':
        return Icons.location_on;
      case 'qr_code':
        return Icons.qr_code_scanner;
      case 'audio':
        return Icons.mic;
      case 'regex':
        return Icons.pattern;
      default:
        return Icons.help_outline;
    }
  }

  String _getChallengeTitle(String challengeType) {
    switch (challengeType) {
      case 'text':
        return 'Text Challenge';
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'photo':
        return 'Photo Challenge';
      case 'location_only':
        return 'Location Challenge';
      case 'qr_code':
        return 'QR Code Challenge';
      case 'audio':
        return 'Audio Challenge';
      case 'regex':
        return 'Pattern Challenge';
      default:
        return 'Challenge';
    }
  }

  Widget _buildChallengeWidget(QuestStop currentStop) {
    switch (currentStop.challengeType) {
      case 'text':
        return ChallengeTextWidget(
          questStop: currentStop,
          onAnswerSubmitted: _handleTextAnswer,
          isSubmitting: _isSubmitting,
        );
      case 'multiple_choice':
        return ChallengeMultipleChoiceWidget(
          questStop: currentStop,
          onAnswerSubmitted: _handleMultipleChoiceAnswer,
          isSubmitting: _isSubmitting,
        );
      case 'photo':
        return ChallengePhotoWidget(
          questStop: currentStop,
          onPhotoTaken: _handlePhotoAnswer,
          isSubmitting: _isSubmitting,
        );
      case 'location_only':
        return ChallengeLocationWidget(
          questStop: currentStop,
          onLocationCheck: _handleLocationCheck,
          isAtLocation: _isAtLocation,
          distanceToTarget: _distanceToTarget,
          isSubmitting: _isSubmitting,
        );
      case 'qr_code':
        return ChallengeQrCodeWidget(
          questStop: currentStop,
          onQrCodeScanned: _handleQrCodeAnswer,
          isSubmitting: _isSubmitting,
        );
      case 'audio':
        return ChallengeAudioWidget(
          questStop: currentStop,
          onAudioRecorded: _handleAudioAnswer,
          isSubmitting: _isSubmitting,
        );
      case 'regex':
        return ChallengeRegexWidget(
          questStop: currentStop,
          onAnswerSubmitted: _handleRegexAnswer,
          isSubmitting: _isSubmitting,
        );
      default:
        return ChallengeTextWidget(
          questStop: currentStop,
          onAnswerSubmitted: _handleTextAnswer,
          isSubmitting: _isSubmitting,
        );
    }
  }

  void _handleTextAnswer(String answer) {
    _handleSubmit('text', answer);
  }

  void _handleMultipleChoiceAnswer(int selectedIndex) {
    _handleSubmit('multiple_choice', selectedIndex);
  }

  void _handlePhotoAnswer(XFile photo) {
    _handleSubmit('photo', photo);
  }

  void _handleLocationCheck() {
    _handleSubmit('location_only', null);
  }

  void _handleQrCodeAnswer(String qrCode) {
    _handleSubmit('qr_code', qrCode);
  }

  void _handleAudioAnswer(String audioPath) {
    _handleSubmit('audio', audioPath);
  }

  void _handleRegexAnswer(String answer) {
    _handleSubmit('regex', answer);
  }

  void _handleSubmit(String challengeType, dynamic answer) {
    if (_isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
      _feedback = null;
    });

    // Simulate submission delay
    Future.delayed(const Duration(milliseconds: 500), () {
      bool isCorrect = false;
      final currentStop = _questStops[_currentStopIndex];
      
      switch (challengeType) {
        case 'text':
          isCorrect = answer.toString().trim().toLowerCase() == 
                     currentStop.challengeAnswer?.toLowerCase();
          break;
        case 'multiple_choice':
          isCorrect = answer == currentStop.correctChoiceIndex;
          break;
        case 'photo':
        case 'audio':
          isCorrect = true; // Photos and audio are always considered correct for now
          break;
        case 'location_only':
          isCorrect = _isAtLocation;
          break;
        case 'qr_code':
          isCorrect = answer.toString() == currentStop.challengeAnswer;
          break;
        case 'regex':
          if (currentStop.challengeRegex != null) {
            try {
              final regex = RegExp(currentStop.challengeRegex!);
              isCorrect = regex.hasMatch(answer.toString());
            } catch (e) {
              isCorrect = false;
            }
          } else {
            isCorrect = answer.toString().trim().toLowerCase() == 
                       currentStop.challengeAnswer?.toLowerCase();
          }
          break;
        default:
          isCorrect = true;
      }
      
      setState(() {
        _isSubmitting = false;
        _isCorrect = isCorrect;
        _feedback = isCorrect 
          ? currentStop.displaySuccessMessage 
          : currentStop.displayFailureMessage;
      });
    });
  }


  void _handleNextStop() {
    if (_currentStopIndex < _questStops.length - 1) {
      setState(() {
        _currentStopIndex++;
        _hasArrived = false;
        _showHints = false;
        _currentHintIndex = 0;
        _feedback = null;
        _isCorrect = false;
        _answerController.clear();
        _selectedChoiceIndex = null;
      });
    } else {
      // Quest completed
      _completeQuest();
    }
  }

  void _completeQuest() {
    // Navigate to quest completion screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.celebration, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'Quest Completed!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showQuestCancelConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Cancel Quest?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to cancel this quest?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your progress will be lost and step tracking will stop.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Continue Quest',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel Quest',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }
}