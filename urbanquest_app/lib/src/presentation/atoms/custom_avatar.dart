import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum AvatarSize {
  small,
  medium,
  large,
  extraLarge,
}

class CustomAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final AvatarSize size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final VoidCallback? onTap;
  final Widget? badge;

  const CustomAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = AvatarSize.medium,
    this.backgroundColor,
    this.foregroundColor,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final avatarSize = _getSize();

    Widget avatar = Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? colorScheme.primary,
      ),
      child: _buildAvatarContent(colorScheme),
    );

    if (badge != null) {
      avatar = Stack(
        children: [
          avatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: badge!,
          ),
        ],
      );
    }

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildAvatarContent(ColorScheme colorScheme) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: _getSize(),
          height: _getSize(),
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildPlaceholder(colorScheme),
          errorWidget: (context, url, error) => _buildPlaceholder(colorScheme),
        ),
      );
    }

    return _buildPlaceholder(colorScheme);
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Center(
      child: Text(
        initials ?? '?',
        style: TextStyle(
          color: foregroundColor ?? colorScheme.onPrimary,
          fontSize: _getFontSize(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double _getSize() {
    switch (size) {
      case AvatarSize.small:
        return 32;
      case AvatarSize.medium:
        return 48;
      case AvatarSize.large:
        return 64;
      case AvatarSize.extraLarge:
        return 96;
    }
  }

  double _getFontSize() {
    switch (size) {
      case AvatarSize.small:
        return 14;
      case AvatarSize.medium:
        return 18;
      case AvatarSize.large:
        return 24;
      case AvatarSize.extraLarge:
        return 36;
    }
  }
} 