import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../atoms/custom_avatar.dart';
import '../atoms/custom_button.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/user_model.dart' as UserModel;

class ProfileHeaderCard extends StatelessWidget {
  final UserModel.User user;
  final VoidCallback? onEditProfile;
  final VoidCallback? onChangePhoto;
  final bool isEditable;
  final Widget? additionalActions;

  const ProfileHeaderCard({
    super.key,
    required this.user,
    this.onEditProfile,
    this.onChangePhoto,
    this.isEditable = true,
    this.additionalActions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.whiteOpacity90,
            AppColors.whiteOpacity95,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.whiteOpacity30,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackOpacity10,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar and Basic Info
            Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildUserInfo(context),
                ),
              ],
            ),
            
            // Additional Actions Section
            if (additionalActions != null) ...[
              const SizedBox(height: 16),
              additionalActions!,
            ],
          ],
        ),
      ),
    ).animate()
     .fadeIn(duration: 600.ms)
     .slideY(begin: -0.2, end: 0);
  }

  Widget _buildAvatar() {
    Widget avatar = CustomAvatar(
      imageUrl: user.avatar,
      initials: _getInitials(user.displayName),
      size: AvatarSize.extraLarge,
    );

    if (isEditable && onChangePhoto != null) {
      return GestureDetector(
        onTap: onChangePhoto,
        child: Stack(
          children: [
            avatar,
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blackOpacity20,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return avatar;
  }

  Widget _buildUserInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                user.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            if (isEditable && onEditProfile != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEditProfile,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                ),
              ),
          ],
        ),
        Text(
          user.email,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildLevelBadge(),
            const SizedBox(width: 8),
            if (user.isVerified == true) _buildVerifiedBadge(),
          ],
        ),
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            user.bio!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'Level ${user.level} Explorer',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.verified,
            color: Colors.green,
            size: 12,
          ),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}