import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../branch_admin_repository.dart';
import '../orders/admin_order_models.dart';
import '../orders/order_list_screen.dart';
import '../products/category_screen.dart';
import '../products/product_list_screen.dart';
import '../products/stock_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final BranchAdminRepository _repository = BranchAdminRepository();
  int _currentIndex = 0;
  BranchAdminAssignment? _assignment;

  static const _background = Color(0xFFF7F9FB);
  static const _primary = Color(0xFFD9001B);
  static const _muted = Color(0xFF6D5A58);

  @override
  void initState() {
    super.initState();
    _loadAssignment();
  }

  Future<void> _loadAssignment() async {
    try {
      final assignment = await _repository.loadAssignment();
      if (!mounted) return;
      setState(() => _assignment = assignment);
    } catch (_) {
      // Dashboard body will show the actual error from data loaders.
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Keluar dari dashboard?'),
          content: const Text(
            'Sesi admin akan diakhiri dan Anda akan kembali ke halaman login.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout gagal. Coba lagi beberapa saat.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDashboardTab = _currentIndex == 0;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        toolbarHeight: 78,
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDashboardTab ? 'Dashboard Cabang' : _tabTitle(_currentIndex),
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.store_mall_directory_outlined,
                  size: 14,
                  color: _muted,
                ),
                const SizedBox(width: 4),
                Text(
                  _assignment?.name ?? 'Cabang KDMP',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD9001B), Color(0xFF8B0011)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              _assignment?.initials ?? 'AD',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opsi admin',
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F1F0),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.more_vert_rounded, color: _muted),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFE9E6),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Produk',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2_rounded),
            label: 'Pelanggan',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _AdminDashboardHome(
          repository: _repository,
          onOpenOrders: () => setState(() => _currentIndex = 1),
          onOpenProducts: () => setState(() => _currentIndex = 2),
          onOpenStock: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const StockManagementScreen(),
              ),
            );
          },
          onOpenCategories: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CategoryScreen(),
              ),
            );
          },
        );
      case 1:
        return const OrderListScreen();
      case 2:
        return const ProductListScreen();
      case 3:
        return _BranchCustomerScreen(repository: _repository);
      default:
        return const SizedBox.shrink();
    }
  }

  String _tabTitle(int index) {
    switch (index) {
      case 1:
        return 'Pesanan Cabang';
      case 2:
        return 'Produk Cabang';
      case 3:
        return 'Pelanggan Cabang';
      default:
        return 'Dashboard Cabang';
    }
  }
}

class _AdminDashboardHome extends StatefulWidget {
  const _AdminDashboardHome({
    required this.repository,
    required this.onOpenOrders,
    required this.onOpenProducts,
    required this.onOpenStock,
    required this.onOpenCategories,
  });

  final BranchAdminRepository repository;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenProducts;
  final VoidCallback onOpenStock;
  final VoidCallback onOpenCategories;

  @override
  State<_AdminDashboardHome> createState() => _AdminDashboardHomeState();
}

class _AdminDashboardHomeState extends State<_AdminDashboardHome> {
  bool _isLoading = true;
  String? _errorMessage;
  BranchAdminDashboardData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await widget.repository.loadDashboardData();
      if (!mounted) return;
      setState(() => _data = data);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 42, color: Color(0xFFD9001B)),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD9001B)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _HeroBranchCard(data: data),
          const SizedBox(height: 18),
          Text(
            'Ringkasan Hari Ini',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _MetricCard(
                title: 'Order Hari Ini',
                value: '${data.todayOrderCount}',
                subtitle: 'Masuk ke cabang hari ini',
                tone: const Color(0xFFD9001B),
                icon: Icons.receipt_long_rounded,
              ),
              _MetricCard(
                title: 'Diproses',
                value: '${data.processingOrders}',
                subtitle: 'Confirmed dan processing',
                tone: const Color(0xFF1565C0),
                icon: Icons.inventory_2_rounded,
              ),
              _MetricCard(
                title: 'Low Stock',
                value: '${data.lowStockProducts}',
                subtitle: 'Perlu restock cepat',
                tone: const Color(0xFFC47A00),
                icon: Icons.warning_amber_rounded,
              ),
              _MetricCard(
                title: 'Selesai',
                value: '${data.completedOrders}',
                subtitle: 'Order completed',
                tone: const Color(0xFF1A7F42),
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Aksi Cepat',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.04,
            children: [
              _QuickActionCard(
                title: 'Pesanan Masuk',
                subtitle: 'Lihat dan proses order pelanggan.',
                icon: Icons.receipt_long_rounded,
                tone: const Color(0xFFD9001B),
                onTap: widget.onOpenOrders,
              ),
              _QuickActionCard(
                title: 'Produk Cabang',
                subtitle: 'Tambah, edit, dan sembunyikan produk.',
                icon: Icons.storefront_rounded,
                tone: const Color(0xFF1565C0),
                onTap: widget.onOpenProducts,
              ),
              _QuickActionCard(
                title: 'Stok Cabang',
                subtitle: 'Restock dan catat mutasi stok manual.',
                icon: Icons.inventory_rounded,
                tone: const Color(0xFF1A7F42),
                onTap: widget.onOpenStock,
              ),
              _QuickActionCard(
                title: 'Kategori Aktif',
                subtitle: 'Lihat kategori pusat yang dipakai cabang.',
                icon: Icons.category_rounded,
                tone: const Color(0xFF7B1FA2),
                onTap: widget.onOpenCategories,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE8BCB8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan Terbaru',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                if (data.recentOrders.isEmpty)
                  const Text('Belum ada pesanan masuk untuk cabang ini.')
                else
                  ...data.recentOrders.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecentOrderTile(order: order),
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

class _HeroBranchCard extends StatelessWidget {
  const _HeroBranchCard({required this.data});

  final BranchAdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFD9001B), Color(0xFF8B0011)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Admin Cabang Aktif',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            data.assignment.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            data.assignment.shortLocation,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Omzet Selesai Hari Ini',
                  value: formatCurrency(data.todayRevenue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStat(
                  label: 'Produk Aktif',
                  value: '${data.totalProducts}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.tone,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8BCB8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: tone.withValues(alpha: 0.12),
            child: Icon(icon, color: tone),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF6D5A58), fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE8BCB8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: tone.withValues(alpha: 0.12),
              child: Icon(icon, color: tone),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF6D5A58), height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final tone = orderStatusColor(order.orderStatus);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${order.orderNo} • ${order.typeLabel}',
                  style: const TextStyle(color: Color(0xFF6D5A58), fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(order.grandTotal),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                order.statusLabel,
                style: TextStyle(
                  color: tone,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BranchCustomerScreen extends StatefulWidget {
  const _BranchCustomerScreen({required this.repository});

  final BranchAdminRepository repository;

  @override
  State<_BranchCustomerScreen> createState() => _BranchCustomerScreenState();
}

class _BranchCustomerScreenState extends State<_BranchCustomerScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<BranchCustomerSummary> _customers = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customers = await widget.repository.loadCustomers();
      if (!mounted) return;
      setState(() => _customers = customers);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Pelanggan Cabang',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Daftar ini diambil dari pesanan pelanggan yang masuk ke cabang aktif.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6D5A58),
                ),
          ),
          const SizedBox(height: 16),
          if (_customers.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8BCB8)),
              ),
              child: const Text(
                'Belum ada pelanggan yang bertransaksi di cabang ini.',
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._customers.map(
              (customer) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE8BCB8)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFFFE9E6),
                        child: Text(
                          _initials(customer.name),
                          style: const TextStyle(
                            color: Color(0xFFD9001B),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              customer.phone.isEmpty ? 'Nomor belum tersedia' : customer.phone,
                              style: const TextStyle(color: Color(0xFF6D5A58)),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${customer.totalOrders} order • ${customer.completedOrders} selesai',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCurrency(customer.totalSpent),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formatShortDate(customer.lastOrderAt),
                            style: const TextStyle(
                              color: Color(0xFF6D5A58),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'PL';
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}
