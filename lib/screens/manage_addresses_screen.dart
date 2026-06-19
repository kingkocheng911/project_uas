import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavedAddressResult {
  const SavedAddressResult({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.address,
    required this.isPrimary,
  });

  final String id;
  final String label;
  final String name;
  final String phone;
  final String address;
  final bool isPrimary;

  factory SavedAddressResult.fromMap(
    Map<String, dynamic> map, {
    required String fallbackUserId,
  }) {
    return SavedAddressResult(
      id: (map['id'] ?? '${fallbackUserId}_${DateTime.now().millisecondsSinceEpoch}')
          .toString(),
      label: (map['label'] ?? 'Alamat').toString(),
      name: (map['recipient_name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      isPrimary: map['is_primary'] == true,
    );
  }
}

class ManageAddressesScreen extends StatefulWidget {
  const ManageAddressesScreen({super.key});

  @override
  State<ManageAddressesScreen> createState() => _ManageAddressesScreenState();
}

class _ManageAddressesScreenState extends State<ManageAddressesScreen> {
  final SupabaseClient _client = Supabase.instance.client;

  List<_AddressData> _addresses = List<_AddressData>.from(_fallbackAddresses);
  String? _selectedAddressId = _fallbackAddresses.first.id;
  bool _isLoading = true;
  bool _isSaving = false;

  User? get _currentUser => _client.auth.currentUser;
  bool get _canUseSupabase => _currentUser != null;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

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
        title: Text(
          'Saved Addresses',
          style: TextStyle(color: primary, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAddresses,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Manage Addresses',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _canUseSupabase
                        ? 'Alamat tersimpan langsung ke akun Supabase kamu.'
                        : 'Kamu belum login ke Supabase, jadi alamat disimpan sementara di perangkat.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6D5A58),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_addresses.isEmpty)
                    _EmptyAddressesCard(
                      onAddAddress: _isSaving ? null : _addNewAddress,
                    )
                  else
                    ..._addresses.map((address) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _AddressCard(
                          key: ValueKey(address.id),
                          address: address,
                          isSelected: _selectedAddressId == address.id,
                          onSelect: () => _selectAddress(address.id),
                          onEdit: _isSaving
                              ? null
                              : () => _editAddress(address),
                          onDelete: _isSaving
                              ? null
                              : () => _deleteAddress(address),
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _addNewAddress,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(62),
                      side: BorderSide(color: primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: _isSaving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primary,
                              ),
                            ),
                          )
                        : Icon(Icons.add_rounded, color: primary),
                    label: Text(_isSaving ? 'Menyimpan...' : 'Add New Address'),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _addresses.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(
                              _selectedAddress == null
                                  ? null
                                  : SavedAddressResult(
                                      id: _selectedAddress!.id,
                                      label: _selectedAddress!.label,
                                      name: _selectedAddress!.name,
                                      phone: _selectedAddress!.phone,
                                      address: _selectedAddress!.address,
                                      isPrimary: _selectedAddress!.isPrimary,
                                    ),
                            ),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      minimumSize: const Size.fromHeight(62),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Confirm Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  _AddressData? get _selectedAddress {
    for (final address in _addresses) {
      if (address.id == _selectedAddressId) {
        return address;
      }
    }
    return _addresses.isEmpty ? null : _addresses.first;
  }

  Future<void> _loadAddresses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    if (!_canUseSupabase) {
      setState(() {
        _addresses = List<_AddressData>.from(_fallbackAddresses);
        _selectedAddressId = _addresses.firstOrNull?.id;
        _isLoading = false;
      });
      return;
    }

    try {
      final rows = await _client
          .from('addresses')
          .select()
          .eq('user_id', _currentUser!.id)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: true);

      final addresses = rows
          .map<_AddressData>(
            (row) => _AddressData.fromMap(row, fallbackUserId: _currentUser!.id),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        _selectedAddressId = addresses
                .where((address) => address.isPrimary)
                .map((address) => address.id)
                .firstOrNull ??
            addresses.firstOrNull?.id;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addresses = List<_AddressData>.from(_fallbackAddresses);
        _selectedAddressId = _addresses.firstOrNull?.id;
        _isLoading = false;
      });
      _showNotice(
        'Gagal memuat alamat dari Supabase. Untuk sementara dipakai data lokal.',
      );
    }
  }

  void _selectAddress(String id) {
    setState(() => _selectedAddressId = id);
  }

  Future<void> _addNewAddress() async {
    final draft = await showModalBottomSheet<_AddressDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _AddAddressSheet(),
    );

    if (!mounted || draft == null) return;

    await _runSaving(() async {
      if (_canUseSupabase) {
        final inserted = await _client
            .from('addresses')
            .insert(draft.toInsertMap(userId: _currentUser!.id))
            .select()
            .single();

        final address = _AddressData.fromMap(
          inserted,
          fallbackUserId: _currentUser!.id,
        );
        setState(() {
          _addresses = [..._addresses, address];
          _selectedAddressId = address.id;
        });
      } else {
        final address = draft.toAddressData();
        setState(() {
          _addresses = [..._addresses, address];
          _selectedAddressId = address.id;
        });
      }

      _showNotice('Alamat baru berhasil ditambahkan.');
    });
  }

  Future<void> _editAddress(_AddressData address) async {
    final draft = await showModalBottomSheet<_AddressDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AddAddressSheet(initialAddress: address),
    );

    if (!mounted || draft == null) return;

    await _runSaving(() async {
      final updatedAddress = address.copyWith(
        label: draft.label,
        name: draft.name,
        phone: draft.phone,
        address: draft.address,
      );

      if (_canUseSupabase) {
        await _client
            .from('addresses')
            .update(draft.toUpdateMap())
            .eq('id', address.id)
            .eq('user_id', _currentUser!.id);
      }

      setState(() {
        _addresses = _addresses
            .map((item) => item.id == address.id ? updatedAddress : item)
            .toList();
      });
      _showNotice('Alamat berhasil diperbarui.');
    });
  }

  Future<void> _deleteAddress(_AddressData address) async {
    await _runSaving(() async {
      if (_canUseSupabase) {
        await _client
            .from('addresses')
            .delete()
            .eq('id', address.id)
            .eq('user_id', _currentUser!.id);
      }

      final remaining = _addresses
          .where((item) => item.id != address.id)
          .toList();
      setState(() {
        _addresses = remaining;
        if (_selectedAddressId == address.id) {
          _selectedAddressId = remaining.firstOrNull?.id;
        }
      });
      _showNotice('Alamat berhasil dihapus.');
    });
  }

  Future<void> _runSaving(Future<void> Function() action) async {
    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      await action();
    } catch (_) {
      _showNotice('Aksi belum berhasil. Coba lagi sebentar.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showNotice(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          margin: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 12,
            16,
            0,
          ),
        ),
      );
  }
}

class _AddressData {
  const _AddressData({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.address,
    required this.isPrimary,
  });

  final String id;
  final String label;
  final String name;
  final String phone;
  final String address;
  final bool isPrimary;

  factory _AddressData.fromMap(
    Map<String, dynamic> map, {
    required String fallbackUserId,
  }) {
    return _AddressData(
      id: (map['id'] ?? '${fallbackUserId}_${DateTime.now().millisecondsSinceEpoch}')
          .toString(),
      label: (map['label'] ?? 'Alamat').toString(),
      name: (map['recipient_name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      isPrimary: map['is_primary'] == true,
    );
  }

  _AddressData copyWith({
    String? label,
    String? name,
    String? phone,
    String? address,
    bool? isPrimary,
  }) {
    return _AddressData(
      id: id,
      label: label ?? this.label,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

class _AddressDraft {
  const _AddressDraft({
    required this.label,
    required this.name,
    required this.phone,
    required this.address,
  });

  final String label;
  final String name;
  final String phone;
  final String address;

  Map<String, dynamic> toInsertMap({required String userId}) {
    return {
      'user_id': userId,
      'label': label,
      'recipient_name': name,
      'phone': phone,
      'address': address,
      'is_primary': false,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'label': label,
      'recipient_name': name,
      'phone': phone,
      'address': address,
    };
  }

  _AddressData toAddressData() {
    return _AddressData(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      label: label,
      name: name,
      phone: phone,
      address: address,
      isPrimary: false,
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    super.key,
    required this.address,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final _AddressData address;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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
                color: isSelected
                    ? primary.withValues(alpha: 0.12)
                    : const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: isSelected ? primary : const Color(0xFF6D5A58),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (address.isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
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
                  Text(
                    address.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    address.phone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6D5A58),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    address.address,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6D5A58),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: onEdit,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            color: primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBA1A1A)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Color(0xFFBA1A1A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onSelect,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primary : const Color(0xFFB9A6A3),
                    width: 2,
                  ),
                  color: isSelected ? primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet({this.initialAddress});

  final _AddressData? initialAddress;

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  bool get _isEditing => widget.initialAddress != null;

  @override
  void initState() {
    super.initState();
    final address = widget.initialAddress;
    _labelController = TextEditingController(text: address?.label ?? '');
    _nameController = TextEditingController(text: address?.name ?? '');
    _phoneController = TextEditingController(text: address?.phone ?? '');
    _addressController = TextEditingController(text: address?.address ?? '');
  }

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
                  _isEditing ? 'Edit Alamat' : 'Tambah Alamat Baru',
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
                  decoration: const InputDecoration(labelText: 'Nama Penerima'),
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
                  decoration: const InputDecoration(labelText: 'Nomor Telepon'),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (!_formKey.currentState!.validate()) return;
                      Navigator.of(context).pop(
                        _AddressDraft(
                          label: _labelController.text.trim(),
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          address: _addressController.text.trim(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    child: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Alamat'),
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

class _EmptyAddressesCard extends StatelessWidget {
  const _EmptyAddressesCard({required this.onAddAddress});

  final VoidCallback? onAddAddress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8BCB8)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 40,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada alamat tersimpan',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tambahkan alamat pengiriman pertama kamu agar checkout lebih cepat.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6D5A58),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onAddAddress,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Alamat'),
          ),
        ],
      ),
    );
  }
}

const List<_AddressData> _fallbackAddresses = [
  _AddressData(
    id: 'fallback_home',
    label: 'Home',
    name: 'Budi Santoso',
    phone: '+62 812-3456-7890',
    address:
        'Jl. Merdeka No. 42, RT 03/RW 04, Sukamaju Village, Subang Regency, West Java 41281',
    isPrimary: true,
  ),
  _AddressData(
    id: 'fallback_work',
    label: 'Work',
    name: 'Budi Santoso',
    phone: '+62 812-3456-7890',
    address:
        'Jl. Pahlawan No. 10, Kec. Kalijati, Subang, West Java 41271',
    isPrimary: false,
  ),
  _AddressData(
    id: 'fallback_parents',
    label: 'Parents',
    name: 'Santoso Family',
    phone: '+62 813-9876-5432',
    address:
        'Jl. Kebun Raya No. 7, Kec. Purwakarta, West Java 41101',
    isPrimary: false,
  ),
];
