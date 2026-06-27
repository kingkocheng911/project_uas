import 'package:flutter/material.dart';
import '../../../services/order_service.dart';
import 'admin_order_models.dart';
import 'order_invoice_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final AdminOrder order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  static const _primary = Color(0xFFD9001B);
  final OrderService _orderService = OrderService();

  late AdminOrder _order = widget.order;
  bool _isSaving = false;

  Future<void> _changeStatus(String nextStatus) async {
    if (_isSaving || nextStatus == _order.orderStatus) return;

    String? courierName = _order.courierName;
    String? courierPhone = _order.courierPhone;

    if (_order.isDelivery && nextStatus == 'out_for_delivery') {
      final courier = await _showCourierSheet(
        initialName: _order.courierName,
        initialPhone: _order.courierPhone,
      );
      if (courier == null) return;
      courierName = courier.$1;
      courierPhone = courier.$2;
    }

    setState(() => _isSaving = true);
    try {
      final result = await _orderService.updateBranchOrderStatus(
        orderId: _order.id,
        nextStatus: nextStatus,
        courierName: courierName,
        courierPhone: courierPhone,
      );

      if (!mounted) return;
      setState(() {
        _order = _order.copyWith(
          orderStatus: result.orderStatus,
          paymentStatus: result.paymentStatus,
          courierName: result.courierName,
          courierPhone: result.courierPhone,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status order diubah menjadi ${_order.statusLabel}.'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui order: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<(String, String?)?> _showCourierSheet({
    String? initialName,
    String? initialPhone,
  }) async {
    final nameController = TextEditingController(text: initialName ?? '');
    final phoneController = TextEditingController(text: initialPhone ?? '');

    final result = await showModalBottomSheet<(String, String?)>(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Kurir Pengantaran',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sebelum status menjadi dikirim, admin perlu menetapkan kurir.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama kurir',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor kurir',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.of(
                      context,
                    ).pop((name, phone.isEmpty ? null : phone));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Simpan Kurir'),
                ),
              ),
            ],
          ),
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = orderStatusColor(_order.orderStatus);
    final statusOptions = availableStatusesFor(_order);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Detail Pesanan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _boxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _order.orderNo,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_order.typeLabel} - ${formatShortDate(_order.placedAt)}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF6D5A58)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _order.statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: 'Informasi Pelanggan'),
                const SizedBox(height: 10),
                _InfoTile(
                  icon: Icons.person_outline_rounded,
                  title: _order.customerName,
                  subtitle: _order.customerPhone.isEmpty
                      ? 'Nomor belum tersedia'
                      : _order.customerPhone,
                ),
                const SizedBox(height: 8),
                _InfoTile(
                  icon: _order.isPickup
                      ? Icons.storefront_rounded
                      : Icons.location_on_outlined,
                  title: _order.isPickup
                      ? 'Metode Pickup'
                      : 'Alamat Pengiriman',
                  subtitle: _order.destinationLabel,
                ),
                if (_order.isDelivery) ...[
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.local_shipping_outlined,
                    title: (_order.courierName ?? '').isEmpty
                        ? 'Kurir belum dipilih'
                        : _order.courierName!,
                    subtitle: (_order.courierPhone ?? '').isEmpty
                        ? 'Tetapkan kurir saat status dikirim.'
                        : _order.courierPhone!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _boxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Produk Pesanan'),
                const SizedBox(height: 12),
                ..._order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.qty} x ${formatCurrency(item.unitPrice)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: const Color(0xFF6D5A58)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatCurrency(item.subtotal),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _boxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Ringkasan Pembayaran'),
                const SizedBox(height: 12),
                _PriceRow(
                  title: 'Subtotal',
                  value: formatCurrency(_order.subtotal),
                ),
                _PriceRow(
                  title: 'Ongkir',
                  value: formatCurrency(_order.deliveryFee),
                ),
                _PriceRow(
                  title: 'Diskon',
                  value: formatCurrency(-_order.discountTotal),
                ),
                const Divider(height: 24),
                _PriceRow(
                  title: 'Total',
                  value: formatCurrency(_order.grandTotal),
                  bold: true,
                ),
                const SizedBox(height: 10),
                _InfoTile(
                  icon: Icons.payments_outlined,
                  title: 'Status Pembayaran',
                  subtitle: _order.paymentLabel,
                  dense: true,
                ),
                if ((_order.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.sticky_note_2_outlined,
                    title: 'Catatan',
                    subtitle: _order.notes!,
                    dense: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: _boxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Aksi Admin'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: statusOptions.map((status) {
                    final selected = status == _order.orderStatus;
                    return ChoiceChip(
                      label: Text(_statusLabel(status)),
                      selected: selected,
                      onSelected: selected || _isSaving
                          ? null
                          : (_) => _changeStatus(status),
                    );
                  }).toList(),
                ),
                if (_order.isDelivery &&
                    _order.orderStatus == 'processing' &&
                    ((_order.courierName ?? '').isEmpty)) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Sebelum status menjadi dikirim, admin harus memilih kurir.',
                    style: TextStyle(
                      color: Color(0xFF6D5A58),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderInvoiceScreen(order: _order),
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Invoice'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving || !_canRunPrimaryAction()
                      ? null
                      : () => _changeStatus(_nextSuggestedStatus()),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: Text(_nextSuggestedAction()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _nextSuggestedAction() {
    if (!_canRunPrimaryAction()) return 'Tidak Ada Aksi';
    final nextStatus = _nextSuggestedStatus();
    switch (nextStatus) {
      case 'confirmed':
        return 'Konfirmasi';
      case 'processing':
        return 'Mulai Proses';
      case 'ready_pickup':
        return 'Siap Pickup';
      case 'out_for_delivery':
        return 'Kirim Pesanan';
      case 'completed':
        return 'Selesaikan';
      default:
        return 'Simpan';
    }
  }

  String _nextSuggestedStatus() {
    switch (_order.orderStatus) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'processing';
      case 'processing':
        return _order.isPickup ? 'ready_pickup' : 'out_for_delivery';
      case 'ready_pickup':
      case 'out_for_delivery':
        return 'completed';
      default:
        return _order.orderStatus;
    }
  }

  bool _canRunPrimaryAction() {
    return _order.orderStatus != 'completed' &&
        _order.orderStatus != 'cancelled';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Konfirmasi';
      case 'processing':
        return 'Diproses';
      case 'ready_pickup':
        return 'Siap Pickup';
      case 'out_for_delivery':
        return 'Dikirim';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Batal';
      default:
        return status;
    }
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE8BCB8)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x11000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
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
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.dense = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: dense ? 38 : 42,
          height: dense ? 38 : 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEFEF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFD9001B),
            size: dense ? 18 : 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6D5A58),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.title,
    required this.value,
    this.bold = false,
  });

  final String title;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF6D5A58),
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: bold ? const Color(0xFFD9001B) : null,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
