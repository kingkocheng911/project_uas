import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/google_maps_address_service.dart';

const LatLng _defaultAddressMapCenter = LatLng(-7.5666, 110.8167);

class SavedAddressResult {
  const SavedAddressResult({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.address,
    required this.isPrimary,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String label;
  final String name;
  final String phone;
  final String address;
  final bool isPrimary;
  final double? latitude;
  final double? longitude;

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
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
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
                                      latitude: _selectedAddress!.latitude,
                                      longitude: _selectedAddress!.longitude,
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
        province: draft.province,
        city: draft.city,
        district: draft.district,
        postalCode: draft.postalCode,
        latitude: draft.latitude,
        longitude: draft.longitude,
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
    this.province = '',
    this.city = '',
    this.district = '',
    this.postalCode = '',
    this.latitude,
    this.longitude,
  });

  final String id;
  final String label;
  final String name;
  final String phone;
  final String address;
  final bool isPrimary;
  final String province;
  final String city;
  final String district;
  final String postalCode;
  final double? latitude;
  final double? longitude;

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
      province: (map['province'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      district: (map['district'] ?? '').toString(),
      postalCode: (map['postal_code'] ?? '').toString(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  _AddressData copyWith({
    String? label,
    String? name,
    String? phone,
    String? address,
    bool? isPrimary,
    String? province,
    String? city,
    String? district,
    String? postalCode,
    double? latitude,
    double? longitude,
  }) {
    return _AddressData(
      id: id,
      label: label ?? this.label,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isPrimary: isPrimary ?? this.isPrimary,
      province: province ?? this.province,
      city: city ?? this.city,
      district: district ?? this.district,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class _AddressDraft {
  const _AddressDraft({
    required this.label,
    required this.name,
    required this.phone,
    required this.address,
    required this.province,
    required this.city,
    required this.district,
    required this.postalCode,
    this.latitude,
    this.longitude,
  });

  final String label;
  final String name;
  final String phone;
  final String address;
  final String province;
  final String city;
  final String district;
  final String postalCode;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toInsertMap({required String userId}) {
    return {
      'user_id': userId,
      'label': label,
      'recipient_name': name,
      'phone': phone,
      'address': address,
      'province': province,
      'city': city,
      'district': district,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'is_primary': false,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'label': label,
      'recipient_name': name,
      'phone': phone,
      'address': address,
      'province': province,
      'city': city,
      'district': district,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
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
      province: province,
      city: city,
      district: district,
      postalCode: postalCode,
      latitude: latitude,
      longitude: longitude,
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
  final GoogleMapsAddressService _mapsService = const GoogleMapsAddressService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  GoogleAddressDetails? _selectedLocation;
  bool _isResolvingLocation = false;

  bool get _isEditing => widget.initialAddress != null;

  @override
  void initState() {
    super.initState();
    final address = widget.initialAddress;
    _labelController = TextEditingController(text: address?.label ?? '');
    _nameController = TextEditingController(text: address?.name ?? '');
    _phoneController = TextEditingController(text: address?.phone ?? '');
    _addressController = TextEditingController(text: address?.address ?? '');
    if (address?.latitude != null && address?.longitude != null) {
      _selectedLocation = GoogleAddressDetails(
        placeId: '',
        formattedAddress: address?.address ?? '',
        latitude: address!.latitude!,
        longitude: address.longitude!,
        province: address.province,
        city: address.city,
        district: address.district,
        postalCode: address.postalCode,
      );
    }
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
                _MapAddressPickerCard(
                  isConfigured: _mapsService.isConfigured,
                  location: _selectedLocation,
                  isLoading: _isResolvingLocation,
                  onSearch: _isResolvingLocation ? null : _searchAddressFromGoogle,
                  onOpenMap: _isResolvingLocation ? null : _openMapPicker,
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
                if (_selectedLocation != null) ...[
                  const SizedBox(height: 12),
                  _LocationMetaPanel(location: _selectedLocation!),
                ],
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
                          province: _selectedLocation?.province ?? '',
                          city: _selectedLocation?.city ?? '',
                          district: _selectedLocation?.district ?? '',
                          postalCode: _selectedLocation?.postalCode ?? '',
                          latitude: _selectedLocation?.latitude,
                          longitude: _selectedLocation?.longitude,
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

  Future<void> _searchAddressFromGoogle() async {
    if (!_mapsService.isConfigured) {
      _showSheetNotice(
        'Google Maps belum aktif. Isi GOOGLE_MAPS_API_KEY dulu agar pencarian alamat bisa dipakai.',
      );
      return;
    }

    final suggestion = await showModalBottomSheet<GooglePlaceSuggestion>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _GoogleAddressSearchSheet(service: _mapsService),
    );

    if (!mounted || suggestion == null) return;

    setState(() => _isResolvingLocation = true);
    try {
      final details = await _mapsService.getPlaceDetails(suggestion.placeId);
      if (!mounted) return;
      setState(() {
        _selectedLocation = details;
        _addressController.text = details.formattedAddress;
      });
    } catch (error) {
      if (!mounted) return;
      _showSheetNotice(error.toString());
    } finally {
      if (mounted) {
        setState(() => _isResolvingLocation = false);
      }
    }
  }

  Future<void> _openMapPicker() async {
    if (!_mapsService.isConfigured) {
      _showSheetNotice(
        'Google Maps belum aktif. Isi GOOGLE_MAPS_API_KEY dulu agar peta bisa dipakai.',
      );
      return;
    }

    final selected = await Navigator.of(context).push<GoogleAddressDetails>(
      MaterialPageRoute(
        builder: (_) => _AddressMapPickerScreen(
          service: _mapsService,
          initialLocation: _selectedLocation,
        ),
        fullscreenDialog: true,
      ),
    );

    if (!mounted || selected == null) return;

    setState(() {
      _selectedLocation = selected;
      _addressController.text = selected.formattedAddress;
    });
  }

  void _showSheetNotice(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MapAddressPickerCard extends StatelessWidget {
  const _MapAddressPickerCard({
    required this.isConfigured,
    required this.location,
    required this.isLoading,
    required this.onSearch,
    required this.onOpenMap,
  });

  final bool isConfigured;
  final GoogleAddressDetails? location;
  final bool isLoading;
  final VoidCallback? onSearch;
  final VoidCallback? onOpenMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8BCB8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.map_outlined, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Maps',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location == null
                          ? 'Cari alamat atau pilih titik peta agar alamat lebih akurat.'
                          : 'Lokasi sudah dipilih. Kamu masih bisa ubah titiknya.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6D5A58),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isConfigured) ...[
            const SizedBox(height: 12),
            const Text(
              'API key Google Maps belum diisi, jadi tombol pencarian dan peta belum aktif.',
              style: TextStyle(
                color: Color(0xFFBA1A1A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isConfigured ? onSearch : null,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search_rounded),
                  label: const Text('Cari Alamat'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isConfigured ? onOpenMap : null,
                  icon: const Icon(Icons.place_outlined),
                  label: Text(location == null ? 'Pilih di Peta' : 'Ubah Titik'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationMetaPanel extends StatelessWidget {
  const _LocationMetaPanel({required this.location});

  final GoogleAddressDetails location;

  @override
  Widget build(BuildContext context) {
    final rows = [
      if (location.district.isNotEmpty) ('Kecamatan', location.district),
      if (location.city.isNotEmpty) ('Kota/Kabupaten', location.city),
      if (location.province.isNotEmpty) ('Provinsi', location.province),
      if (location.postalCode.isNotEmpty) ('Kode Pos', location.postalCode),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8BCB8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data lokasi dari Google Maps',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      row.$1,
                      style: const TextStyle(color: Color(0xFF6D5A58)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            'Lat ${location.latitude.toStringAsFixed(6)}, Lng ${location.longitude.toStringAsFixed(6)}',
            style: const TextStyle(
              color: Color(0xFF6D5A58),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleAddressSearchSheet extends StatefulWidget {
  const _GoogleAddressSearchSheet({required this.service});

  final GoogleMapsAddressService service;

  @override
  State<_GoogleAddressSearchSheet> createState() => _GoogleAddressSearchSheetState();
}

class _GoogleAddressSearchSheetState extends State<_GoogleAddressSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<GooglePlaceSuggestion> _results = const [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.length < 3) {
      setState(() {
        _results = const [];
        _errorMessage = 'Masukkan minimal 3 karakter.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await widget.service.autocomplete(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _errorMessage = 'Alamat tidak ditemukan.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Cari alamat, jalan, atau tempat',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  onPressed: _isLoading ? null : _search,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: _results.isNotEmpty
                    ? ListView.separated(
                        shrinkWrap: true,
                        itemCount: _results.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final suggestion = _results[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.place_outlined),
                            title: Text(suggestion.mainText),
                            subtitle: suggestion.secondaryText == null
                                ? null
                                : Text(suggestion.secondaryText!),
                            onTap: () => Navigator.of(context).pop(suggestion),
                          );
                        },
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          _errorMessage ??
                              'Cari alamat dari Google Maps agar lokasi pengiriman lebih akurat.',
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressMapPickerScreen extends StatefulWidget {
  const _AddressMapPickerScreen({
    required this.service,
    this.initialLocation,
  });

  final GoogleMapsAddressService service;
  final GoogleAddressDetails? initialLocation;

  @override
  State<_AddressMapPickerScreen> createState() => _AddressMapPickerScreenState();
}

class _AddressMapPickerScreenState extends State<_AddressMapPickerScreen> {
  GoogleAddressDetails? _selectedLocation;
  bool _isResolving = false;
  GoogleMapController? _mapController;
  late LatLng _cameraTarget;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _cameraTarget = _selectedLocation == null
        ? _defaultAddressMapCenter
        : LatLng(_selectedLocation!.latitude, _selectedLocation!.longitude);
    if (_selectedLocation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveFromCameraTarget(_defaultAddressMapCenter);
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = _selectedLocation == null
        ? _cameraTarget
        : LatLng(_selectedLocation!.latitude, _selectedLocation!.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Titik Alamat'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: target, zoom: 16),
            onMapCreated: (controller) => _mapController = controller,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('selected-address'),
                position: target,
                draggable: true,
                onDragEnd: _resolveFromCameraTarget,
              ),
            },
            onTap: _resolveFromCameraTarget,
            onCameraMove: (position) {
              _cameraTarget = position.target;
            },
            onCameraIdle: () async {
              await _resolveFromCameraTarget(_cameraTarget, moveCamera: false);
            },
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, color: Color(0xFFD9001B)),
                      const SizedBox(width: 8),
                      Text(
                        _isResolving ? 'Mencari alamat...' : 'Alamat terpilih',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _selectedLocation?.formattedAddress ??
                        'Geser pin atau tap peta untuk memilih lokasi.',
                    style: const TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _selectedLocation == null || _isResolving
                          ? null
                          : () => Navigator.of(context).pop(_selectedLocation),
                      child: const Text('Gunakan Lokasi Ini'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveFromCameraTarget(
    LatLng target, {
    bool moveCamera = true,
  }) async {
    setState(() => _isResolving = true);
    if (moveCamera) {
      await _mapController?.animateCamera(CameraUpdate.newLatLng(target));
    }
    try {
      final details = await widget.service.reverseGeocode(
        latitude: target.latitude,
        longitude: target.longitude,
      );
      if (!mounted) return;
      setState(() => _selectedLocation = details);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedLocation = GoogleAddressDetails(
          placeId: '',
          formattedAddress:
              'Titik dipilih di ${target.latitude.toStringAsFixed(6)}, ${target.longitude.toStringAsFixed(6)}',
          latitude: target.latitude,
          longitude: target.longitude,
          province: '',
          city: '',
          district: '',
          postalCode: '',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
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
