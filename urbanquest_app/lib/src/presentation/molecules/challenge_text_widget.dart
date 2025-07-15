import 'package:flutter/material.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_card.dart';
import '../atoms/custom_text_field.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/quest_stop_model.dart';

class ChallengeTextWidget extends StatefulWidget {
  final QuestStop questStop;
  final Function(String) onAnswerSubmitted;
  final bool isSubmitting;

  const ChallengeTextWidget({
    Key? key,
    required this.questStop,
    required this.onAnswerSubmitted,
    this.isSubmitting = false,
  }) : super(key: key);

  @override
  State<ChallengeTextWidget> createState() => _ChallengeTextWidgetState();
}

class _ChallengeTextWidgetState extends State<ChallengeTextWidget> {
  final TextEditingController _textController = TextEditingController();

  void _handleSubmit() {
    final answer = _textController.text.trim();
    if (answer.isNotEmpty) {
      widget.onAnswerSubmitted(answer);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenge Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.green, Colors.lightGreen],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Text Challenge',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Type your response',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Question
          if (widget.questStop.challengeText?.isNotEmpty == true) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blackOpacity10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.blackOpacity20,
                ),
              ),
              child: Text(
                widget.questStop.challengeText!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Text Input
          CustomTextField(
            controller: _textController,
            labelText: 'Your answer',
            hintText: 'Type your answer here...',
            maxLines: 4,
            onSubmitted: (_) => _handleSubmit(),
          ),
          
          const SizedBox(height: 16),
          
          // Submit Button
          CustomButton(
            text: 'Submit Answer',
            icon: Icons.send,
            onPressed: !widget.isSubmitting ? _handleSubmit : null,
            isLoading: widget.isSubmitting,
            isFullWidth: true,
            size: ButtonSize.large,
          ),
        ],
      ),
    );
  }
}