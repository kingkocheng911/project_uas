import 'package:flutter/material.dart';

import '../branch_admin_repository.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key, required this.product});

  final BranchAdminProduct product;

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final BranchAdminRepository _repository = BranchAdminRepository();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _originalPriceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _brandController;
  late final TextEditingController _unitController;
  late final TextEditingController _minStockController;

  bool _isLoadingCategories = true;
  bool _isSaving = false;
  bool _isActive = true;
  bool _isFeatured = false;
  String? _selectedCategory;
  List<BranchAdminCategory> _categories = const [];

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product.name);
    _priceController = TextEditingController(text: '${product.sellingPrice}');
    _originalPriceController = TextEditingController(
      text: product.originalPrice > 0 ? '${product.originalPrice}' : '',
    );
    _descriptionController = TextEditingController(text: product.description);
    _brandController = TextEditingController(text: product.brand);
    _unitController = TextEditingController(text: product.unit);
    _minStockController = TextEditingController(
      text: '${product.minStockAlert}',
    );
    _isActive = product.isActive;
    _isFeatured = product.isFeatured;
    _selectedCategory = product.categoryLabel;
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
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
        if (_selectedCategory == null ||
            !_categories.any((item) => item.label == _selectedCategory)) {
          _selectedCategory = categories.isEmpty
              ? null
              : categories.first.label;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedCategory!.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final price = int.parse(_priceController.text.trim());
      final originalPrice =
          int.tryParse(_originalPriceController.text.trim()) ?? price;
      final minStock = int.tryParse(_minStockController.text.trim()) ?? 5;

      await _repository.updateProduct(
        branchProductId: widget.product.branchProductId,
        name: _nameController.text.trim(),
        categoryLabel: _selectedCategory!,
        sellingPrice: price,
        originalPrice: originalPrice,
        description: _descriptionController.text.trim(),
        unit: _unitController.text.trim(),
        brand: _brandController.text.trim(),
        minStockAlert: minStock,
        isFeatured: _isFeatured,
        isActive: _isActive,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui produk: $error')),
      );
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
        title: const Text('Edit Produk Cabang'),
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
                    title: 'Informasi Produk',
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
                    title: 'Harga dan Status',
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
                        controller: _minStockController,
                        label: 'Batas Minimum Stok',
                        keyboardType: TextInputType.number,
                        validator: _requiredNumber,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _isFeatured,
                        title: const Text('Produk unggulan'),
                        onChanged: (value) =>
                            setState(() => _isFeatured = value),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _isActive,
                        title: const Text('Produk aktif di cabang'),
                        subtitle: const Text(
                          'Nonaktifkan jika produk ingin disembunyikan dari pelanggan.',
                        ),
                        onChanged: (value) => setState(() => _isActive = value),
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
          child: Text(_isSaving ? 'Menyimpan...' : 'Simpan Perubahan'),
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
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    return null;
  }

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    if (int.tryParse(value.trim()) == null) return 'Harus berupa angka';
    return null;
  }
}
