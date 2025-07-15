import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_card.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/quest_stop_model.dart';

class QuestHelpWidget extends StatefulWidget {
  final QuestStop questStop;
  final VoidCallback onClose;

  const QuestHelpWidget({
    Key? key,
    required this.questStop,
    required this.onClose,
  }) : super(key: key);

  @override
  State<QuestHelpWidget> createState() => _QuestHelpWidgetState();
}

class _QuestHelpWidgetState extends State<QuestHelpWidget> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Challenge Help',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.questStop.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabButton(0, 'Guide', Icons.book),
                _buildTabButton(1, 'Tips', Icons.lightbulb_outline),
                _buildTabButton(2, 'Examples', Icons.code),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildTabContent(),
            ),
          ),

          // Close Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: CustomButton(
              text: 'Got It!',
              icon: Icons.check,
              onPressed: widget.onClose,
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildGuideContent();
      case 1:
        return _buildTipsContent();
      case 2:
        return _buildExamplesContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGuideContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChallengeGuide(),
        const SizedBox(height: 20),
        _buildGeneralInstructions(),
      ],
    );
  }

  Widget _buildChallengeGuide() {
    final challengeType = widget.questStop.challengeType;
    
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getChallengeIcon(challengeType),
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _getChallengeTitle(challengeType),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getChallengeDescription(challengeType),
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ...(widget.questStop.helpSteps ?? _getDefaultChallengeSteps(challengeType)).map((step) => _buildStep(step)),
        ],
      ),
    );
  }

  Widget _buildGeneralInstructions() {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 12),
              Text(
                'General Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.questStop.challengeInstructions?.isNotEmpty == true)
            Text(
              widget.questStop.challengeInstructions!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          if (widget.questStop.infoText?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              widget.questStop.infoText!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipsContent() {
    return Column(
      children: [
        ...(widget.questStop.helpTips ?? _getDefaultTipsForChallengeType(widget.questStop.challengeType))
            .map((tip) => _buildTipCard(tip)),
        const SizedBox(height: 20),
        _buildContextualTips(),
      ],
    );
  }

  Widget _buildExamplesContent() {
    return Column(
      children: [
        ...(widget.questStop.helpExamples ?? _getDefaultExamplesForChallengeType(widget.questStop.challengeType))
            .map((example) => _buildExampleCard(example)),
      ],
    );
  }

  Widget _buildStep(String step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(Map<String, String> example) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            example['title']!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          if (example['input'] != null) ...[
            Text(
              'Input: ${example['input']}',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            example['description']!,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextualTips() {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contextual Tips',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.questStop.historicalContext?.isNotEmpty == true) ...[
            _buildContextSection(
              'Historical Context',
              widget.questStop.historicalContext!,
              Icons.history,
            ),
            const SizedBox(height: 12),
          ],
          if (widget.questStop.funFacts?.isNotEmpty == true) ...[
            _buildContextSection(
              'Fun Facts',
              widget.questStop.funFacts!.join('\n• '),
              Icons.emoji_objects,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContextSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.purple, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: Colors.grey,
          ),
        ),
      ],
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

  String _getChallengeDescription(String challengeType) {
    switch (challengeType) {
      case 'text':
        return 'Type your answer in the text field. Pay attention to spelling and formatting.';
      case 'multiple_choice':
        return 'Select the correct answer from the given options. Only one answer is correct.';
      case 'photo':
        return 'Take a photo that meets the specified requirements. The image will be analyzed automatically.';
      case 'location_only':
        return 'Simply arrive at the specified location. No additional challenge required.';
      case 'qr_code':
        return 'Scan the QR code at this location using your camera.';
      case 'audio':
        return 'Record an audio response to the challenge prompt.';
      case 'regex':
        return 'Enter text that matches the specified pattern. Follow the examples provided.';
      default:
        return 'Complete the challenge to proceed to the next stop.';
    }
  }

  List<String> _getDefaultChallengeSteps(String challengeType) {
    switch (challengeType) {
      case 'text':
        return [
          'Read the question carefully',
          'Type your answer in the text field',
          'Check your spelling and formatting',
          'Submit your answer'
        ];
      case 'multiple_choice':
        return [
          'Read all the options carefully',
          'Tap on the option you think is correct',
          'The selected option will be highlighted',
          'Submit your answer'
        ];
      case 'photo':
        return [
          'Read the photo requirements',
          'Tap "Take Photo" to open the camera',
          'Frame your shot according to the requirements',
          'Take the photo and review it',
          'Submit if satisfied or retake if needed'
        ];
      case 'location_only':
        return [
          'Navigate to the specified location',
          'Get within the required distance',
          'Tap "I\'m Here!" when you arrive',
          'The challenge will complete automatically'
        ];
      case 'qr_code':
        return [
          'Tap "Start Scanning" to open the camera',
          'Point your camera at the QR code',
          'Keep the code within the scan area',
          'The code will be scanned automatically'
        ];
      case 'audio':
        return [
          'Tap "Start Recording" to begin',
          'Speak clearly into the microphone',
          'Tap "Stop Recording" when finished',
          'Play back to review your recording',
          'Submit or record again if needed'
        ];
      case 'regex':
        return [
          'Review the pattern requirements',
          'Look at the provided examples',
          'Type text that matches the pattern',
          'Watch for real-time validation feedback',
          'Submit when the pattern matches'
        ];
      default:
        return ['Complete the challenge to proceed'];
    }
  }

  List<String> _getDefaultTipsForChallengeType(String challengeType) {
    switch (challengeType) {
      case 'text':
        return [
          'Read the question multiple times before answering',
          'Check for spelling and grammar mistakes',
          'Consider if the answer should be capitalized',
          'Some answers might be case-sensitive'
        ];
      case 'multiple_choice':
        return [
          'Eliminate obviously wrong answers first',
          'Read each option completely before deciding',
          'Look for key words that match the question',
          'When in doubt, go with your first instinct'
        ];
      case 'photo':
        return [
          'Ensure good lighting for clear photos',
          'Hold the camera steady to avoid blur',
          'Include all required elements in the frame',
          'Check photo requirements before taking the shot'
        ];
      case 'location_only':
        return [
          'Enable GPS for accurate location tracking',
          'Be patient - GPS can take time to be accurate',
          'Try moving around if location isn\'t detected',
          'Check if you\'re in the right general area'
        ];
      case 'qr_code':
        return [
          'Ensure good lighting on the QR code',
          'Hold the camera steady and at the right distance',
          'Clean your camera lens if scanning fails',
          'Try different angles if the code won\'t scan'
        ];
      case 'audio':
        return [
          'Find a quiet location for recording',
          'Speak clearly and at normal volume',
          'Hold the device close to your mouth',
          'Avoid background noise and wind'
        ];
      case 'regex':
        return [
          'Study the pattern examples carefully',
          'Test your input against the pattern',
          'Watch for real-time validation feedback',
          'Common patterns include emails, phone numbers, dates'
        ];
      default:
        return ['Follow the challenge instructions carefully'];
    }
  }

  List<Map<String, String>> _getDefaultExamplesForChallengeType(String challengeType) {
    switch (challengeType) {
      case 'text':
        return [
          {
            'title': 'Simple Text Answer',
            'input': 'Paris',
            'description': 'A straightforward one-word answer to "What is the capital of France?"'
          },
          {
            'title': 'Detailed Text Answer',
            'input': 'The Eiffel Tower was built in 1889',
            'description': 'A complete sentence providing historical information'
          }
        ];
      case 'multiple_choice':
        return [
          {
            'title': 'Historical Question',
            'description': 'Question: "When was the city founded?"\nOptions: A) 1850, B) 1871, C) 1901\nSelect the correct year based on historical context'
          }
        ];
      case 'photo':
        return [
          {
            'title': 'Architectural Photo',
            'description': 'Take a photo of the building\'s main entrance, ensuring the sign is visible and readable'
          },
          {
            'title': 'Landmark Photo',
            'description': 'Capture the monument with yourself in the frame to prove you were there'
          }
        ];
      case 'qr_code':
        return [
          {
            'title': 'Information QR Code',
            'description': 'Scan the QR code on the information plaque to get the historical data'
          }
        ];
      case 'regex':
        return [
          {
            'title': 'Email Pattern',
            'input': 'user@example.com',
            'description': 'Standard email format with @ symbol and domain'
          },
          {
            'title': 'Phone Number Pattern',
            'input': '+1-555-123-4567',
            'description': 'Phone number with country code and proper formatting'
          }
        ];
      default:
        return [];
    }
  }
}