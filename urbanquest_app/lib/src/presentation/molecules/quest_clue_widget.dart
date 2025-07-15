import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../atoms/custom_card.dart';
import '../../core/constants/app_colors.dart';

class QuestClueWidget extends StatelessWidget {
  final String clue;
  final String stopTitle;

  const QuestClueWidget({
    Key? key,
    required this.clue,
    required this.stopTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.blue.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'CLUE FOR: ${stopTitle.toUpperCase()}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            clue,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2);
  }
}