import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double opacity;
  final bool hasBorder;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius,
    this.opacity = 0.9,
    this.hasBorder = true,
    this.backgroundColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.whiteOpacity90.withOpacity(opacity),
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: hasBorder ? Border.all(
          color: AppColors.whiteOpacity30,
          width: 1,
        ) : null,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: AppColors.blackOpacity10,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: padding != null 
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }
}

class GlassCardVariant extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color primaryColor;
  final double intensity;

  const GlassCardVariant({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.primaryColor = AppColors.primary,
    this.intensity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(intensity),
            primaryColor.withOpacity(intensity * 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: padding != null 
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }
}