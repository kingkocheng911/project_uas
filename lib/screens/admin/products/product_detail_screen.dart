import 'package:flutter/material.dart';

import '../branch_admin_repository.dart';
import '../orders/admin_order_models.dart';
import 'edit_product_screen.dart';
import 'stock_management_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final BranchAdminProduct product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final BranchAdminRepository _repository = BranchAdminRepository();
  late final BranchAdminProduct _product = widget.product;
  bool _isArchiving = false;

  Future<void> _editProduct() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditProductScreen(product: _product)),
    );
    if (changed == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openStock() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StockManagementScreen(
          initialBranchProductId: _product.branchProductId,
        ),
      ),
    );
    if (changed == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _archiveProduct() async {
    if (_isArchiving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sembunyikan produk?'),
          content: const Text(
            'Produk akan dinonaktifkan dari cabang ini dan tidak tampil di aplikasi pelanggan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Nonaktifkan'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isArchiving = true);
    try {
      await _repository.archiveProduct(_product.branchProductId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menonaktifkan produk: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isArchiving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockTone = _product.isLowStock
        ? const Color(0xFFD9001B)
        : const Color(0xFF1A7F42);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Produk'),
        actions: [
          IconButton(
            onPressed: _editProduct,
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _boxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _product.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatCurrency(_product.sellingPrice),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFFD9001B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (_product.originalPrice > _product.sellingPrice) ...[
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(_product.originalPrice),
                    style: const TextStyle(
                      color: Color(0xFF6D5A58),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _pill(_product.categoryLabel, Icons.category_outlined),
                    _pill(
                      '${_product.stockOnHand} ${_product.unit}',
                      Icons.inventory_2_outlined,
                    ),
                    _pill(
                      _product.isActive ? 'Aktif' : 'Nonaktif',
                      Icons.visibility_outlined,
                    ),
                    if (_product.isFeatured)
                      _pill('Unggulan', Icons.star_rounded),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _boxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Operasional',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        label: 'Stok Sekarang',
                        value: '${_product.stockOnHand}',
                        tone: stockTone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        label: 'Alert Minimum',
                        value: '${_product.effectiveMinStockAlert}',
                        tone: const Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _infoRow(
                  'Brand',
                  _product.brand.isEmpty ? '-' : _product.brand,
                ),
                _infoRow('Satuan', _product.unit),
                _infoRow(
                  'Badge',
                  _product.badge.isEmpty ? '-' : _product.badge,
                ),
                _infoRow(
                  'Terakhir diperbarui',
                  formatShortDate(_product.updatedAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _boxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deskripsi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _product.description.isEmpty
                      ? 'Belum ada deskripsi produk.'
                      : _product.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openStock,
                  icon: const Icon(Icons.inventory_rounded),
                  label: const Text('Kelola Stok'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _editProduct,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD9001B),
                  ),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit Produk'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _isArchiving ? null : _archiveProduct,
            icon: const Icon(Icons.visibility_off_outlined),
            label: const Text('Nonaktifkan produk dari cabang ini'),
          ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE8BCB8)),
    );
  }

  Widget _pill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFD9001B)),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color tone,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: tone,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6D5A58)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
