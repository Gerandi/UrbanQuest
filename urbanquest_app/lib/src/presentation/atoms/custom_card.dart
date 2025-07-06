import 'package:flutter/material.dart';

enum CardVariant {
  elevated,
  outlined,
  filled,
}

class CustomCard extends StatelessWidget {
  final Widget child;
  final CardVariant variant;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Color? backgroundColor;
  final double? elevation;

  const CustomCard({
    super.key,
    required this.child,
    this.variant = CardVariant.elevated,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? _getBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        border: _getBorder(colorScheme),
        boxShadow: _getBoxShadow(),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          child: card,
        ),
      );
    }

    return card;
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (variant) {
      case CardVariant.elevated:
        return colorScheme.surface;
      case CardVariant.outlined:
        return colorScheme.surface;
      case CardVariant.filled:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Border? _getBorder(ColorScheme colorScheme) {
    switch (variant) {
      case CardVariant.outlined:
        return Border.all(
          color: colorScheme.outline,
          width: 1,
        );
      default:
        return null;
    }
  }

  List<BoxShadow>? _getBoxShadow() {
    switch (variant) {
      case CardVariant.elevated:
        return [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ];
      default:
        return null;
    }
  }
} 