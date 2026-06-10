import 'package:flutter/material.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometric = true;
  bool _twoFactor = false;
  bool _loginAlert = true;

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
        title: Text('Security', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Security Settings', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Manage your account security and login protection.',
            style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF6D5A58)),
          ),
          const SizedBox(height: 24),

          // Security status banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFDFF5E8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF9ECFAE)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A7F42).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_outlined, color: Color(0xFF1A7F42), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account is Secure',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF1A7F42),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Last login: Today, 08:30 from Android device',
                        style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF2A6E46)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // PIN & Password
          Text('PIN & Password', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8BCB8)),
            ),
            child: Column(
              children: [
                _SecurityActionTile(
                  icon: Icons.pin_outlined,
                  iconColor: primary,
                  iconBg: const Color(0xFFFFE9E6),
                  title: 'Change Transaction PIN',
                  subtitle: 'Last changed 30 days ago',
                  onTap: () => _showPinDialog(context),
                  isLast: false,
                ),
                _SecurityActionTile(
                  icon: Icons.lock_outline_rounded,
                  iconColor: const Color(0xFF1565C0),
                  iconBg: const Color(0xFFE3F2FD),
                  title: 'Change Password',
                  subtitle: 'Update your login password',
                  onTap: () {},
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Authentication
          Text('Authentication', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8BCB8)),
            ),
            child: Column(
              children: [
                _ToggleTile(
                  icon: Icons.fingerprint_rounded,
                  iconColor: const Color(0xFF5D5F5F),
                  iconBg: const Color(0xFFDFE0E0),
                  title: 'Biometric Login',
                  subtitle: 'Use fingerprint or face ID',
                  value: _biometric,
                  onChanged: (v) => setState(() => _biometric = v),
                  isLast: false,
                ),
                _ToggleTile(
                  icon: Icons.phonelink_lock_outlined,
                  iconColor: const Color(0xFFC9A900),
                  iconBg: const Color(0xFFFFF3CD),
                  title: 'Two-Factor Authentication',
                  subtitle: 'Extra security via SMS OTP',
                  value: _twoFactor,
                  onChanged: (v) => setState(() => _twoFactor = v),
                  isLast: false,
                ),
                _ToggleTile(
                  icon: Icons.notifications_active_outlined,
                  iconColor: const Color(0xFF1A7F42),
                  iconBg: const Color(0xFFDFF5E8),
                  title: 'Login Alerts',
                  subtitle: 'Notify me on new device login',
                  value: _loginAlert,
                  onChanged: (v) => setState(() => _loginAlert = v),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Danger zone
          Text('Account', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8BCB8)),
            ),
            child: Column(
              children: [
                _SecurityActionTile(
                  icon: Icons.devices_outlined,
                  iconColor: const Color(0xFF5D5F5F),
                  iconBg: const Color(0xFFDFE0E0),
                  title: 'Manage Trusted Devices',
                  subtitle: '2 active devices',
                  onTap: () {},
                  isLast: false,
                ),
                _SecurityActionTile(
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFFBA1A1A),
                  iconBg: const Color(0xFFFFDAD6),
                  title: 'Logout All Devices',
                  subtitle: 'Sign out from every session',
                  onTap: () {},
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showPinDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Change PIN'),
        content: const Text('Enter your current PIN to continue.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _SecurityActionTile extends StatelessWidget {
  const _SecurityActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isLast,
  });

  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isLast ? 22 : 0),
      child: Container(
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
                  Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6D5A58))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9F7E79)),
          ],
        ),
      ),
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
    required this.isLast,
  });

  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
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
                Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6D5A58))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
