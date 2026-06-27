import 'package:flutter/material.dart';

import '../branch_admin_repository.dart';
import '../orders/admin_order_models.dart';

class RevenueReportScreen extends StatefulWidget {
  const RevenueReportScreen({super.key});

  @override
  State<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
  final BranchAdminRepository _repository = BranchAdminRepository();

  bool _isLoading = true;
  String? _errorMessage;
  late DateTime _fromDate;
  late DateTime _toDate;
  BranchReportSummary? _summary;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, now.day);
    _toDate = _fromDate;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final summary = await _repository.loadReportSummary(
        from: _fromDate,
        to: _toDate,
      );
      if (!mounted) return;
      setState(() => _summary = summary);
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

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
    );
    if (picked == null) return;
    setState(() {
      _fromDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      _toDate = DateTime(picked.end.year, picked.end.month, picked.end.day);
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Laporan Cabang'),
        actions: [
          IconButton(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range_rounded),
            tooltip: 'Pilih rentang tanggal',
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: Color(0xFFD9001B),
          ),
          const SizedBox(height: 12),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _load,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD9001B),
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      );
    }

    final summary = _summary;
    if (summary == null) {
      return ListView(
        children: const [
          SizedBox(height: 220),
          Center(child: Text('Data laporan belum tersedia.')),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD9001B), Color(0xFF8B0011)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.branchName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatDate(summary.from)} - ${_formatDate(summary.to)}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _heroStat(
                      label: 'Omzet',
                      value: formatCurrency(summary.grossRevenue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _heroStat(
                      label: 'Transaksi',
                      value: '${summary.dailyTransactions}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.04,
          children: [
            _metricCard(
              title: 'Penjualan',
              value: '${summary.dailySales}',
              subtitle: 'Item terjual pada periode ini',
              tone: const Color(0xFF1565C0),
              icon: Icons.shopping_bag_rounded,
            ),
            _metricCard(
              title: 'Order Masuk',
              value: '${summary.dailyTransactions}',
              subtitle: 'Total transaksi tercatat',
              tone: const Color(0xFFD9001B),
              icon: Icons.receipt_long_rounded,
            ),
            _metricCard(
              title: 'Order Selesai',
              value: '${summary.completedTransactions}',
              subtitle: 'Transaksi completed',
              tone: const Color(0xFF1A7F42),
              icon: Icons.check_circle_rounded,
            ),
            _metricCard(
              title: 'Rata-rata Order',
              value: summary.dailyTransactions == 0
                  ? formatCurrency(0)
                  : formatCurrency(
                      (summary.grossRevenue / summary.dailyTransactions)
                          .round(),
                    ),
              subtitle: 'Nilai rata-rata per transaksi',
              tone: const Color(0xFFC47A00),
              icon: Icons.payments_rounded,
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
                'Produk Terlaris',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              if (summary.topProducts.isEmpty)
                const Text('Belum ada penjualan pada periode ini.')
              else
                ...summary.topProducts.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _topProductTile(
                      rank: entry.key + 1,
                      product: entry.value,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroStat({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color tone,
    required IconData icon,
  }) {
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
              style: const TextStyle(fontSize: 12, color: Color(0xFF6D5A58)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topProductTile({
    required int rank,
    required BranchTopProduct product,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4F3),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFE9E6),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Color(0xFFD9001B),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.totalQty} item terjual',
                  style: const TextStyle(
                    color: Color(0xFF6D5A58),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatCurrency(product.totalRevenue),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year;
    return '$day/$month/$year';
  }
}
