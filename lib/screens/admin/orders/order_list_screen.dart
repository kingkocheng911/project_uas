import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../branch_admin_repository.dart';
import 'admin_order_models.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  static const _primary = Color(0xFFD9001B);
  static const _background = Color(0xFFF7F9FB);
  static const _muted = Color(0xFF6D5A58);

  final SupabaseClient _client = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  final BranchAdminRepository _repository = BranchAdminRepository();

  List<AdminOrder> _orders = const [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedFilter = 'semua';
  String? _branchName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders({bool refresh = false}) async {
    if (!mounted) return;
    setState(() {
      if (refresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('Admin belum login ke Supabase.');
      }

      final assignment = await _repository.loadAssignment().timeout(
        const Duration(seconds: 12),
        onTimeout: () =>
            throw Exception('Waktu memuat data cabang habis. Coba muat ulang.'),
      );

      final rows = await _repository
          .loadBranchOrders(assignment.branchId)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw Exception('Waktu memuat pesanan habis. Coba muat ulang.'),
          );

      final orders = rows
          .map<AdminOrder>((row) => AdminOrder.fromRow(row))
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _branchName = assignment.name;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _openOrderDetail(AdminOrder order) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
    );
    if (changed == true) {
      await _loadOrders(refresh: true);
    }
  }

  List<AdminOrder> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();
    return _orders
        .where((order) {
          final matchesFilter = _matchesFilter(order);
          final haystack = [
            order.orderNo,
            order.customerName,
            order.customerPhone,
            order.statusLabel,
          ].join(' ').toLowerCase();
          final matchesQuery = query.isEmpty || haystack.contains(query);
          return matchesFilter && matchesQuery;
        })
        .toList(growable: false);
  }

  bool _matchesFilter(AdminOrder order) {
    switch (_selectedFilter) {
      case 'processing':
        return order.orderStatus == 'confirmed' ||
            order.orderStatus == 'processing';
      case 'semua':
        return true;
      default:
        return order.orderStatus == _selectedFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _filteredOrders;
    final pendingCount = _orders
        .where((order) => order.orderStatus == 'pending')
        .length;
    final processingCount = _orders
        .where(
          (order) =>
              order.orderStatus == 'confirmed' ||
              order.orderStatus == 'processing',
        )
        .length;
    final shippingCount = _orders
        .where(
          (order) =>
              order.orderStatus == 'out_for_delivery' ||
              order.orderStatus == 'ready_pickup',
        )
        .length;
    final completedCount = _orders
        .where((order) => order.orderStatus == 'completed')
        .length;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadOrders(refresh: true),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pesanan Cabang',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _branchName == null
                            ? 'Kelola order pelanggan yang masuk ke cabang.'
                            : 'Pantau order pelanggan untuk $_branchName.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: _muted),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Cari nomor order atau nama pelanggan',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 132,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _SummaryCard(
                              title: 'Pending',
                              value: '$pendingCount',
                              color: const Color(0xFFF57C00),
                              icon: Icons.schedule_rounded,
                            ),
                            _SummaryCard(
                              title: 'Diproses',
                              value: '$processingCount',
                              color: const Color(0xFF1565C0),
                              icon: Icons.inventory_2_rounded,
                            ),
                            _SummaryCard(
                              title: 'Pickup/Dikirim',
                              value: '$shippingCount',
                              color: const Color(0xFF2E7D32),
                              icon: Icons.local_shipping_rounded,
                            ),
                            _SummaryCard(
                              title: 'Selesai',
                              value: '$completedCount',
                              color: const Color(0xFF00897B),
                              icon: Icons.check_circle_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _FilterChip(
                            label: 'Semua',
                            selected: _selectedFilter == 'semua',
                            onTap: () =>
                                setState(() => _selectedFilter = 'semua'),
                          ),
                          _FilterChip(
                            label: 'Pending',
                            selected: _selectedFilter == 'pending',
                            onTap: () =>
                                setState(() => _selectedFilter = 'pending'),
                          ),
                          _FilterChip(
                            label: 'Diproses',
                            selected: _selectedFilter == 'processing',
                            onTap: () =>
                                setState(() => _selectedFilter = 'processing'),
                          ),
                          _FilterChip(
                            label: 'Pickup',
                            selected: _selectedFilter == 'ready_pickup',
                            onTap: () => setState(
                              () => _selectedFilter = 'ready_pickup',
                            ),
                          ),
                          _FilterChip(
                            label: 'Dikirim',
                            selected: _selectedFilter == 'out_for_delivery',
                            onTap: () => setState(
                              () => _selectedFilter = 'out_for_delivery',
                            ),
                          ),
                          _FilterChip(
                            label: 'Selesai',
                            selected: _selectedFilter == 'completed',
                            onTap: () =>
                                setState(() => _selectedFilter = 'completed'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(
                    message: _errorMessage!,
                    onRetry: _loadOrders,
                  ),
                )
              else if (filteredOrders.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    isSearching:
                        _searchController.text.trim().isNotEmpty ||
                        _selectedFilter != 'semua',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList.builder(
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _OrderListCard(
                          order: order,
                          onTap: () => _openOrderDetail(order),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _primary,
        onPressed: _isRefreshing ? null : () => _loadOrders(refresh: true),
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        label: const Text(
          'Muat Ulang',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD9001B) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFFD9001B) : const Color(0xFFE8BCB8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6D5A58),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OrderListCard extends StatelessWidget {
  const _OrderListCard({required this.order, required this.onTap});

  final AdminOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = orderStatusColor(order.orderStatus);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8BCB8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      orderStatusIcon(order.orderStatus),
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.orderNo,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF6D5A58)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaPill(
                    icon: Icons.shopping_bag_outlined,
                    label: order.typeLabel,
                  ),
                  _MetaPill(
                    icon: Icons.schedule_outlined,
                    label: formatShortDate(order.placedAt),
                  ),
                  _MetaPill(
                    icon: Icons.payments_outlined,
                    label: order.paymentLabel,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _InfoBlock(
                      label: 'Jumlah Item',
                      value: '${order.totalItemQuantity} item',
                    ),
                  ),
                  Expanded(
                    child: _InfoBlock(
                      label: 'Total Belanja',
                      value: formatCurrency(order.grandTotal),
                      highlight: true,
                    ),
                  ),
                ],
              ),
              if (order.isDelivery) ...[
                const SizedBox(height: 12),
                Text(
                  order.destinationLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6D5A58),
                    height: 1.35,
                  ),
                ),
              ],
              if (order.courierName != null &&
                  order.courierName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Kurir: ${order.courierName} ${order.courierPhone == null ? '' : '(${order.courierPhone})'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF2E7D32),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Lihat Detail & Proses'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD9001B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4F4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6D5A58)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6D5A58),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6D5A58)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: highlight ? const Color(0xFFD9001B) : null,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Color(0xFFD9001B),
            ),
            const SizedBox(height: 12),
            Text(
              'Pesanan belum bisa dimuat',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6D5A58)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD9001B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 58,
              color: Color(0xFFD9001B),
            ),
            const SizedBox(height: 14),
            Text(
              isSearching
                  ? 'Pesanan tidak ditemukan'
                  : 'Belum ada pesanan masuk',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Coba ubah pencarian atau filter status.'
                  : 'Begitu pelanggan checkout, order cabang akan muncul di sini.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6D5A58)),
            ),
          ],
        ),
      ),
    );
  }
}
