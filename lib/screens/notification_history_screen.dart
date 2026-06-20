import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isLoading = true;
  bool _isMarkingAllRead = false;
  List<_NotificationItem> _items = const [];

  User? get _currentUser => _client.auth.currentUser;
  bool get _canUseSupabase => _currentUser != null;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

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
        title: Text(
          'Notifications',
          style: TextStyle(color: primary, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed:
                _isMarkingAllRead || _items.every((item) => item.isRead)
                    ? null
                    : _markAllRead,
            child: Text(
              _isMarkingAllRead ? 'Marking...' : 'Mark all read',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _items.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        _EmptyNotificationState(),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: _buildSections(),
                    ),
            ),
    );
  }

  List<Widget> _buildSections() {
    final today = <_NotificationItem>[];
    final yesterday = <_NotificationItem>[];
    final earlier = <_NotificationItem>[];
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    for (final item in _items) {
      final createdAt = item.createdAt.toLocal();
      if (!createdAt.isBefore(todayStart)) {
        today.add(item);
      } else if (!createdAt.isBefore(yesterdayStart)) {
        yesterday.add(item);
      } else {
        earlier.add(item);
      }
    }

    final children = <Widget>[];
    void addSection(String label, List<_NotificationItem> items) {
      if (items.isEmpty) return;
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 20));
      }
      children.add(_SectionLabel(label: label));
      children.add(const SizedBox(height: 10));
      for (final item in items) {
        children.add(
          _NotifTile(
            item: item,
            onTap: () => _markAsRead(item),
          ),
        );
      }
    }

    addSection('Today', today);
    addSection('Yesterday', yesterday);
    addSection('Earlier', earlier);
    children.add(const SizedBox(height: 32));
    return children;
  }

  Future<void> _loadNotifications() async {
    if (!_canUseSupabase) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _isLoading = false;
      });
      return;
    }

    try {
      final rows = await _client
          .from('notifications')
          .select('id, type, title, message, is_read, created_at')
          .eq('user_id', _currentUser!.id)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _items = rows
            .map<_NotificationItem>(
              (row) => _NotificationItem.fromRow(Map<String, dynamic>.from(row)),
            )
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _isLoading = false;
      });
      _showNotice('Notifikasi belum berhasil dimuat.');
    }
  }

  Future<void> _markAllRead() async {
    if (!_canUseSupabase || _items.every((item) => item.isRead)) return;
    setState(() => _isMarkingAllRead = true);
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _currentUser!.id)
          .eq('is_read', false);
      if (!mounted) return;
      setState(() {
        _items = _items
            .map((item) => item.copyWith(isRead: true))
            .toList(growable: false);
      });
    } catch (_) {
      if (mounted) {
        _showNotice('Gagal menandai semua notifikasi sebagai dibaca.');
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingAllRead = false);
      }
    }
  }

  Future<void> _markAsRead(_NotificationItem item) async {
    if (!_canUseSupabase || item.isRead) return;
    setState(() {
      _items = _items
          .map((entry) => entry.id == item.id ? entry.copyWith(isRead: true) : entry)
          .toList(growable: false);
    });
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', item.id);
    } catch (_) {
      if (!mounted) return;
      _showNotice('Status notifikasi belum berhasil diperbarui.');
      setState(() {
        _items = _items
            .map((entry) => entry.id == item.id ? item : entry)
            .toList(growable: false);
      });
    }
  }

  void _showNotice(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  factory _NotificationItem.fromRow(Map<String, dynamic> row) {
    final rawCreatedAt = (row['created_at'] ?? '').toString();
    return _NotificationItem(
      id: (row['id'] ?? '').toString(),
      type: (row['type'] ?? 'system').toString(),
      title: (row['title'] ?? '').toString(),
      message: (row['message'] ?? '').toString(),
      isRead: row['is_read'] == true,
      createdAt: DateTime.tryParse(rawCreatedAt)?.toLocal() ?? DateTime.now(),
    );
  }

  _NotificationItem copyWith({bool? isRead}) {
    return _NotificationItem(
      id: id,
      type: type,
      title: title,
      message: message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            'Belum ada notifikasi',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi order, pembayaran, dan promo akan muncul di sini.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF6D5A58),
            ),
            textAlign: TextAlign.center,
          ),
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
  const _NotifTile({required this.item, required this.onTap});

  final _NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _notificationStyle(item.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFFFF5F5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFE8BCB8)
                  : theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: style.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.foreground, size: 22),
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
                            item.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!item.isRead)
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
                      item.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6D5A58),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatNotificationTime(item.createdAt),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF9F7E79),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationStyle {
  const _NotificationStyle({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
}

_NotificationStyle _notificationStyle(String type) {
  switch (type) {
    case 'order':
      return const _NotificationStyle(
        icon: Icons.local_shipping_outlined,
        background: Color(0xFFE3F2FD),
        foreground: Color(0xFF1565C0),
      );
    case 'promo':
      return const _NotificationStyle(
        icon: Icons.local_offer_outlined,
        background: Color(0xFFFCE1E4),
        foreground: Color(0xFFD9001B),
      );
    case 'stock':
      return const _NotificationStyle(
        icon: Icons.inventory_2_outlined,
        background: Color(0xFFFFF3CD),
        foreground: Color(0xFFC9A900),
      );
    case 'admin':
      return const _NotificationStyle(
        icon: Icons.support_agent_outlined,
        background: Color(0xFFEDEEEF),
        foreground: Color(0xFF5D5F5F),
      );
    case 'system':
    default:
      return const _NotificationStyle(
        icon: Icons.account_balance_wallet_outlined,
        background: Color(0xFFDFF5E8),
        foreground: Color(0xFF1A7F42),
      );
  }
}

String _formatNotificationTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);
  if (difference.inMinutes < 1) return 'Baru saja';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min lalu';
  if (difference.inHours < 24) return '${difference.inHours} jam lalu';
  if (difference.inDays == 1) {
    return 'Kemarin';
  }
  return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
}
