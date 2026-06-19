import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<_PaymentMethodViewModel> _methods = const [];
  int _walletBalance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      final methodRows = await client
          .from('payment_methods')
          .select('code, name, type, provider_name, is_active, sort_order')
          .eq('is_active', true)
          .order('sort_order');

      int walletBalance = 0;
      if (user != null) {
        final profileRow = await client
            .from('profiles')
            .select('wallet_balance')
            .eq('id', user.id)
            .maybeSingle();
        walletBalance = (profileRow?['wallet_balance'] as num?)?.toInt() ?? 0;
      }

      if (!mounted) return;
      setState(() {
        _walletBalance = walletBalance;
        _methods = methodRows.isEmpty
            ? _fallbackMethods
            : methodRows
                .map<_PaymentMethodViewModel>(_mapMethodRow)
                .toList(growable: false);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _walletBalance = 0;
        _methods = _fallbackMethods;
        _isLoading = false;
      });
    }
  }

  _PaymentMethodViewModel _mapMethodRow(Map<String, dynamic> row) {
    final code = (row['code'] ?? '').toString();
    final type = (row['type'] ?? '').toString();
    final provider = (row['provider_name'] ?? '').toString();
    final name = (row['name'] ?? '').toString();

    switch (type) {
      case 'qris':
        return _PaymentMethodViewModel(
          title: name.isEmpty ? 'QRIS' : name,
          subtitle: 'Bayar melalui mobile banking atau e-wallet yang mendukung QRIS.',
          icon: Icons.qr_code_2_rounded,
          iconColor: const Color(0xFF0F766E),
          iconBg: const Color(0xFFCCFBF1),
          availability: 'Aktif',
          availabilityColor: const Color(0xFF166534),
          availabilityBg: const Color(0xFFDCFCE7),
          detail: provider.isEmpty ? 'Semua aplikasi QRIS' : provider,
        );
      case 'ewallet':
        return _PaymentMethodViewModel(
          title: name,
          subtitle: 'Pembayaran instan dari akun e-wallet yang sudah Anda miliki.',
          icon: Icons.account_balance_wallet_outlined,
          iconColor: const Color(0xFF1D4ED8),
          iconBg: const Color(0xFFDBEAFE),
          availability: 'Aktif',
          availabilityColor: const Color(0xFF166534),
          availabilityBg: const Color(0xFFDCFCE7),
          detail: provider.isEmpty ? 'E-Wallet' : provider,
        );
      case 'cod':
        return _PaymentMethodViewModel(
          title: name.isEmpty ? 'Bayar di Tempat' : name,
          subtitle: 'Tersedia untuk area layanan tertentu dan pesanan yang memenuhi syarat.',
          icon: Icons.local_shipping_outlined,
          iconColor: const Color(0xFF92400E),
          iconBg: const Color(0xFFFEF3C7),
          availability: 'Terbatas',
          availabilityColor: const Color(0xFF92400E),
          availabilityBg: const Color(0xFFFEF3C7),
          detail: provider.isEmpty ? 'Cabang KDMP' : provider,
        );
      case 'cash':
        return _PaymentMethodViewModel(
          title: name.isEmpty ? 'Tunai di Kasir' : name,
          subtitle: 'Digunakan saat ambil pesanan di cabang atau loket koperasi.',
          icon: Icons.payments_outlined,
          iconColor: const Color(0xFF7C2D12),
          iconBg: const Color(0xFFFED7AA),
          availability: 'Aktif',
          availabilityColor: const Color(0xFF166534),
          availabilityBg: const Color(0xFFDCFCE7),
          detail: provider.isEmpty ? 'Kasir cabang' : provider,
        );
      case 'bank_transfer':
      default:
        return _PaymentMethodViewModel(
          title: name.isEmpty ? 'Transfer Bank' : name,
          subtitle: 'Nomor Virtual Account dibuat otomatis saat checkout.',
          icon: Icons.account_balance_rounded,
          iconColor: const Color(0xFF1D4ED8),
          iconBg: const Color(0xFFDBEAFE),
          availability: 'Aktif',
          availabilityColor: const Color(0xFF166534),
          availabilityBg: const Color(0xFFDCFCE7),
          detail: provider.isEmpty ? code.toUpperCase() : provider,
        );
    }
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
          'Metode Pembayaran',
          style: TextStyle(color: primary, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPaymentData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Metode Pembayaran',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Metode yang tersedia untuk checkout, top up sandbox, dan transaksi di jaringan KDMP.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6D5A58),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _WalletSummaryCard(balance: _walletBalance),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Metode Aktif'),
                  const SizedBox(height: 12),
                  for (final method in _methods) ...[
                    _RealisticPaymentCard(method: method),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 12),
                  _SectionTitle(title: 'Catatan Penggunaan'),
                  const SizedBox(height: 12),
                  const _OperationalNote(
                    icon: Icons.info_outline_rounded,
                    title: 'Virtual Account dibuat saat checkout',
                    subtitle: 'Nomor pembayaran tidak disimpan permanen. Sistem membuat nomor VA unik untuk setiap transaksi.',
                  ),
                  const SizedBox(height: 10),
                  const _OperationalNote(
                    icon: Icons.qr_code_2_rounded,
                    title: 'QRIS cocok untuk pembayaran cepat',
                    subtitle: 'Pelanggan dapat membayar dari aplikasi bank atau e-wallet yang mendukung QRIS nasional.',
                  ),
                  const SizedBox(height: 10),
                  const _OperationalNote(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Saldo MepuPoin dipakai dari akun pelanggan',
                    subtitle: 'Saldo tersimpan di backend dan hanya bertambah setelah top up sandbox dinyatakan berhasil.',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _WalletSummaryCard extends StatelessWidget {
  const _WalletSummaryCard({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD9001B), Color(0xFF8B0011)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo MepuPoin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRupiah(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Sandbox Ready',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: const Color(0xFF6D5A58),
      ),
    );
  }
}

class _RealisticPaymentCard extends StatelessWidget {
  const _RealisticPaymentCard({required this.method});

  final _PaymentMethodViewModel method;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8BCB8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: method.iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(method.icon, color: method.iconColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      method.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: method.availabilityBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        method.availability,
                        style: TextStyle(
                          color: method.availabilityColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  method.subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6D5A58),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        method.detail,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationalNote extends StatelessWidget {
  const _OperationalNote({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
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

class _PaymentMethodViewModel {
  const _PaymentMethodViewModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.availability,
    required this.availabilityColor,
    required this.availabilityBg,
    required this.detail,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String availability;
  final Color availabilityColor;
  final Color availabilityBg;
  final String detail;
}

const _fallbackMethods = <_PaymentMethodViewModel>[
  _PaymentMethodViewModel(
    title: 'Saldo MepuPoin',
    subtitle: 'Dipakai langsung dari saldo akun pelanggan saat checkout.',
    icon: Icons.account_balance_wallet_outlined,
    iconColor: Color(0xFF7C2D12),
    iconBg: Color(0xFFFED7AA),
    availability: 'Aktif',
    availabilityColor: Color(0xFF166534),
    availabilityBg: Color(0xFFDCFCE7),
    detail: 'Tersimpan di akun pelanggan',
  ),
  _PaymentMethodViewModel(
    title: 'Transfer Virtual Account',
    subtitle: 'Nomor VA unik dibuat saat checkout dan berlaku terbatas.',
    icon: Icons.account_balance_rounded,
    iconColor: Color(0xFF1D4ED8),
    iconBg: Color(0xFFDBEAFE),
    availability: 'Aktif',
    availabilityColor: Color(0xFF166534),
    availabilityBg: Color(0xFFDCFCE7),
    detail: 'BRI, BNI, BCA, Mandiri',
  ),
  _PaymentMethodViewModel(
    title: 'QRIS',
    subtitle: 'Bayar dari mobile banking atau e-wallet yang mendukung QRIS.',
    icon: Icons.qr_code_2_rounded,
    iconColor: Color(0xFF0F766E),
    iconBg: Color(0xFFCCFBF1),
    availability: 'Aktif',
    availabilityColor: Color(0xFF166534),
    availabilityBg: Color(0xFFDCFCE7),
    detail: 'Semua aplikasi QRIS',
  ),
  _PaymentMethodViewModel(
    title: 'Bayar di Tempat',
    subtitle: 'Tersedia terbatas untuk area pengantaran dan pesanan tertentu.',
    icon: Icons.local_shipping_outlined,
    iconColor: Color(0xFF92400E),
    iconBg: Color(0xFFFEF3C7),
    availability: 'Terbatas',
    availabilityColor: Color(0xFF92400E),
    availabilityBg: Color(0xFFFEF3C7),
    detail: 'Bergantung cabang dan wilayah',
  ),
];

String _formatRupiah(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final reversedIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reversedIndex > 1 && reversedIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'Rp $buffer';
}
