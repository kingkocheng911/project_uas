import 'package:flutter/material.dart';

class ManageAddressesScreen extends StatefulWidget {
  const ManageAddressesScreen({super.key});

  @override
  State<ManageAddressesScreen> createState() => _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends State<ManageAddressesScreen> {
  int _selected = 0;

  final List<_AddressData> _addresses = [
    const _AddressData(
      label: 'Home',
      icon: Icons.home_outlined,
      name: 'Budi Santoso',
      phone: '+62 812-3456-7890',
      address: 'Jl. Merdeka No. 42, RT 03/RW 04, Sukamaju Village, Subang Regency, West Java 41281',
      isPrimary: true,
    ),
    const _AddressData(
      label: 'Work',
      icon: Icons.business_outlined,
      name: 'Budi Santoso',
      phone: '+62 812-3456-7890',
      address: 'Jl. Pahlawan No. 10, Kec. Kalijati, Subang, West Java 41271',
      isPrimary: false,
    ),
    const _AddressData(
      label: 'Parents',
      icon: Icons.people_outline_rounded,
      name: 'Santoso Family',
      phone: '+62 813-9876-5432',
      address: 'Jl. Kebun Raya No. 7, Kec. Purwakarta, West Java 41101',
      isPrimary: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Saved Addresses', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Manage Addresses',
            style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Select or manage your delivery addresses.',
            style: theme.textTheme.bodyLarge?.copyWith(color: const Color(0xFF6D5A58)),
          ),
          const SizedBox(height: 20),
          ..._addresses.asMap().entries.map((e) {
            final i = e.key;
            final addr = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AddressCard(
                address: addr,
                isSelected: _selected == i,
                onSelect: () => setState(() => _selected = i),
                onEdit: () {},
                onDelete: () {},
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addNewAddress,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(62),
              side: BorderSide(color: primary, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            icon: Icon(Icons.add_rounded, color: primary),
            label: const Text('Add New Address'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              minimumSize: const Size.fromHeight(62),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: const Text('Confirm Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _addNewAddress() async {
    final newAddress = await showModalBottomSheet<_AddressData>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _AddAddressSheet(),
    );

    if (!mounted || newAddress == null) return;
    setState(() {
      _addresses.add(newAddress);
      _selected = _addresses.length - 1;
    });
  }
}

class _AddressData {
  const _AddressData({
    required this.label,
    required this.icon,
    required this.name,
    required this.phone,
    required this.address,
    required this.isPrimary,
  });
  final String label, name, phone, address;
  final IconData icon;
  final bool isPrimary;
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final _AddressData address;
  final bool isSelected;
  final VoidCallback onSelect, onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? primary : const Color(0xFFE8BCB8),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? primary.withValues(alpha: 0.12) : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(address.icon, color: isSelected ? primary : const Color(0xFF6D5A58)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.label, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      if (address.isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFF5E8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'PRIMARY',
                            style: TextStyle(
                              color: Color(0xFF1A7F42),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(address.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(address.phone, style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6D5A58))),
                  const SizedBox(height: 6),
                  Text(
                    address.address,
                    style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6D5A58), height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        child: Text('Edit', style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBA1A1A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Delete', style: TextStyle(color: Color(0xFFBA1A1A), fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            RadioGroup<int>(
              groupValue: isSelected ? 0 : 1,
              onChanged: (_) => onSelect(),
              child: Radio<int>(
                value: 0,
                activeColor: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet();

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  IconData _selectedIcon = Icons.location_on_outlined;

  @override
  void dispose() {
    _labelController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tambah Alamat Baru',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lengkapi detail alamat agar bisa dipakai untuk pengiriman berikutnya.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6D5A58),
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label Alamat',
                    hintText: 'Contoh: Rumah, Kos, Kantor',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Label alamat wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Penerima',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Nama penerima belum valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 10) {
                      return 'Nomor telepon belum valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Lengkap',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 10) {
                      return 'Alamat lengkap belum valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Pilih ikon alamat',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _AddressIconOption(
                      icon: Icons.home_outlined,
                      selected: _selectedIcon == Icons.home_outlined,
                      onTap: () =>
                          setState(() => _selectedIcon = Icons.home_outlined),
                    ),
                    _AddressIconOption(
                      icon: Icons.business_outlined,
                      selected: _selectedIcon == Icons.business_outlined,
                      onTap: () => setState(
                        () => _selectedIcon = Icons.business_outlined,
                      ),
                    ),
                    _AddressIconOption(
                      icon: Icons.people_outline_rounded,
                      selected: _selectedIcon == Icons.people_outline_rounded,
                      onTap: () => setState(
                        () => _selectedIcon = Icons.people_outline_rounded,
                      ),
                    ),
                    _AddressIconOption(
                      icon: Icons.location_on_outlined,
                      selected: _selectedIcon == Icons.location_on_outlined,
                      onTap: () => setState(
                        () => _selectedIcon = Icons.location_on_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      Navigator.of(context).pop(
                        _AddressData(
                          label: _labelController.text.trim(),
                          icon: _selectedIcon,
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          address: _addressController.text.trim(),
                          isPrimary: false,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: const Text('Simpan Alamat'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressIconOption extends StatelessWidget {
  const _AddressIconOption({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: selected ? theme.colorScheme.primary : const Color(0xFF6D5A58),
        ),
      ),
    );
  }
}
