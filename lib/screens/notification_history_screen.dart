import 'package:flutter/material.dart';

class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Notifications', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Mark all read', style: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionLabel(label: 'Today'),
          const SizedBox(height: 10),
          const _NotifTile(
            icon: Icons.local_shipping_outlined,
            iconBg: Color(0xFFE3F2FD),
            iconColor: Color(0xFF1565C0),
            title: 'Your order is on the way!',
            subtitle: 'ORD-240526-01 has been picked up by the courier and is heading to your address.',
            time: '10 min ago',
            isRead: false,
          ),
          const _NotifTile(
            icon: Icons.local_offer_outlined,
            iconBg: Color(0xFFFCE1E4),
            iconColor: Color(0xFFD9001B),
            title: 'Flash Sale starts now',
            subtitle: 'Exclusive deals for KDMP members. Up to 30% off on sembako items until midnight.',
            time: '1 hour ago',
            isRead: false,
          ),
          const _NotifTile(
            icon: Icons.account_balance_wallet_outlined,
            iconBg: Color(0xFFDFF5E8),
            iconColor: Color(0xFF1A7F42),
            title: 'Top Up Successful',
            subtitle: 'Your KDMP balance has been topped up by Rp 250.000. Current balance: Rp 450.000.',
            time: '3 hours ago',
            isRead: true,
          ),
          const SizedBox(height: 20),
          _SectionLabel(label: 'Yesterday'),
          const SizedBox(height: 10),
          const _NotifTile(
            icon: Icons.star_rounded,
            iconBg: Color(0xFFFFF3CD),
            iconColor: Color(0xFFC9A900),
            title: 'You earned 75 reward points',
            subtitle: 'Purchase of Beras Premium 5kg has earned you 75 KDMP points. Keep shopping!',
            time: 'Yesterday, 14:30',
            isRead: true,
          ),
          const _NotifTile(
            icon: Icons.location_on_outlined,
            iconBg: Color(0xFFEDEEEF),
            iconColor: Color(0xFF5D5F5F),
            title: 'Address updated successfully',
            subtitle: 'Your primary delivery address has been changed to Jl. Merdeka No. 42.',
            time: 'Yesterday, 09:00',
            isRead: true,
          ),
          const _NotifTile(
            icon: Icons.security_outlined,
            iconBg: Color(0xFFE3F2FD),
            iconColor: Color(0xFF1565C0),
            title: 'Login from new device',
            subtitle: 'We detected a sign-in from a new device. If this was you, no action is needed.',
            time: 'Yesterday, 08:15',
            isRead: true,
          ),
          const SizedBox(height: 20),
          _SectionLabel(label: 'Earlier'),
          const SizedBox(height: 10),
          const _NotifTile(
            icon: Icons.payments_outlined,
            iconBg: Color(0xFFFFF3CD),
            iconColor: Color(0xFFC9A900),
            title: 'Quarterly Dividend Received',
            subtitle: 'Your Q3 2023 dividend of Rp 150.000 has been credited to your savings balance.',
            time: '3 days ago',
            isRead: true,
          ),
          const _NotifTile(
            icon: Icons.check_circle_outline_rounded,
            iconBg: Color(0xFFDFF5E8),
            iconColor: Color(0xFF1A7F42),
            title: 'Order Completed',
            subtitle: 'Your order ORD-240523-03 (KDMP Smart Band) has been delivered and completed.',
            time: '5 days ago',
            isRead: true,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: const Color(0xFF6D5A58),
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isRead,
  });

  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle, time;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead ? const Color(0xFFE8BCB8) : theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6D5A58), height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF9F7E79)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
