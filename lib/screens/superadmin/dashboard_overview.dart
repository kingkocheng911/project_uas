import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/top_nav.dart';
import 'superadmin_repository.dart';

class SuperAdminDashboardOverview extends StatefulWidget {
  const SuperAdminDashboardOverview({super.key});

  @override
  State<SuperAdminDashboardOverview> createState() =>
      _SuperAdminDashboardOverviewState();
}

class _SuperAdminDashboardOverviewState
    extends State<SuperAdminDashboardOverview> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SuperadminRepository _repository = SuperadminRepository();

  bool _sidebarExtended = true;
  bool _isLoading = true;
  String? _errorMessage;
  String _currentMenu = 'Dashboard';
  String _searchQuery = '';

  SuperadminDashboardSummary? _dashboardSummary;
  SuperadminKpiSummary? _kpiSummary;
  List<SuperadminBranchMonitoringRecord> _branchMonitoring =
      const <SuperadminBranchMonitoringRecord>[];
  List<SuperadminBranchPerformanceRecord> _branchPerformance =
      const <SuperadminBranchPerformanceRecord>[];
  List<SuperadminAdminMonitoringRecord> _adminMonitoring =
      const <SuperadminAdminMonitoringRecord>[];
  SuperadminAnalyticsBundle? _analytics;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAll());
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _repository.loadDashboardSummary(),
        _repository.loadKpiSummary(),
        _repository.loadBranchMonitoring(),
        _repository.loadBranchPerformance(),
        _repository.loadAdminMonitoring(),
        _repository.loadAnalytics(),
      ]);
      final summary = results[0] as SuperadminDashboardSummary;
      final kpi = results[1] as SuperadminKpiSummary;
      final branchMonitoring =
          results[2] as List<SuperadminBranchMonitoringRecord>;
      final branchPerformance =
          results[3] as List<SuperadminBranchPerformanceRecord>;
      final adminMonitoring =
          results[4] as List<SuperadminAdminMonitoringRecord>;
      final analytics = results[5] as SuperadminAnalyticsBundle;

      if (!mounted) return;
      setState(() {
        _dashboardSummary = summary;
        _kpiSummary = kpi;
        _branchMonitoring = branchMonitoring;
        _branchPerformance = branchPerformance;
        _adminMonitoring = adminMonitoring;
        _analytics = analytics;
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectMenu(String menu) {
    setState(() => _currentMenu = menu);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final useDrawer = width < 900;
    final useBottomNav = width < 720;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.secondary,
      drawer: useDrawer
          ? SidebarWidget(
              isExtended: true,
              currentMenu: _currentMenu,
              onMenuSelected: (menu) {
                Navigator.of(context).pop();
                _selectMenu(menu);
              },
              onToggle: () {},
            )
          : null,
      body: Row(
        children: [
          if (!useDrawer)
            SidebarWidget(
              isExtended: _sidebarExtended,
              currentMenu: _currentMenu,
              onMenuSelected: _selectMenu,
              onToggle: () =>
                  setState(() => _sidebarExtended = !_sidebarExtended),
            ),
          Expanded(
            child: Column(
              children: [
                TopNav(
                  pageTitle: _currentMenu,
                  onOpenNotifications: () =>
                      _showSnack('Notifikasi Super Admin dibuka.'),
                  onOpenProfile: () => _showSnack('Profil Super Admin dibuka.'),
                  onSearch: (value) =>
                      setState(() => _searchQuery = value.trim()),
                  onOpenMenu: useDrawer
                      ? () => _scaffoldKey.currentState?.openDrawer()
                      : null,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAll,
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: useBottomNav ? _buildMobileNavigation() : null,
    );
  }

  Widget _buildMobileNavigation() {
    const menus = <String>[
      'Dashboard',
      'Branch Monitoring',
      'Admin Monitoring',
      'Analytics',
    ];
    final currentIndex = math.max(menus.indexOf(_currentMenu), 0);

    return NavigationBar(
      selectedIndex: currentIndex,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withValues(alpha: 0.1),
      onDestinationSelected: (index) =>
          setState(() => _currentMenu = menus[index]),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront_rounded),
          label: 'Cabang',
        ),
        NavigationDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings_rounded),
          label: 'Admin',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights_rounded),
          label: 'Analytics',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading && _dashboardSummary == null) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorMessage != null && _dashboardSummary == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 140),
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadAll,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Coba Lagi'),
          ),
        ],
      );
    }

    final padding = MediaQuery.of(context).size.width < 720
        ? const EdgeInsets.fromLTRB(16, 12, 16, 96)
        : const EdgeInsets.fromLTRB(24, 20, 24, 24);

    return ListView(
      padding: padding,
      children: [
        if (_errorMessage != null) ...[
          _InlineWarning(message: _errorMessage!, onRetry: _loadAll),
          const SizedBox(height: 16),
        ],
        ...switch (_currentMenu) {
          'Dashboard' => _buildDashboardPage(),
          'Branch Monitoring' => _buildBranchMonitoringPage(),
          'Branch Performance' => _buildBranchPerformancePage(),
          'Admin Monitoring' => _buildAdminMonitoringPage(),
          'Branch Management' => _buildBranchManagementPage(),
          'Analytics' => _buildAnalyticsPage(),
          _ => _buildDashboardPage(),
        },
      ],
    );
  }

  List<Widget> _buildDashboardPage() {
    final summary = _dashboardSummary!;
    final kpi = _kpiSummary!;
    final criticalBranches = _branchMonitoring
        .where((item) => item.healthStatus != 'Normal')
        .take(5)
        .toList(growable: false);
    final topBranches = List<SuperadminBranchPerformanceRecord>.from(
      _branchPerformance,
    )..sort((a, b) => b.revenueMonth.compareTo(a.revenueMonth));

    return [
      _PageHeader(
        title: 'Monitoring Global KDMP',
        subtitle:
            'Pantau seluruh cabang, transaksi, stok, dan KPI nasional dari backend Supabase.',
      ),
      const SizedBox(height: 20),
      _ResponsiveGrid(
        minWidth: 220,
        children: [
          StatCard(
            title: 'Total Cabang',
            value: '${summary.totalBranches}',
            icon: Icons.storefront_rounded,
            trend: '${summary.activeBranches} cabang aktif',
            accentColor: AppColors.primary,
          ),
          StatCard(
            title: 'Customer',
            value: '${summary.totalCustomers}',
            icon: Icons.people_alt_rounded,
            trend: '${summary.totalTransactionsToday} transaksi hari ini',
            accentColor: AppColors.accent,
          ),
          StatCard(
            title: 'Admin Cabang',
            value: '${summary.totalBranchAdmins}',
            icon: Icons.admin_panel_settings_rounded,
            trend:
                '${_adminMonitoring.where((item) => item.isActive).length} aktif',
            accentColor: const Color(0xFF7C3AED),
          ),
          StatCard(
            title: 'Omzet Hari Ini',
            value: _formatCurrency(summary.totalRevenueToday),
            icon: Icons.payments_rounded,
            trend: _formatCurrency(summary.totalRevenueMonth),
            accentColor: const Color(0xFF16A34A),
          ),
          StatCard(
            title: 'Produk Low Stock',
            value: '${summary.lowStockProducts}',
            icon: Icons.warning_amber_rounded,
            trend: '${summary.outOfStockProducts} produk habis',
            accentColor: const Color(0xFFF59E0B),
          ),
        ],
      ),
      const SizedBox(height: 20),
      _ResponsiveGrid(
        minWidth: 220,
        children: [
          _KpiCard(
            title: 'Average Order Value',
            value: _formatCurrency(kpi.averageOrderValue.round()),
            subtitle: 'Rata-rata nilai order bulan ini',
            tone: AppColors.primary,
            icon: Icons.shopping_bag_rounded,
          ),
          _KpiCard(
            title: 'Conversion Order',
            value: '${kpi.conversionOrder.toStringAsFixed(2)}%',
            subtitle: 'Order selesai dibanding total order bulan ini',
            tone: AppColors.accent,
            icon: Icons.analytics_rounded,
          ),
          _KpiCard(
            title: 'Repeat Customer',
            value: '${kpi.repeatCustomer}',
            subtitle: 'Customer dengan minimal dua transaksi berbayar',
            tone: const Color(0xFF7C3AED),
            icon: Icons.repeat_rounded,
          ),
          _KpiCard(
            title: 'Reward Bulan Ini',
            value: '${kpi.totalRewardEarned} / ${kpi.totalRewardRedeemed}',
            subtitle: 'Earned vs redeemed Mepu Point',
            tone: const Color(0xFF16A34A),
            icon: Icons.stars_rounded,
          ),
        ],
      ),
      const SizedBox(height: 20),
      _ResponsiveTwoColumn(
        left: _SectionCard(
          title: 'Cabang Perlu Perhatian',
          subtitle:
              'Cabang dengan stok atau antrian pesanan yang perlu dipantau.',
          child: criticalBranches.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('Seluruh cabang dalam status normal.'),
                )
              : Column(
                  children: criticalBranches
                      .map(
                        (branch) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BranchAlertTile(branch: branch),
                        ),
                      )
                      .toList(),
                ),
        ),
        right: _SectionCard(
          title: 'Top Omzet Bulan Ini',
          subtitle: 'Cabang dengan omzet bulanan tertinggi.',
          child: Column(
            children: topBranches
                .take(5)
                .map(
                  (branch) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RankingTile(
                      title: branch.branchName,
                      value: _formatCurrency(branch.revenueMonth),
                      subtitle:
                          '${branch.transactionsMonth} transaksi | Growth ${branch.growthPercent.toStringAsFixed(1)}%',
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildBranchMonitoringPage() {
    final branches = _filteredBranches();
    return [
      _PageHeader(
        title: 'Branch Monitoring',
        subtitle:
            'Lihat kondisi seluruh cabang, indikator kritis, pending order, dan stok secara real time dari backend.',
      ),
      const SizedBox(height: 20),
      if (branches.isEmpty)
        const _EmptyState(
          message: 'Tidak ada cabang yang cocok dengan pencarian.',
        )
      else
        ...branches.map(
          (branch) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _BranchMonitoringCard(branch: branch),
          ),
        ),
    ];
  }

  List<Widget> _buildBranchPerformancePage() {
    final performance = _filteredPerformance();
    final topRevenue = List<SuperadminBranchPerformanceRecord>.from(performance)
      ..sort((a, b) => b.revenueMonth.compareTo(a.revenueMonth));
    final topTransactions = List<SuperadminBranchPerformanceRecord>.from(
      performance,
    )..sort((a, b) => b.transactionsMonth.compareTo(a.transactionsMonth));
    final topGrowth = List<SuperadminBranchPerformanceRecord>.from(performance)
      ..sort((a, b) => b.growthPercent.compareTo(a.growthPercent));
    final lowestPerformance = List<SuperadminBranchPerformanceRecord>.from(
      performance,
    )..sort((a, b) => a.performanceScore.compareTo(b.performanceScore));

    return [
      _PageHeader(
        title: 'Branch Performance',
        subtitle:
            'Monitoring cabang terbaik, transaksi tertinggi, pertumbuhan terbaik, dan cabang dengan performa terendah.',
      ),
      const SizedBox(height: 20),
      _ResponsiveTwoColumn(
        left: _SectionCard(
          title: 'Top 10 Omzet Tertinggi',
          subtitle: 'Berdasarkan omzet bulan berjalan.',
          child: _buildPerformanceList(
            topRevenue.take(10),
            (item) => _formatCurrency(item.revenueMonth),
            (item) =>
                '${item.transactionsMonth} transaksi | Score ${item.performanceScore.toStringAsFixed(1)}',
          ),
        ),
        right: _SectionCard(
          title: 'Top 10 Transaksi Terbanyak',
          subtitle: 'Berdasarkan jumlah transaksi bulan berjalan.',
          child: _buildPerformanceList(
            topTransactions.take(10),
            (item) => '${item.transactionsMonth} trx',
            (item) =>
                'Omzet ${_formatCurrency(item.revenueMonth)} | Growth ${item.growthPercent.toStringAsFixed(1)}%',
          ),
        ),
      ),
      const SizedBox(height: 20),
      _ResponsiveTwoColumn(
        left: _SectionCard(
          title: 'Cabang Pertumbuhan Terbaik',
          subtitle: 'Dibanding bulan sebelumnya.',
          child: _buildPerformanceList(
            topGrowth.take(10),
            (item) => '${item.growthPercent.toStringAsFixed(1)}%',
            (item) =>
                'Omzet ${_formatCurrency(item.revenueMonth)} | Score ${item.performanceScore.toStringAsFixed(1)}',
          ),
        ),
        right: _SectionCard(
          title: 'Cabang Performa Terendah',
          subtitle: 'Prioritas monitoring dan evaluasi.',
          child: _buildPerformanceList(
            lowestPerformance.take(10),
            (item) => item.performanceScore.toStringAsFixed(1),
            (item) =>
                'Omzet ${_formatCurrency(item.revenueMonth)} | Growth ${item.growthPercent.toStringAsFixed(1)}%',
          ),
        ),
      ),
    ];
  }

  Widget _buildPerformanceList(
    Iterable<SuperadminBranchPerformanceRecord> items,
    String Function(SuperadminBranchPerformanceRecord item) valueBuilder,
    String Function(SuperadminBranchPerformanceRecord item) subtitleBuilder,
  ) {
    final list = items.toList(growable: false);
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('Belum ada data performa cabang.'),
      );
    }

    return Column(
      children: list
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RankingTile(
                title: item.branchName,
                value: valueBuilder(item),
                subtitle: subtitleBuilder(item),
              ),
            ),
          )
          .toList(),
    );
  }

  List<Widget> _buildAdminMonitoringPage() {
    final admins = _filteredAdmins();
    return [
      _PageHeader(
        title: 'Admin Monitoring',
        subtitle:
            'Pantau admin cabang, status akun, cabang penugasan, login terakhir, dan transaksi yang dikelola.',
      ),
      const SizedBox(height: 20),
      if (admins.isEmpty)
        const _EmptyState(
          message: 'Tidak ada admin yang cocok dengan pencarian.',
        )
      else
        ...admins.map(
          (admin) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _AdminMonitoringCard(admin: admin),
          ),
        ),
    ];
  }

  List<Widget> _buildBranchManagementPage() {
    final branches = _filteredBranches();
    return [
      _PageHeader(
        title: 'Branch Management',
        subtitle:
            'Aktifkan, nonaktifkan, dan ubah data cabang melalui backend Supabase.',
        actionLabel: 'Tambah Cabang',
        onAction: () => _openBranchEditor(),
      ),
      const SizedBox(height: 20),
      if (branches.isEmpty)
        const _EmptyState(
          message: 'Tidak ada cabang yang cocok dengan pencarian.',
        )
      else
        ...branches.map(
          (branch) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _BranchManagementCard(
              branch: branch,
              onEdit: () => _openBranchEditor(branch),
              onToggleActive: () => _toggleBranch(branch),
            ),
          ),
        ),
    ];
  }

  List<Widget> _buildAnalyticsPage() {
    final analytics = _analytics;
    if (analytics == null) {
      return const [_EmptyState(message: 'Data analytics belum tersedia.')];
    }

    return [
      _PageHeader(
        title: 'Analytics',
        subtitle:
            'Visualisasi omzet bulanan, transaksi harian, distribusi kategori, metode pembayaran, dan Mepu Point.',
      ),
      const SizedBox(height: 20),
      _ResponsiveTwoColumn(
        left: _SectionCard(
          title: 'Omzet Bulanan',
          subtitle: '6 bulan terakhir',
          child: _BarChartPanel(
            data: analytics.monthlyRevenue,
            prefixCurrency: true,
          ),
        ),
        right: _SectionCard(
          title: 'Transaksi Harian',
          subtitle: '7 hari terakhir',
          child: _BarChartPanel(data: analytics.dailyTransactions),
        ),
      ),
      const SizedBox(height: 20),
      _ResponsiveTwoColumn(
        left: _SectionCard(
          title: 'Distribusi Kategori',
          subtitle: 'Kategori produk terjual',
          child: _PieChartPanel(data: analytics.categoryDistribution),
        ),
        right: _SectionCard(
          title: 'Distribusi Metode Pembayaran',
          subtitle: 'Berdasarkan pesanan masuk',
          child: _PieChartPanel(data: analytics.paymentDistribution),
        ),
      ),
      const SizedBox(height: 20),
      _SectionCard(
        title: 'Distribusi Penggunaan Mepu Point',
        subtitle: 'Earned, redeemed, dan saldo saat ini',
        child: _PieChartPanel(data: analytics.rewardDistribution),
      ),
    ];
  }

  List<SuperadminBranchMonitoringRecord> _filteredBranches() {
    final query = _searchQuery.toLowerCase();
    return _branchMonitoring
        .where((branch) {
          if (query.isEmpty) return true;
          final haystack = [
            branch.branchName,
            branch.branchCode,
            branch.city,
            branch.district,
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  List<SuperadminBranchPerformanceRecord> _filteredPerformance() {
    final query = _searchQuery.toLowerCase();
    return _branchPerformance
        .where((branch) {
          if (query.isEmpty) return true;
          return branch.branchName.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  List<SuperadminAdminMonitoringRecord> _filteredAdmins() {
    final query = _searchQuery.toLowerCase();
    return _adminMonitoring
        .where((admin) {
          if (query.isEmpty) return true;
          final haystack = [
            admin.fullName,
            admin.branchName,
            admin.email,
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  Future<void> _toggleBranch(SuperadminBranchMonitoringRecord branch) async {
    try {
      await _repository.setBranchActive(
        branchId: branch.branchId,
        isActive: !branch.isActive,
      );
      if (!mounted) return;
      _showSnack(
        branch.isActive
            ? 'Cabang ${branch.branchName} dinonaktifkan.'
            : 'Cabang ${branch.branchName} diaktifkan.',
      );
      await _loadAll();
    } catch (error) {
      if (!mounted) return;
      _showSnack('Gagal mengubah status cabang: $error');
    }
  }

  Future<void> _openBranchEditor([
    SuperadminBranchMonitoringRecord? branch,
  ]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _BranchEditorSheet(branch: branch, repository: _repository),
    );
    if (result == true) {
      await _loadAll();
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatCurrency(int amount) {
    final digits = amount.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp ${amount < 0 ? '-' : ''}${buffer.toString()}';
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: onAction,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children, this.minWidth = 220});

  final List<Widget> children;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final count = math.max(1, (width / minWidth).floor() - 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count.clamp(1, 5),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        mainAxisExtent: 168,
      ),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _ResponsiveTwoColumn extends StatelessWidget {
  const _ResponsiveTwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 980;
    if (compact) {
      return Column(children: [left, const SizedBox(height: 20), right]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 20),
        Expanded(child: right),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
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
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchAlertTile extends StatelessWidget {
  const _BranchAlertTile({required this.branch});

  final SuperadminBranchMonitoringRecord branch;

  @override
  Widget build(BuildContext context) {
    final tone = _healthColor(branch.healthStatus);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: tone.withValues(alpha: 0.16),
            child: Icon(Icons.warning_amber_rounded, color: tone),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  branch.branchName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${branch.pendingOrders} pending | ${branch.lowStockProducts} low stock | ${branch.outOfStockProducts} habis',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            branch.healthStatus,
            style: TextStyle(color: tone, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _BranchMonitoringCard extends StatelessWidget {
  const _BranchMonitoringCard({required this.branch});

  final SuperadminBranchMonitoringRecord branch;

  @override
  Widget build(BuildContext context) {
    final tone = _healthColor(branch.healthStatus);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.branchName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${branch.branchCode} | ${[branch.district, branch.city].where((item) => item.trim().isNotEmpty).join(', ')}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _StatusChip(label: branch.healthStatus, tone: tone),
            ],
          ),
          const SizedBox(height: 16),
          _ResponsiveGrid(
            minWidth: 170,
            children: [
              _MetricMiniCard(
                label: 'Transaksi Hari Ini',
                value: '${branch.transactionsToday}',
                tone: AppColors.accent,
              ),
              _MetricMiniCard(
                label: 'Omzet Hari Ini',
                value: _formatMoney(branch.revenueToday),
                tone: const Color(0xFF16A34A),
              ),
              _MetricMiniCard(
                label: 'Order Pending',
                value: '${branch.pendingOrders}',
                tone: const Color(0xFFF59E0B),
              ),
              _MetricMiniCard(
                label: 'Total Stok',
                value: '${branch.totalStock}',
                tone: AppColors.primary,
              ),
              _MetricMiniCard(
                label: 'Produk Habis',
                value: '${branch.outOfStockProducts}',
                tone: const Color(0xFFDC2626),
              ),
              _MetricMiniCard(
                label: 'Low Stock',
                value: '${branch.lowStockProducts}',
                tone: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminMonitoringCard extends StatelessWidget {
  const _AdminMonitoringCard({required this.admin});

  final SuperadminAdminMonitoringRecord admin;

  @override
  Widget build(BuildContext context) {
    final tone = admin.isActive
        ? const Color(0xFF16A34A)
        : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin.fullName.isEmpty ? 'Admin Cabang' : admin.fullName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${admin.branchName} (${admin.branchCode})',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                label: admin.isActive ? 'Aktif' : 'Nonaktif',
                tone: tone,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: admin.adminRole),
              _InfoChip(label: admin.isPrimary ? 'Primary' : 'Secondary'),
              _InfoChip(
                label: admin.lastLoginAt == null
                    ? 'Belum login'
                    : 'Login ${_formatDateTime(admin.lastLoginAt!)}',
              ),
              _InfoChip(label: '${admin.managedTransactions} transaksi'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            admin.email.isEmpty ? '-' : admin.email,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            admin.phone.isEmpty ? 'Nomor belum tersedia' : admin.phone,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _BranchManagementCard extends StatelessWidget {
  const _BranchManagementCard({
    required this.branch,
    required this.onEdit,
    required this.onToggleActive,
  });

  final SuperadminBranchMonitoringRecord branch;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final tone = branch.isActive
        ? const Color(0xFF16A34A)
        : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.branchName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${branch.branchCode} | ${branch.address}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                label: branch.isActive ? 'Aktif' : 'Nonaktif',
                tone: tone,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: branch.phone.isEmpty ? 'No phone' : branch.phone,
              ),
              _InfoChip(
                label: branch.email.isEmpty ? 'No email' : branch.email,
              ),
              _InfoChip(label: branch.healthStatus),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Ubah'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onToggleActive,
                style: FilledButton.styleFrom(
                  backgroundColor: branch.isActive
                      ? const Color(0xFF6B7280)
                      : AppColors.primary,
                ),
                icon: Icon(
                  branch.isActive
                      ? Icons.pause_circle_rounded
                      : Icons.play_circle_rounded,
                ),
                label: Text(branch.isActive ? 'Nonaktifkan' : 'Aktifkan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricMiniCard extends StatelessWidget {
  const _MetricMiniCard({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(color: tone, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _BarChartPanel extends StatelessWidget {
  const _BarChartPanel({required this.data, this.prefixCurrency = false});

  final List<SuperadminChartDatum> data;
  final bool prefixCurrency;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('Belum ada data chart.');
    }

    final maxY = data.fold<double>(
      0,
      (max, item) => math.max(max, item.amount),
    );

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 10 : maxY * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[index].label,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: data.asMap().entries.map((entry) {
            final item = entry.value;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: item.amount,
                  color: AppColors.primary,
                  width: 22,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            );
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = data[group.x.toInt()];
                final value = prefixCurrency
                    ? _formatMoney(item.amount.round())
                    : item.amount.round().toString();
                return BarTooltipItem(
                  '${item.label}\n$value',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PieChartPanel extends StatelessWidget {
  const _PieChartPanel({required this.data});

  final List<SuperadminChartDatum> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Text('Belum ada data chart.');
    }

    final colors = <Color>[
      AppColors.primary,
      AppColors.accent,
      const Color(0xFF7C3AED),
      const Color(0xFF16A34A),
      const Color(0xFFF59E0B),
      const Color(0xFF0EA5E9),
    ];

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 44,
              sectionsSpace: 2,
              sections: data.asMap().entries.map((entry) {
                final item = entry.value;
                return PieChartSectionData(
                  color: colors[entry.key % colors.length],
                  value: item.amount <= 0 ? 0.1 : item.amount,
                  title: '${item.amount.round()}',
                  radius: 58,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...data.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[entry.key % colors.length],
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.value.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${entry.value.amount.round()}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          const SizedBox(width: 12),
          TextButton(onPressed: onRetry, child: const Text('Muat Ulang')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Center(child: Text(message)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: tone, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _BranchEditorSheet extends StatefulWidget {
  const _BranchEditorSheet({required this.repository, this.branch});

  final SuperadminRepository repository;
  final SuperadminBranchMonitoringRecord? branch;

  @override
  State<_BranchEditorSheet> createState() => _BranchEditorSheetState();
}

class _BranchEditorSheetState extends State<_BranchEditorSheet> {
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _provinceController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _postalCodeController;
  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final branch = widget.branch;
    _codeController = TextEditingController(text: branch?.branchCode ?? '');
    _nameController = TextEditingController(text: branch?.branchName ?? '');
    _phoneController = TextEditingController(text: branch?.phone ?? '');
    _emailController = TextEditingController(text: branch?.email ?? '');
    _addressController = TextEditingController(text: branch?.address ?? '');
    _provinceController = TextEditingController(text: branch?.province ?? '');
    _cityController = TextEditingController(text: branch?.city ?? '');
    _districtController = TextEditingController(text: branch?.district ?? '');
    _postalCodeController = TextEditingController(
      text: branch?.postalCode ?? '',
    );
    _isActive = branch?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_codeController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode, nama, dan alamat cabang wajib diisi.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.repository.upsertBranch(
        branchId: widget.branch?.branchId,
        code: _codeController.text,
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        address: _addressController.text,
        province: _provinceController.text,
        city: _cityController.text,
        district: _districtController.text,
        postalCode: _postalCodeController.text,
        isActive: _isActive,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan cabang: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.branch == null ? 'Tambah Cabang' : 'Ubah Cabang',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _field(_codeController, 'Kode Cabang'),
            const SizedBox(height: 12),
            _field(_nameController, 'Nama Cabang'),
            const SizedBox(height: 12),
            _field(_phoneController, 'Phone'),
            const SizedBox(height: 12),
            _field(_emailController, 'Email'),
            const SizedBox(height: 12),
            _field(_addressController, 'Alamat', maxLines: 3),
            const SizedBox(height: 12),
            _field(_provinceController, 'Provinsi'),
            const SizedBox(height: 12),
            _field(_cityController, 'Kota'),
            const SizedBox(height: 12),
            _field(_districtController, 'Kecamatan'),
            const SizedBox(height: 12),
            _field(_postalCodeController, 'Kode Pos'),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              title: const Text('Cabang aktif'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(_isSaving ? 'Menyimpan...' : 'Simpan Cabang'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

Color _healthColor(String status) {
  switch (status) {
    case 'Kritis':
      return const Color(0xFFDC2626);
    case 'Perlu Perhatian':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFF16A34A);
  }
}

String _formatMoney(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'Rp ${amount < 0 ? '-' : ''}${buffer.toString()}';
}

String _formatDateTime(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year;
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
