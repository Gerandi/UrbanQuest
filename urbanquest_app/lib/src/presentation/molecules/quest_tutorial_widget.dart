import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_card.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/quest_model.dart';

class QuestTutorialWidget extends StatefulWidget {
  final Quest quest;
  final VoidCallback onTutorialComplete;
  final VoidCallback onSkipTutorial;

  const QuestTutorialWidget({
    Key? key,
    required this.quest,
    required this.onTutorialComplete,
    required this.onSkipTutorial,
  }) : super(key: key);

  @override
  State<QuestTutorialWidget> createState() => _QuestTutorialWidgetState();
}

class _QuestTutorialWidgetState extends State<QuestTutorialWidget> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  List<TutorialStep> get tutorialSteps => [
    TutorialStep(
      icon: Icons.location_on,
      title: 'Location-Based Adventure',
      description: 'This is a location-based quest! You\'ll need to physically visit different stops to complete challenges.',
      tips: [
        'Make sure GPS is enabled on your device',
        'You\'ll see your distance to each stop',
        'Get within ${widget.quest.title.contains('close') ? '20' : '50'} meters to unlock challenges',
      ],
    ),
    TutorialStep(
      icon: Icons.quiz,
      title: 'Challenge Types',
      description: 'Each stop has different types of challenges you might encounter:',
      tips: [
        'Text answers - Type your response',
        'Multiple choice - Select the correct option',
        'Photo challenges - Take pictures of specific objects',
        'QR code scanning - Scan codes at locations',
        'Audio recording - Record your voice',
        'Pattern matching - Match text patterns',
      ],
    ),
    TutorialStep(
      icon: Icons.lightbulb_outline,
      title: 'Hints & Help',
      description: 'Stuck on a challenge? We\'ve got you covered!',
      tips: [
        'Tap the hint button to reveal progressive clues',
        'Hints unlock one at a time to help you gradually',
        'Location challenges show distance and direction',
        'Photos are analyzed for requirements automatically',
      ],
    ),
    TutorialStep(
      icon: Icons.star,
      title: 'Points & Progress',
      description: 'Earn points and track your adventure progress!',
      tips: [
        'Each challenge gives you points based on difficulty',
        'Bonus points for fast completion',
        'Your steps and distance are tracked',
        'Complete all stops to finish the quest',
      ],
    ),
    TutorialStep(
      icon: Icons.safety_check,
      title: 'Safety Tips',
      description: 'Stay safe while exploring!',
      tips: [
        'Always be aware of your surroundings',
        'Follow local laws and regulations',
        'Don\'t trespass on private property',
        'Quest in daylight when possible',
        'Bring water and wear comfortable shoes',
      ],
    ),
  ];

  void _nextStep() {
    if (_currentStep < tutorialSteps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onTutorialComplete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quest Tutorial',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.quest.title,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: widget.onSkipTutorial,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(
                    tutorialSteps.length,
                    (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Tutorial Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  itemCount: tutorialSteps.length,
                  itemBuilder: (context, index) {
                    final step = tutorialSteps[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: CustomCard(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                step.icon,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ).animate().scale(delay: 200.ms),

                            const SizedBox(height: 24),

                            // Title
                            Text(
                              step.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 300.ms),

                            const SizedBox(height: 16),

                            // Description
                            Text(
                              step.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 400.ms),

                            const SizedBox(height: 24),

                            // Tips
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: step.tips.asMap().entries.map((entry) {
                                    final tipIndex = entry.key;
                                    final tip = entry.value;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${tipIndex + 1}',
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
                                              tip,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textPrimary,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animate().slideX(
                                      begin: 0.3,
                                      delay: (500 + tipIndex * 100).ms,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Navigation Buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: CustomButton(
                          text: 'Previous',
                          icon: Icons.arrow_back,
                          onPressed: _previousStep,
                          variant: ButtonVariant.secondary,
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: _currentStep == tutorialSteps.length - 1
                            ? 'Start Quest'
                            : 'Next',
                        icon: _currentStep == tutorialSteps.length - 1
                            ? Icons.play_arrow
                            : Icons.arrow_forward,
                        onPressed: _nextStep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  final List<String> tips;

  TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.tips,
  });
}