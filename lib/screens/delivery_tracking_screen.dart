import 'package:flutter/material.dart';

import '../models.dart';

class DeliveryTrackingScreen extends StatelessWidget {
  const DeliveryTrackingScreen({super.key, required this.order});

  final OrderItem order;

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
        title: Text('Track Order', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Map placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFCEE6D0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                // Map style grid
                CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _MapGridPainter(),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))],
                        ),
                        child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [BoxShadow(color: Color(0x20000000), blurRadius: 8)],
                        ),
                        child: Text(
                          'Courier is on the way',
                          style: theme.textTheme.labelLarge?.copyWith(color: primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ETA card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8BCB8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.timer_outlined, color: primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Estimated Arrival', style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF6D5A58))),
                      Text('Today, 02:30 PM', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Text(
                  '~15 min',
                  style: theme.textTheme.titleMedium?.copyWith(color: primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Order info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8BCB8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                _InfoRow(label: 'Order ID', value: order.id),
                _InfoRow(label: 'Items', value: order.items.join(', ')),
                _InfoRow(label: 'Destination', value: order.address),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tracking timeline
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8BCB8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tracking Timeline', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _TimelineTile(
                  title: 'Order Placed',
                  time: '26 May 2026, 09:15',
                  isDone: true,
                  isFirst: true,
                ),
                _TimelineTile(
                  title: 'Order Prepared',
                  time: '26 May 2026, 10:00',
                  isDone: true,
                  isFirst: false,
                ),
                _TimelineTile(
                  title: 'Out for Delivery',
                  time: '26 May 2026, 11:30',
                  isDone: true,
                  isFirst: false,
                ),
                _TimelineTile(
                  title: 'Delivered',
                  time: 'Expected ~02:30 PM',
                  isDone: false,
                  isFirst: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Courier info
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8BCB8)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF25313B),
                  child: const Text(
                    'AK',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ahmad Kurniawan', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text('KDMP Delivery Partner', style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6D5A58))),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.call_outlined, color: primary, size: 22),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chat_bubble_outline_rounded, color: primary, size: 22),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF6D5A58))),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.title,
    required this.time,
    required this.isDone,
    required this.isFirst,
  });
  final String title, time;
  final bool isDone, isFirst;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? primary : const Color(0xFFE1E3E4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone ? Icons.check_rounded : Icons.circle_outlined,
                color: isDone ? Colors.white : const Color(0xFF9F7E79),
                size: 14,
              ),
            ),
            if (!isFirst)
              Container(
                width: 2,
                height: 36,
                color: isDone ? primary.withValues(alpha: 0.4) : const Color(0xFFE1E3E4),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDone ? theme.colorScheme.onSurface : const Color(0xFF9F7E79),
                  ),
                ),
                Text(time, style: theme.textTheme.labelMedium?.copyWith(color: const Color(0xFF9F7E79))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB0D8B5)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
