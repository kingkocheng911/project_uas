import 'package:flutter/material.dart';

import '../constants/colors.dart';

class TopNav extends StatelessWidget {
  const TopNav({
    super.key,
    required this.pageTitle,
    required this.onOpenNotifications,
    required this.onOpenProfile,
    required this.onSearch,
  });

  final String pageTitle;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenProfile;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 920;

    return Container(
      height: 76,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pageTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Kantor Pusat / $pageTitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            SizedBox(
              width: 320,
              height: 44,
              child: TextField(
                onSubmitted: onSearch,
                decoration: InputDecoration(
                  hintText: 'Cari cabang, admin, order...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: AppColors.secondary,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          _TopIconButton(
            tooltip: 'Notifications',
            onTap: onOpenNotifications,
            child: const Badge(
              label: Text('5'),
              child: Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 10),
          _TopIconButton(
            tooltip: 'Quick actions',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quick action panel dibuka.')),
            ),
            child: const Icon(Icons.add_circle_outline_rounded),
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: onOpenProfile,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      'SA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 10),
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safitri Novitasari',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Super Admin',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
