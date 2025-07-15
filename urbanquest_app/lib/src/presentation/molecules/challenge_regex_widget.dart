import 'package:flutter/material.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_card.dart';
import '../atoms/custom_text_field.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/quest_stop_model.dart';

class ChallengeRegexWidget extends StatefulWidget {
  final QuestStop questStop;
  final Function(String) onAnswerSubmitted;
  final bool isSubmitting;

  const ChallengeRegexWidget({
    Key? key,
    required this.questStop,
    required this.onAnswerSubmitted,
    this.isSubmitting = false,
  }) : super(key: key);

  @override
  State<ChallengeRegexWidget> createState() => _ChallengeRegexWidgetState();
}

class _ChallengeRegexWidgetState extends State<ChallengeRegexWidget> {
  final TextEditingController _textController = TextEditingController();
  bool _isValid = false;
  String? _errorMessage;
  List<String> _examples = [];
  
  @override
  void initState() {
    super.initState();
    _textController.addListener(_validateInput);
    _generateExamples();
  }

  @override
  void dispose() {
    _textController.removeListener(_validateInput);
    _textController.dispose();
    super.dispose();
  }

  void _validateInput() {
    final text = _textController.text;
    final pattern = widget.questStop.challengeRegex;
    
    if (pattern == null || pattern.isEmpty) {
      setState(() {
        _isValid = text.isNotEmpty;
        _errorMessage = null;
      });
      return;
    }

    try {
      final regex = RegExp(pattern);
      final matches = regex.hasMatch(text);
      
      setState(() {
        _isValid = matches;
        _errorMessage = matches ? null : 'Input doesn\'t match the required pattern';
      });
    } catch (e) {
      setState(() {
        _isValid = false;
        _errorMessage = 'Pattern validation error';
      });
    }
  }

  void _generateExamples() {
    final pattern = widget.questStop.challengeRegex;
    if (pattern == null || pattern.isEmpty) return;

    // Generate some example patterns based on common regex patterns
    final examples = <String>[];
    
    // Email pattern
    if (pattern.contains('@') && pattern.contains('\\.')) {
      examples.addAll(['user@example.com', 'test.email@domain.org']);
    }
    
    // Phone pattern
    if (pattern.contains(r'\d') && (pattern.contains(r'{') || pattern.contains('+'))) {
      examples.addAll(['+1234567890', '(123) 456-7890']);
    }
    
    // Date pattern
    if (pattern.contains(r'\d') && pattern.contains('-')) {
      examples.addAll(['2024-01-15', '12-31-2023']);
    }
    
    // License plate pattern
    if (pattern.contains(r'[A-Z]') && pattern.contains(r'\d')) {
      examples.addAll(['ABC123', 'XYZ-456']);
    }
    
    // Generic examples for common patterns
    if (examples.isEmpty) {
      if (pattern.contains(r'\d+')) {
        examples.add('123456');
      }
      if (pattern.contains(r'[A-Z]')) {
        examples.add('HELLO');
      }
      if (pattern.contains(r'[a-z]')) {
        examples.add('world');
      }
    }

    setState(() {
      _examples = examples.take(3).toList();
    });
  }

  String _getPatternDescription(String pattern) {
    if (pattern.contains('@') && pattern.contains('\\.')) {
      return 'Email address format';
    }
    if (pattern.contains(r'\d') && (pattern.contains(r'{') || pattern.contains('+'))) {
      return 'Phone number format';
    }
    if (pattern.contains(r'\d') && pattern.contains('-')) {
      return 'Date format (YYYY-MM-DD or MM-DD-YYYY)';
    }
    if (pattern.contains(r'[A-Z]') && pattern.contains(r'\d')) {
      return 'License plate or code format';
    }
    if (pattern.contains(r'\d+')) {
      return 'Number format';
    }
    return 'Custom text pattern';
  }

  void _handleSubmit() {
    final answer = _textController.text.trim();
    if (answer.isNotEmpty) {
      widget.onAnswerSubmitted(answer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pattern = widget.questStop.challengeRegex;
    
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
                    colors: [Colors.indigo, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pattern,
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
                      'Pattern Challenge',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      pattern != null ? _getPatternDescription(pattern) : 'Follow the pattern',
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
          
          // Challenge Question
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
          
          // Pattern Information
          if (pattern != null && pattern.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.indigo.withOpacity(0.1),
                    Colors.purple.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.indigo.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.indigo, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Pattern Requirements',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.code, color: Colors.grey, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pattern,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Examples
                  if (_examples.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Examples:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _examples.map((example) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.indigo.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          example,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.indigo,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Text Input with Real-time Validation
          CustomTextField(
            controller: _textController,
            labelText: 'Your answer',
            hintText: 'Enter text matching the pattern...',
            errorText: _errorMessage,
            suffix: _textController.text.isNotEmpty 
                ? Icon(
                    _isValid ? Icons.check_circle : Icons.error,
                    color: _isValid ? Colors.green : Colors.red,
                  )
                : null,
          ),
          
          const SizedBox(height: 16),
          
          // Validation Feedback
          if (_textController.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_isValid ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_isValid ? Colors.green : Colors.red).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isValid ? Icons.check_circle : Icons.error,
                    color: _isValid ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isValid 
                          ? 'Perfect! Your input matches the pattern.'
                          : _errorMessage ?? 'Input doesn\'t match the pattern.',
                      style: TextStyle(
                        color: _isValid ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Submit Button
          CustomButton(
            text: 'Submit Answer',
            icon: Icons.send,
            onPressed: _isValid && !widget.isSubmitting ? _handleSubmit : null,
            isLoading: widget.isSubmitting,
            isFullWidth: true,
            size: ButtonSize.large,
          ),
        ],
      ),
    );
  }
}