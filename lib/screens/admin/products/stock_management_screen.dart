import 'package:flutter/material.dart';

import '../branch_admin_repository.dart';
import '../orders/admin_order_models.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({
    super.key,
    this.initialBranchProductId,
  });

  final String? initialBranchProductId;

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  final BranchAdminRepository _repository = BranchAdminRepository();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  BranchStockSnapshot? _snapshot;

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
      final snapshot = await _repository.loadStockSnapshot();
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openAdjustStock(BranchAdminProduct product) async {
    final qtyController = TextEditingController();
    final notesController = TextEditingController();
    var selectedType = 'purchase';

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sesuaikan Stok',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(product.name),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: _decoration('Jenis mutasi'),
                    items: const [
                      DropdownMenuItem(value: 'purchase', child: Text('Restock')),
                      DropdownMenuItem(
                        value: 'adjustment_in',
                        child: Text('Penyesuaian masuk'),
                      ),
                      DropdownMenuItem(
                        value: 'adjustment_out',
                        child: Text('Penyesuaian keluar'),
                      ),
                      DropdownMenuItem(value: 'return', child: Text('Retur')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => selectedType = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: _decoration('Jumlah perubahan'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: _decoration('Catatan'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final parsed = int.tryParse(qtyController.text.trim());
                        if (parsed == null || parsed <= 0) return;
                        final qtyChange = selectedType == 'adjustment_out' ? -parsed : parsed;
                        Navigator.of(context).pop(
                          await _submitAdjustment(
                            product: product,
                            movementType: selectedType,
                            qtyChange: qtyChange,
                            notes: notesController.text.trim(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD9001B),
                      ),
                      child: const Text('Simpan Mutasi'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    qtyController.dispose();
    notesController.dispose();

    if (changed == true) {
      await _load();
    }
  }

  Future<bool> _submitAdjustment({
    required BranchAdminProduct product,
    required String movementType,
    required int qtyChange,
    required String notes,
  }) async {
    if (_isSaving) return false;

    setState(() => _isSaving = true);
    try {
      await _repository.adjustStock(
        branchProductId: product.branchProductId,
        qtyChange: qtyChange,
        movementType: movementType,
        notes: notes.isEmpty ? null : notes,
      );
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mutasi stok berhasil disimpan.')),
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui stok: $error')),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final products = List<BranchAdminProduct>.from(
      snapshot?.products ?? const <BranchAdminProduct>[],
    );
    final initialId = widget.initialBranchProductId;
    if (initialId != null && initialId.isNotEmpty) {
      products.sort((a, b) {
        if (a.branchProductId == initialId) return -1;
        if (b.branchProductId == initialId) return 1;
        return a.name.compareTo(b.name);
      });
    }
    final lowStockCount = products.where((product) => product.isLowStock).length;
    final totalUnits = products.fold<int>(0, (sum, product) => sum + product.stockOnHand);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Manajemen Stok'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ListView(
                    children: [
                      const SizedBox(height: 160),
                      Center(child: Text(_errorMessage!)),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _summaryCard(
                              'Total Unit',
                              '$totalUnits',
                              Icons.inventory_2_rounded,
                              const Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryCard(
                              'Low Stock',
                              '$lowStockCount',
                              Icons.warning_amber_rounded,
                              const Color(0xFFD9001B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Daftar Produk Cabang',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...products.map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(fontWeight: FontWeight.w800),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(product.categoryLabel),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: product.isLowStock
                                            ? const Color(0xFFFFE9E6)
                                            : const Color(0xFFDFF5E8),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        product.isLowStock ? 'Low Stock' : 'Aman',
                                        style: TextStyle(
                                          color: product.isLowStock
                                              ? const Color(0xFFD9001B)
                                              : const Color(0xFF1A7F42),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _stockMeta(
                                        'Stok',
                                        '${product.stockOnHand} ${product.unit}',
                                      ),
                                    ),
                                    Expanded(
                                      child: _stockMeta(
                                        'Minimum',
                                        '${product.effectiveMinStockAlert}',
                                      ),
                                    ),
                                    Expanded(
                                      child: _stockMeta(
                                        'Harga',
                                        formatCurrency(product.sellingPrice),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isSaving
                                        ? null
                                        : () => _openAdjustStock(product),
                                    icon: const Icon(Icons.sync_alt_rounded),
                                    label: const Text('Sesuaikan Stok'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Riwayat Mutasi',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...?snapshot?.movements.map(
                        (movement) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: Color(0xFFE8BCB8)),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: movement.tone.withValues(alpha: 0.12),
                              child: Text(
                                movement.qtyChange >= 0
                                    ? '+${movement.qtyChange}'
                                    : '${movement.qtyChange}',
                                style: TextStyle(
                                  color: movement.tone,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(movement.productName),
                            subtitle: Text(
                              '${movement.label} • ${formatShortDate(movement.createdAt)}'
                              '${movement.notes == null ? '' : '\n${movement.notes}'}',
                            ),
                            trailing: Text(
                              '${movement.qtyBefore} -> ${movement.qtyAfter}',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8F6F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color tone) {
    return Container(
      padding: const EdgeInsets.all(18),
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
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }

  Widget _stockMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6D5A58)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
