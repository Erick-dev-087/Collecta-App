import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// App scaffold hosting the five primary destinations as a bottom nav bar
/// (the desktop sidebar adapted for mobile).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    (icon: Icons.dashboard_outlined, active: Icons.dashboard, label: 'Dashboard'),
    (icon: Icons.folder_copy_outlined, active: Icons.folder_copy, label: 'Collections'),
    (icon: Icons.groups_outlined, active: Icons.groups, label: 'Members'),
    (icon: Icons.receipt_long_outlined, active: Icons.receipt_long, label: 'Ledger'),
    (icon: Icons.settings_outlined, active: Icons.settings, label: 'Settings'),
  ];

  void _go(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final current = navigationShell.currentIndex;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.panel,
          border: Border(top: BorderSide(color: AppColors.slateBorder)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _items[i].icon,
                      activeIcon: _items[i].active,
                      label: _items[i].label,
                      selected: i == current,
                      onTap: () => _go(i),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.emeraldDeep : AppColors.slateMuted;
    return InkResponse(
      onTap: onTap,
      radius: 36,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(selected ? activeIcon : icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: AppType.labelSm.copyWith(
                color: color,
                letterSpacing: 0.1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              )),
        ],
      ),
    );
  }
}
