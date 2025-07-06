import 'dart:ui';
import 'package:flutter/material.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';  // Comment out for now

enum NavigationTab {
  home,
  citySelection,
  leaderboard,
  profile,
}

class NavigationItem {
  final NavigationTab tab;
  final IconData icon;
  final String label;

  const NavigationItem({
    required this.tab,
    required this.icon,
    required this.label,
  });
}

class BottomNavigationBarCustom extends StatelessWidget {
  final NavigationTab currentTab;
  final Function(NavigationTab) onTabChanged;

  const BottomNavigationBarCustom({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  static const List<NavigationItem> _navigationItems = [
    NavigationItem(
      tab: NavigationTab.home,
      icon: Icons.home,
      label: 'Home',
    ),
    NavigationItem(
      tab: NavigationTab.citySelection,
      icon: Icons.explore,
      label: 'Explore',
    ),
    NavigationItem(
      tab: NavigationTab.leaderboard,
      icon: Icons.emoji_events,
      label: 'Leaderboard',
    ),
    NavigationItem(
      tab: NavigationTab.profile,
      icon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _navigationItems.map((item) {
                  final isSelected = item.tab == currentTab;
                  return _NavigationButton(
                    item: item,
                    isSelected: isSelected,
                    onTap: () => onTabChanged(item.tab),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavigationButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [
                        Color(0xFFf97316), // Orange-500
                        Color(0xFFef4444), // Red-500
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFf97316).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: isSelected
                        ? Colors.white
                        : colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 