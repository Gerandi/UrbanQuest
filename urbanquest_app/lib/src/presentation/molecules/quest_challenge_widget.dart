import 'package:flutter/material.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_text_field.dart';
import '../../data/models/quest_stop_model.dart';

class QuestChallengeWidget extends StatefulWidget {
  final QuestStop questStop;
  final Function(dynamic answer) onAnswerSubmitted;
  final VoidCallback? onPhotoTap;
  final bool isTestMode;

  const QuestChallengeWidget({
    Key? key,
    required this.questStop,
    required this.onAnswerSubmitted,
    this.onPhotoTap,
    this.isTestMode = false,
  }) : super(key: key);

  @override
  State<QuestChallengeWidget> createState() => _QuestChallengeWidgetState();
}

class _QuestChallengeWidgetState extends State<QuestChallengeWidget> {
  final TextEditingController _textController = TextEditingController();
  int? _selectedChoiceIndex;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge header
            Row(
              children: [
                Icon(
                  _getChallengeIcon(),
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _getChallengeTypeLabel(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                if (widget.isTestMode) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'TEST MODE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Challenge instructions
            if (widget.questStop.displayInstructions.isNotEmpty) ...[
              Text(
                widget.questStop.displayInstructions,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
            ],

            // Challenge content based on type
            _buildChallengeContent(),

            const SizedBox(height: 16),

            // Submit button (only if not location-only)
            if (widget.questStop.hasChallenge)
              CustomButton(
                text: _isSubmitting ? 'Submitting...' : 'Submit Answer',
                onPressed: _isSubmitting ? null : _handleSubmit,
                isLoading: _isSubmitting,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeContent() {
    switch (widget.questStop.challengeType) {
      case 'text':
      case 'trivia':
      case 'regex':
        return _buildTextInput();
      case 'multiple_choice':
        return _buildMultipleChoice();
      case 'photo':
        return _buildPhotoChallenge();
      case 'location_only':
        return _buildLocationOnlyMessage();
      default:
        return _buildTextInput();
    }
  }

  Widget _buildTextInput() {
    return CustomTextField(
      controller: _textController,
      labelText: widget.questStop.challengeType == 'regex' 
          ? 'Enter your answer'
          : 'Your answer',
      hintText: widget.questStop.challengeType == 'regex'
          ? 'Enter text matching the required pattern'
          : 'Type your answer here...',
    );
  }

  Widget _buildMultipleChoice() {
    final options = widget.questStop.multipleChoiceOptions;
    if (options == null || options.isEmpty) {
      return const Text('No options available for this question.');
    }

    return Column(
      children: [
        for (int i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedChoiceIndex = i;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedChoiceIndex == i
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _selectedChoiceIndex == i
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedChoiceIndex == i
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          width: 2,
                        ),
                        color: _selectedChoiceIndex == i
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                      child: _selectedChoiceIndex == i
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        options[i].toString(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoChallenge() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.withOpacity(0.1),
          ),
          child: InkWell(
            onTap: widget.onPhotoTap,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 8),
                Text(
                  'Tap to take a photo',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.questStop.photoRequirements != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Photo Requirements:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...widget.questStop.photoRequirements!.entries.map(
                  (entry) => Text('• ${entry.key}: ${entry.value}'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationOnlyMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_on,
            color: Colors.green,
            size: 48,
          ),
          const SizedBox(height: 8),
          const Text(
            'Location Challenge',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isTestMode
                ? 'You\'re here! (Test mode - location verification disabled)'
                : 'Simply arrive at this location to complete the challenge.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  IconData _getChallengeIcon() {
    switch (widget.questStop.challengeType) {
      case 'text':
      case 'trivia':
        return Icons.quiz;
      case 'multiple_choice':
        return Icons.checklist;
      case 'photo':
        return Icons.camera_alt;
      case 'regex':
        return Icons.code;
      case 'location_only':
        return Icons.location_on;
      case 'qr_code':
        return Icons.qr_code;
      case 'audio':
        return Icons.mic;
      default:
        return Icons.help;
    }
  }

  String _getChallengeTypeLabel() {
    switch (widget.questStop.challengeType) {
      case 'text':
        return 'Text Challenge';
      case 'trivia':
        return 'Trivia Question';
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'photo':
        return 'Photo Challenge';
      case 'regex':
        return 'Pattern Challenge';
      case 'location_only':
        return 'Location Challenge';
      case 'qr_code':
        return 'QR Code Challenge';
      case 'audio':
        return 'Audio Challenge';
      default:
        return 'Challenge';
    }
  }

  void _handleSubmit() {
    dynamic answer;

    switch (widget.questStop.challengeType) {
      case 'text':
      case 'trivia':
      case 'regex':
        answer = _textController.text.trim();
        if (answer.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter an answer')),
          );
          return;
        }
        break;
      case 'multiple_choice':
        if (_selectedChoiceIndex == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an option')),
          );
          return;
        }
        answer = _selectedChoiceIndex;
        break;
      default:
        return;
    }

    setState(() {
      _isSubmitting = true;
    });

    widget.onAnswerSubmitted(answer);

    // Reset submitting state after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    });
  }
} 