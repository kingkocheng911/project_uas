import 'package:flutter/material.dart';

import '../../constants/colors.dart';
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
  bool isSidebarExtended = true;
  bool showSkeleton = false;
  String currentMenu = 'Dashboard';
  String searchQuery = '';
  String selectedRegion = 'Semua Region';
  String selectedStatus = 'Semua Status';

  final branches = List<_BranchData>.of(_branchSeed);
  final admins = List<_AdminData>.of(_adminSeed);
  final couriers = List<_CourierData>.of(_courierSeed);
  final users = List<_UserData>.of(_userSeed);
  final categories = List<_CategoryData>.of(_categorySeed);
  final products = List<_ProductMonitorData>.of(_productSeed);
  final orders = List<_OrderMonitorData>.of(_orderSeed);
  final banners = List<_PromotionData>.of(_promotionSeed);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final useDrawer = width < 900;

    return Scaffold(
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
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _simulateRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(width < 720 ? 16 : 24),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _openQuickCreate,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Quick Create'),
      ),
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
      case 'Courier Management':
        return _buildCourierManagement();
      case 'User Management':
        return _buildUserManagement();
      case 'Product Categories':
        return _buildCategoryManagement();
      case 'Product Monitoring':
        return _buildProductMonitoring();
      case 'Orders Monitoring':
        return _buildOrdersMonitoring();
      case 'Loyalty Points Management':
        return _buildLoyaltyManagement();
      case 'Promotions & Banners':
        return _buildPromotions();
      case 'Reports & Analytics':
        return _buildReportsAnalytics();
      case 'Financial Reports':
        return _buildFinancialReports();
      case 'System Settings':
        return _buildSystemSettings();
      case 'Activity Logs':
        return _buildActivityLogs();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
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
        _ResponsiveStatGrid(
          children: const [
            StatCard(
              title: 'Total Branches',
              value: '128',
              icon: Icons.storefront_rounded,
              trend: '+12 cabang baru',
              accentColor: AppColors.primary,
            ),
            StatCard(
              title: 'Total Customers',
              value: '84.230',
              icon: Icons.people_alt_rounded,
              trend: '+18.4% bulan ini',
              accentColor: AppColors.accent,
            ),
            StatCard(
              title: 'Total Admins',
              value: '312',
              icon: Icons.admin_panel_settings_rounded,
              trend: '+24 aktif',
              accentColor: Color(0xFF7C3AED),
            ),
            StatCard(
              title: 'Total Couriers',
              value: '642',
              icon: Icons.delivery_dining_rounded,
              trend: '91% online',
              accentColor: Color(0xFF16A34A),
            ),
            StatCard(
              title: 'Total Products',
              value: '12.485',
              icon: Icons.inventory_2_rounded,
              trend: '+830 produk',
              accentColor: Color(0xFFF59E0B),
            ),
            StatCard(
              title: 'Total Orders',
              value: '36.904',
              icon: Icons.receipt_long_rounded,
              trend: '+9.8% mingguan',
              accentColor: Color(0xFF06B6D4),
            ),
            StatCard(
              title: 'Monthly Revenue',
              value: 'Rp 4.8M',
              icon: Icons.payments_rounded,
              trend: '+22.1% MoM',
              accentColor: Color(0xFF10B981),
            ),
            StatCard(
              title: 'Monthly Transactions',
              value: '18.720',
              icon: Icons.swap_horiz_rounded,
              trend: '+2.340 trx',
              accentColor: Color(0xFFEF4444),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _ResponsiveTwoColumn(
          leftFlex: 2,
          left: _PanelCard(
            title: 'Revenue & Orders Chart',
            subtitle: 'Data performa 7 bulan terakhir',
            trailing: _SmallActionButton(
              label: 'Detail',
              onTap: () => _selectMenu('Reports & Analytics'),
            ),
            child: const _BarChartMock(),
          ),
          right: _PanelCard(
            title: 'Top Branches Ranking',
            subtitle: 'Cabang dengan transaksi tertinggi',
            child: Column(
              children: branches
                  .take(5)
                  .map(
                    (branch) => _RankingTile(
                      title: branch.name,
                      subtitle: branch.region,
                      value: '${branch.orders} orders',
                      score: branch.performance,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _ResponsiveTwoColumn(
          left: _PanelCard(
            title: 'Most Active Branches',
            subtitle: 'Aktivitas operasional real-time',
            child: Column(
              children: branches
                  .take(4)
                  .map(
                    (branch) => _ActivityBranchTile(
                      branch: branch,
                      onTap: () => _openBranchDetail(branch),
                    ),
                  )
                  .toList(),
            ),
          ),
          right: const _PanelCard(
            title: 'User Growth Graph',
            subtitle: 'Pertumbuhan user 6 minggu',
            child: _LineChartMock(),
          ),
        ),
      ],
    );
  }

  Widget _buildBranchManagement() {
    final rows = branches.where((branch) {
      final matchQuery =
          searchQuery.isEmpty ||
          branch.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          branch.region.toLowerCase().contains(searchQuery.toLowerCase());
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
          filters: [
            _ToolbarDropdown(
              value: selectedRegion,
              values: const [
                'Semua Region',
                'Jawa Barat',
                'Jawa Tengah',
                'Jawa Timur',
                'Sumatera',
              ],
              onChanged: (value) => setState(() => selectedRegion = value),
            ),
            _ToolbarDropdown(
              value: selectedStatus,
              values: const ['Semua Status', 'Active', 'Review', 'Suspended'],
              onChanged: (value) => setState(() => selectedStatus = value),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _DataTablePanel(
          columns: const [
            'Branch',
            'Region',
            'Admin',
            'Orders',
            'Revenue',
            'Status',
            'Action',
          ],
          rows: rows
              .map(
                (branch) => [
                  _TableTitle(title: branch.name, subtitle: branch.code),
                  Text(branch.region),
                  Text(branch.admin),
                  Text('${branch.orders}'),
                  Text(branch.revenue),
                  _StatusPill(label: branch.status),
                  _TableActions(
                    onView: () => _openBranchDetail(branch),
                    onEdit: () => _openBranchForm(branch: branch),
                  ),
                ],
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildAdminManagement() {
    return _buildSimpleManagementPage(
      title: 'Admin Management',
      subtitle: 'Tambah admin, assign branch, edit permission, dan deactivate.',
      primaryAction: 'Add Admin',
      onPrimaryAction: _openAdminForm,
      columns: const [
        'Admin',
        'Branch',
        'Role',
        'Permission',
        'Status',
        'Action',
      ],
      rows: admins
          .map(
            (admin) => [
              _TableTitle(title: admin.name, subtitle: admin.email),
              Text(admin.branch),
              Text(admin.role),
              Text(admin.permission),
              _StatusPill(label: admin.active ? 'Active' : 'Inactive'),
              _TableActions(
                onView: () => _showInfoDialog('Admin Detail', admin.name),
                onEdit: _openAdminForm,
                onDeactivate: () => _showSnack('${admin.name} dinonaktifkan.'),
              ),
            ],
          )
          .toList(),
    );
  }

  Widget _buildCourierManagement() {
    return _buildSimpleManagementPage(
      title: 'Courier Management',
      subtitle: 'Monitor status online, performa delivery, dan rating kurir.',
      primaryAction: 'Add Courier',
      onPrimaryAction: () => _showSnack('Form tambah kurir dibuka.'),
      columns: const [
        'Courier',
        'Area',
        'Status',
        'Completed',
        'Rating',
        'Action',
      ],
      rows: couriers
          .map(
            (courier) => [
              _TableTitle(title: courier.name, subtitle: courier.phone),
              Text(courier.area),
              _StatusPill(label: courier.online ? 'Online' : 'Offline'),
              Text('${courier.completed}'),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(courier.rating.toStringAsFixed(1)),
                ],
              ),
              _TableActions(
                onView: () => _showInfoDialog('Courier Detail', courier.name),
                onEdit: () => _showSnack('Edit data ${courier.name}.'),
              ),
            ],
          )
          .toList(),
    );
  }

  Widget _buildUserManagement() {
    return _buildSimpleManagementPage(
      title: 'User Management',
      subtitle: 'Kelola akun user mobile, status, dan segmentasi pelanggan.',
      primaryAction: 'Export Users',
      onPrimaryAction: () => _showSnack('User report diexport.'),
      columns: const ['User', 'Phone', 'Orders', 'Points', 'Status', 'Action'],
      rows: users
          .map(
            (user) => [
              _TableTitle(title: user.name, subtitle: user.email),
              Text(user.phone),
              Text('${user.orders}'),
              Text('${user.points} pts'),
              _StatusPill(label: user.status),
              _TableActions(
                onView: () => _showInfoDialog('User Detail', user.name),
                onEdit: () => _showSnack('Edit user ${user.name}.'),
              ),
            ],
          )
          .toList(),
    );
  }

  Widget _buildCategoryManagement() {
    return _buildSimpleManagementPage(
      title: 'Product Categories',
      subtitle: 'Kelola kategori produk untuk marketplace semua cabang.',
      primaryAction: 'Add Category',
      onPrimaryAction: () => _openTextForm('Tambah Kategori', 'Nama kategori'),
      columns: const ['Category', 'Products', 'Commission', 'Status', 'Action'],
      rows: categories
          .map(
            (category) => [
              _TableTitle(title: category.name, subtitle: category.description),
              Text('${category.products}'),
              Text('${category.commission}%'),
              _StatusPill(label: category.active ? 'Active' : 'Inactive'),
              _TableActions(
                onView: () => _showInfoDialog('Kategori', category.name),
                onEdit: () => _openTextForm('Edit Kategori', category.name),
              ),
            ],
          )
          .toList(),
    );
  }

  Widget _buildProductMonitoring() {
    return _buildSimpleManagementPage(
      title: 'Product Monitoring',
      subtitle: 'Pantau stok, status produk, dan performa penjualan.',
      primaryAction: 'Review Flagged',
      onPrimaryAction: () => _showSnack('Produk flagged dibuka.'),
      columns: const [
        'Product',
        'Category',
        'Branch',
        'Stock',
        'Sales',
        'Status',
      ],
      rows: products
          .map(
            (product) => [
              _TableTitle(title: product.name, subtitle: product.sku),
              Text(product.category),
              Text(product.branch),
              Text('${product.stock}'),
              Text('${product.sales}'),
              _StatusPill(label: product.status),
            ],
          )
          .toList(),
    );
  }

  Widget _buildOrdersMonitoring() {
    return _buildSimpleManagementPage(
      title: 'Orders Monitoring',
      subtitle: 'Pantau order masuk, pengiriman, dan status pembayaran.',
      primaryAction: 'Export Orders',
      onPrimaryAction: () => _showSnack('Order monitoring diexport.'),
      columns: const [
        'Order ID',
        'Customer',
        'Branch',
        'Courier',
        'Total',
        'Status',
      ],
      rows: orders
          .map(
            (order) => [
              Text(order.id),
              Text(order.customer),
              Text(order.branch),
              Text(order.courier),
              Text(order.total),
              _StatusPill(label: order.status),
            ],
          )
          .toList(),
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
    return _buildSimpleManagementPage(
      title: 'Promotions & Banners',
      subtitle: 'Kelola banner, voucher, dan campaign nasional.',
      primaryAction: 'Create Promotion',
      onPrimaryAction: () => _openTextForm('Buat Promo', 'Judul promo'),
      columns: const [
        'Campaign',
        'Placement',
        'Period',
        'CTR',
        'Status',
        'Action',
      ],
      rows: banners
          .map(
            (promo) => [
              _TableTitle(title: promo.title, subtitle: promo.code),
              Text(promo.placement),
              Text(promo.period),
              Text('${promo.ctr}%'),
              _StatusPill(label: promo.status),
              _TableActions(
                onView: () => _showInfoDialog('Promo Detail', promo.title),
                onEdit: () => _openTextForm('Edit Promo', promo.title),
              ),
            ],
          )
          .toList(),
    );
  }

  Widget _buildReportsAnalytics() {
    return Column(
      children: [
        _PageHeader(
          title: 'Reports & Analytics',
          subtitle:
              'Sales report, branch report, product report, revenue report.',
          actionLabel: 'Download PDF',
          onAction: () => _showSnack('PDF report diunduh.'),
          secondaryActionLabel: 'Download Excel',
          onSecondaryAction: () => _showSnack('Excel report diunduh.'),
        ),
        const SizedBox(height: 18),
        _ResponsiveTwoColumn(
          leftFlex: 2,
          left: const _PanelCard(
            title: 'Sales Analytics',
            subtitle: 'Order dan revenue lintas cabang',
            child: _BarChartMock(),
          ),
          right: const _PanelCard(
            title: 'User Growth',
            subtitle: 'Akuisisi dan retensi pelanggan',
            child: _LineChartMock(),
          ),
        ),
        const SizedBox(height: 18),
        _buildOrdersMonitoring(),
      ],
    );
  }

  Widget _buildFinancialReports() {
    return Column(
      children: [
        _PageHeader(
          title: 'Financial Reports',
          subtitle: 'Laporan pendapatan, settlement, fee, dan payout cabang.',
          actionLabel: 'Download Excel',
          onAction: () => _showSnack('Financial report diunduh.'),
        ),
        const SizedBox(height: 18),
        _ResponsiveStatGrid(
          children: const [
            StatCard(
              title: 'Gross Revenue',
              value: 'Rp 4.8M',
              icon: Icons.trending_up_rounded,
              trend: '+22.1%',
              accentColor: Color(0xFF16A34A),
            ),
            StatCard(
              title: 'Platform Fee',
              value: 'Rp 284Jt',
              icon: Icons.percent_rounded,
              trend: '+8.4%',
              accentColor: AppColors.accent,
            ),
            StatCard(
              title: 'Pending Payout',
              value: 'Rp 512Jt',
              icon: Icons.pending_actions_rounded,
              trend: '-4.2%',
              accentColor: Color(0xFFF59E0B),
            ),
            StatCard(
              title: 'Net Settlement',
              value: 'Rp 3.9M',
              icon: Icons.account_balance_rounded,
              trend: '+18.7%',
              accentColor: AppColors.primary,
            ),
          ],
        ),
      ],
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
              _SettingsTile('Delivery Radius', '15 km dari cabang'),
              _SettingsTile('Default Delivery Fee', 'Rp 8.000'),
              _SettingsTile(
                'COD Availability',
                'Aktif untuk cabang terverifikasi',
              ),
            ],
          ),
          right: _SettingsPanel(
            title: 'Roles & Notifications',
            children: [
              _SettingsTile('Superadmin', 'Full access'),
              _SettingsTile('Admin Cabang', 'Branch scoped access'),
              _SettingsTile('Courier', 'Delivery mobile app only'),
              _SettingsTile('Real-time Notifications', 'Email, in-app, push'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityLogs() {
    return _PanelCard(
      title: 'Activity Logs',
      subtitle: 'Audit trail aktivitas superadmin dan admin cabang',
      child: Column(
        children: _activityLogs
            .map(
              (log) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                  child: Icon(log.icon, color: AppColors.primary),
                ),
                title: Text(log.title),
                subtitle: Text(log.subtitle),
                trailing: Text(
                  log.time,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSimpleManagementPage({
    required String title,
    required String subtitle,
    required String primaryAction,
    required VoidCallback onPrimaryAction,
    required List<String> columns,
    required List<List<Widget>> rows,
  }) {
    return Column(
      children: [
        _ManagementToolbar(
          title: title,
          subtitle: subtitle,
          primaryAction: primaryAction,
          onPrimaryAction: onPrimaryAction,
        ),
        const SizedBox(height: 18),
        _DataTablePanel(columns: columns, rows: rows),
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
              ..._activityLogs
                  .take(5)
                  .map(
                    (log) => ListTile(
                      leading: Icon(log.icon, color: AppColors.primary),
                      title: Text(log.title),
                      subtitle: Text(log.subtitle),
                    ),
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
      if (value != null) _showSnack('Menu profile: $value');
    });
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
                _openAdminForm,
              ),
              _QuickActionChip(
                'Create Promo',
                Icons.campaign_rounded,
                () => _openTextForm('Buat Promo', 'Judul promo'),
              ),
              _QuickActionChip(
                'Download Report',
                Icons.download_rounded,
                () => _showSnack('Report diunduh.'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBranchForm({_BranchData? branch}) {
    _openTextForm(
      branch == null ? 'Add Branch' : 'Edit Branch',
      branch?.name ?? 'Nama cabang',
    );
  }

  void _openAdminForm() {
    _openTextForm('Add Admin', 'Nama admin');
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
              _InfoRow(label: 'Orders', value: '${branch.orders}'),
              _InfoRow(label: 'Revenue', value: branch.revenue),
              _InfoRow(label: 'Performance', value: '${branch.performance}%'),
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
        ],
      ),
    );
  }

  void _showInfoDialog(String title, String value) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(value),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 780;
    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (secondaryActionLabel != null)
          OutlinedButton.icon(
            onPressed: onSecondaryAction,
            icon: const Icon(Icons.table_chart_rounded),
            label: Text(secondaryActionLabel!),
          ),
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
          childAspectRatio: count == 1 ? 2.4 : 1.45,
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
  const _BarChartMock();

  @override
  Widget build(BuildContext context) {
    const data = [42, 58, 46, 72, 66, 88, 94];
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul'];
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
                          heightFactor: data[index] / 100,
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
  const _LineChartMock();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: CustomPaint(
        painter: _LineChartPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE9ECEF)
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = [
      Offset(0, size.height * 0.72),
      Offset(size.width * 0.16, size.height * 0.58),
      Offset(size.width * 0.32, size.height * 0.62),
      Offset(size.width * 0.50, size.height * 0.40),
      Offset(size.width * 0.68, size.height * 0.34),
      Offset(size.width * 0.84, size.height * 0.24),
      Offset(size.width, size.height * 0.18),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
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
    for (final point in points) {
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

class _ActivityBranchTile extends StatelessWidget {
  const _ActivityBranchTile({required this.branch, required this.onTap});

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
  });

  final String title;
  final String subtitle;
  final String primaryAction;
  final VoidCallback onPrimaryAction;
  final List<Widget> filters;

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
            child: TextField(
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
  const _TableActions({this.onView, this.onEdit, this.onDeactivate});

  final VoidCallback? onView;
  final VoidCallback? onEdit;
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

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onTap, child: Text(label));
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

class _BranchData {
  const _BranchData({
    required this.code,
    required this.name,
    required this.region,
    required this.admin,
    required this.orders,
    required this.revenue,
    required this.performance,
    required this.status,
  });

  final String code;
  final String name;
  final String region;
  final String admin;
  final int orders;
  final String revenue;
  final int performance;
  final String status;
}

class _AdminData {
  const _AdminData({
    required this.name,
    required this.email,
    required this.branch,
    required this.role,
    required this.permission,
    required this.active,
  });

  final String name;
  final String email;
  final String branch;
  final String role;
  final String permission;
  final bool active;
}

class _CourierData {
  const _CourierData({
    required this.name,
    required this.phone,
    required this.area,
    required this.online,
    required this.completed,
    required this.rating,
  });

  final String name;
  final String phone;
  final String area;
  final bool online;
  final int completed;
  final double rating;
}

class _UserData {
  const _UserData({
    required this.name,
    required this.email,
    required this.phone,
    required this.orders,
    required this.points,
    required this.status,
  });

  final String name;
  final String email;
  final String phone;
  final int orders;
  final int points;
  final String status;
}

class _CategoryData {
  const _CategoryData({
    required this.name,
    required this.description,
    required this.products,
    required this.commission,
    required this.active,
  });

  final String name;
  final String description;
  final int products;
  final int commission;
  final bool active;
}

class _ProductMonitorData {
  const _ProductMonitorData({
    required this.name,
    required this.sku,
    required this.category,
    required this.branch,
    required this.stock,
    required this.sales,
    required this.status,
  });

  final String name;
  final String sku;
  final String category;
  final String branch;
  final int stock;
  final int sales;
  final String status;
}

class _OrderMonitorData {
  const _OrderMonitorData({
    required this.id,
    required this.customer,
    required this.branch,
    required this.courier,
    required this.total,
    required this.status,
  });

  final String id;
  final String customer;
  final String branch;
  final String courier;
  final String total;
  final String status;
}

class _PromotionData {
  const _PromotionData({
    required this.title,
    required this.code,
    required this.placement,
    required this.period,
    required this.ctr,
    required this.status,
  });

  final String title;
  final String code;
  final String placement;
  final String period;
  final double ctr;
  final String status;
}

class _ActivityLogData {
  const _ActivityLogData({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
}

const _branchSeed = <_BranchData>[
  _BranchData(
    code: 'BR-001',
    name: 'KDMP Sukamaju',
    region: 'Jawa Barat',
    admin: 'Rani Maharani',
    orders: 1280,
    revenue: 'Rp 482Jt',
    performance: 94,
    status: 'Active',
  ),
  _BranchData(
    code: 'BR-002',
    name: 'KDMP Sumber Rejeki',
    region: 'Jawa Tengah',
    admin: 'Agus Santoso',
    orders: 1118,
    revenue: 'Rp 397Jt',
    performance: 89,
    status: 'Active',
  ),
  _BranchData(
    code: 'BR-003',
    name: 'KDMP Maju Bersama',
    region: 'Jawa Timur',
    admin: 'Dewi Lestari',
    orders: 980,
    revenue: 'Rp 345Jt',
    performance: 82,
    status: 'Review',
  ),
  _BranchData(
    code: 'BR-004',
    name: 'KDMP Harapan Desa',
    region: 'Sumatera',
    admin: 'Fajar Hidayat',
    orders: 744,
    revenue: 'Rp 224Jt',
    performance: 76,
    status: 'Suspended',
  ),
  _BranchData(
    code: 'BR-005',
    name: 'KDMP Tani Makmur',
    region: 'Jawa Barat',
    admin: 'Nadia Putri',
    orders: 1322,
    revenue: 'Rp 501Jt',
    performance: 96,
    status: 'Active',
  ),
];

const _adminSeed = <_AdminData>[
  _AdminData(
    name: 'Rani Maharani',
    email: 'rani@mepupoin.com',
    branch: 'KDMP Sukamaju',
    role: 'Branch Admin',
    permission: 'Full Branch',
    active: true,
  ),
  _AdminData(
    name: 'Agus Santoso',
    email: 'agus@mepupoin.com',
    branch: 'KDMP Sumber Rejeki',
    role: 'Branch Admin',
    permission: 'Orders + Products',
    active: true,
  ),
  _AdminData(
    name: 'Dewi Lestari',
    email: 'dewi@mepupoin.com',
    branch: 'KDMP Maju Bersama',
    role: 'Finance Admin',
    permission: 'Finance Only',
    active: true,
  ),
  _AdminData(
    name: 'Bima Saputra',
    email: 'bima@mepupoin.com',
    branch: 'KDMP Harapan Desa',
    role: 'Operator',
    permission: 'Read Only',
    active: false,
  ),
];

const _courierSeed = <_CourierData>[
  _CourierData(
    name: 'Joko Prasetyo',
    phone: '+62 812 1111 2222',
    area: 'Sukamaju',
    online: true,
    completed: 482,
    rating: 4.8,
  ),
  _CourierData(
    name: 'Yudi Saputra',
    phone: '+62 813 2222 3333',
    area: 'Sumber Rejeki',
    online: true,
    completed: 390,
    rating: 4.6,
  ),
  _CourierData(
    name: 'Rizal Ahmad',
    phone: '+62 857 4444 5555',
    area: 'Maju Bersama',
    online: false,
    completed: 244,
    rating: 4.4,
  ),
];

const _userSeed = <_UserData>[
  _UserData(
    name: 'Budi Santoso',
    email: 'budi@email.com',
    phone: '+62 812 3456 7890',
    orders: 18,
    points: 1250,
    status: 'Active',
  ),
  _UserData(
    name: 'Siti Aminah',
    email: 'siti@email.com',
    phone: '+62 811 9988 7766',
    orders: 11,
    points: 840,
    status: 'Active',
  ),
  _UserData(
    name: 'Hendra Wijaya',
    email: 'hendra@email.com',
    phone: '+62 856 3322 1100',
    orders: 4,
    points: 120,
    status: 'Review',
  ),
];

const _categorySeed = <_CategoryData>[
  _CategoryData(
    name: 'Sembako',
    description: 'Kebutuhan pokok harian',
    products: 3420,
    commission: 2,
    active: true,
  ),
  _CategoryData(
    name: 'Alat Pertanian',
    description: 'Produk tani dan pupuk',
    products: 980,
    commission: 3,
    active: true,
  ),
  _CategoryData(
    name: 'Elektronik',
    description: 'Perangkat pendukung UMKM',
    products: 740,
    commission: 5,
    active: true,
  ),
  _CategoryData(
    name: 'Rumah Tangga',
    description: 'Peralatan rumah desa',
    products: 1180,
    commission: 4,
    active: false,
  ),
];

const _productSeed = <_ProductMonitorData>[
  _ProductMonitorData(
    name: 'Beras Premium 5kg',
    sku: 'SKU-RICE-5KG',
    category: 'Sembako',
    branch: 'KDMP Sukamaju',
    stock: 240,
    sales: 1820,
    status: 'Active',
  ),
  _ProductMonitorData(
    name: 'Pupuk Organik 10kg',
    sku: 'SKU-FERT-10',
    category: 'Alat Pertanian',
    branch: 'KDMP Tani Makmur',
    stock: 84,
    sales: 642,
    status: 'Active',
  ),
  _ProductMonitorData(
    name: 'Minyak Goreng 2L',
    sku: 'SKU-OIL-2L',
    category: 'Sembako',
    branch: 'KDMP Sumber Rejeki',
    stock: 42,
    sales: 1320,
    status: 'Review',
  ),
  _ProductMonitorData(
    name: 'Power Bank 10.000mAh',
    sku: 'SKU-PWR-10K',
    category: 'Elektronik',
    branch: 'KDMP Maju Bersama',
    stock: 8,
    sales: 214,
    status: 'Flagged',
  ),
];

const _orderSeed = <_OrderMonitorData>[
  _OrderMonitorData(
    id: '#ORD-20260614-001',
    customer: 'Budi Santoso',
    branch: 'KDMP Sukamaju',
    courier: 'Joko Prasetyo',
    total: 'Rp 156.000',
    status: 'Processing',
  ),
  _OrderMonitorData(
    id: '#ORD-20260614-002',
    customer: 'Siti Aminah',
    branch: 'KDMP Tani Makmur',
    courier: 'Yudi Saputra',
    total: 'Rp 284.000',
    status: 'Shipped',
  ),
  _OrderMonitorData(
    id: '#ORD-20260613-119',
    customer: 'Hendra Wijaya',
    branch: 'KDMP Maju Bersama',
    courier: 'Rizal Ahmad',
    total: 'Rp 74.000',
    status: 'Delivered',
  ),
];

const _promotionSeed = <_PromotionData>[
  _PromotionData(
    title: 'Diskon 50% Pupuk',
    code: 'PUPUK50',
    placement: 'Home Banner',
    period: '14-30 Jun',
    ctr: 12.4,
    status: 'Active',
  ),
  _PromotionData(
    title: 'Gratis Ongkir Desa',
    code: 'ONGKIRHEMAT',
    placement: 'Checkout',
    period: '10-25 Jun',
    ctr: 9.8,
    status: 'Active',
  ),
  _PromotionData(
    title: 'Double Points Weekend',
    code: 'DOUBLEPTS',
    placement: 'Wallet',
    period: 'Draft',
    ctr: 0,
    status: 'Draft',
  ),
];

const _activityLogs = <_ActivityLogData>[
  _ActivityLogData(
    title: 'Branch status updated',
    subtitle: 'KDMP Harapan Desa marked as suspended',
    time: '5m ago',
    icon: Icons.storefront_rounded,
  ),
  _ActivityLogData(
    title: 'New admin assigned',
    subtitle: 'Rani assigned to KDMP Sukamaju',
    time: '18m ago',
    icon: Icons.admin_panel_settings_rounded,
  ),
  _ActivityLogData(
    title: 'Payment settlement completed',
    subtitle: 'Rp 512Jt payout queued',
    time: '1h ago',
    icon: Icons.payments_rounded,
  ),
  _ActivityLogData(
    title: 'Promotion published',
    subtitle: 'PUPUK50 banner is now live',
    time: '2h ago',
    icon: Icons.campaign_rounded,
  ),
];
