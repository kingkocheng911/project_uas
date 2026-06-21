import 'package:flutter/material.dart';

import '../constants/colors.dart';

class TopNav extends StatelessWidget {
  const TopNav({
    super.key,
    required this.pageTitle,
    required this.onOpenNotifications,
    required this.onOpenProfile,
    required this.onSearch,
    this.onOpenMenu,
  });

  final String pageTitle;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenProfile;
  final ValueChanged<String> onSearch;
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 920;
    final mobile = width < 720;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF))),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: mobile ? 64 : 76,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
            child: Row(
              children: [
                if (mobile && onOpenMenu != null) ...[
                  _TopIconButton(
                    tooltip: 'Open menu',
                    onTap: onOpenMenu!,
                    child: const Icon(Icons.menu_rounded),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pageTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.w900,
                          fontSize: mobile ? 17 : 20,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (!mobile)
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
                        hintText: 'Cari cabang, admin, user...',
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
                ] else if (mobile) ...[
                  _TopIconButton(
                    tooltip: 'Search',
                    onTap: () => _openSearchSheet(context),
                    child: const Icon(Icons.search_rounded),
                  ),
                  const SizedBox(width: 8),
                ],
                _TopIconButton(
                  tooltip: 'Notifications',
                  onTap: onOpenNotifications,
                  child: const Badge(
                    label: Text('5'),
                    child: Icon(Icons.notifications_none_rounded),
                  ),
                ),
                if (!mobile) ...[
                  const SizedBox(width: 10),
                  _TopIconButton(
                    tooltip: 'Quick actions',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quick action panel dibuka.')),
                    ),
                    child: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
                const SizedBox(width: 10),
                InkWell(
                  onTap: onOpenProfile,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: mobile ? 6 : 10,
                      vertical: mobile ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: mobile ? 16 : 18,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            'SA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: mobile ? 11 : 12,
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
          ),
        ),
      ),
    );
  }

  void _openSearchSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cari Data Superadmin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cari cabang, admin, atau user langsung dari dashboard mobile.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  autofocus: true,
                  onSubmitted: (value) {
                    Navigator.of(context).pop();
                    onSearch(value);
                  },
                  decoration: InputDecoration(
                    hintText: 'Ketik nama cabang atau admin...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: AppColors.secondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
