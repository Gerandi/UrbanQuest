import 'package:flutter/material.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_card.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/quest_stop_model.dart';

class ChallengeMultipleChoiceWidget extends StatefulWidget {
  final QuestStop questStop;
  final Function(int) onAnswerSubmitted;
  final bool isSubmitting;

  const ChallengeMultipleChoiceWidget({
    Key? key,
    required this.questStop,
    required this.onAnswerSubmitted,
    this.isSubmitting = false,
  }) : super(key: key);

  @override
  State<ChallengeMultipleChoiceWidget> createState() => _ChallengeMultipleChoiceWidgetState();
}

class _ChallengeMultipleChoiceWidgetState extends State<ChallengeMultipleChoiceWidget> {
  int? _selectedChoiceIndex;

  void _handleSubmit() {
    if (_selectedChoiceIndex != null) {
      widget.onAnswerSubmitted(_selectedChoiceIndex!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.questStop.multipleChoiceOptions ?? [];
    
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
                    colors: [Colors.blue, Colors.lightBlueAccent],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.quiz,
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
                      'Multiple Choice',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Choose the correct answer',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Question
          if (widget.questStop.challengeText?.isNotEmpty == true) ...[
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
                widget.questStop.challengeText!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Options
          if (options.isNotEmpty) ...[
            Text(
              'Choose your answer:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            ...List.generate(options.length, (index) {
              final option = options[index];
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
                      color: isSelected ? null : AppColors.blackOpacity10,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.blue : AppColors.blackOpacity20,
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
                              color: isSelected ? Colors.blue : AppColors.textSecondary,
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
                            option.toString(),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: AppColors.textPrimary,
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
            
            // Submit Button
            CustomButton(
              text: 'Submit Answer',
              icon: Icons.send,
              onPressed: _selectedChoiceIndex != null && !widget.isSubmitting ? _handleSubmit : null,
              isLoading: widget.isSubmitting,
              isFullWidth: true,
              size: ButtonSize.large,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'No options available for this question.',
                    style: TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}