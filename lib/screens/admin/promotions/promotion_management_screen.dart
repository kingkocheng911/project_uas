import 'package:flutter/material.dart';

import '../branch_admin_repository.dart';
import '../orders/admin_order_models.dart';

class PromotionManagementScreen extends StatefulWidget {
  const PromotionManagementScreen({super.key});

  @override
  State<PromotionManagementScreen> createState() =>
      _PromotionManagementScreenState();
}

class _PromotionManagementScreenState extends State<PromotionManagementScreen> {
  final BranchAdminRepository _repository = BranchAdminRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<BranchPromotion> _promotions = const [];

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
      final promotions = await _repository.loadPromotions();
      if (!mounted) return;
      setState(() => _promotions = promotions);
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

  Future<void> _openEditor([BranchPromotion? promotion]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _PromotionEditorSheet(repository: _repository, promotion: promotion),
    );
    if (result == true) {
      await _load();
    }
  }

  Future<void> _togglePromotion(BranchPromotion promotion) async {
    try {
      await _repository.togglePromotion(
        promotionId: promotion.id,
        isActive: !promotion.isActive,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            promotion.isActive ? 'Promo dinonaktifkan.' : 'Promo diaktifkan.',
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status promo: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _promotions.where((item) => item.isActive).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Promo Cabang'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD9001B),
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Promo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(activeCount)),
    );
  }

  Widget _buildBody(int activeCount) {
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
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Promo Aktif',
                value: '$activeCount',
                tone: const Color(0xFF1A7F42),
                icon: Icons.local_offer_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                title: 'Total Promo',
                value: '${_promotions.length}',
                tone: const Color(0xFF1565C0),
                icon: Icons.campaign_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_promotions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 96),
              child: Text('Belum ada promo cabang.'),
            ),
          )
        else
          ..._promotions.map(
            (promotion) => Padding(
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
                          child: Text(
                            promotion.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Switch(
                          value: promotion.isActive,
                          activeThumbColor: const Color(0xFFD9001B),
                          onChanged: (_) => _togglePromotion(promotion),
                        ),
                      ],
                    ),
                    if (promotion.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        promotion.description,
                        style: const TextStyle(color: Color(0xFF6D5A58)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _infoChip(_formatDiscount(promotion)),
                        _infoChip(
                          'Min belanja ${formatCurrency(promotion.minPurchase ?? 0)}',
                        ),
                        _infoChip(
                          '${_formatDate(promotion.startAt)} - ${_formatDate(promotion.endAt)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _openEditor(promotion),
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Ubah Promo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 96),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
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
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6D5A58),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDiscount(BranchPromotion promotion) {
    if (promotion.promoType == 'nominal') {
      return 'Potongan ${formatCurrency(promotion.discountValue)}';
    }
    final maxDiscount = promotion.maxDiscount == null
        ? ''
        : ' maks ${formatCurrency(promotion.maxDiscount!)}';
    return '${promotion.discountValue}%$maxDiscount';
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year;
    return '$day/$month/$year';
  }
}

class _PromotionEditorSheet extends StatefulWidget {
  const _PromotionEditorSheet({required this.repository, this.promotion});

  final BranchAdminRepository repository;
  final BranchPromotion? promotion;

  @override
  State<_PromotionEditorSheet> createState() => _PromotionEditorSheetState();
}

class _PromotionEditorSheetState extends State<_PromotionEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _discountController;
  late final TextEditingController _minPurchaseController;
  late final TextEditingController _maxDiscountController;

  bool _isSaving = false;
  late String _promoType;
  late bool _isActive;
  late DateTime _startAt;
  late DateTime _endAt;

  @override
  void initState() {
    super.initState();
    final promotion = widget.promotion;
    _titleController = TextEditingController(text: promotion?.title ?? '');
    _descriptionController = TextEditingController(
      text: promotion?.description ?? '',
    );
    _discountController = TextEditingController(
      text: promotion == null ? '' : '${promotion.discountValue}',
    );
    _minPurchaseController = TextEditingController(
      text: promotion?.minPurchase == null ? '' : '${promotion!.minPurchase}',
    );
    _maxDiscountController = TextEditingController(
      text: promotion?.maxDiscount == null ? '' : '${promotion!.maxDiscount}',
    );
    _promoType = promotion?.promoType == 'nominal' ? 'nominal' : 'percentage';
    _isActive = promotion?.isActive ?? true;
    _startAt = promotion?.startAt ?? DateTime.now();
    _endAt = promotion?.endAt ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _minPurchaseController.dispose();
    _maxDiscountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startAt : _endAt;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDate: initial,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startAt = DateTime(picked.year, picked.month, picked.day, 0, 0);
        if (_endAt.isBefore(_startAt)) {
          _endAt = _startAt.add(const Duration(days: 1));
        }
      } else {
        _endAt = DateTime(picked.year, picked.month, picked.day, 23, 59);
      }
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final discountValue = int.tryParse(_discountController.text.trim());
    final minPurchase = int.tryParse(_minPurchaseController.text.trim());
    final maxDiscount = int.tryParse(_maxDiscountController.text.trim());

    if (title.isEmpty || discountValue == null || discountValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi judul promo dan nilai diskon yang valid.'),
        ),
      );
      return;
    }

    if (_endAt.isBefore(_startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal akhir promo harus setelah tanggal mulai.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.repository.upsertPromotion(
        promotionId: widget.promotion?.id,
        title: title,
        description: _descriptionController.text.trim(),
        promoType: _promoType,
        discountValue: discountValue,
        minPurchase: minPurchase,
        maxDiscount: _promoType == 'percentage' ? maxDiscount : null,
        startAt: _startAt,
        endAt: _endAt,
        isActive: _isActive,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan promo: $error')));
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
              widget.promotion == null ? 'Tambah Promo' : 'Ubah Promo',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul promo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _promoType,
              decoration: const InputDecoration(
                labelText: 'Jenis promo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'percentage',
                  child: Text('Persentase'),
                ),
                DropdownMenuItem(value: 'nominal', child: Text('Nominal')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _promoType = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _promoType == 'nominal'
                    ? 'Nominal diskon'
                    : 'Diskon (%)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minPurchaseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum belanja',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_promoType == 'percentage')
              TextField(
                controller: _maxDiscountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maksimum diskon',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_promoType == 'percentage') const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.event_rounded),
                    label: Text('Mulai ${_formatDate(_startAt)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.event_available_rounded),
                    label: Text('Selesai ${_formatDate(_endAt)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
              activeThumbColor: const Color(0xFFD9001B),
              contentPadding: EdgeInsets.zero,
              title: const Text('Promo aktif'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD9001B),
                ),
                child: Text(_isSaving ? 'Menyimpan...' : 'Simpan Promo'),
              ),
            ),
          ],
        ),
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
