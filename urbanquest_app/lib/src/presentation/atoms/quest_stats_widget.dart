import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';

class QuestStatsWidget extends StatelessWidget {
  final int currentStopIndex;
  final int totalStops;
  final int steps;
  final Duration elapsedTime;
  final bool isAtLocation;

  const QuestStatsWidget({
    Key? key,
    required this.currentStopIndex,
    required this.totalStops,
    required this.steps,
    required this.elapsedTime,
    required this.isAtLocation,
  }) : super(key: key);

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
    final progressPercentage = totalStops > 0 
        ? ((currentStopIndex + 1) / totalStops) * 100 
        : 0.0;

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
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress tracking section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Progress text and percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stop ${currentStopIndex + 1} of $totalStops',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${progressPercentage.toInt()}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Progress bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.whiteOpacity20,
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
                
                const SizedBox(height: 24),
                
                // Glassmorphic stats row
                _buildGlassmorphicStatsRow(),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2);
  }

  Widget _buildGlassmorphicStatsRow() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.whiteOpacity10,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.whiteOpacity20,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Steps stat
              Expanded(
                child: _buildStatColumn(
                  icon: Icons.directions_walk,
                  label: 'Steps',
                  value: steps.toString(),
                ),
              ),
              
              // Glass divider
              _buildGlassDivider(),
              
              // Time stat
              Expanded(
                child: _buildStatColumn(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: _formatDuration(elapsedTime),
                ),
              ),
              
              // Glass divider
              _buildGlassDivider(),
              
              // GPS stat
              Expanded(
                child: _buildStatColumn(
                  icon: isAtLocation ? Icons.location_on : Icons.location_searching,
                  label: 'GPS',
                  value: isAtLocation ? 'Locked' : 'Searching',
                  isGpsLocked: !isAtLocation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            AppColors.whiteOpacity10,
            AppColors.whiteOpacity30,
            AppColors.whiteOpacity10,
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
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
                color: AppColors.whiteOpacity20,
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
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.whiteOpacity80,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}