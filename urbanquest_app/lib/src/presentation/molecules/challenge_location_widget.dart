import 'package:flutter/material.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_card.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/quest_stop_model.dart';

class ChallengeLocationWidget extends StatelessWidget {
  final QuestStop questStop;
  final Function() onLocationCheck;
  final bool isAtLocation;
  final double distanceToTarget;
  final bool isSubmitting;

  const ChallengeLocationWidget({
    Key? key,
    required this.questStop,
    required this.onLocationCheck,
    required this.isAtLocation,
    required this.distanceToTarget,
    this.isSubmitting = false,
  }) : super(key: key);

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
                    colors: [Colors.red, Colors.redAccent],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
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
                      'Location Challenge',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Get to the right spot',
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
          
          // Challenge Description
          if (questStop.challengeText?.isNotEmpty == true) ...[
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
                questStop.challengeText!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Location Status Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isAtLocation 
                    ? [Colors.green.withOpacity(0.1), Colors.lightGreen.withOpacity(0.05)]
                    : [Colors.orange.withOpacity(0.1), Colors.deepOrange.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAtLocation ? Colors.green : Colors.orange,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isAtLocation ? Colors.green : Colors.orange).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAtLocation ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isAtLocation ? Icons.location_on : Icons.location_searching,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAtLocation ? 'Location Found!' : 'Searching...',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isAtLocation ? Colors.green : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAtLocation 
                          ? 'You\'re at the correct location!'
                          : 'Distance: ${distanceToTarget.toStringAsFixed(0)}m away',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action Button
          CustomButton(
            text: isAtLocation ? 'Continue Quest' : 'Check My Location',
            icon: isAtLocation ? Icons.arrow_forward : Icons.my_location,
            onPressed: !isSubmitting ? onLocationCheck : null,
            isLoading: isSubmitting,
            isFullWidth: true,
            size: ButtonSize.large,
            variant: isAtLocation ? ButtonVariant.primary : ButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}