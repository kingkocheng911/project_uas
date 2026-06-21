import 'package:flutter/material.dart';

import '../constants/colors.dart';

class StatCard extends StatefulWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.trend,
    this.accentColor = AppColors.primary,
  });

  final String title;
  final String value;
  final IconData icon;
  final String trend;
  final Color accentColor;

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 720;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovering ? -3 : 0, 0),
        padding: EdgeInsets.all(compact ? 16 : 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9ECEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovering ? 0.08 : 0.035),
              blurRadius: _hovering ? 24 : 14,
              offset: Offset(0, _hovering ? 10 : 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: compact ? 40 : 44,
                  height: compact ? 40 : 44,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.accentColor,
                    size: compact ? 20 : 22,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
            SizedBox(height: compact ? 12 : 18),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 13,
              ),
            ),
            SizedBox(height: compact ? 4 : 6),
            Text(
              widget.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.w900,
                color: AppColors.textMain,
              ),
            ),
            SizedBox(height: compact ? 8 : 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  widget.trend.startsWith('-')
                      ? Icons.trending_down_rounded
                      : Icons.trending_up_rounded,
                  color: widget.trend.startsWith('-')
                      ? const Color(0xFFE53935)
                      : const Color(0xFF16A34A),
                  size: compact ? 14 : 16,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    widget.trend,
                    maxLines: compact ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.trend.startsWith('-')
                          ? const Color(0xFFE53935)
                          : const Color(0xFF16A34A),
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
