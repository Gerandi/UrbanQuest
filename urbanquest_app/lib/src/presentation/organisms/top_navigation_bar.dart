import 'dart:ui';
import 'package:flutter/material.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';  // Comment out for now
import '../atoms/custom_button.dart';

class TopNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;

  const TopNavigationBar({
    super.key,
    this.title,
    this.onBackPressed,
    this.actions,
    this.showBackButton = false,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: elevation,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      leading: showBackButton
          ? Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomButton(
                text: '',
                icon: Icons.arrow_back,
                variant: ButtonVariant.ghost,
                size: ButtonSize.small,
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              ),
            )
          : null,
      title: title != null
          ? ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFf97316), // Orange-500
                  Color(0xFFef4444), // Red-500
                ],
              ).createShader(bounds),
              child: Text(
                title!,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withOpacity(0.8),
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class NavigationAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  const NavigationAction({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: CustomButton(
        text: '',
        icon: icon,
        variant: ButtonVariant.ghost,
        size: ButtonSize.small,
        onPressed: onPressed,
      ),
    );
  }
} 