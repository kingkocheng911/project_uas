import 'package:flutter/material.dart';

import '../constants/colors.dart';

class SidebarMenuItem {
  const SidebarMenuItem({required this.name, required this.icon});

  final String name;
  final IconData icon;
}

const superAdminMenus = <SidebarMenuItem>[
  SidebarMenuItem(name: 'Dashboard', icon: Icons.dashboard_rounded),
  SidebarMenuItem(name: 'Branch Monitoring', icon: Icons.storefront_rounded),
  SidebarMenuItem(name: 'Branch Performance', icon: Icons.leaderboard_rounded),
  SidebarMenuItem(
    name: 'Admin Monitoring',
    icon: Icons.admin_panel_settings_rounded,
  ),
  SidebarMenuItem(
    name: 'Branch Management',
    icon: Icons.edit_location_alt_rounded,
  ),
  SidebarMenuItem(name: 'Analytics', icon: Icons.insights_rounded),
];

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({
    super.key,
    required this.isExtended,
    required this.currentMenu,
    required this.onMenuSelected,
    required this.onToggle,
  });

  final bool isExtended;
  final String currentMenu;
  final ValueChanged<String> onMenuSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: isExtended ? 280 : 82,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Column(
        children: [
          Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: isExtended
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: [
                if (isExtended)
                  const Row(
                    children: [
                      _BrandMark(),
                      SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mepu Point',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Head Office',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  const _BrandMark(),
                IconButton(
                  tooltip: isExtended ? 'Collapse sidebar' : 'Expand sidebar',
                  onPressed: onToggle,
                  icon: Icon(
                    isExtended
                        ? Icons.keyboard_double_arrow_left_rounded
                        : Icons.keyboard_double_arrow_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE9ECEF)),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              itemCount: superAdminMenus.length,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = superAdminMenus[index];
                final selected = currentMenu == item.name;
                return Tooltip(
                  message: isExtended ? '' : item.name,
                  child: InkWell(
                    onTap: () => onMenuSelected(item.name),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                        horizontal: isExtended ? 14 : 0,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.10)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: isExtended
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textMuted,
                            size: 22,
                          ),
                          if (isExtended) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textMain,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isExtended)
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded, color: AppColors.accent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Super Admin Access',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.storefront_rounded, color: Colors.white),
    );
  }
}
