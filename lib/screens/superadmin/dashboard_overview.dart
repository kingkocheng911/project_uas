import 'dart:async';

// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/colors.dart';
import 'superadmin_repository.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/top_nav.dart';

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
  bool isSidebarExtended = true;
  bool showSkeleton = false;
  bool _isBranchLoading = false;
  bool _isAdminLoading = false;
  bool _isOverviewLoading = false;
  bool _isPromotionLoading = false;
  bool _isUserLoading = false;
  bool _isReportsLoading = false;
  String currentMenu = 'Dashboard';
  String searchQuery = '';
  String selectedRegion = 'Semua Region';
  String selectedStatus = 'Semua Status';

  List<_BranchData> branches = const <_BranchData>[];
  List<_AdminData> admins = const <_AdminData>[];
  List<SuperadminProfileCandidate> _adminCandidates = const [];
  List<_UserData> users = const <_UserData>[];
  List<_PromotionData> banners = List<_PromotionData>.of(_promotionSeed);
  SuperadminDashboardOverviewData? _overview;
  SuperadminReportsSummary? _reportsSummary;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBranches());
    unawaited(_loadAdmins());
    unawaited(_loadOverview());
    unawaited(_loadPromotions());
    unawaited(_loadUsers());
    unawaited(_loadReports());
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final useDrawer = width < 900;
    final useBottomNav = width < 720;
    final compactFab = width < 720;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.secondary,
      drawer: useDrawer ? _buildDrawerSidebar() : null,
      body: Row(
        children: [
          if (!useDrawer)
            SidebarWidget(
              isExtended: isSidebarExtended,
              currentMenu: currentMenu,
              onMenuSelected: _selectMenu,
              onToggle: () =>
                  setState(() => isSidebarExtended = !isSidebarExtended),
            ),
          Expanded(
            child: Column(
              children: [
                TopNav(
                  pageTitle: currentMenu,
                  onOpenNotifications: _openNotifications,
                  onOpenProfile: _openProfileMenu,
                  onSearch: (value) => setState(() => searchQuery = value),
                  onOpenMenu: useDrawer
                      ? () => _scaffoldKey.currentState?.openDrawer()
                      : null,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _simulateRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        width < 720 ? 16 : 24,
                        width < 720 ? 12 : 24,
                        width < 720 ? 16 : 24,
                        width < 720 ? 96 : 24,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        child: showSkeleton
                            ? const _DashboardSkeleton()
                            : _buildCurrentPage(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: useBottomNav ? _buildMobileNavigation() : null,
      floatingActionButtonLocation: compactFab
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: compactFab
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: _openQuickCreate,
              child: const Icon(Icons.add_rounded),
            )
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: _openQuickCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Quick Create'),
            ),
    );
  }

  Widget _buildMobileNavigation() {
    const mobileMenus = <String>[
      'Dashboard',
      'Branch Management',
      'Admin Management',
      'User Management',
    ];
    final currentIndex = mobileMenus.indexOf(currentMenu);

    return NavigationBar(
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primary.withValues(alpha: 0.10),
      selectedIndex: currentIndex < 0 ? 0 : currentIndex,
      onDestinationSelected: (index) {
        setState(() => currentMenu = mobileMenus[index]);
      },
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
          icon: Icon(Icons.people_alt_outlined),
          selectedIcon: Icon(Icons.people_alt_rounded),
          label: 'User',
        ),
      ],
    );
  }

  Widget _buildDrawerSidebar() {
    return SidebarWidget(
      isExtended: true,
      currentMenu: currentMenu,
      onMenuSelected: (menu) {
        Navigator.of(context).pop();
        _selectMenu(menu);
      },
      onToggle: () {},
    );
  }

  Widget _buildCurrentPage() {
    switch (currentMenu) {
      case 'Dashboard':
        return _buildDashboard();
      case 'Branch Management':
        return _buildBranchManagement();
      case 'Admin Management':
        return _buildAdminManagement();
      case 'User Management':
        return _buildUserManagement();
      case 'Loyalty Points Management':
        return _buildLoyaltyManagement();
      case 'Promotions & Banners':
        return _buildPromotions();
      case 'Reports':
        return _buildReports();
      case 'System Settings':
        return _buildSystemSettings();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final overview = _overview;
    final rankedBranches = overview?.rankedBranches ?? const <SuperadminRankedBranch>[];
    final branchStatusItems = branches.take(4).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'Halo, Superadmin Office',
          subtitle:
              'Pantau performa nasional Mepu Point dari seluruh cabang KDMP.',
          actionLabel: 'Export Ringkasan',
          onAction: () => _showSnack('Ringkasan dashboard diexport.'),
        ),
        const SizedBox(height: 22),
        if (_isOverviewLoading && overview == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _ResponsiveStatGrid(
            children: [
              StatCard(
              title: 'Total Branches',
              value: '${overview?.totalBranches ?? branches.length}',
              icon: Icons.storefront_rounded,
              trend: '${overview?.activeBranches ?? 0} cabang aktif',
              accentColor: AppColors.primary,
              ),
              StatCard(
              title: 'Total Customers',
              value: '${overview?.totalCustomers ?? 0}',
              icon: Icons.people_alt_rounded,
              trend: '${overview?.totalOrders ?? 0} total pesanan',
              accentColor: AppColors.accent,
              ),
              StatCard(
              title: 'Total Admins',
              value: '${overview?.totalAdmins ?? admins.length}',
              icon: Icons.admin_panel_settings_rounded,
              trend: '${admins.where((admin) => admin.active).length} aktif',
              accentColor: Color(0xFF7C3AED),
              ),
              StatCard(
              title: 'Active Branches',
              value: '${overview?.activeBranches ?? 0}',
              icon: Icons.verified_rounded,
              trend: _formatCurrency(overview?.paidRevenue ?? 0),
              accentColor: Color(0xFF16A34A),
              ),
              StatCard(
              title: 'Admin Coverage',
              value: '${overview?.avgPerformance ?? 0}%',
              icon: Icons.assignment_ind_rounded,
              trend: 'Skor performa rata-rata',
              accentColor: Color(0xFFF59E0B),
              ),
            ],
          ),
        const SizedBox(height: 24),
        _ResponsiveTwoColumn(
          leftFlex: 2,
          left: _PanelCard(
            title: 'Branch Performance Chart',
            subtitle: 'Perbandingan omzet cabang aktif',
            child: _BarChartMock(
              points: overview?.revenueSeries ?? const [],
            ),
          ),
          right: _PanelCard(
            title: 'Top Branches Ranking',
            subtitle: 'Cabang dengan indeks operasional tertinggi',
            child: Column(
              children: rankedBranches.isEmpty
                  ? const [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Belum ada data performa cabang.'),
                      ),
                    ]
                  : rankedBranches
                  .take(5)
                  .map(
                    (branch) => _RankingTile(
                      title: branch.branch.name,
                      subtitle: [
                        branch.branch.district.trim(),
                        branch.branch.city.trim(),
                      ].where((item) => item.isNotEmpty).join(', ').ifEmpty('-'),
                      value: _formatCurrency(branch.revenue),
                      score: branch.score,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _ResponsiveTwoColumn(
          left: _PanelCard(
            title: 'Branch Status',
            subtitle: 'Ringkasan status cabang nasional',
            child: Column(
              children: branchStatusItems
                  .take(4)
                  .map(
                    (branch) => _BranchStatusTile(
                      branch: branch,
                      onTap: () => _openBranchDetail(branch),
                    ),
                  )
                  .toList(),
            ),
          ),
          right: _PanelCard(
            title: 'User Growth Graph',
            subtitle: 'Aktivitas omzet beberapa hari terakhir',
            child: _LineChartMock(
              points: overview?.growthSeries ?? const [],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBranchManagement() {
    final regionOptions = <String>[
      'Semua Region',
      ...{
        for (final branch in branches)
          if (branch.region.isNotEmpty) branch.region,
      },
    ];
    final statusOptions = <String>[
      'Semua Status',
      ...{
        for (final branch in branches) branch.status,
      },
    ];
    final rows = branches.where((branch) {
      final matchQuery =
          searchQuery.isEmpty ||
          branch.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          branch.region.toLowerCase().contains(searchQuery.toLowerCase()) ||
          branch.code.toLowerCase().contains(searchQuery.toLowerCase());
      final matchRegion =
          selectedRegion == 'Semua Region' || branch.region == selectedRegion;
      final matchStatus =
          selectedStatus == 'Semua Status' || branch.status == selectedStatus;
      return matchQuery && matchRegion && matchStatus;
    }).toList();

    return Column(
      children: [
        _ManagementToolbar(
          title: 'Branch Management',
          subtitle: 'Kelola data cabang, performa, dan status operasional.',
          primaryAction: 'Add Branch',
          onPrimaryAction: () => _openBranchForm(),
          initialSearchValue: searchQuery,
          onSearchChanged: (value) => setState(() => searchQuery = value),
          filters: [
            _ToolbarDropdown(
              value: selectedRegion,
              values: regionOptions,
              onChanged: (value) => setState(() => selectedRegion = value),
            ),
            _ToolbarDropdown(
              value: selectedStatus,
              values: statusOptions,
              onChanged: (value) => setState(() => selectedStatus = value),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_isBranchLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          _DataTablePanel(
            columns: const [
              'Branch',
              'Region',
              'Admin',
              'Performance',
              'Status',
              'Action',
            ],
            rows: rows
                .map(
                  (branch) => [
                    _TableTitle(title: branch.name, subtitle: branch.code),
                    Text(branch.region),
                    Text(branch.admin),
                    Text('${branch.performance}%'),
                    _StatusPill(label: branch.status),
                    _TableActions(
                      onView: () => _openBranchDetail(branch),
                      onEdit: () => _openBranchForm(branch: branch),
                      onCredentials: () => _openBranchCredentials(branch),
                      onDeactivate: () => _toggleBranchStatus(branch),
                    ),
                  ],
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildAdminManagement() {
    final rows = admins.where((admin) {
      if (searchQuery.isEmpty) return true;
      final query = searchQuery.toLowerCase();
      return admin.name.toLowerCase().contains(query) ||
          admin.branch.toLowerCase().contains(query) ||
          admin.phone.toLowerCase().contains(query);
    }).toList(growable: false);

    return _buildSimpleManagementPage(
      title: 'Admin Management',
      subtitle: 'Tambah admin, assign branch, edit permission, dan deactivate.',
      primaryAction: 'Add Admin',
      onPrimaryAction: _openAdminForm,
      initialSearchValue: searchQuery,
      onSearchChanged: (value) => setState(() => searchQuery = value),
      columns: const [
        'Admin',
        'Branch',
        'Role',
        'Permission',
        'Status',
        'Action',
      ],
      rows: _isAdminLoading
          ? const []
          : rows
          .map(
            (admin) => [
              _TableTitle(
                title: admin.name,
                subtitle: [
                  admin.email.ifEmpty('-'),
                  admin.phone.ifEmpty('-'),
                ].join(' • '),
              ),
              Text(admin.branch),
              Text(admin.role),
              Text(admin.permission),
              _StatusPill(label: admin.active ? 'Active' : 'Inactive'),
              _TableActions(
                onView: () => _openAdminDetail(admin),
                onEdit: () => _openAdminForm(admin: admin),
                onDeactivate: () => _deactivateAdmin(admin),
              ),
            ],
          )
          .toList(),
      emptyState: _isAdminLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          : null,
    );
  }

  Widget _buildUserManagement() {
    final rows = users.where((user) {
      if (searchQuery.isEmpty) return true;
      final query = searchQuery.toLowerCase();
      return user.name.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query);
    }).toList(growable: false);

    return _buildSimpleManagementPage(
      title: 'User Management',
      subtitle: 'Kelola akun user mobile, status, dan segmentasi pelanggan.',
      primaryAction: 'Export Users',
      onPrimaryAction: () => _showSnack('Export user summary siap diunduh.'),
      initialSearchValue: searchQuery,
      onSearchChanged: (value) => setState(() => searchQuery = value),
      columns: const ['User', 'Phone', 'Points', 'Status', 'Action'],
      rows: _isUserLoading
          ? const []
          : rows
          .map(
            (user) => [
              _TableTitle(title: user.name, subtitle: user.subtitle),
              Text(user.phone),
              Text('${user.points} pts'),
              _StatusPill(label: user.status),
              _TableActions(
                onView: () => _openUserDetail(user),
              ),
            ],
          )
          .toList(),
      emptyState: _isUserLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          : null,
    );
  }

  Widget _buildLoyaltyManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'Loyalty Points Management',
          subtitle: 'Konfigurasi rasio poin, expiry, dan campaign reward.',
          actionLabel: 'Save Configuration',
          onAction: () => _showSnack('Konfigurasi poin disimpan.'),
        ),
        const SizedBox(height: 18),
        _ResponsiveTwoColumn(
          left: _SettingsPanel(
            title: 'Point Configuration',
            children: [
              _SettingsTile('Rasio Poin', '1 poin per Rp 10.000 transaksi'),
              _SettingsTile('Point Expiry', '365 hari setelah diterima'),
              _SettingsTile('Redeem Minimum', 'Minimal 500 poin'),
            ],
          ),
          right: _PanelCard(
            title: 'Reward Campaigns',
            subtitle: 'Campaign aktif nasional',
            child: Column(
              children: const [
                _CampaignTile(title: 'Double Points Weekend', status: 'Active'),
                _CampaignTile(title: 'New User Reward', status: 'Active'),
                _CampaignTile(title: 'Branch Growth Bonus', status: 'Draft'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPromotions() {
    final rows = banners.where((promo) {
      if (searchQuery.isEmpty) return true;
      final query = searchQuery.toLowerCase();
      return promo.title.toLowerCase().contains(query) ||
          promo.placement.toLowerCase().contains(query) ||
          promo.status.toLowerCase().contains(query);
    }).toList(growable: false);

    return _buildSimpleManagementPage(
      title: 'Promotions & Banners',
      subtitle: 'Kelola banner, voucher, dan campaign nasional.',
      primaryAction: 'Create Promotion',
      onPrimaryAction: () => _openPromotionForm(),
      initialSearchValue: searchQuery,
      onSearchChanged: (value) => setState(() => searchQuery = value),
      columns: const [
        'Campaign',
        'Scope',
        'Period',
        'Discount',
        'Status',
        'Action',
      ],
      rows: _isPromotionLoading
          ? const []
          : rows
          .map(
            (promo) => [
              _TableTitle(title: promo.title, subtitle: promo.code),
              Text(promo.placement),
              Text(promo.period),
              Text(promo.discountLabel),
              _StatusPill(label: promo.status),
              _TableActions(
                onView: () => _openPromotionDetail(promo),
                onEdit: () => _openPromotionForm(promo),
                onDeactivate: () => _togglePromotionStatus(promo),
              ),
            ],
          )
          .toList(),
      emptyState: _isPromotionLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          : null,
    );
  }

  Widget _buildSystemSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'System Settings',
          subtitle:
              'Atur delivery, role, notifikasi, dan konfigurasi platform.',
          actionLabel: 'Save Settings',
          onAction: () => _showSnack('System settings disimpan.'),
        ),
        const SizedBox(height: 18),
        _ResponsiveTwoColumn(
          left: _SettingsPanel(
            title: 'Operational Settings',
            children: [
              _SettingsTile('Branch Verification', 'Wajib review kantor pusat'),
              _SettingsTile('Admin Approval', 'Aktif untuk admin cabang baru'),
              _SettingsTile('Notification Policy', 'Email dan in-app'),
            ],
          ),
          right: _SettingsPanel(
            title: 'Role Access',
            children: [
              _SettingsTile(
                'Superadmin',
                'Branch, admin, user, loyalty, promotion, and system access',
              ),
              _SettingsTile('Admin Cabang', 'Branch scoped access'),
              _SettingsTile('Real-time Notifications', 'Email dan in-app'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleManagementPage({
    required String title,
    required String subtitle,
    required String primaryAction,
    required VoidCallback onPrimaryAction,
    required List<String> columns,
    required List<List<Widget>> rows,
    String initialSearchValue = '',
    ValueChanged<String>? onSearchChanged,
    Widget? emptyState,
  }) {
    return Column(
      children: [
        _ManagementToolbar(
          title: title,
          subtitle: subtitle,
          primaryAction: primaryAction,
          onPrimaryAction: onPrimaryAction,
          initialSearchValue: initialSearchValue,
          onSearchChanged: onSearchChanged,
        ),
        const SizedBox(height: 18),
        if (rows.isEmpty && emptyState != null)
          _PanelCard(
            title: 'Data Table',
            subtitle: '0 records found',
            child: emptyState,
          )
        else
          _DataTablePanel(columns: columns, rows: rows),
      ],
    );
  }

  Widget _buildReports() {
    final summary = _reportsSummary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'Reports',
          subtitle: 'Ringkasan laporan operasional global seluruh jaringan KDMP.',
          actionLabel: 'Export Summary',
          onAction: () => _showSnack('Export laporan global sedang disiapkan.'),
        ),
        const SizedBox(height: 18),
        if (_isReportsLoading && summary == null)
          const Center(child: CircularProgressIndicator())
        else ...[
          _ResponsiveStatGrid(
            children: [
              StatCard(
                title: 'Total Revenue',
                value: _formatCurrency(summary?.totalRevenue ?? 0),
                icon: Icons.payments_rounded,
                trend: '${summary?.totalOrders ?? 0} total order',
                accentColor: AppColors.primary,
              ),
              StatCard(
                title: 'Completed Orders',
                value: '${summary?.completedOrders ?? 0}',
                icon: Icons.inventory_rounded,
                trend: '${summary?.itemsSold ?? 0} item terjual',
                accentColor: AppColors.accent,
              ),
              StatCard(
                title: 'Wallet Topups',
                value: _formatCurrency(summary?.totalTopups ?? 0),
                icon: Icons.account_balance_wallet_rounded,
                trend: 'Top up berhasil',
                accentColor: const Color(0xFF7C3AED),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ResponsiveTwoColumn(
            left: _PanelCard(
              title: 'Revenue by Branch',
              subtitle: 'Cabang dengan omzet tertinggi',
              child: Column(
                children: (summary?.branchReports ?? const <SuperadminBranchReport>[])
                    .take(6)
                    .map(
                      (branch) => _RankingTile(
                        title: branch.branchName,
                        subtitle: branch.location.ifEmpty('-'),
                        value: _formatCurrency(branch.revenue),
                        score: branch.revenue == 0
                            ? 0
                            : ((branch.revenue /
                                            ((summary?.branchReports.firstOrNull?.revenue ?? 1)))
                                        * 100)
                                    .round()
                                    .clamp(0, 100),
                      ),
                    )
                    .toList(),
              ),
            ),
            right: _PanelCard(
              title: 'Top Products',
              subtitle: 'Produk paling banyak terjual',
              child: Column(
                children: (summary?.topProducts ?? const <SuperadminTopProduct>[])
                    .map(
                      (product) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                          child: const Icon(
                            Icons.shopping_bag_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: Text(
                          '${product.quantity} qty',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _selectMenu(String menu) {
    setState(() {
      currentMenu = menu;
      searchQuery = '';
      selectedRegion = 'Semua Region';
      selectedStatus = 'Semua Status';
    });
  }

  Future<void> _simulateRefresh() async {
    setState(() => showSkeleton = true);
    await _loadBranches(showLoader: false);
    await _loadOverview(showLoader: false);
    await _loadUsers(showLoader: false);
    await _loadReports(showLoader: false);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => showSkeleton = false);
  }

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Real-time Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const ListTile(
                leading: Icon(
                  Icons.storefront_rounded,
                  color: AppColors.primary,
                ),
                title: Text('Branch review completed'),
                subtitle: Text('KDMP Harapan Desa selesai diverifikasi'),
              ),
              const ListTile(
                leading: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.primary,
                ),
                title: Text('New admin assigned'),
                subtitle: Text('Rani assigned to KDMP Sukamaju'),
              ),
              const ListTile(
                leading: Icon(Icons.campaign_rounded, color: AppColors.primary),
                title: Text('Promotion published'),
                subtitle: Text('PUPUK50 banner is now live'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProfileMenu() {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 72, 24, 0),
      items: const [
        PopupMenuItem(value: 'profile', child: Text('My Profile')),
        PopupMenuItem(value: 'security', child: Text('Security Settings')),
        PopupMenuItem(value: 'logout', child: Text('Logout')),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'logout':
          unawaited(_handleSuperadminLogout());
          break;
        case 'profile':
          _showSnack('Profil superadmin akan tersedia di iterasi berikutnya.');
          break;
        case 'security':
          _showSnack('Pengaturan keamanan akan tersedia di iterasi berikutnya.');
          break;
      }
    });
  }

  Future<void> _handleSuperadminLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout Superadmin'),
        content: const Text(
          'Anda akan keluar dari dashboard superadmin dan kembali ke halaman login.',
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
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      if (!mounted) return;
      _showSnack('Logout gagal. Coba lagi beberapa saat.');
    }
  }

  void _openQuickCreate() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickActionChip(
                'Add Branch',
                Icons.storefront_rounded,
                _openBranchForm,
              ),
              _QuickActionChip(
                'Add Admin',
                Icons.admin_panel_settings_rounded,
                () => _openAdminForm(),
              ),
              _QuickActionChip(
                'Create Promo',
                Icons.campaign_rounded,
                () => _openTextForm('Buat Promo', 'Judul promo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadBranches({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _isBranchLoading = true);
    }
    try {
      final records = await _repository.loadBranches();
      if (!mounted) return;
      setState(() {
        branches = records.map(_BranchData.fromRecord).toList(growable: false);
        _isBranchLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isBranchLoading = false);
      _showSnack('Gagal memuat data cabang dari backend: $error');
    }
  }

  Future<void> _loadAdmins({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _isAdminLoading = true);
    }
    try {
      final loadedAdmins = await _repository.loadAdminAssignments();
      final loadedCandidates = await _repository.loadAdminCandidates();
      if (!mounted) return;
      setState(() {
        admins = loadedAdmins.map(_AdminData.fromRecord).toList(growable: false);
        _adminCandidates = loadedCandidates;
        _isAdminLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isAdminLoading = false);
      _showSnack('Gagal memuat data admin cabang: $error');
    }
  }

  Future<void> _loadOverview({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _isOverviewLoading = true);
    }
    try {
      final overview = await _repository.loadDashboardOverview();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _isOverviewLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isOverviewLoading = false);
      _showSnack('Gagal memuat ringkasan dashboard global: $error');
    }
  }

  Future<void> _loadPromotions({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _isPromotionLoading = true);
    }
    try {
      final promotions = await _repository.loadPromotions();
      if (!mounted) return;
      setState(() {
        banners = promotions
            .map(_PromotionData.fromRecord)
            .toList(growable: false);
        _isPromotionLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isPromotionLoading = false);
      _showSnack('Gagal memuat data promosi: $error');
    }
  }

  Future<void> _loadUsers({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _isUserLoading = true);
    }
    try {
      final records = await _repository.loadUsers();
      if (!mounted) return;
      setState(() {
        users = records.map(_UserData.fromRecord).toList(growable: false);
        _isUserLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isUserLoading = false);
      _showSnack('Gagal memuat data user pelanggan: $error');
    }
  }

  Future<void> _loadReports({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _isReportsLoading = true);
    }
    try {
      final summary = await _repository.loadReportsSummary();
      if (!mounted) return;
      setState(() {
        _reportsSummary = summary;
        _isReportsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isReportsLoading = false);
      _showSnack('Gagal memuat laporan global: $error');
    }
  }

  Future<void> _openBranchForm({_BranchData? branch}) async {
    final result = await showDialog<SuperadminBranchDraft>(
      context: context,
      builder: (context) => _BranchFormDialog(branch: branch),
    );
    if (!mounted || result == null) return;

    try {
      await _repository.saveBranch(result, branchId: branch?.id);
      await _loadBranches(showLoader: false);
      if (!mounted) return;
      _showSnack(branch == null ? 'Cabang baru berhasil ditambahkan.' : 'Cabang berhasil diperbarui.');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Gagal menyimpan data cabang: $error');
    }
  }

  Future<void> _openAdminForm({_AdminData? admin}) async {
    final result = await showDialog<SuperadminAdminDraft>(
      context: context,
      builder: (context) => _AdminFormDialog(
        admin: admin,
        branches: branches,
        candidates: _adminCandidates,
      ),
    );
    if (!mounted || result == null) return;

    try {
      await _repository.saveAdminAssignment(result, assignmentId: admin?.id);
      await _loadAdmins(showLoader: false);
      if (!mounted) return;
      _showSnack(
        admin == null
            ? 'Admin cabang berhasil ditambahkan.'
            : 'Admin cabang berhasil diperbarui.',
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal menyimpan admin cabang.');
    }
  }

  void _openTextForm(String title, String hint) {
    final controller = TextEditingController(
      text: hint.startsWith('Nama') ? '' : hint,
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: hint),
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showSnack('$title disimpan.');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openBranchDetail(_BranchData branch) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(branch.name),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoRow(label: 'Kode', value: branch.code),
              _InfoRow(label: 'Region', value: branch.region),
              _InfoRow(label: 'Admin', value: branch.admin),
              _InfoRow(label: 'Performance', value: '${branch.performance}%'),
              _InfoRow(label: 'Status', value: branch.status),
              _InfoRow(label: 'Alamat', value: branch.address),
              _InfoRow(label: 'Telepon', value: branch.phone.ifEmpty('-')),
              _InfoRow(label: 'Email', value: branch.email.ifEmpty('-')),
              _InfoRow(
                label: 'Email Admin Login',
                value: branch.adminLoginEmail.ifEmpty('-'),
              ),
              _InfoRow(
                label: 'Nama Admin Login',
                value: branch.adminLoginName.ifEmpty('-'),
              ),
              _InfoRow(label: 'Total Order', value: '${branch.totalOrders}'),
              _InfoRow(
                label: 'Omzet Kotor',
                value: _formatCurrency(branch.grossRevenue),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _selectMenu('Branch Management');
            },
            child: const Text('Open Branch'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openBranchCredentials(branch);
            },
            child: const Text('Kelola Akun Admin'),
          ),
        ],
      ),
    );
  }

  void _openAdminDetail(_AdminData admin) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(admin.name),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoRow(label: 'Cabang', value: admin.branch),
              _InfoRow(label: 'Email', value: admin.email.ifEmpty('-')),
              _InfoRow(label: 'Role', value: admin.role),
              _InfoRow(label: 'Permission', value: admin.permission),
              _InfoRow(label: 'Telepon', value: admin.phone.ifEmpty('-')),
              _InfoRow(label: 'Status', value: admin.active ? 'Active' : 'Inactive'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deactivateAdmin(_AdminData admin) async {
    try {
      await _repository.deactivateAdminAssignment(admin.id, userId: admin.userId);
      await _loadAdmins(showLoader: false);
      if (!mounted) return;
      _showSnack('${admin.name} dinonaktifkan dari cabang.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal menonaktifkan admin cabang.');
    }
  }

  Future<void> _openBranchCredentials(_BranchData branch) async {
    SuperadminBranchAdminAccount? currentAccount;
    try {
      currentAccount = await _repository.loadPrimaryBranchAdminAccount(branch.id);
    } catch (_) {
      currentAccount = null;
    }
    if (!mounted) return;

    final result = await showDialog<_BranchCredentialResult>(
      context: context,
      builder: (context) => _BranchCredentialDialog(
        branch: branch,
        currentAccount: currentAccount,
      ),
    );
    if (!mounted || result == null) return;

    try {
      await _repository.upsertBranchAdminCredentials(
        branchId: branch.id,
        email: result.email,
        password: result.password,
        fullName: result.fullName,
        phone: result.phone,
      );
      await _loadBranches(showLoader: false);
      await _loadAdmins(showLoader: false);
      if (!mounted) return;
      _showSnack(
        'Akun admin ${branch.name} tersimpan. Login: ${result.email}',
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack('Gagal menyimpan akun admin cabang: $error');
    }
  }

  Future<void> _openPromotionForm([_PromotionData? promo]) async {
    final result = await showDialog<SuperadminPromotionDraft>(
      context: context,
      builder: (context) => _PromotionFormDialog(
        promotion: promo,
        branches: branches,
      ),
    );
    if (!mounted || result == null) return;

    try {
      await _repository.savePromotion(result, promotionId: promo?.id);
      await _loadPromotions(showLoader: false);
      if (!mounted) return;
      _showSnack(
        promo == null
            ? 'Promo berhasil ditambahkan.'
            : 'Promo berhasil diperbarui.',
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal menyimpan promo.');
    }
  }

  void _openPromotionDetail(_PromotionData promo) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(promo.title),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoRow(label: 'Scope', value: promo.placement),
              _InfoRow(label: 'Periode', value: promo.period),
              _InfoRow(label: 'Diskon', value: promo.discountLabel),
              _InfoRow(label: 'Status', value: promo.status),
              _InfoRow(label: 'Deskripsi', value: promo.description.ifEmpty('-')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openUserDetail(_UserData user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.name),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _InfoRow(label: 'Telepon', value: user.phone.ifEmpty('-')),
              _InfoRow(label: 'Status', value: user.status),
              _InfoRow(label: 'Wallet Balance', value: _formatCurrency(user.walletBalance)),
              _InfoRow(label: 'Total Topup', value: _formatCurrency(user.totalTopup)),
              _InfoRow(label: 'Total Belanja', value: _formatCurrency(user.totalSpent)),
              _InfoRow(label: 'Jumlah Order', value: '${user.orderCount}'),
              _InfoRow(label: 'Order Terakhir', value: user.lastOrderLabel),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePromotionStatus(_PromotionData promo) async {
    final nextIsActive = promo.status != 'Active';
    try {
      await _repository.setPromotionActive(promo.id, isActive: nextIsActive);
      await _loadPromotions(showLoader: false);
      if (!mounted) return;
      _showSnack(
        nextIsActive
            ? '${promo.title} diaktifkan.'
            : '${promo.title} dinonaktifkan.',
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal mengubah status promo.');
    }
  }

  Future<void> _toggleBranchStatus(_BranchData branch) async {
    final nextIsActive = !branch.isActive;
    try {
      await _repository.setBranchActive(branch.id, isActive: nextIsActive);
      await _loadBranches(showLoader: false);
      if (!mounted) return;
      _showSnack(
        nextIsActive
            ? '${branch.name} diaktifkan kembali.'
            : '${branch.name} dinonaktifkan.',
      );
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal mengubah status cabang.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatCurrency(int value) {
    final normalized = value.clamp(0, 999999999);
    final digits = normalized.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp $buffer';
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
    final compact = MediaQuery.of(context).size.width < 780;
    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (actionLabel != null)
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.download_rounded),
            label: Text(actionLabel!),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );

    return Flex(
      direction: compact ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: compact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: compact ? 0 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (compact) const SizedBox(height: 14),
        actions,
      ],
    );
  }
}

class _ResponsiveStatGrid extends StatelessWidget {
  const _ResponsiveStatGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final count = width >= 1320
            ? 4
            : width >= 860
            ? 3
            : width >= 560
            ? 2
            : 1;
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: count == 1
              ? 2.2
              : count == 2
              ? 1.08
              : 1.38,
          children: children,
        );
      },
    );
  }
}

class _ResponsiveTwoColumn extends StatelessWidget {
  const _ResponsiveTwoColumn({
    required this.left,
    required this.right,
    this.leftFlex = 1,
  });

  final Widget left;
  final Widget right;
  final int leftFlex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 960) {
          return Column(children: [left, const SizedBox(height: 18), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            const SizedBox(width: 18),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _BarChartMock extends StatelessWidget {
  const _BarChartMock({required this.points});

  final List<SuperadminChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final data = points.isEmpty
        ? const [12, 8, 6]
        : points.map((point) => point.value).toList(growable: false);
    final labels = points.isEmpty
        ? const ['A', 'B', 'C']
        : points.map((point) => point.label).toList(growable: false);
    final maxValue = data.reduce((a, b) => a > b ? a : b).clamp(1, 999999999);

    return SizedBox(
      height: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < data.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: data[index] / maxValue,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      labels[index],
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LineChartMock extends StatelessWidget {
  const _LineChartMock({required this.points});

  final List<SuperadminChartPoint> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: CustomPaint(
        painter: _LineChartPainter(points),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter(this.points);

  final List<SuperadminChartPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE9ECEF)
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final values = points.isEmpty
        ? const [16, 22, 14, 28, 32, 24, 36]
        : points.map((point) => point.value).toList(growable: false);
    final maxValue = values.reduce((a, b) => a > b ? a : b).clamp(1, 999999999);
    final chartPoints = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? size.width / 2 : size.width * i / (values.length - 1);
      final normalized = values[i] / maxValue;
      final y = size.height - (size.height * (normalized * 0.75 + 0.10));
      chartPoints.add(Offset(x, y));
    }

    final path = Path()..moveTo(chartPoints.first.dx, chartPoints.first.dy);
    for (final point in chartPoints.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final linePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = AppColors.primary;
    for (final point in chartPoints) {
      canvas.drawCircle(point, 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.score,
  });

  final String title;
  final String subtitle;
  final String value;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
                const SizedBox(height: 3),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              SizedBox(
                width: 94,
                child: LinearProgressIndicator(
                  value: score / 100,
                  color: AppColors.primary,
                  backgroundColor: AppColors.secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BranchStatusTile extends StatelessWidget {
  const _BranchStatusTile({required this.branch, required this.onTap});

  final _BranchData branch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.10),
        child: const Icon(Icons.storefront_rounded, color: AppColors.primary),
      ),
      title: Text(
        branch.name,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text('${branch.region} • ${branch.admin}'),
      trailing: _StatusPill(label: branch.status),
    );
  }
}

class _ManagementToolbar extends StatelessWidget {
  const _ManagementToolbar({
    required this.title,
    required this.subtitle,
    required this.primaryAction,
    required this.onPrimaryAction,
    this.filters = const [],
    this.initialSearchValue = '',
    this.onSearchChanged,
  });

  final String title;
  final String subtitle;
  final String primaryAction;
  final VoidCallback onPrimaryAction;
  final List<Widget> filters;
  final String initialSearchValue;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: title,
      subtitle: subtitle,
      trailing: FilledButton.icon(
        onPressed: onPrimaryAction,
        icon: const Icon(Icons.add_rounded),
        label: Text(primaryAction),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 280,
            child: TextFormField(
              initialValue: initialSearchValue,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search data...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.secondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          ...filters,
        ],
      ),
    );
  }
}

class _ToolbarDropdown extends StatelessWidget {
  const _ToolbarDropdown({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: values
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _DataTablePanel extends StatelessWidget {
  const _DataTablePanel({required this.columns, required this.rows});

  final List<String> columns;
  final List<List<Widget>> rows;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: 'Data Table',
      subtitle: '${rows.length} records found',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.secondary),
          columns: columns
              .map((column) => DataColumn(label: Text(column)))
              .toList(),
          rows: rows
              .map(
                (cells) => DataRow(
                  cells: cells.map((cell) => DataCell(cell)).toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _TableTitle extends StatelessWidget {
  const _TableTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _TableActions extends StatelessWidget {
  const _TableActions({
    this.onView,
    this.onEdit,
    this.onCredentials,
    this.onDeactivate,
  });

  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onCredentials;
  final VoidCallback? onDeactivate;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View',
          onPressed: onView,
          icon: const Icon(Icons.visibility_outlined),
        ),
        IconButton(
          tooltip: 'Edit',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        if (onCredentials != null)
          IconButton(
            tooltip: 'Akun Login',
            onPressed: onCredentials,
            icon: const Icon(Icons.key_rounded),
          ),
        if (onDeactivate != null)
          IconButton(
            tooltip: 'Deactivate',
            onPressed: onDeactivate,
            icon: const Icon(Icons.block_rounded),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Active' || 'Online' || 'Delivered' => const Color(0xFF16A34A),
      'Review' || 'Pending' || 'Draft' => const Color(0xFFF59E0B),
      'Suspended' ||
      'Inactive' ||
      'Cancelled' ||
      'Flagged' => const Color(0xFFE53935),
      'Processing' || 'Shipped' => AppColors.accent,
      _ => AppColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _PanelCard(
      title: title,
      subtitle: 'Editable platform configuration',
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatefulWidget {
  const _SettingsTile(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  bool enabled = true;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: enabled,
      onChanged: (value) => setState(() => enabled = value),
      title: Text(
        widget.title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(widget.subtitle),
      activeThumbColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _CampaignTile extends StatelessWidget {
  const _CampaignTile({required this.title, required this.status});

  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.campaign_rounded, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      trailing: _StatusPill(label: status),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 6; i++)
          Container(
            height: i == 0 ? 110 : 86,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
      ],
    );
  }
}

class _BranchFormDialog extends StatefulWidget {
  const _BranchFormDialog({this.branch});

  final _BranchData? branch;

  @override
  State<_BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends State<_BranchFormDialog> {
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _adminNameController;
  late final TextEditingController _adminEmailController;
  late final TextEditingController _adminPasswordController;
  late final TextEditingController _addressController;
  late final TextEditingController _provinceController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _postalController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final branch = widget.branch;
    _codeController = TextEditingController(text: branch?.code ?? '');
    _nameController = TextEditingController(text: branch?.name ?? '');
    _phoneController = TextEditingController(text: branch?.phone ?? '');
    _emailController = TextEditingController(text: branch?.email ?? '');
    _adminNameController = TextEditingController(
      text: branch?.adminLoginName ?? '',
    );
    _adminEmailController = TextEditingController(
      text: branch?.adminLoginEmail ?? '',
    );
    _adminPasswordController = TextEditingController();
    _addressController = TextEditingController(text: branch?.address ?? '');
    _provinceController = TextEditingController(
      text: branch?.province ?? '',
    );
    _cityController = TextEditingController(
      text: branch?.city ?? '',
    );
    _districtController = TextEditingController(
      text: branch?.district ?? '',
    );
    _postalController = TextEditingController(text: branch?.postalCode ?? '');
    _isActive = branch?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    _addressController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.branch != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Branch' : 'Add Branch'),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(_codeController, 'Kode Cabang'),
              const SizedBox(height: 12),
              _dialogField(_nameController, 'Nama Cabang'),
              const SizedBox(height: 12),
              _dialogField(_phoneController, 'Nomor Telepon'),
              const SizedBox(height: 12),
              _dialogField(_emailController, 'Email Cabang'),
              const SizedBox(height: 12),
              _dialogField(_addressController, 'Alamat Lengkap', maxLines: 3),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dialogField(_districtController, 'Kecamatan')),
                  const SizedBox(width: 12),
                  Expanded(child: _dialogField(_cityController, 'Kota')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dialogField(_provinceController, 'Provinsi')),
                  const SizedBox(width: 12),
                  Expanded(child: _dialogField(_postalController, 'Kode Pos')),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cabang Aktif'),
                subtitle: const Text('Jika nonaktif, customer tidak bisa memilih cabang ini.'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const Divider(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Akun Login Admin Cabang',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _dialogField(_adminNameController, 'Nama Admin Cabang'),
              const SizedBox(height: 12),
              _dialogField(_adminEmailController, 'Email Login Admin'),
              const SizedBox(height: 12),
              _dialogField(
                _adminPasswordController,
                isEdit
                    ? 'Password Baru Admin (opsional untuk reset)'
                    : 'Password Admin Cabang',
                obscureText: true,
                helperText: isEdit
                    ? 'Kosongkan jika tidak ingin mengganti password admin cabang.'
                    : 'Admin cabang akan login memakai email dan password ini.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? helperText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _save() {
    final isEdit = widget.branch != null;
    final adminEmail = _adminEmailController.text.trim();
    final adminPassword = _adminPasswordController.text.trim();

    if (_codeController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode, nama, dan alamat cabang wajib diisi.')),
      );
      return;
    }

    if (!isEdit && (adminEmail.isEmpty || adminPassword.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan password admin cabang wajib diisi saat membuat cabang baru.'),
        ),
      );
      return;
    }

    if (adminEmail.isNotEmpty &&
        (!adminEmail.contains('@') || !adminEmail.contains('.'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email login admin cabang belum valid.')),
      );
      return;
    }

    if (adminPassword.isNotEmpty && adminPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password admin cabang minimal 6 karakter.')),
      );
      return;
    }

    Navigator.of(context).pop(
      SuperadminBranchDraft(
        code: _codeController.text,
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        address: _addressController.text,
        province: _provinceController.text,
        city: _cityController.text,
        district: _districtController.text,
        postalCode: _postalController.text,
        isActive: _isActive,
        adminLoginName: _adminNameController.text,
        adminLoginEmail: adminEmail,
        adminLoginPassword: adminPassword,
        adminLoginPhone: _phoneController.text,
      ),
    );
  }
}

class _AdminFormDialog extends StatefulWidget {
  const _AdminFormDialog({
    this.admin,
    required this.branches,
    required this.candidates,
  });

  final _AdminData? admin;
  final List<_BranchData> branches;
  final List<SuperadminProfileCandidate> candidates;

  @override
  State<_AdminFormDialog> createState() => _AdminFormDialogState();
}

class _AdminFormDialogState extends State<_AdminFormDialog> {
  String? _selectedUserId;
  String? _selectedBranchId;
  String _adminRole = 'branch_admin';
  bool _isPrimary = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final admin = widget.admin;
    _selectedUserId = admin?.userId;
    _selectedBranchId = widget.branches
        .where((branch) => branch.name == admin?.branch)
        .map((branch) => branch.id)
        .firstOrNull;
    _adminRole = switch (admin?.role) {
      'Branch Manager' => 'branch_manager',
      'Inventory Admin' => 'inventory_admin',
      _ => 'branch_admin',
    };
    _isPrimary = admin?.permission == 'Full Branch';
    _isActive = admin?.active ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.admin == null ? 'Add Admin' : 'Edit Admin'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedUserId,
                decoration: const InputDecoration(
                  labelText: 'Pilih User',
                  border: OutlineInputBorder(),
                ),
                items: widget.candidates
                    .where((candidate) => candidate.isActive)
                    .map(
                      (candidate) => DropdownMenuItem(
                        value: candidate.id,
                        child: Text(
                          candidate.fullName.ifEmpty(candidate.phone.ifEmpty('User')),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: widget.admin == null
                    ? (value) => setState(() => _selectedUserId = value)
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedBranchId,
                decoration: const InputDecoration(
                  labelText: 'Pilih Cabang',
                  border: OutlineInputBorder(),
                ),
                items: widget.branches
                    .map(
                      (branch) => DropdownMenuItem(
                        value: branch.id,
                        child: Text(branch.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedBranchId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _adminRole,
                decoration: const InputDecoration(
                  labelText: 'Role Admin',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'branch_admin',
                    child: Text('Branch Admin'),
                  ),
                  DropdownMenuItem(
                    value: 'branch_manager',
                    child: Text('Branch Manager'),
                  ),
                  DropdownMenuItem(
                    value: 'inventory_admin',
                    child: Text('Inventory Admin'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _adminRole = value);
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Jadikan Admin Utama Cabang'),
                value: _isPrimary,
                onChanged: (value) => setState(() => _isPrimary = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Admin Aktif'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    if ((_selectedUserId ?? '').isEmpty || (_selectedBranchId ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User dan cabang wajib dipilih.')),
      );
      return;
    }

    Navigator.of(context).pop(
      SuperadminAdminDraft(
        userId: _selectedUserId!,
        branchId: _selectedBranchId!,
        adminRole: _adminRole,
        isPrimary: _isPrimary,
        isActive: _isActive,
      ),
    );
  }
}

class _BranchCredentialDialog extends StatefulWidget {
  const _BranchCredentialDialog({
    required this.branch,
    this.currentAccount,
  });

  final _BranchData branch;
  final SuperadminBranchAdminAccount? currentAccount;

  @override
  State<_BranchCredentialDialog> createState() => _BranchCredentialDialogState();
}

class _BranchCredentialDialogState extends State<_BranchCredentialDialog> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final branchSlug = widget.branch.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
        .replaceAll(RegExp(r'\.+'), '.')
        .replaceAll(RegExp(r'(^\.)|(\.$)'), '');
    _fullNameController = TextEditingController(
      text: widget.currentAccount?.fullName.ifEmpty(
            'Admin ${widget.branch.name}',
          ) ??
          'Admin ${widget.branch.name}',
    );
    _phoneController = TextEditingController(
      text: widget.currentAccount?.phone.ifEmpty(widget.branch.phone) ??
          widget.branch.phone,
    );
    _emailController = TextEditingController(
      text: widget.currentAccount?.email.ifEmpty(
            'admin.$branchSlug@kdmp.id',
          ) ??
          'admin.$branchSlug@kdmp.id',
    );
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Akun Admin ${widget.branch.name}'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _readonlyInfo('Cabang', widget.branch.name),
              const SizedBox(height: 12),
              _dialogField(_fullNameController, 'Nama Admin'),
              const SizedBox(height: 12),
              _dialogField(_phoneController, 'Nomor Telepon'),
              const SizedBox(height: 12),
              _dialogField(_emailController, 'Email Login'),
              const SizedBox(height: 12),
              _dialogField(
                _passwordController,
                'Password Baru',
                helperText: widget.currentAccount == null
                    ? 'Password ini akan dipakai saat login admin cabang.'
                    : 'Isi password baru untuk mereset login admin cabang.',
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Simpan Akun'),
        ),
      ],
    );
  }

  Widget _readonlyInfo(String label, String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    String? helperText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _save() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (_fullNameController.text.trim().isEmpty ||
        email.isEmpty ||
        !email.contains('@') ||
        !email.contains('.') ||
        password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nama admin, email valid, dan password minimal 6 karakter wajib diisi.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _BranchCredentialResult(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: email,
        password: password,
      ),
    );
  }
}

class _PromotionFormDialog extends StatefulWidget {
  const _PromotionFormDialog({
    this.promotion,
    required this.branches,
  });

  final _PromotionData? promotion;
  final List<_BranchData> branches;

  @override
  State<_PromotionFormDialog> createState() => _PromotionFormDialogState();
}

class _PromotionFormDialogState extends State<_PromotionFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _discountController;
  late final TextEditingController _minPurchaseController;
  late final TextEditingController _maxDiscountController;
  late final TextEditingController _quotaController;
  String _promoType = 'percentage';
  String _promoScope = 'global';
  String _branchId = '';
  bool _isActive = true;
  DateTime _startAt = DateTime.now();
  DateTime _endAt = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    final promotion = widget.promotion;
    _titleController = TextEditingController(text: promotion?.title ?? '');
    _descriptionController = TextEditingController(
      text: promotion?.description ?? '',
    );
    _discountController = TextEditingController(
      text: promotion == null
          ? ''
          : promotion.discountLabel.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    _minPurchaseController = TextEditingController();
    _maxDiscountController = TextEditingController();
    _quotaController = TextEditingController();

    if (promotion != null) {
      _promoType = promotion.code == 'percentage' ? 'percentage' : 'nominal';
      _promoScope = promotion.placement.startsWith('Cabang:') ? 'branch' : 'global';
      _branchId = widget.branches
          .where((branch) => promotion.placement.contains(branch.name))
          .map((branch) => branch.id)
          .firstOrNull ?? '';
      _isActive = promotion.status == 'Active' || promotion.status == 'Scheduled';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _minPurchaseController.dispose();
    _maxDiscountController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.promotion == null ? 'Create Promotion' : 'Edit Promotion'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(_titleController, 'Judul Promo'),
              const SizedBox(height: 12),
              _dialogField(_descriptionController, 'Deskripsi', maxLines: 3),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _promoType,
                      decoration: const InputDecoration(
                        labelText: 'Tipe Promo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'percentage',
                          child: Text('Persentase'),
                        ),
                        DropdownMenuItem(
                          value: 'nominal',
                          child: Text('Nominal'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _promoType = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _promoScope,
                      decoration: const InputDecoration(
                        labelText: 'Scope Promo',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'global', child: Text('Global')),
                        DropdownMenuItem(value: 'branch', child: Text('Per Cabang')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _promoScope = value);
                      },
                    ),
                  ),
                ],
              ),
              if (_promoScope == 'branch') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _branchId.isEmpty ? null : _branchId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Cabang',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.branches
                      .map(
                        (branch) => DropdownMenuItem(
                          value: branch.id,
                          child: Text(branch.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _branchId = value ?? ''),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dialogField(_discountController, 'Nilai Diskon')),
                  const SizedBox(width: 12),
                  Expanded(child: _dialogField(_quotaController, 'Kuota')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _dialogField(_minPurchaseController, 'Min. Belanja')),
                  const SizedBox(width: 12),
                  Expanded(child: _dialogField(_maxDiscountController, 'Maks. Diskon')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mulai'),
                      subtitle: Text(_PromotionData._formatDate(_startAt)),
                      onTap: () => _pickDate(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Berakhir'),
                      subtitle: Text(_PromotionData._formatDate(_endAt)),
                      onTap: () => _pickDate(isStart: false),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Promo Aktif'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startAt : _endAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _startAt.hour,
          _startAt.minute,
        );
      } else {
        _endAt = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _endAt.hour,
          _endAt.minute,
        );
      }
    });
  }

  void _save() {
    if (_titleController.text.trim().isEmpty ||
        _discountController.text.trim().isEmpty ||
        (_promoScope == 'branch' && _branchId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul, diskon, dan cabang wajib diisi.')),
      );
      return;
    }
    if (_endAt.isBefore(_startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal selesai harus setelah tanggal mulai.')),
      );
      return;
    }

    Navigator.of(context).pop(
      SuperadminPromotionDraft(
        title: _titleController.text,
        description: _descriptionController.text,
        promoType: _promoType,
        promoScope: _promoScope,
        branchId: _branchId,
        discountValue: int.tryParse(_discountController.text) ?? 0,
        minPurchase: int.tryParse(_minPurchaseController.text) ?? 0,
        maxDiscount: int.tryParse(_maxDiscountController.text) ?? 0,
        quotaTotal: int.tryParse(_quotaController.text) ?? 0,
        startAt: _startAt,
        endAt: _endAt,
        isActive: _isActive,
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) {
    return trim().isEmpty ? fallback : this;
  }
}

class _BranchData {
  const _BranchData({
    required this.id,
    required this.code,
    required this.name,
    required this.region,
    required this.admin,
    required this.performance,
    required this.status,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.province = '',
    this.city = '',
    this.district = '',
    this.postalCode = '',
    this.isActive = true,
    this.totalOrders = 0,
    this.grossRevenue = 0,
    this.adminLoginEmail = '',
    this.adminLoginName = '',
    this.adminLoginPhone = '',
  });

  final String id;
  final String code;
  final String name;
  final String region;
  final String admin;
  final int performance;
  final String status;
  final String phone;
  final String email;
  final String address;
  final String province;
  final String city;
  final String district;
  final String postalCode;
  final bool isActive;
  final int totalOrders;
  final int grossRevenue;
  final String adminLoginEmail;
  final String adminLoginName;
  final String adminLoginPhone;

  factory _BranchData.fromRecord(SuperadminBranchRecord record) {
    final adminLabel = record.activeAdminNames.isEmpty
        ? 'Belum ada admin'
        : record.activeAdminNames.join(', ');
    final regionParts = [
      record.district.trim(),
      record.city.trim(),
      record.province.trim(),
    ].where((part) => part.isNotEmpty).toList(growable: false);

    return _BranchData(
      id: record.id,
      code: record.code,
      name: record.name,
      region: regionParts.isEmpty ? 'Belum diatur' : regionParts.join(', '),
      admin: adminLabel,
      performance: record.performanceScore,
      status: record.isActive ? 'Active' : 'Suspended',
      phone: record.phone,
      email: record.email,
      address: record.address,
      province: record.province,
      city: record.city,
      district: record.district,
      postalCode: record.postalCode,
      isActive: record.isActive,
      totalOrders: record.totalOrders,
      grossRevenue: record.grossRevenue,
      adminLoginEmail: record.primaryAdminEmail,
      adminLoginName: record.primaryAdminName,
      adminLoginPhone: record.primaryAdminPhone,
    );
  }
}

class _AdminData {
  const _AdminData({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.branch,
    required this.role,
    required this.permission,
    required this.active,
  });

  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final String branch;
  final String role;
  final String permission;
  final bool active;

  factory _AdminData.fromRecord(SuperadminAdminRecord record) {
    final role = switch (record.adminRole) {
      'branch_manager' => 'Branch Manager',
      'inventory_admin' => 'Inventory Admin',
      _ => 'Branch Admin',
    };
    final permission = switch (record.adminRole) {
      'branch_manager' => 'Full Branch',
      'inventory_admin' => 'Inventory Focus',
      _ => 'Branch Operations',
    };

    return _AdminData(
      id: record.id,
      userId: record.userId,
      name: record.fullName,
      phone: record.phone,
      email: record.email,
      branch: record.branchName,
      role: role,
      permission: permission,
      active: record.isActive && record.profileIsActive,
    );
  }
}

class _BranchCredentialResult {
  const _BranchCredentialResult({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String phone;
  final String email;
  final String password;
}

class _UserData {
  const _UserData({
    required this.id,
    required this.name,
    required this.phone,
    required this.points,
    required this.status,
    this.walletBalance = 0,
    this.totalTopup = 0,
    this.totalSpent = 0,
    this.orderCount = 0,
    this.lastOrderLabel = '-',
    this.subtitle = '',
  });

  final String id;
  final String name;
  final String phone;
  final int points;
  final String status;
  final int walletBalance;
  final int totalTopup;
  final int totalSpent;
  final int orderCount;
  final String lastOrderLabel;
  final String subtitle;

  factory _UserData.fromRecord(SuperadminUserRecord record) {
    final status = record.isActive ? 'Active' : 'Inactive';
    final subtitle = [
      '${record.totalOrders} order',
      _formatShortCurrency(record.totalSpent),
    ].join(' • ');

    return _UserData(
      id: record.id,
      name: record.fullName.ifEmpty('Pelanggan'),
      phone: record.phone,
      points: record.walletBalance,
      status: status,
      walletBalance: record.walletBalance,
      totalTopup: record.totalTopup,
      totalSpent: record.totalSpent,
      orderCount: record.totalOrders,
      lastOrderLabel: record.lastOrderAt == null
          ? '-'
          : '${record.lastOrderAt!.day.toString().padLeft(2, '0')}/${record.lastOrderAt!.month.toString().padLeft(2, '0')}/${record.lastOrderAt!.year}',
      subtitle: subtitle,
    );
  }

  static String _formatShortCurrency(int value) {
    if (value <= 0) return 'Rp 0';
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)} jt';
    }
    if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)} rb';
    }
    return 'Rp $value';
  }
}

class _PromotionData {
  const _PromotionData({
    required this.id,
    required this.title,
    required this.code,
    required this.placement,
    required this.period,
    required this.discountLabel,
    required this.status,
    this.description = '',
  });

  final String id;
  final String title;
  final String code;
  final String placement;
  final String period;
  final String discountLabel;
  final String status;
  final String description;

  factory _PromotionData.fromRecord(SuperadminPromotionRecord record) {
    final now = DateTime.now();
    final status = !record.isActive
        ? 'Inactive'
        : record.endAt != null && record.endAt!.isBefore(now)
        ? 'Ended'
        : record.startAt != null && record.startAt!.isAfter(now)
        ? 'Scheduled'
        : 'Active';

    final placement = record.promoScope == 'branch'
        ? 'Cabang: ${record.branchName.ifEmpty('Belum dipilih')}'
        : 'Global';
    final period =
        '${_formatDate(record.startAt)} - ${_formatDate(record.endAt)}';
    final discountLabel = record.promoType == 'percentage'
        ? '${record.discountValue}%'
        : 'Rp ${record.discountValue}';

    return _PromotionData(
      id: record.id,
      title: record.title,
      code: record.promoType,
      placement: placement,
      period: period,
      discountLabel: discountLabel,
      status: status,
      description: record.description,
    );
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return '-';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }
}

const _branchSeed = <_BranchData>[
  _BranchData(
    id: 'seed-1',
    code: 'BR-001',
    name: 'KDMP Sukamaju',
    region: 'Jawa Barat',
    admin: 'Rani Maharani',
    performance: 94,
    status: 'Active',
  ),
  _BranchData(
    id: 'seed-2',
    code: 'BR-002',
    name: 'KDMP Sumber Rejeki',
    region: 'Jawa Tengah',
    admin: 'Agus Santoso',
    performance: 89,
    status: 'Active',
  ),
  _BranchData(
    id: 'seed-3',
    code: 'BR-003',
    name: 'KDMP Maju Bersama',
    region: 'Jawa Timur',
    admin: 'Dewi Lestari',
    performance: 82,
    status: 'Review',
  ),
  _BranchData(
    id: 'seed-4',
    code: 'BR-004',
    name: 'KDMP Harapan Desa',
    region: 'Sumatera',
    admin: 'Fajar Hidayat',
    performance: 76,
    status: 'Suspended',
  ),
  _BranchData(
    id: 'seed-5',
    code: 'BR-005',
    name: 'KDMP Tani Makmur',
    region: 'Jawa Barat',
    admin: 'Nadia Putri',
    performance: 96,
    status: 'Active',
  ),
];

const _adminSeed = <_AdminData>[
  _AdminData(
    id: 'admin-seed-1',
    userId: 'user-seed-1',
    name: 'Rani Maharani',
    phone: '+62 812-0000-1111',
    email: 'rani.maharani@kdmp.id',
    branch: 'KDMP Sukamaju',
    role: 'Branch Admin',
    permission: 'Full Branch',
    active: true,
  ),
  _AdminData(
    id: 'admin-seed-2',
    userId: 'user-seed-2',
    name: 'Agus Santoso',
    phone: '+62 812-0000-2222',
    email: 'agus.santoso@kdmp.id',
    branch: 'KDMP Sumber Rejeki',
    role: 'Branch Admin',
    permission: 'Branch Operations',
    active: true,
  ),
  _AdminData(
    id: 'admin-seed-3',
    userId: 'user-seed-3',
    name: 'Dewi Lestari',
    phone: '+62 812-0000-3333',
    email: 'dewi.lestari@kdmp.id',
    branch: 'KDMP Maju Bersama',
    role: 'Branch Admin',
    permission: 'Branch Review',
    active: true,
  ),
  _AdminData(
    id: 'admin-seed-4',
    userId: 'user-seed-4',
    name: 'Bima Saputra',
    phone: '+62 812-0000-4444',
    email: 'bima.saputra@kdmp.id',
    branch: 'KDMP Harapan Desa',
    role: 'Operator',
    permission: 'Read Only',
    active: false,
  ),
];

const _userSeed = <_UserData>[
  _UserData(
    id: 'user-seed-1',
    name: 'Budi Santoso',
    phone: '+62 812 3456 7890',
    points: 1250,
    status: 'Active',
    subtitle: '4 order • Rp 320 rb',
  ),
  _UserData(
    id: 'user-seed-2',
    name: 'Siti Aminah',
    phone: '+62 811 9988 7766',
    points: 840,
    status: 'Active',
    subtitle: '2 order • Rp 140 rb',
  ),
  _UserData(
    id: 'user-seed-3',
    name: 'Hendra Wijaya',
    phone: '+62 856 3322 1100',
    points: 120,
    status: 'Review',
    subtitle: '0 order • Rp 0',
  ),
];

const _promotionSeed = <_PromotionData>[
  _PromotionData(
    id: 'promo-seed-1',
    title: 'Diskon 50% Pupuk',
    code: 'PUPUK50',
    placement: 'Home Banner',
    period: '14-30 Jun',
    discountLabel: '50%',
    status: 'Active',
  ),
  _PromotionData(
    id: 'promo-seed-2',
    title: 'Gratis Ongkir Desa',
    code: 'ONGKIRHEMAT',
    placement: 'Checkout',
    period: '10-25 Jun',
    discountLabel: 'Rp 8.000',
    status: 'Active',
  ),
  _PromotionData(
    id: 'promo-seed-3',
    title: 'Double Points Weekend',
    code: 'DOUBLEPTS',
    placement: 'Wallet',
    period: 'Draft',
    discountLabel: '2x poin',
    status: 'Draft',
  ),
];
