import 'package:flutter/material.dart';

import '../branch_admin_repository.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final BranchAdminRepository _repository = BranchAdminRepository();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _unitController = TextEditingController(text: 'pcs');
  final _minStockController = TextEditingController(text: '5');

  bool _isLoadingCategories = true;
  bool _isSaving = false;
  String? _selectedCategory;
  bool _isFeatured = false;
  List<BranchAdminCategory> _categories = const [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _unitController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _repository.loadCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectedCategory = categories.isEmpty ? null : categories.first.label;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori produk belum dipilih.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final price = int.parse(_priceController.text.trim());
      final originalPrice =
          int.tryParse(_originalPriceController.text.trim()) ?? price;
      final stock = int.tryParse(_stockController.text.trim()) ?? 0;
      final minStock = int.tryParse(_minStockController.text.trim()) ?? 5;

      await _repository.createProduct(
        name: _nameController.text.trim(),
        categoryLabel: _selectedCategory!,
        sellingPrice: price,
        originalPrice: originalPrice,
        initialStock: stock,
        description: _descriptionController.text.trim(),
        unit: _unitController.text.trim(),
        brand: _brandController.text.trim(),
        minStockAlert: minStock,
        isFeatured: _isFeatured,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menambah produk: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Tambah Produk Cabang'),
      ),
      body: _isLoadingCategories
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection(
                    context,
                    title: 'Informasi Utama',
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nama Produk',
                        validator: _requiredText,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: _inputDecoration('Kategori'),
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category.label,
                                child: Text(category.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Deskripsi',
                        maxLines: 4,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _brandController,
                        label: 'Brand',
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _unitController,
                        label: 'Satuan',
                        validator: _requiredText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    context,
                    title: 'Harga dan Stok',
                    children: [
                      _buildTextField(
                        controller: _priceController,
                        label: 'Harga Jual',
                        keyboardType: TextInputType.number,
                        validator: _requiredNumber,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _originalPriceController,
                        label: 'Harga Coret',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _stockController,
                        label: 'Stok Awal',
                        keyboardType: TextInputType.number,
                        validator: _requiredNumber,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _minStockController,
                        label: 'Batas Minimum Stok',
                        keyboardType: TextInputType.number,
                        validator: _requiredNumber,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _isFeatured,
                        title: const Text('Tampilkan sebagai produk unggulan'),
                        subtitle: const Text(
                          'Produk unggulan akan tampil lebih atas.',
                        ),
                        onChanged: (value) =>
                            setState(() => _isFeatured = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton(
          onPressed: _isSaving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD9001B),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(_isSaving ? 'Menyimpan...' : 'Simpan Produk'),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
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
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
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

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wajib diisi';
    }
    return null;
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wajib diisi';
    }
    if (int.tryParse(value.trim()) == null) {
      return 'Harus berupa angka';
    }
    return null;
  }
}

// uyi6yy5u6u5u
