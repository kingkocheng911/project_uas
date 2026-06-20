import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  bool _orders = true;
  bool _promotions = true;
  bool _payments = true;
  bool _membership = false;
  bool _security = true;
  bool _newsletter = false;
  bool _email = true;
  bool _sms = false;
  bool _push = true;
  bool _isLoading = true;
  bool _isSaving = false;

  User? get _currentUser => _client.auth.currentUser;
  bool get _canUseSupabase => _currentUser != null;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
        title: Text('Notifications', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Notification Settings', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  _canUseSupabase
                      ? 'Manage how and when you receive notifications.'
                      : 'Pengaturan notifikasi belum tersimpan ke akun karena kamu belum login ke Supabase.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF6D5A58)),
                ),
                const SizedBox(height: 24),

                // Notification types
                _SectionCard(
                  title: 'Notification Types',
                  children: [
                    _ToggleTile(
                      icon: Icons.receipt_long_outlined,
                      iconColor: const Color(0xFF1565C0),
                      iconBg: const Color(0xFFE3F2FD),
                      title: 'Orders & Delivery',
                      subtitle: 'Status updates for your orders',
                      value: _orders,
                      onChanged: _isSaving ? null : (v) => setState(() => _orders = v),
                    ),
                    _ToggleTile(
                      icon: Icons.local_offer_outlined,
                      iconColor: const Color(0xFFD9001B),
                      iconBg: const Color(0xFFFCE1E4),
                      title: 'Promotions & Flash Sales',
                      subtitle: 'Exclusive deals and discounts',
                      value: _promotions,
                      onChanged: _isSaving ? null : (v) => setState(() => _promotions = v),
                    ),
                    _ToggleTile(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: const Color(0xFF1A7F42),
                      iconBg: const Color(0xFFDFF5E8),
                      title: 'Payments & Balance',
                      subtitle: 'Top ups, transactions, dividends',
                      value: _payments,
                      onChanged: _isSaving ? null : (v) => setState(() => _payments = v),
                    ),
                    _ToggleTile(
                      icon: Icons.workspace_premium_outlined,
                      iconColor: const Color(0xFFC9A900),
                      iconBg: const Color(0xFFFFF3CD),
                      title: 'Membership & Points',
                      subtitle: 'Reward points and tier updates',
                      value: _membership,
                      onChanged: _isSaving ? null : (v) => setState(() => _membership = v),
                    ),
                    _ToggleTile(
                      icon: Icons.security_outlined,
                      iconColor: const Color(0xFF1565C0),
                      iconBg: const Color(0xFFE3F2FD),
                      title: 'Security Alerts',
                      subtitle: 'Login, PIN change, suspicious activity',
                      value: _security,
                      onChanged: _isSaving ? null : (v) => setState(() => _security = v),
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Delivery channels
                _SectionCard(
                  title: 'Delivery Channels',
                  children: [
                    _ToggleTile(
                      icon: Icons.notifications_outlined,
                      iconColor: primary,
                      iconBg: const Color(0xFFFFE9E6),
                      title: 'Push Notifications',
                      subtitle: 'Receive alerts on your device',
                      value: _push,
                      onChanged: _isSaving ? null : (v) => setState(() => _push = v),
                    ),
                    _ToggleTile(
                      icon: Icons.email_outlined,
                      iconColor: const Color(0xFF5D5F5F),
                      iconBg: const Color(0xFFDFE0E0),
                      title: 'Email Notifications',
                      subtitle: 'Sent to your registered email address',
                      value: _email,
                      onChanged: _isSaving ? null : (v) => setState(() => _email = v),
                    ),
                    _ToggleTile(
                      icon: Icons.sms_outlined,
                      iconColor: const Color(0xFF1A7F42),
                      iconBg: const Color(0xFFDFF5E8),
                      title: 'SMS Notifications',
                      subtitle: 'Sent to your registered phone number',
                      value: _sms,
                      onChanged: _isSaving ? null : (v) => setState(() => _sms = v),
                    ),
                    _ToggleTile(
                      icon: Icons.mark_email_unread_outlined,
                      iconColor: const Color(0xFF6D5A58),
                      iconBg: const Color(0xFFF1F3F5),
                      title: 'Newsletter',
                      subtitle: 'Monthly cooperative updates',
                      value: _newsletter,
                      onChanged: _isSaving ? null : (v) => setState(() => _newsletter = v),
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                FilledButton(
                  onPressed: _isSaving ? null : _saveSettings,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    minimumSize: const Size.fromHeight(62),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    _isSaving ? 'Saving...' : 'Save Preferences',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Future<void> _loadSettings() async {
    if (!_canUseSupabase) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final row = await _client
          .from('notification_settings')
          .select(
            'orders_enabled, promotions_enabled, payments_enabled, '
            'membership_enabled, security_enabled, newsletter_enabled, '
            'email_enabled, sms_enabled, push_enabled',
          )
          .eq('user_id', _currentUser!.id)
          .maybeSingle();

      if (!mounted) return;
      if (row != null) {
        setState(() {
          _applySettingsRow(row);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showNotice('Gagal memuat pengaturan notifikasi. Menampilkan data default.');
    }
  }

  Future<void> _saveSettings() async {
    if (!_canUseSupabase) {
      _showNotice('Login ke Supabase diperlukan untuk menyimpan pengaturan notifikasi.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _client.from('notification_settings').upsert({
        'user_id': _currentUser!.id,
        'orders_enabled': _orders,
        'promotions_enabled': _promotions,
        'payments_enabled': _payments,
        'membership_enabled': _membership,
        'security_enabled': _security,
        'newsletter_enabled': _newsletter,
        'email_enabled': _email,
        'sms_enabled': _sms,
        'push_enabled': _push,
      });

      if (!mounted) return;
      _showNotice('Pengaturan notifikasi berhasil disimpan.');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      _showNotice('Pengaturan notifikasi belum berhasil disimpan. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _applySettingsRow(Map<String, dynamic> row) {
    _orders = row['orders_enabled'] != false;
    _promotions = row['promotions_enabled'] != false;
    _payments = row['payments_enabled'] != false;
    _membership = row['membership_enabled'] == true;
    _security = row['security_enabled'] != false;
    _newsletter = row['newsletter_enabled'] == true;
    _email = row['email_enabled'] != false;
    _sms = row['sms_enabled'] == true;
    _push = row['push_enabled'] != false;
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8BCB8)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFE8BCB8))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6D5A58))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
