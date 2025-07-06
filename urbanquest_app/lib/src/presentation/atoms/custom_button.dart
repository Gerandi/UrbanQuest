import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
// // import 'package:lucide_icons_flutter/lucide_icons.dart';  // Comment out for now  // Comment out for now

enum ButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
}

enum ButtonSize {
  small,
  medium,
  large,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(colorScheme),
          foregroundColor: _getForegroundColor(colorScheme),
          elevation: _getElevation(),
          shadowColor: Colors.black26,
          padding: _getPadding(),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_getBorderRadius()),
            side: _getBorderSide(colorScheme),
          ),
          minimumSize: Size(0, _getHeight()),
        ),
        child: isLoading
            ? SizedBox(
                height: _getIconSize(),
                width: _getIconSize(),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _getForegroundColor(colorScheme),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: _getIconSize()),
                    SizedBox(width: _getIconSpacing()),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: _getTextStyle(theme),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.primary; // Use our brand primary color
      case ButtonVariant.secondary:
        return AppColors.secondary; // Use our brand secondary color
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
        return AppColors.transparent;
    }
  }

  Color _getForegroundColor(ColorScheme colorScheme) {
    switch (variant) {
      case ButtonVariant.primary:
        return AppColors.white; // White text on primary button
      case ButtonVariant.secondary:
        return AppColors.white; // White text on secondary button
      case ButtonVariant.outline:
        return AppColors.white; // White text for outline buttons on colored backgrounds
      case ButtonVariant.ghost:
        return AppColors.white; // White text for ghost buttons on colored backgrounds
    }
  }

  double _getElevation() {
    switch (variant) {
      case ButtonVariant.primary:
      case ButtonVariant.secondary:
        return 4;
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
        return 0;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case ButtonSize.small:
        return 8;
      case ButtonSize.medium:
        return 12;
      case ButtonSize.large:
        return 16;
    }
  }

  BorderSide _getBorderSide(ColorScheme colorScheme) {
    switch (variant) {
      case ButtonVariant.outline:
        return BorderSide(color: AppColors.whiteOpacity30, width: 1.5);
      default:
        return BorderSide.none;
    }
  }

  double _getHeight() {
    switch (size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 44;
      case ButtonSize.large:
        return 52;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  double _getIconSpacing() {
    switch (size) {
      case ButtonSize.small:
        return 6;
      case ButtonSize.medium:
        return 8;
      case ButtonSize.large:
        return 10;
    }
  }

  TextStyle _getTextStyle(ThemeData theme) {
    final baseStyle = switch (size) {
      ButtonSize.small => theme.textTheme.labelSmall,
      ButtonSize.medium => theme.textTheme.labelMedium,
      ButtonSize.large => theme.textTheme.labelLarge,
    };

    return baseStyle?.copyWith(
          fontWeight: FontWeight.w600,
          color: _getForegroundColor(theme.colorScheme),
        ) ??
        TextStyle(
          fontWeight: FontWeight.w600,
          color: _getForegroundColor(theme.colorScheme),
    );
  }
}
