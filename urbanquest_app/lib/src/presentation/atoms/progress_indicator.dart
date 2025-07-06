import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomProgressIndicator extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double height;
  final Color? backgroundColor;
  final Color? progressColor;
  final String? label;
  final String? percentage;
  final bool showAnimation;

  const CustomProgressIndicator({
    super.key,
    required this.progress,
    this.height = 8,
    this.backgroundColor,
    this.progressColor,
    this.label,
    this.percentage,
    this.showAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || percentage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (percentage != null)
                  Text(
                    percentage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: progressColor ?? colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? colorScheme.outline.withOpacity(0.2),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: height,
                  color: backgroundColor ?? colorScheme.outline.withOpacity(0.2),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          progressColor ?? colorScheme.primary,
                          (progressColor ?? colorScheme.primary).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ).animate(target: showAnimation ? 1 : 0)
                    .scaleX(
                      duration: 800.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CircularProgressCustom extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final Widget? child;

  const CircularProgressCustom({
    super.key,
    required this.progress,
    this.size = 48,
    this.strokeWidth = 4,
    this.backgroundColor,
    this.progressColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              backgroundColor: backgroundColor ?? colorScheme.outline.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                progressColor ?? colorScheme.primary,
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
} 