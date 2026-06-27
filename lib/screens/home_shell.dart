import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../catalog_repository.dart';
import '../mock_data.dart' show activities, orders, profileSettings;
import '../models.dart';
<<<<<<< HEAD
import '../services/sandbox_order_payment_service.dart';
import '../services/sandbox_topup_service.dart';
=======
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/reward_service.dart';
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
import 'manage_addresses_screen.dart';
import 'notification_history_screen.dart';
import 'notification_settings_screen.dart';
import 'payment_methods_screen.dart';
import 'security_settings_screen.dart';

const _cooperativeImageUrl =
    'https://images.unsplash.com/photo-1516321497487-e288fb19713f?auto=format&fit=crop&w=600&q=80';
const _initialsAvatarKey = '__initials__';

class UserProfile {
  const UserProfile({
    required this.name,
    required this.phone,
    required this.email,
    required this.avatarUrl,
    this.role = 'user',
  });

  final String name;
  final String phone;
  final String email;
  final String avatarUrl;
  final String role;
}

class CheckoutVoucher {
  const CheckoutVoucher({
    this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.minimumSpend,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    this.endAt,
    this.usageCount = 0,
    this.maxUsagePerUser = 1,
  });

  final String? id;
  final String code;
  final String title;
  final String description;
  final IconData icon;
  final int minimumSpend;
  final String discountType;
  final int discountValue;
  final int? maxDiscount;
  final DateTime? endAt;
  final int usageCount;
  final int maxUsagePerUser;

  bool get isUsed => usageCount >= maxUsagePerUser;

  bool get isExpired {
    final expiry = endAt;
    return expiry != null && expiry.isBefore(DateTime.now());
  }

  bool get isAvailable => !isUsed && !isExpired;

  String get statusLabel {
    if (isUsed) return 'Sudah dipakai';
    if (isExpired) return 'Kedaluwarsa';
    return 'Bisa dipakai';
  }

  String get validityLabel {
    final expiry = endAt;
    if (expiry == null) return 'Berlaku selama promo aktif';
    final day = expiry.day.toString().padLeft(2, '0');
    final month = expiry.month.toString().padLeft(2, '0');
    return 'Berlaku sampai $day/$month/${expiry.year}';
  }

  int calculateDiscount(int subtotal, int deliveryFee, int serviceFee) {
    if (subtotal < minimumSpend || !isAvailable) return 0;
    final totalBeforeDiscount = subtotal + deliveryFee + serviceFee;
    final discount = switch (discountType) {
      'free_delivery' => deliveryFee,
      'percentage' => (subtotal * (discountValue / 100)).round(),
      'fixed_amount' => discountValue,
      _ => 0,
    };
    final limitedDiscount = maxDiscount == null
        ? discount
        : discount.clamp(0, maxDiscount!);
    return limitedDiscount.clamp(0, totalBeforeDiscount).toInt();
  }

  factory CheckoutVoucher.fromMap(
    Map<String, dynamic> row, {
    int usageCount = 0,
  }) {
    return CheckoutVoucher(
      id: row['id']?.toString(),
      code: (row['code'] ?? '').toString(),
      title: (row['title'] ?? '').toString(),
      description: (row['description'] ?? '').toString(),
      icon: _voucherIconFromName((row['icon_name'] ?? '').toString()),
      minimumSpend: (row['minimum_spend'] as num?)?.toInt() ?? 0,
      discountType: (row['discount_type'] ?? 'fixed_amount').toString(),
      discountValue: (row['discount_value'] as num?)?.toInt() ?? 0,
      maxDiscount: (row['max_discount'] as num?)?.toInt(),
      endAt: DateTime.tryParse((row['end_at'] ?? '').toString())?.toLocal(),
      usageCount: usageCount,
      maxUsagePerUser: (row['max_usage_per_user'] as num?)?.toInt() ?? 1,
    );
  }
}

class CheckoutAddress {
  const CheckoutAddress({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.address,
    required this.icon,
  });

  final String id;
  final String label;
  final String name;
  final String phone;
  final String address;
  final IconData icon;
}

class _CheckoutBranchContext {
  const _CheckoutBranchContext({
    required this.branchId,
    required this.branchName,
  });

  final String? branchId;
  final String branchName;
}

<<<<<<< HEAD
class _CustomerOrderSnapshot {
  const _CustomerOrderSnapshot({required this.name, required this.phone});

  final String name;
  final String? phone;
}

=======
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

class _UserBranchOption {
  const _UserBranchOption({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    required this.district,
    required this.city,
  });

  final String id;
  final String code;
  final String name;
  final String address;
  final String district;
  final String city;

  String get subtitle {
    final parts = [district, city].where((item) => item.isNotEmpty).toList();
    return parts.isEmpty ? address : parts.join(', ');
  }
}

const _checkoutVouchers = <CheckoutVoucher>[
  CheckoutVoucher(
    code: 'ONGKIRHEMAT',
    title: 'Gratis Ongkir',
    description: 'Potongan ongkir sampai Rp 8.000',
    icon: Icons.local_shipping_outlined,
    minimumSpend: 50000,
    discountType: 'free_delivery',
    discountValue: 8000,
    maxDiscount: 8000,
  ),
  CheckoutVoucher(
    code: 'MEPU10',
    title: 'Diskon Belanja 10%',
    description: 'Maksimal potongan Rp 25.000',
    icon: Icons.percent_rounded,
    minimumSpend: 100000,
    discountType: 'percentage',
    discountValue: 10,
    maxDiscount: 25000,
  ),
  CheckoutVoucher(
    code: 'ANGGOTA15',
    title: 'Voucher Anggota',
    description: 'Potongan langsung Rp 15.000',
    icon: Icons.workspace_premium_outlined,
    minimumSpend: 75000,
    discountType: 'fixed_amount',
    discountValue: 15000,
  ),
];

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.initialProfile,
    required this.onLogout,
    this.onProfileChanged,
  });

  final UserProfile initialProfile;
  final VoidCallback onLogout;
  final ValueChanged<UserProfile>? onProfileChanged;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _catalogRepository = CatalogRepository();
  static const _cartService = CartService();
  static const _rewardService = RewardService();
  final OrderService _orderService = OrderService();
  int _currentIndex = 0;
  int _shopSearchRequestToken = 0;
  int _mepuBalance = 0;
  String _shopSelectedCategory = 'Semua';
  late UserProfile _profile;
  final Map<String, int> _productStocks = <String, int>{};
  List<CartLine> _cartLines = const [];
  String? _cartErrorMessage;
  final List<OrderItem> _orderItems = List<OrderItem>.of(orders);
<<<<<<< HEAD
  List<CheckoutVoucher> _vouchers = List<CheckoutVoucher>.of(_checkoutVouchers);
  List<_UserBranchOption> _branches = const [];
  String? _selectedBranchId;
  String _selectedBranchName = 'Pilih Cabang';
  String _selectedBranchSubtitle = 'Pilih cabang KDMP terdekat';
  String? _branchLoadError;
=======
  List<CategoryItem> _catalogCategories = const [];
  List<Product> _catalogProducts = const [];
  List<PromoBanner> _catalogPromotions = const [];
  String? _catalogErrorMessage;
  RewardSummary? _rewardSummary;
  List<_UserBranchOption> _branches = const [];
  String? _selectedBranchId;
  String _selectedBranchName = 'Pilih Cabang';
  String _selectedBranchSubtitle = 'Pilih cabang MepuPoin terdekat';

  List<String> get _catalogCategoryLabels => [
    'Semua',
    ..._catalogCategories.map((category) => category.label),
  ];

  int get _cartItemCount =>
      _cartLines.fold<int>(0, (sum, item) => sum + item.quantity);

  String? get _cartBranchId =>
      _cartLines.isEmpty ? null : _cartLines.first.branchId;
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    if (_canUseSupabase) {
      _orderItems.clear();
    }
    unawaited(_initializeBranchSelection());
    unawaited(_loadCart());
    unawaited(_loadRewardSummary());
    unawaited(_loadWalletBalance());
    unawaited(_loadOrders());
    unawaited(_loadVouchers());
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(
        cartItemCount: _cartItemCount,
        mepuBalance: _mepuBalance,
        productStocks: _productStocks,
        products: _catalogProducts,
        categories: _catalogCategoryLabels,
        promotions: _catalogPromotions,
        catalogErrorMessage: _catalogErrorMessage,
        selectedBranchName: _selectedBranchName,
        selectedBranchSubtitle: _selectedBranchSubtitle,
        onOpenProduct: _openProduct,
        onChangeTab: _changeTab,
        onOpenCart: _openCart,
        onAddToCart: _addToCart,
        onTopUp: _openTopUpDialog,
        onOpenSearch: _openShopSearch,
        onSelectCategory: _openShopCategory,
        onOpenNotifications: _openNotifications,
        onSelectBranch: _handleSelectBranchTap,
      ),
      ShopScreen(
        cartItemCount: _cartItemCount,
        productStocks: _productStocks,
        products: _catalogProducts,
        categories: _catalogCategoryLabels,
        catalogErrorMessage: _catalogErrorMessage,
        selectedCategory: _shopSelectedCategory,
        searchRequestToken: _shopSearchRequestToken,
        selectedBranchName: _selectedBranchName,
        onOpenProduct: _openProduct,
        onOpenCart: _openCart,
        onAddToCart: _addToCart,
        onSelectBranch: _handleSelectBranchTap,
      ),
      OrdersScreen(
        orders: _orderItems,
        onOpenOrder: _openOrder,
        onPayOrder: _payOrder,
        onCancelOrder: _cancelOrder,
      ),
      ProfileScreen(
        profile: _profile,
        mepuBalance: _mepuBalance,
<<<<<<< HEAD
        vouchers: _vouchers,
=======
        rewardSummary: _rewardSummary,
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
        onTopUp: _openTopUpDialog,
        onEditProfile: _openEditProfile,
        onOpenSetting: _openSetting,
        onChangeTab: _changeTab,
        onOpenPromo: _openPromoCenter,
        onOpenRewardHistory: _openRewardHistory,
        onOpenFaq: _openFaq,
        onOpenContactSupport: _openContactSupport,
        onLogout: _handleLogout,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _currentIndex, children: pages),
      ),
      bottomNavigationBar: KdmpBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  void _changeTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _openShopSearch() {
    setState(() {
      _currentIndex = 1;
      _shopSearchRequestToken++;
    });
  }

  void _handleSelectBranchTap() {
    unawaited(_openBranchSelector());
  }

  Future<void> _initializeBranchSelection() async {
    await _loadBranches();
    await _loadCatalog();
  }

  Future<void> _loadBranches() async {
    try {
      if (!_canUseSupabase) {
        throw Exception('Sesi login Supabase belum aktif.');
      }

      final rows = await Supabase.instance.client
          .from('branches')
          .select('id, code, name, address, district, city')
          .eq('is_active', true)
          .order('name');

      final branches = rows
          .map<_UserBranchOption>(
            (row) => _UserBranchOption(
              id: (row['id'] ?? '').toString(),
              code: (row['code'] ?? '').toString(),
              name: (row['name'] ?? '').toString(),
              address: (row['address'] ?? '').toString(),
              district: (row['district'] ?? '').toString(),
              city: (row['city'] ?? '').toString(),
            ),
          )
          .where((branch) => branch.id.isNotEmpty && branch.name.isNotEmpty)
          .toList(growable: false);

      if (!mounted) return;

      String? preferredBranchId = _selectedBranchId;
      if ((preferredBranchId ?? '').isEmpty && _canUseSupabase) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final profileRow = await Supabase.instance.client
              .from('profiles')
              .select('default_branch_id')
              .eq('id', user.id)
              .maybeSingle();
          preferredBranchId = profileRow?['default_branch_id']?.toString();
        }
      }

      final selectedBranch = branches.firstWhere(
        (branch) => branch.id == preferredBranchId,
        orElse: () => branches.isNotEmpty
            ? branches.first
            : const _UserBranchOption(
                id: '',
                code: '',
                name: 'Pilih Cabang',
                address: '',
                district: '',
                city: '',
              ),
      );

      setState(() {
        _branches = branches;
        _selectedBranchId = selectedBranch.id.isEmpty
            ? null
            : selectedBranch.id;
        _selectedBranchName = selectedBranch.name;
        _selectedBranchSubtitle = selectedBranch.id.isEmpty
            ? 'Pilih cabang MepuPoin terdekat'
            : selectedBranch.subtitle;
        _branchLoadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _branches = const [];
        _selectedBranchId = null;
        _selectedBranchName = 'Pilih Cabang';
<<<<<<< HEAD
        _selectedBranchSubtitle = 'Cabang KDMP belum tersedia dari backend.';
        _branchLoadError = error.toString();
=======
        _selectedBranchSubtitle = 'Pilih cabang MepuPoin terdekat';
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
      });
    }
  }

  Future<void> _loadCatalog() async {
    try {
      final snapshot = await _catalogRepository.load(
        branchId: _selectedBranchId,
      );
<<<<<<< HEAD
      final loadedCategories = List<CategoryItem>.of(snapshot.categories);
      final loadedProducts = List<Product>.of(snapshot.products);
=======
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
      if (!mounted) return;
      setState(() {
        _catalogErrorMessage = null;
        _catalogCategories = List<CategoryItem>.of(snapshot.categories);
        _catalogProducts = List<Product>.of(snapshot.products);
        _catalogPromotions = List<PromoBanner>.of(snapshot.promotions);
        _productStocks
          ..clear()
          ..addAll(_createStocks(_catalogProducts));
        if (!_catalogCategoryLabels.contains(_shopSelectedCategory)) {
          _shopSelectedCategory = 'Semua';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _catalogCategories = const [];
        _catalogProducts = const [];
        _catalogPromotions = const [];
        _catalogErrorMessage =
            'Catalog belum berhasil dimuat. Periksa koneksi atau data Supabase.';
        _productStocks.clear();
        _shopSelectedCategory = 'Semua';
      });
    }
  }

  Future<void> _loadCart() async {
    if (!_canUseSupabase) {
      if (!mounted) return;
      setState(() {
        _cartLines = const [];
        _cartErrorMessage = null;
      });
      return;
    }

    try {
      final snapshot = await _cartService.load();
      if (!mounted) return;
      setState(() {
        _cartLines = List<CartLine>.of(snapshot.items);
        _cartErrorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cartLines = const [];
        _cartErrorMessage =
            'Keranjang belum berhasil dimuat. Periksa koneksi lalu coba lagi.';
      });
    }
  }

  Future<void> _loadRewardSummary() async {
    if (!_canUseSupabase) {
      if (!mounted) return;
      setState(() => _rewardSummary = null);
      return;
    }

    try {
      final summary = await _rewardService.getSummary();
      if (!mounted) return;
      setState(() => _rewardSummary = summary);
    } catch (_) {
      if (!mounted) return;
      setState(() => _rewardSummary = null);
    }
  }

  bool get _canUseSupabase {
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadWalletBalance() async {
    if (!_canUseSupabase) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final row = await Supabase.instance.client
          .from('profiles')
          .select('wallet_balance')
          .eq('id', user.id)
          .maybeSingle();
      final balance = (row?['wallet_balance'] as num?)?.toInt() ?? 0;
      if (!mounted) return;
      setState(() => _mepuBalance = balance);
    } catch (_) {
      if (!mounted) return;
      setState(() => _mepuBalance = 0);
    }
  }

  Future<void> _loadOrders() async {
    if (!_canUseSupabase) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final rows = await Supabase.instance.client
          .from('orders')
          .select(
            'order_no, order_status, payment_status, grand_total, placed_at, '
            'order_type, delivery_label, delivery_address, courier_name, courier_phone, '
            'provider_va_number, provider_bank, provider_qr_url, payment_expires_at, '
            'payment_methods(code, name), addresses(label, address), order_items(product_name, qty)',
          )
          .eq('user_id', user.id)
          .order('placed_at', ascending: false);

      final mappedOrders = rows
          .map<OrderItem?>(
            (row) => _orderFromBackendRow(Map<String, dynamic>.from(row)),
          )
          .whereType<OrderItem>()
          .toList();

      if (!mounted) return;
      setState(() {
        _orderItems
          ..clear()
          ..addAll(mappedOrders);
      });
    } catch (_) {
<<<<<<< HEAD
      // Keep local fallback orders if remote load fails.
    }
  }

  Future<void> _loadVouchers() async {
    if (!_canUseSupabase) return;
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final voucherRows = await client
          .from('vouchers')
          .select(
            'id, code, title, description, icon_name, discount_type, '
            'discount_value, max_discount, minimum_spend, max_usage_per_user, end_at',
          )
          .eq('is_active', true)
          .order('minimum_spend');

      final redemptionRows = await client
          .from('voucher_redemptions')
          .select('voucher_id')
          .eq('user_id', user.id);
      final usageByVoucher = <String, int>{};
      for (final row in redemptionRows) {
        final voucherId = row['voucher_id']?.toString();
        if (voucherId == null || voucherId.isEmpty) continue;
        usageByVoucher[voucherId] = (usageByVoucher[voucherId] ?? 0) + 1;
      }

      final loadedVouchers = voucherRows
          .map<CheckoutVoucher>(
            (row) => CheckoutVoucher.fromMap(
              Map<String, dynamic>.from(row),
              usageCount: usageByVoucher[row['id']?.toString()] ?? 0,
            ),
          )
          .where(
            (voucher) => voucher.code.isNotEmpty && voucher.title.isNotEmpty,
          )
          .toList(growable: false);

      if (!mounted || loadedVouchers.isEmpty) return;
      setState(() => _vouchers = loadedVouchers);
    } catch (_) {
      // Keep local fallback vouchers if the voucher tables are not available yet.
    }
  }

  Future<bool> _persistWalletBalance(int newBalance) async {
    if (!_canUseSupabase) return true;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      await Supabase.instance.client
          .from('profiles')
          .update({'wallet_balance': newBalance.clamp(0, 2147483647)})
          .eq('id', user.id);
      return true;
    } catch (_) {
      return false;
=======
      if (!mounted) return;
      setState(() => _orderItems.clear());
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
    }
  }

  void _setWalletBalance(int newBalance) {
    setState(() => _mepuBalance = newBalance.clamp(0, 2147483647));
  }

  Future<void> _createNotification({
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    if (!_canUseSupabase) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final settingsRow = await Supabase.instance.client
          .from('notification_settings')
          .select(
            'orders_enabled, promotions_enabled, payments_enabled, '
            'membership_enabled, security_enabled, newsletter_enabled, '
            'email_enabled, sms_enabled, push_enabled',
          )
          .eq('user_id', user.id)
          .maybeSingle();

      if (settingsRow != null) {
        final notificationAllowed = switch (type) {
          'order' => settingsRow['orders_enabled'] != false,
          'promo' => settingsRow['promotions_enabled'] != false,
          _ => settingsRow['payments_enabled'] != false,
        };
        if (!notificationAllowed) return;
      }

      await Supabase.instance.client.from('notifications').insert({
        'user_id': user.id,
        'type': type,
        'title': title,
        'message': message,
        'data': data ?? <String, dynamic>{},
        'is_read': false,
        'sent_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Keep customer flow working even if notification insert fails.
    }
  }

  void _openShopCategory(String category) {
    setState(() {
      _shopSelectedCategory = category;
      _currentIndex = 1;
    });
  }

  void _openOrder(OrderItem order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(order: order)),
    );
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          cartItemCount: _cartItemCount,
          product: product,
          stock: _stockOf(product),
          rewardEarnLabel: _rewardSummary?.earnLabel,
          productStocks: _productStocks,
          catalogProducts: _catalogProducts,
          onOpenCart: _openCart,
          onAddToCart: _addToCart,
          onAddItemsToCart: _addItemsToCart,
          onBuyNow: _buyNow,
        ),
      ),
    );
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CartScreen(
          items: List<CartLine>.of(_cartLines),
          errorMessage: _cartErrorMessage,
          onReload: _reloadCartForScreen,
          onClearCart: _clearCart,
          onRemoveItem: _removeCartItem,
          onUpdateQuantity: _updateCartQuantity,
          onCheckout: _checkoutCartSelection,
        ),
      ),
    );
  }

  void _addToCart(Product product) {
    unawaited(_addProductToCart(product, quantity: 1));
  }

  void _addItemsToCart(List<Product> items) {
    if (items.isEmpty) return;
    final firstProduct = items.first;
    if (items.any((item) => item.id != firstProduct.id)) {
      _showFeatureSnack(
        context,
        'Tambah banyak produk sekaligus belum didukung dari layar ini.',
        title: 'Keranjang',
      );
      return;
    }
    unawaited(_addProductToCart(firstProduct, quantity: items.length));
  }

  void _buyNow(List<Product> items) {
    unawaited(_openCheckout(items, clearCart: false));
  }

  Future<void> _openCheckout(
    List<Product> items, {
    required bool clearCart,
    List<String> purchasedCartItemIds = const [],
  }) async {
    if (items.isEmpty) return;
    if (!_hasAvailableStock(items, includeCartItems: false)) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutScreen(
          items: List<Product>.of(items),
          mepuBalance: _mepuBalance,
          rewardSummary: _rewardSummary,
          productStocks: _productStocks,
          vouchers: _vouchers,
          onCompletePayment: _payOrder,
          onCancelOrder: _cancelOrder,
          onPlaceOrder:
              (
                checkoutItems,
                paymentMethod,
                deliveryMethod,
                addressId,
                address,
                finalTotal,
<<<<<<< HEAD
                voucher,
                voucherDiscount,
=======
                voucherLabel,
                redeemedPoints,
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
              ) async {
                final order = await _createOrder(
                  checkoutItems,
                  paymentMethod: paymentMethod,
                  deliveryMethod: deliveryMethod,
                  addressId: addressId,
                  address: address,
                  finalTotal: finalTotal,
<<<<<<< HEAD
                  voucher: voucher,
                  voucherDiscount: voucherDiscount,
=======
                  voucherLabel: voucherLabel,
                  redeemedPoints: redeemedPoints,
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
                );
                if (order == null) return null;
                setState(() {
                  _orderItems.insert(0, order);
                  _decreaseStock(checkoutItems);
                });
                if (clearCart && purchasedCartItemIds.isNotEmpty) {
                  await _removePurchasedCartItems(
                    purchasedCartItemIds,
                    showFeedback: false,
                  );
                }
                unawaited(_loadCatalog());
                unawaited(_loadRewardSummary());
                if (paymentMethod == 'Saldo MepuPoin') {
                  unawaited(_loadWalletBalance());
                }
<<<<<<< HEAD
                unawaited(
                  _createNotification(
                    type: 'order',
                    title: 'Pesanan berhasil dibuat',
                    message: paymentMethod == 'Saldo MepuPoin'
                        ? 'Pesanan ${order.id} sudah dibayar dan sedang diproses.'
                        : 'Pesanan ${order.id} menunggu pembayaran sebelum diproses.',
                    data: {'order_no': order.id, 'status': order.status},
                  ),
                );
=======
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
                unawaited(_loadOrders());
                return order;
              },
        ),
      ),
    );
  }

  Future<void> _addProductToCart(
    Product product, {
    required int quantity,
  }) async {
    if (!_canUseSupabase) {
      _showFeatureSnack(
        context,
        'Keranjang membutuhkan sesi login aktif.',
        title: 'Keranjang Tidak Tersedia',
      );
      return;
    }
    if (quantity < 1) return;
    if ((product.branchProductId ?? '').isEmpty ||
        (product.branchId ?? '').isEmpty) {
      _showFeatureSnack(
        context,
        'Produk belum terhubung ke cabang aktif. Muat ulang katalog lalu coba lagi.',
        title: 'Produk Tidak Valid',
      );
      return;
    }

    final shouldContinue = await _ensureCartBranchForProduct(product);
    if (!shouldContinue || !mounted) return;

    try {
      final snapshot = await _cartService.addProduct(
        product: product,
        quantity: quantity,
      );
      if (!mounted) return;
      _applyCartSnapshot(snapshot);
      final message = quantity == 1
          ? '${product.name} ditambahkan ke keranjang.'
          : '${product.name} x $quantity ditambahkan ke keranjang.';
      _showFeatureSnack(
        context,
        message,
        title: 'Produk Ditambahkan',
        icon: Icons.shopping_cart_checkout_rounded,
      );
    } catch (error) {
      if (!mounted) return;
      _showFeatureSnack(
        context,
        '$error',
        title: 'Keranjang Gagal Diperbarui',
        icon: Icons.error_outline_rounded,
      );
    }
  }

  Future<bool> _ensureCartBranchForProduct(Product product) async {
    final cartBranchId = _cartBranchId;
    final productBranchId = product.branchId;
    if (cartBranchId == null ||
        cartBranchId.isEmpty ||
        productBranchId == null ||
        productBranchId.isEmpty ||
        cartBranchId == productBranchId) {
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Isi Keranjang?'),
        content: const Text(
          'Keranjang Anda berisi produk dari cabang lain. Kosongkan keranjang untuk melanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;
    await _clearCart(showFeedback: false);
    return mounted;
  }

  Future<List<CartLine>> _clearCart({bool showFeedback = true}) async {
    try {
      final snapshot = await _cartService.clear();
      if (!mounted) return const [];
      _applyCartSnapshot(snapshot);
      if (showFeedback) {
        _showFeatureSnack(context, 'Keranjang dikosongkan.');
      }
      return List<CartLine>.of(snapshot.items);
    } catch (error) {
      if (mounted) {
        _showFeatureSnack(
          context,
          '$error',
          title: 'Keranjang Gagal Dikosongkan',
          icon: Icons.error_outline_rounded,
        );
      }
      rethrow;
    }
  }

  Future<List<CartLine>> _removeCartItem(String cartItemId) async {
    try {
      final snapshot = await _cartService.removeItem(cartItemId);
      if (!mounted) return const [];
      _applyCartSnapshot(snapshot);
      return List<CartLine>.of(snapshot.items);
    } catch (error) {
      if (mounted) {
        _showFeatureSnack(
          context,
          '$error',
          title: 'Item Gagal Dihapus',
          icon: Icons.error_outline_rounded,
        );
      }
      rethrow;
    }
  }

  Future<List<CartLine>> _updateCartQuantity(
    String cartItemId,
    int quantity,
  ) async {
    try {
      final snapshot = await _cartService.updateQuantity(
        cartItemId: cartItemId,
        quantity: quantity,
      );
      if (!mounted) return const [];
      _applyCartSnapshot(snapshot);
      return List<CartLine>.of(snapshot.items);
    } catch (error) {
      if (mounted) {
        _showFeatureSnack(
          context,
          '$error',
          title: 'Jumlah Keranjang Tidak Valid',
          icon: Icons.error_outline_rounded,
        );
      }
      rethrow;
    }
  }

  Future<List<CartLine>> _checkoutCartSelection(
    List<CartLine> selectedLines,
  ) async {
    try {
      final validation = await _cartService.validateCheckout(selectedLines);
      if (!mounted) return List<CartLine>.of(_cartLines);
      if (validation.hasPriceChanges) {
        final preview = validation.changedProducts.take(2).join(', ');
        final moreCount = validation.changedProducts.length - 2;
        final message = moreCount > 0
            ? 'Harga $preview dan $moreCount produk lain diperbarui mengikuti data cabang terbaru.'
            : 'Harga $preview diperbarui mengikuti data cabang terbaru.';
        _showFeatureSnack(
          context,
          message,
          title: 'Harga Diperbarui',
          icon: Icons.sell_outlined,
        );
      }
      await _openCheckout(
        _expandCartLines(validation.items),
        clearCart: true,
        purchasedCartItemIds: validation.items.map((item) => item.id).toList(),
      );
      return List<CartLine>.of(_cartLines);
    } catch (error) {
      if (mounted) {
        _showFeatureSnack(
          context,
          '$error',
          title: 'Checkout Tidak Dapat Dilanjutkan',
          icon: Icons.error_outline_rounded,
        );
      }
      rethrow;
    }
  }

  Future<void> _removePurchasedCartItems(
    List<String> cartItemIds, {
    required bool showFeedback,
  }) async {
    try {
      final snapshot = await _cartService.removeItems(cartItemIds);
      if (!mounted) return;
      _applyCartSnapshot(snapshot);
      if (showFeedback) {
        _showFeatureSnack(
          context,
          'Produk yang berhasil dipesan sudah dikeluarkan dari keranjang.',
        );
      }
    } catch (_) {
      unawaited(_loadCart());
    }
  }

  void _applyCartSnapshot(CartSnapshot snapshot) {
    setState(() {
      _cartLines = List<CartLine>.of(snapshot.items);
      _cartErrorMessage = null;
    });
  }

  Future<List<CartLine>> _reloadCartForScreen() async {
    await _loadCart();
    return List<CartLine>.of(_cartLines);
  }

  Future<OrderItem?> _createOrder(
    List<Product> items, {
    required String paymentMethod,
    required String deliveryMethod,
    String? addressId,
    required String address,
    required int finalTotal,
<<<<<<< HEAD
    CheckoutVoucher? voucher,
    required int voucherDiscount,
=======
    String? voucherLabel,
    int redeemedPoints = 0,
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
  }) async {
    final voucherLabel = voucher?.code;
    if (_canUseSupabase) {
      try {
        final groupedItems = _summarizeProducts(items);
        final orderType = deliveryMethod == 'Ambil di Koperasi'
            ? 'pickup'
            : 'delivery';
<<<<<<< HEAD
        final paymentStatus = paymentMethod == 'Saldo MepuPoin'
            ? 'paid'
            : 'unpaid';
        final orderStatus = paymentStatus == 'paid' ? 'processing' : 'pending';
        final paymentMethodId = await _paymentMethodIdForCheckout(
          paymentMethod,
        );
=======
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
        final branchContext = await _resolveCheckoutBranchContext();
        final deliveryLabel = orderType == 'delivery'
            ? _extractDeliveryLabel(address)
            : null;
        final deliveryAddress = orderType == 'delivery'
            ? _extractDeliveryAddress(address)
            : null;
        final normalizedAddressId =
            orderType == 'delivery' && _isValidUuid(addressId)
            ? addressId
            : null;
<<<<<<< HEAD

        final orderRow = await client
            .from('orders')
            .insert({
              'user_id': user.id,
              'branch_id': branchContext.branchId,
              'address_id': normalizedAddressId,
              'payment_method_id': paymentMethodId,
              'order_type': orderType,
              'order_status': orderStatus,
              'payment_status': paymentStatus,
              'customer_name': customerSnapshot.name,
              'customer_phone': customerSnapshot.phone,
              'delivery_label': deliveryLabel,
              'delivery_address': deliveryAddress,
              'subtotal': items.fold<int>(
                0,
                (sum, product) => sum + product.price,
              ),
              'discount_total': voucherDiscount,
              'delivery_fee': orderType == 'delivery' ? 8000 : 0,
              'grand_total': finalTotal,
              'notes': voucherLabel == null ? null : 'Voucher: $voucherLabel',
            })
            .select('id, order_no, placed_at')
            .single();

        await client
            .from('order_items')
            .insert(
              items
                  .map(
                    (product) => {
                      'order_id': orderRow['id'],
                      'product_id': product.id,
                      'product_name': product.name,
                      'sku': product.id,
                      'qty': 1,
                      'unit_price': product.price,
                      'discount_amount': 0,
                      'subtotal': product.price,
                    },
                  )
                  .toList(),
            );

        final voucherId = voucher?.id;
        if (voucherId != null && voucherId.isNotEmpty && voucherDiscount > 0) {
          await client.from('voucher_redemptions').insert({
            'user_id': user.id,
            'voucher_id': voucherId,
            'order_id': orderRow['id'],
            'discount_amount': voucherDiscount,
          });
          unawaited(_loadVouchers());
        }

        final orderNo = (orderRow['order_no'] ?? '').toString();
        SandboxOrderPaymentSummary? paymentSummary;
        if (paymentMethod == 'Transfer Bank' || paymentMethod == 'QRIS') {
          paymentSummary = await const SandboxOrderPaymentService()
              .createPayment(orderNo: orderNo);
        }

=======
        final itemPayload = _countProducts(items).entries
            .map((entry) => {'product_id': entry.key, 'qty': entry.value})
            .toList(growable: false);
        final result = await _orderService.placeOrder(
          items: itemPayload,
          paymentMethodCode: _paymentMethodCodeForCheckout(paymentMethod),
          orderType: orderType,
          branchId: branchContext.branchId,
          addressId: normalizedAddressId,
          deliveryLabel: deliveryLabel,
          deliveryAddress: deliveryAddress,
          notes: voucherLabel == null ? null : 'Voucher: $voucherLabel',
          serviceFee: 1500,
          redeemPoints: redeemedPoints,
        );
        if (paymentMethod == 'Saldo MepuPoin') {
          _mepuBalance = result.walletBalance;
        }
        _rewardSummary = _rewardSummary == null
            ? null
            : RewardSummary(
                currentBalance: result.rewardBalance,
                lifetimeEarned: _rewardSummary!.lifetimeEarned,
                lifetimeRedeemed:
                    _rewardSummary!.lifetimeRedeemed +
                    result.rewardPointsRedeemed,
                earnPoints: _rewardSummary!.earnPoints,
                earnAmountSpent: _rewardSummary!.earnAmountSpent,
                redeemPoints: _rewardSummary!.redeemPoints,
                redeemAmount: _rewardSummary!.redeemAmount,
                minRedeemPoints: _rewardSummary!.minRedeemPoints,
                ruleName: _rewardSummary!.ruleName,
                ruleDescription: _rewardSummary!.ruleDescription,
              );
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
        return OrderItem(
          id: result.orderNo,
          title: groupedItems.length == 1
              ? groupedItems.first
              : '${groupedItems.first} + ${groupedItems.length - 1} produk',
          status: _displayOrderStatus(
            orderStatus: result.orderStatus,
            paymentStatus: result.paymentStatus,
            orderType: result.orderType,
          ),
          createdAt: _formatOrderDate(result.placedAt.toLocal()),
          total: result.grandTotal,
          progressLabel: _backendProgressLabel(
            orderNo: result.orderNo,
            orderStatus: result.orderStatus,
            paymentStatus: result.paymentStatus,
            orderType: result.orderType,
            paymentCode: _paymentMethodCodeForCheckout(paymentMethod),
            paymentName: paymentMethod,
            providerVaNumber: paymentSummary?.providerVaNumber ?? '',
            providerBank: paymentSummary?.providerBank ?? '',
          ),
          address: result.orderType == 'pickup'
              ? '${result.branchName} - Pickup Counter'
              : address,
          items: [
            ...groupedItems,
            if (voucherLabel != null) 'Voucher: $voucherLabel',
          ],
          paymentMethodCode:
              paymentSummary?.paymentMethodCode ??
              _paymentMethodCodeForCheckout(paymentMethod),
          paymentMethodName: paymentSummary?.paymentMethodName ?? paymentMethod,
          providerVaNumber: paymentSummary?.providerVaNumber,
          providerBank: paymentSummary?.providerBank,
          providerQrUrl: paymentSummary?.providerQrUrl,
          paymentExpiresAt: paymentSummary?.paymentExpiresAt,
        );
      } catch (error) {
        if (mounted) {
          _showFeatureSnack(
            context,
            '$error',
            title: 'Pesanan Gagal',
            icon: Icons.error_outline_rounded,
          );
        }
        return null;
      }
    }

    final orderId = _generateOrderId();
    final groupedItems = _summarizeProducts(items);
    final orderItems = [
      ...groupedItems,
      if (voucherLabel != null) 'Voucher: $voucherLabel',
    ];
    final itemTitle = groupedItems.length == 1
        ? groupedItems.first
        : '${groupedItems.first} + ${groupedItems.length - 1} produk';

    return OrderItem(
      id: orderId,
      title: itemTitle,
      status: _initialOrderStatus(paymentMethod),
      createdAt: _formatOrderDate(DateTime.now()),
      total: finalTotal,
      progressLabel: _initialProgressLabel(
        orderId: orderId,
        paymentMethod: paymentMethod,
      ),
      address: deliveryMethod == 'Ambil di Koperasi'
          ? 'MepuPoin Sukamaju - Pickup Counter'
          : address,
      items: orderItems,
    );
  }

  bool _isValidUuid(String? value) {
    if (value == null) return false;
    return _uuidPattern.hasMatch(value.trim());
  }

  String _initialOrderStatus(String paymentMethod) {
    if (paymentMethod == 'Saldo MepuPoin') {
      return 'On Delivery';
    }
    return 'Payment Pending';
  }

  String _initialProgressLabel({
    required String orderId,
    required String paymentMethod,
  }) {
    if (paymentMethod == 'Saldo MepuPoin') {
      return 'Pembayaran saldo berhasil, pesanan sedang diproses';
    }
    if (paymentMethod == 'Transfer Bank') {
      final codeSuffix = orderId.replaceAll(RegExp(r'[^0-9]'), '');
      final vaSuffix = codeSuffix.length > 8
          ? codeSuffix.substring(codeSuffix.length - 8)
          : codeSuffix.padLeft(8, '0');
      return 'Virtual Account BNI 8808$vaSuffix • bayar sebelum 23:14';
    }
    if (paymentMethod == 'QRIS') {
      return 'QRIS pembayaran menunggu dipindai dan dibayar';
    }
    return 'Bayar di kasir koperasi saat mengambil pesanan';
  }

  List<String> _summarizeProducts(List<Product> items) {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.name] = (counts[item.name] ?? 0) + 1;
    }
    return counts.entries
        .map(
          (entry) =>
              entry.value == 1 ? entry.key : '${entry.key} x ${entry.value}',
        )
        .toList();
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationHistoryScreen(),
      ),
    );
  }

  Future<void> _openBranchSelector() async {
    if (_branches.isEmpty) {
      _showFeatureSnack(
        context,
<<<<<<< HEAD
        _branchLoadError == null
            ? 'Cabang KDMP belum tersedia dari backend.'
            : 'Cabang KDMP belum tersedia dari backend. Detail: $_branchLoadError',
=======
        'Cabang MepuPoin belum tersedia dari backend.',
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
        title: 'Cabang Tidak Ditemukan',
      );
      return;
    }

    final selected = await showModalBottomSheet<_UserBranchOption>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text(
<<<<<<< HEAD
                'Pilih Cabang KDMP',
=======
                'Pilih Cabang MepuPoin',
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Produk, stok, harga, dan pesanan akan mengikuti cabang yang dipilih.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6D5A58),
                ),
              ),
              const SizedBox(height: 18),
              for (final branch in _branches)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(branch),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: branch.id == _selectedBranchId
                                ? const Color(0xFFD9001B)
                                : const Color(0xFFE8BCB8),
                            width: branch.id == _selectedBranchId ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEFEF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.store_mall_directory_outlined,
                                color: Color(0xFFD9001B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    branch.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    branch.subtitle,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: const Color(0xFF6D5A58),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    branch.address,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: const Color(0xFF9A7B76),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (branch.id == _selectedBranchId)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFFD9001B),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted || selected.id == _selectedBranchId) {
      return;
    }

    setState(() {
      _selectedBranchId = selected.id;
      _selectedBranchName = selected.name;
      _selectedBranchSubtitle = selected.subtitle;
      _shopSelectedCategory = 'Semua';
    });

    await _persistSelectedBranch(selected.id);
    await _loadCatalog();
    if (!mounted) return;
    _showFeatureSnack(
      context,
      'Sekarang kamu berbelanja di ${selected.name}.',
      title: 'Cabang Diganti',
      icon: Icons.store_mall_directory_outlined,
    );
  }

  Future<void> _persistSelectedBranch(String branchId) async {
    if (!_canUseSupabase) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client
          .from('profiles')
          .update({'default_branch_id': branchId})
          .eq('id', user.id);
    } catch (_) {
      // Keep branch selection local if profile persistence fails.
    }
  }

  OrderItem? _orderFromBackendRow(Map<String, dynamic> row) {
    final orderNo = (row['order_no'] ?? '').toString().trim();
    if (orderNo.isEmpty) return null;

    final orderStatus = (row['order_status'] ?? '').toString().trim();
    final paymentStatus = (row['payment_status'] ?? '').toString().trim();
    final orderType = (row['order_type'] ?? 'delivery').toString().trim();
    final paymentRow = row['payment_methods'] is Map<String, dynamic>
        ? row['payment_methods'] as Map<String, dynamic>
        : <String, dynamic>{};
    final addressRow = row['addresses'] is Map<String, dynamic>
        ? row['addresses'] as Map<String, dynamic>
        : <String, dynamic>{};
    final itemRows = row['order_items'] is List
        ? List<Map<String, dynamic>>.from(row['order_items'] as List)
        : const <Map<String, dynamic>>[];

    final items = itemRows
        .map((item) {
          final productName = (item['product_name'] ?? '').toString().trim();
          final qty = (item['qty'] as num?)?.toInt() ?? 1;
          if (productName.isEmpty) return '';
          return qty <= 1 ? productName : '$productName x $qty';
        })
        .where((item) => item.isNotEmpty)
        .toList();

    final title = items.isEmpty
        ? 'Pesanan MepuPoin'
        : items.length == 1
        ? items.first
        : '${items.first} + ${items.length - 1} produk';

    return OrderItem(
      id: orderNo,
      title: title,
      status: _displayOrderStatus(
        orderStatus: orderStatus,
        paymentStatus: paymentStatus,
        orderType: orderType,
      ),
      createdAt: _formatBackendOrderDate(row['placed_at']),
      total: (row['grand_total'] as num?)?.toInt() ?? 0,
      progressLabel: _backendProgressLabel(
        orderNo: orderNo,
        orderStatus: orderStatus,
        paymentStatus: paymentStatus,
        orderType: orderType,
        paymentCode: (paymentRow['code'] ?? '').toString(),
        paymentName: (paymentRow['name'] ?? '').toString(),
        providerVaNumber: (row['provider_va_number'] ?? '').toString(),
        providerBank: (row['provider_bank'] ?? '').toString(),
      ),
      address: _backendOrderAddress(
        orderType: orderType,
        addressRow: addressRow,
        row: row,
      ),
      items: items,
      paymentMethodCode: (paymentRow['code'] ?? '').toString(),
      paymentMethodName: (paymentRow['name'] ?? '').toString(),
      providerVaNumber: (row['provider_va_number'] ?? '').toString(),
      providerBank: (row['provider_bank'] ?? '').toString(),
      providerQrUrl: (row['provider_qr_url'] ?? '').toString(),
      paymentExpiresAt: DateTime.tryParse(
        (row['payment_expires_at'] ?? '').toString(),
      )?.toLocal(),
    );
  }

  String _displayOrderStatus({
    required String orderStatus,
    required String paymentStatus,
    required String orderType,
  }) {
    if (orderStatus == 'cancelled') return 'Cancelled';
    if (orderStatus == 'completed') return 'Completed';
    if (orderType == 'pickup') {
      if (orderStatus == 'pending' && paymentStatus != 'paid') {
        return 'Payment Pending';
      }
      if (orderStatus == 'ready_pickup') return 'Ready for Pickup';
      return 'Preparing Pickup';
    }
    if (orderStatus == 'pending' && paymentStatus != 'paid') {
      return 'Payment Pending';
    }
    if (orderStatus == 'out_for_delivery') return 'On Delivery';
    return 'Being Prepared';
  }

  String _paymentMethodCodeForCheckout(String paymentMethod) {
    switch (paymentMethod) {
      case 'Transfer Bank':
        return 'transfer_bca';
      case 'QRIS':
        return 'qris';
      case 'Bayar di Koperasi':
        return 'cash';
      default:
        return 'wallet';
    }
  }

  Future<_CheckoutBranchContext> _resolveCheckoutBranchContext() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    const fallbackBranchName = 'Cabang MepuPoin Solo Banjarsari';

    if ((_selectedBranchId ?? '').isNotEmpty) {
      return _CheckoutBranchContext(
        branchId: _selectedBranchId,
        branchName: _selectedBranchName,
      );
    }

    if (user == null) {
      return const _CheckoutBranchContext(
        branchId: null,
        branchName: fallbackBranchName,
      );
    }

    final profileRow = await client
        .from('profiles')
        .select('default_branch_id')
        .eq('id', user.id)
        .maybeSingle();
    final defaultBranchId = profileRow?['default_branch_id']?.toString();

    if (defaultBranchId != null && defaultBranchId.isNotEmpty) {
      final branchRow = await client
          .from('branches')
          .select('id, name')
          .eq('id', defaultBranchId)
          .maybeSingle();
      if (branchRow != null) {
        return _CheckoutBranchContext(
          branchId: branchRow['id']?.toString(),
          branchName: (branchRow['name'] ?? fallbackBranchName).toString(),
        );
      }
    }

    final activeBranch = await client
        .from('branches')
        .select('id, name')
        .eq('is_active', true)
        .order('name')
        .limit(1)
        .maybeSingle();
    if (activeBranch != null) {
      return _CheckoutBranchContext(
        branchId: activeBranch['id']?.toString(),
        branchName: (activeBranch['name'] ?? fallbackBranchName).toString(),
      );
    }

    return const _CheckoutBranchContext(
      branchId: null,
      branchName: fallbackBranchName,
    );
  }

  String _extractDeliveryLabel(String rawAddress) {
    final segments = rawAddress.split('•');
    return segments.first.trim();
  }

  String _extractDeliveryAddress(String rawAddress) {
    final segments = rawAddress.split('•');
    if (segments.length <= 1) return rawAddress.trim();
    return segments.sublist(1).join('•').trim();
  }

  String _backendProgressLabel({
    required String orderNo,
    required String orderStatus,
    required String paymentStatus,
    required String orderType,
    required String paymentCode,
    required String paymentName,
    String providerVaNumber = '',
    String providerBank = '',
  }) {
    if (orderStatus == 'cancelled') {
      return 'Pesanan dibatalkan.';
    }
    if (orderStatus == 'completed') {
      return 'Pesanan selesai dan transaksi berhasil.';
    }
    if (paymentStatus != 'paid' && orderStatus == 'pending') {
      if (paymentCode.startsWith('transfer_')) {
        final bankName = providerBank.isNotEmpty
            ? providerBank.toUpperCase()
            : paymentName.isEmpty
            ? 'Bank'
            : paymentName;
        if (providerVaNumber.isNotEmpty) {
          return 'Virtual Account $bankName $providerVaNumber';
        }
        final suffix = orderNo.replaceAll(RegExp(r'[^0-9]'), '');
        final vaSuffix = suffix.length > 8
            ? suffix.substring(suffix.length - 8)
            : suffix.padLeft(8, '0');
        return 'Virtual Account $bankName 8808$vaSuffix';
      }
      if (paymentCode == 'qris') {
        return 'QRIS pembayaran menunggu dipindai dan dibayar';
      }
      return 'Bayar di kasir koperasi saat mengambil pesanan';
    }
    if (orderType == 'pickup') {
      if (orderStatus == 'ready_pickup') {
        return 'Pesanan siap diambil di koperasi';
      }
      if (orderStatus == 'confirmed') {
        return 'Pesanan sudah dikonfirmasi dan mulai disiapkan untuk pickup';
      }
      return 'Pesanan sedang disiapkan untuk pickup';
    }
    if (orderStatus == 'out_for_delivery') {
      return 'Kurir sedang menuju alamat pengantaran';
    }
    if (orderStatus == 'confirmed') {
      return 'Pesanan sudah dikonfirmasi admin cabang';
    }
    return 'Pembayaran berhasil, pesanan sedang diproses';
  }

  String _backendOrderAddress({
    required String orderType,
    required Map<String, dynamic> addressRow,
    required Map<String, dynamic> row,
  }) {
    if (orderType == 'pickup') {
      return 'MepuPoin Sukamaju - Pickup Counter';
    }
    final snapshotLabel = (row['delivery_label'] ?? '').toString().trim();
    final snapshotAddress = (row['delivery_address'] ?? '').toString().trim();
    if (snapshotLabel.isNotEmpty && snapshotAddress.isNotEmpty) {
      return '$snapshotLabel • $snapshotAddress';
    }
    if (snapshotAddress.isNotEmpty) return snapshotAddress;
    final label = (addressRow['label'] ?? '').toString().trim();
    final address = (addressRow['address'] ?? '').toString().trim();
    if (label.isEmpty) return address;
    if (address.isEmpty) return label;
    return '$label • $address';
  }

  int _stockOf(Product product) => _productStocks[product.id] ?? 0;

  Map<String, int> _countProducts(List<Product> items) {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.id] = (counts[item.id] ?? 0) + 1;
    }
    return counts;
  }

  List<Product> _expandCartLines(List<CartLine> items) {
    final expanded = <Product>[];
    for (final item in items) {
      expanded.addAll(List<Product>.filled(item.quantity, item.product));
    }
    return expanded;
  }

  bool _hasAvailableStock(
    List<Product> items, {
    required bool includeCartItems,
  }) {
    final requestedCounts = _countProducts(items);
    final cartCounts = includeCartItems
        ? {for (final item in _cartLines) item.product.id: item.quantity}
        : <String, int>{};
    for (final entry in requestedCounts.entries) {
      final product = _catalogProducts.firstWhere(
        (item) => item.id == entry.key,
        orElse: () => Product(
          id: entry.key,
          name: 'Produk',
          price: 0,
          originalPrice: 0,
          stock: 0,
          claimedPercent: 0,
          rewardPoints: 0,
          badge: '',
          description: '',
          icon: Icons.inventory_2_outlined,
          tone: const Color(0xFF8B0011),
          categories: const ['Lainnya'],
          highlights: const [],
          relatedIds: const [],
        ),
      );
      final available = _productStocks[entry.key] ?? 0;
      final totalRequested = entry.value + (cartCounts[entry.key] ?? 0);
      if (totalRequested > available) {
        _showFeatureSnack(
          context,
          'Stok ${product.name} tersisa $available. Kurangi jumlah pembelian atau pilih produk lain.',
          title: 'Stok Tidak Cukup',
          icon: Icons.inventory_2_outlined,
        );
        return false;
      }
    }
    return true;
  }

  void _decreaseStock(List<Product> items) {
    final counts = _countProducts(items);
    for (final entry in counts.entries) {
      final currentStock = _productStocks[entry.key] ?? 0;
      _productStocks[entry.key] = (currentStock - entry.value)
          .clamp(0, currentStock)
          .toInt();
    }
  }

  String _generateOrderId() {
    final now = DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return 'ORD-${twoDigits(now.day)}${twoDigits(now.month)}${now.year.toString().substring(2)}-${(_orderItems.length + 1).toString().padLeft(2, '0')}';
  }

  String _formatOrderDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  String _formatBackendOrderDate(dynamic rawValue) {
    if (rawValue is String) {
      final parsed = DateTime.tryParse(rawValue);
      if (parsed != null) {
        return _formatOrderDate(parsed.toLocal());
      }
    }
    return _formatOrderDate(DateTime.now());
  }

  Future<void> _openTopUpDialog() async {
    final request = await showDialog<_TopUpRequest>(
      context: context,
      builder: (_) => const _TopUpDialog(),
    );
    if (!mounted || request == null || request.amount <= 0) return;
    await _startSandboxTopUp(request);
  }

  Future<void> _startSandboxTopUp(_TopUpRequest request) async {
    if (!_canUseSupabase) {
      final newBalance = _mepuBalance + request.amount;
      _setWalletBalance(newBalance);
      _showFeatureSnack(
        context,
        'Mode lokal aktif. Saldo bertambah ${formatRupiah(request.amount)}.',
        title: 'Top Up Demo',
        icon: Icons.account_balance_wallet_outlined,
      );
      return;
    }

    try {
      final createdSummary = await const SandboxTopUpService().createTopUp(
        amount: request.amount,
        method: _walletPaymentMethodCode(request.method),
      );

      if (!mounted) return;

      final latestSummary = await showDialog<SandboxTopUpSummary>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SandboxPaymentDialog(
          initialSummary: createdSummary,
          onCheckStatus: () =>
              const SandboxTopUpService().syncTopUp(createdSummary.topupId),
        ),
      );
      if (!mounted) return;

      if (latestSummary == null || !latestSummary.isPaid) {
        _showFeatureSnack(
          context,
          'Transaksi masih menunggu pembayaran. Anda bisa cek status lagi nanti.',
          title: 'Menunggu Pembayaran',
          icon: Icons.schedule_outlined,
        );
        return;
      }

<<<<<<< HEAD
      final newBalance = latestSummary.walletBalance > 0
          ? latestSummary.walletBalance
          : _mepuBalance + request.amount;
=======
      final confirmResult = await Supabase.instance.client.rpc(
        'confirm_wallet_topup',
        params: {'p_topup_id': createdRow['topup_id']},
      );
      final confirmRow = _rpcRow(confirmResult);
      if (confirmRow == null) {
        throw Exception('Konfirmasi pembayaran sandbox gagal.');
      }

      final newBalance =
          (confirmRow['wallet_balance'] as num?)?.toInt() ?? _mepuBalance;
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
      if (!mounted) return;
      setState(() => _mepuBalance = newBalance);
      unawaited(_loadWalletBalance());
      unawaited(
        _createNotification(
          type: 'system',
          title: 'Top Up berhasil',
          message:
              'Saldo bertambah ${formatRupiah(request.amount)}. Saldo sekarang ${formatRupiah(newBalance)}.',
          data: {'amount': request.amount, 'wallet_balance': newBalance},
        ),
      );
      _showFeatureSnack(
        context,
        'Pembayaran sandbox sukses. Saldo bertambah ${formatRupiah(request.amount)} dan sekarang ${formatRupiah(newBalance)}.',
        title: 'Top Up Berhasil',
        icon: Icons.account_balance_wallet_outlined,
      );
    } on FunctionException catch (error) {
      if (!mounted) return;
      _showFeatureSnack(
        context,
        error.details?.toString() ??
            error.reasonPhrase ??
            'Top up sandbox gagal.',
        title: 'Top Up Gagal',
        icon: Icons.error_outline_rounded,
      );
    } catch (error) {
      if (!mounted) return;
      _showFeatureSnack(
        context,
        '$error',
        title: 'Top Up Gagal',
        icon: Icons.error_outline_rounded,
      );
    }
  }

<<<<<<< HEAD
=======
  Map<String, dynamic>? _rpcRow(dynamic result) {
    if (result is Map<String, dynamic>) return result;
    if (result is List &&
        result.isNotEmpty &&
        result.first is Map<String, dynamic>) {
      return result.first as Map<String, dynamic>;
    }
    return null;
  }

>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
  String _walletPaymentMethodCode(String method) {
    return method == 'QRIS' ? 'qris' : 'virtual_account';
  }

  Future<OrderItem?> _payOrder(OrderItem order) async {
    final index = _orderItems.indexWhere((item) => item.id == order.id);
    if (index == -1) return null;
<<<<<<< HEAD
    final isSandboxPayment =
        (order.paymentMethodCode ?? '') == 'qris' ||
        (order.paymentMethodCode ?? '').startsWith('transfer_') ||
        order.progressLabel.contains('Virtual Account') ||
        order.progressLabel.contains('QRIS');
    final usesMepuBalance = order.progressLabel.contains('Saldo MepuPoin');
    if (isSandboxPayment) {
      try {
        final paymentSummary = await const SandboxOrderPaymentService()
            .syncPayment(orderNo: order.id);
        final updatedOrder = _mergeOrderWithPaymentSummary(
          order,
          paymentSummary,
        );
        if (!mounted) return updatedOrder;
        setState(() => _orderItems[index] = updatedOrder);
        unawaited(_loadOrders());
        if (paymentSummary.isPaid) {
          unawaited(
            _createNotification(
              type: 'order',
              title: 'Pembayaran pesanan berhasil',
              message:
                  'Pesanan ${order.id} sudah dibayar melalui sandbox dan sedang diproses.',
              data: {'order_no': order.id},
            ),
          );
          _showFeatureSnack(
            context,
            'Pembayaran sandbox sudah terverifikasi. Pesanan masuk ke proses berikutnya.',
            title: 'Pembayaran Berhasil',
            icon: Icons.verified_rounded,
          );
        } else if (paymentSummary.isFailed) {
          _showFeatureSnack(
            context,
            'Pembayaran pesanan belum berhasil atau sudah kedaluwarsa.',
            title: 'Pembayaran Gagal',
            icon: Icons.error_outline_rounded,
          );
        } else {
          _showFeatureSnack(
            context,
            'Sandbox masih menunggu pembayaran untuk pesanan ini.',
            title: 'Masih Pending',
            icon: Icons.schedule_outlined,
          );
        }
=======
    if (_canUseSupabase) {
      try {
        final result = await _orderService.payOrder(order.id);
        final isTransferBank = order.progressLabel.contains('Virtual Account');
        final updatedOrder = OrderItem(
          id: order.id,
          title: order.title,
          status: _displayOrderStatus(
            orderStatus: result.orderStatus,
            paymentStatus: result.paymentStatus,
            orderType: result.orderType,
          ),
          createdAt: order.createdAt,
          total: order.total,
          progressLabel: _backendProgressLabel(
            orderNo: result.orderNo,
            orderStatus: result.orderStatus,
            paymentStatus: result.paymentStatus,
            orderType: result.orderType,
            paymentCode: isTransferBank ? 'transfer_bca' : 'cash',
            paymentName: isTransferBank ? 'Transfer Bank' : 'Bayar di Koperasi',
          ),
          address: order.address,
          items: order.items,
        );
        if (!mounted) return null;
        setState(() => _orderItems[index] = updatedOrder);
        unawaited(_loadOrders());
        _showFeatureSnack(
          context,
          'Pembayaran berhasil. Pesanan masuk ke proses berikutnya.',
          title: 'Pembayaran Berhasil',
          icon: Icons.verified_rounded,
        );
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
        return updatedOrder;
      } catch (error) {
        if (mounted) {
          _showFeatureSnack(
            context,
            '$error',
<<<<<<< HEAD
            title: 'Cek Status Gagal',
=======
            title: 'Pembayaran Gagal',
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
            icon: Icons.error_outline_rounded,
          );
        }
        return null;
      }
<<<<<<< HEAD
    }
    if (usesMepuBalance && _mepuBalance < order.total) {
      _showFeatureSnack(
        context,
        'Saldo kamu kurang ${formatRupiah(order.total - _mepuBalance)} untuk membayar pesanan ini.',
        title: 'Saldo Tidak Cukup',
        icon: Icons.account_balance_wallet_outlined,
        actionLabel: 'Isi Saldo',
        onAction: _openTopUpDialog,
      );
      return null;
=======
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
    }

    late final OrderItem updatedOrder;
    setState(() {
      updatedOrder = OrderItem(
        id: order.id,
        title: order.title,
        status: order.address.contains('Pickup Counter')
            ? 'Ready for Pickup'
            : 'On Delivery',
        createdAt: order.createdAt,
        total: order.total,
        progressLabel: order.address.contains('Pickup Counter')
            ? 'Pesanan siap diambil di koperasi'
            : 'Pembayaran berhasil, pesanan sedang diproses',
        address: order.address,
        items: order.items,
      );
      _orderItems[index] = updatedOrder;
    });
<<<<<<< HEAD
    if (_canUseSupabase) {
      final nextStatus = order.address.contains('Pickup Counter')
          ? 'ready_pickup'
          : 'processing';
      unawaited(
        Supabase.instance.client
            .from('orders')
            .update({'order_status': nextStatus, 'payment_status': 'paid'})
            .eq('order_no', order.id)
            .then((_) => _loadOrders()),
      );
    }
    if (usesMepuBalance) {
      unawaited(_persistWalletBalance(_mepuBalance));
      unawaited(_loadWalletBalance());
    }
    unawaited(
      _createNotification(
        type: usesMepuBalance ? 'system' : 'order',
        title: usesMepuBalance
            ? 'Pembayaran saldo berhasil'
            : 'Pembayaran pesanan dikonfirmasi',
        message: usesMepuBalance
            ? 'Pembayaran untuk pesanan ${order.id} berhasil. Saldo sekarang ${formatRupiah(_mepuBalance)}.'
            : 'Pesanan ${order.id} berhasil dibayar dan sedang diproses.',
        data: {'order_no': order.id, 'wallet_balance': _mepuBalance},
      ),
    );
    _showFeatureSnack(
      context,
      'Pembayaran berhasil. Pesanan masuk ke Aktif.',
      title: 'Pembayaran Berhasil',
      icon: Icons.verified_rounded,
    );
    return updatedOrder;
  }

  OrderItem _mergeOrderWithPaymentSummary(
    OrderItem order,
    SandboxOrderPaymentSummary summary,
  ) {
    final isPickup = order.address.contains('Pickup Counter');
    final nextStatus = summary.paymentStatus == 'paid'
        ? (isPickup ? 'Preparing Pickup' : 'On Delivery')
        : summary.isFailed
        ? 'Cancelled'
        : 'Payment Pending';

    final nextProgressLabel = _backendProgressLabel(
      orderNo: summary.orderNo,
      orderStatus: summary.orderStatus,
      paymentStatus: summary.paymentStatus,
      orderType: isPickup ? 'pickup' : 'delivery',
      paymentCode: summary.paymentMethodCode,
      paymentName: summary.paymentMethodName,
      providerVaNumber: summary.providerVaNumber,
      providerBank: summary.providerBank,
    );

    return OrderItem(
      id: order.id,
      title: order.title,
      status: nextStatus,
      createdAt: order.createdAt,
      total: order.total,
      progressLabel: nextProgressLabel,
      address: order.address,
      items: order.items,
      paymentMethodCode: summary.paymentMethodCode,
      paymentMethodName: summary.paymentMethodName,
      providerVaNumber: summary.providerVaNumber,
      providerBank: summary.providerBank,
      providerQrUrl: summary.providerQrUrl,
      paymentExpiresAt: summary.paymentExpiresAt,
    );
  }

  void _cancelOrder(OrderItem order) {
=======
    return updatedOrder;
  }

  Future<void> _cancelOrder(OrderItem order) async {
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
    if (_canUseSupabase) {
      try {
        await _orderService.cancelOrder(order.id);
        if (!mounted) return;
        setState(() {
          final index = _orderItems.indexWhere((item) => item.id == order.id);
          if (index != -1) {
            _orderItems[index] = OrderItem(
              id: order.id,
              title: order.title,
              status: 'Cancelled',
              createdAt: order.createdAt,
              total: order.total,
              progressLabel: 'Pesanan dibatalkan.',
              address: order.address,
              items: order.items,
            );
          }
        });
        unawaited(_loadCatalog());
        unawaited(_loadOrders());
        _showFeatureSnack(
          context,
          'Pesanan ${order.id} dibatalkan.',
          title: 'Pesanan Dibatalkan',
          icon: Icons.cancel_outlined,
        );
        return;
      } catch (error) {
        if (mounted) {
          _showFeatureSnack(
            context,
            '$error',
            title: 'Pembatalan Gagal',
            icon: Icons.error_outline_rounded,
          );
        }
<<<<<<< HEAD
      });
      unawaited(
        Supabase.instance.client
            .from('orders')
            .update({'order_status': 'cancelled', 'payment_status': 'failed'})
            .eq('order_no', order.id)
            .then((_) => _loadOrders()),
      );
      unawaited(
        _createNotification(
          type: 'order',
          title: 'Pesanan dibatalkan',
          message: 'Pesanan ${order.id} telah dibatalkan.',
          data: {'order_no': order.id},
        ),
      );
=======
        return;
      }
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
    } else {
      setState(() {
        _orderItems.removeWhere((item) => item.id == order.id);
      });
    }
    _showFeatureSnack(
      context,
      'Pesanan ${order.id} dibatalkan.',
      title: 'Pesanan Dibatalkan',
      icon: Icons.cancel_outlined,
    );
  }

  void _openSetting(SettingShortcut setting) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          switch (setting.title) {
            case 'Saved Addresses':
              return const ManageAddressesScreen();
            case 'Payment Methods':
              return const PaymentMethodsScreen();
            case 'Notifications':
              return const NotificationSettingsScreen();
            case 'Security':
              return const SecuritySettingsScreen();
            default:
              return SettingDetailScreen(setting: setting);
          }
        },
      ),
    );
  }

  void _openPromoCenter() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PromoCenterScreen(promotions: _catalogPromotions),
      ),
    );
  }

  void _openRewardHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RewardHistoryScreen(summary: _rewardSummary),
      ),
    );
  }

  void _openFaq() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const FaqScreen()));
  }

  void _openContactSupport() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ContactSupportScreen()),
    );
  }

  void _handleLogout() {
    widget.onLogout();
  }

  Future<void> _openEditProfile() async {
    final updatedProfile = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute<UserProfile>(
        builder: (_) => EditProfileScreen(profile: _profile),
      ),
    );
    if (!mounted || updatedProfile == null) return;

    setState(() => _profile = updatedProfile);
    widget.onProfileChanged?.call(updatedProfile);
    _showFeatureSnack(
      context,
      'Data profil berhasil diperbarui.',
      title: 'Profil Tersimpan',
      icon: Icons.verified_user_outlined,
    );
  }
}

Map<String, int> _createStocks(List<Product> items) {
  return {for (final product in items) product.id: product.stock};
}

Future<void> _showFeatureSnack(
  BuildContext context,
  String message, {
  String title = 'Informasi',
  IconData icon = Icons.info_outline_rounded,
  String actionLabel = 'Mengerti',
  VoidCallback? onAction,
}) {
  _TopNotificationController.instance.show(
    context,
    title: title,
    message: message,
    icon: icon,
    actionLabel: actionLabel == 'Mengerti' ? null : actionLabel,
    onAction: onAction,
  );
  return Future<void>.value();
}

class _TopNotificationController {
  _TopNotificationController._();

  static final instance = _TopNotificationController._();
  OverlayEntry? _entry;
  Timer? _timer;

  void show(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _timer?.cancel();
    _entry?.remove();

    final overlay = Overlay.of(context);
    if (overlay.mounted == false) return;

    _entry = OverlayEntry(
      builder: (context) => _TopNotificationBanner(
        title: title,
        message: message,
        icon: icon,
        actionLabel: actionLabel,
        onTapAction: () {
          hide();
          onAction?.call();
        },
      ),
    );

    overlay.insert(_entry!);
    _timer = Timer(const Duration(seconds: 1), hide);
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _TopNotificationBanner extends StatefulWidget {
  const _TopNotificationBanner({
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onTapAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onTapAction;

  @override
  State<_TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<_TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: IgnorePointer(
        ignoring: widget.onTapAction == null,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, -0.35),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTapAction,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.icon,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF64748B),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopUpDialog extends StatefulWidget {
  const _TopUpDialog();

  @override
  State<_TopUpDialog> createState() => _TopUpDialogState();
}

class _TopUpDialogState extends State<_TopUpDialog> {
  final TextEditingController _amountController = TextEditingController();
  int _selectedAmount = 100000;
  String _selectedMethod = 'Virtual Account';
  String? _errorText;

  static const _quickAmounts = [50000, 100000, 250000, 500000];
  static const _adminFee = 1000;

  @override
  void initState() {
    super.initState();
    _amountController.text = _selectedAmount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = _currentAmount();
    final totalPayment = amount + (amount > 0 ? _adminFee : 0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Material(
            color: const Color(0xFFF8FAFC),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_outlined,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Isi Saldo MepuPoin',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: const Color(0xFF111827),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Saldo masuk instan setelah pembayaran berhasil.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE5EAF1),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD9001B), Color(0xFFAE0017)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: const Color(0xFFFFD5D9),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26D9001B),
                                blurRadius: 24,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'Top up instant',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Saldo yang akan masuk',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                formatRupiah(amount),
                                style: theme.textTheme.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.receipt_long_outlined,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Total pembayaran ${formatRupiah(totalPayment)}',
                                        style: theme.textTheme.labelLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopUpSectionTitle(
                          icon: Icons.payments_outlined,
                          title: 'Pilih Nominal',
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          itemCount: _quickAmounts.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 2.7,
                              ),
                          itemBuilder: (context, index) {
                            final quickAmount = _quickAmounts[index];
                            return _TopUpAmountChip(
                              amount: quickAmount,
                              selected: _selectedAmount == quickAmount,
                              onTap: () => _selectAmount(quickAmount),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Nominal Manual',
                            prefixText: 'Rp ',
                            helperText: 'Minimal top up Rp 10.000',
                            errorText: _errorText,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 1.4,
                              ),
                            ),
                          ),
                          onChanged: (_) {
                            if (_errorText != null) {
                              setState(() => _errorText = null);
                            }
                            setState(() => _selectedAmount = _currentAmount());
                          },
                        ),
                        const SizedBox(height: 20),
                        _TopUpSectionTitle(
                          icon: Icons.credit_card_rounded,
                          title: 'Metode Pembayaran',
                        ),
                        const SizedBox(height: 12),
                        _TopUpMethodTile(
                          icon: Icons.account_balance_rounded,
                          title: 'Virtual Account',
                          subtitle: 'BCA, BRI, BNI, Mandiri',
                          selected: _selectedMethod == 'Virtual Account',
                          onTap: () => _selectMethod('Virtual Account'),
                        ),
                        const SizedBox(height: 10),
                        _TopUpMethodTile(
                          icon: Icons.qr_code_2_rounded,
                          title: 'QRIS',
                          subtitle: 'Bayar dari e-wallet atau mobile banking',
                          selected: _selectedMethod == 'QRIS',
                          onTap: () => _selectMethod('QRIS'),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE5EAF1)),
                          ),
                          child: Column(
                            children: [
                              _TopUpSummaryRow(
                                label: 'Saldo masuk',
                                value: formatRupiah(amount),
                              ),
                              const SizedBox(height: 10),
                              _TopUpSummaryRow(
                                label: 'Biaya admin',
                                value: amount > 0
                                    ? formatRupiah(_adminFee)
                                    : '-',
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Divider(height: 1),
                              ),
                              _TopUpSummaryRow(
                                label: 'Total bayar',
                                value: formatRupiah(totalPayment),
                                emphasized: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text('Batal'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _submit,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  backgroundColor: theme.colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text('Bayar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectAmount(int amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toString();
      _errorText = null;
    });
  }

  void _selectMethod(String method) {
    setState(() => _selectedMethod = method);
  }

  int _currentAmount() {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  void _submit() {
    final amount = _currentAmount();
    if (amount < 10000) {
      setState(() => _errorText = 'Minimal top up Rp 10.000');
      return;
    }
    Navigator.of(
      context,
    ).pop(_TopUpRequest(amount: amount, method: _selectedMethod));
  }
}

class _TopUpRequest {
  const _TopUpRequest({required this.amount, required this.method});

  final int amount;
  final String method;
}

class _SandboxPaymentDialog extends StatefulWidget {
  const _SandboxPaymentDialog({
    required this.initialSummary,
    required this.onCheckStatus,
  });

  final SandboxTopUpSummary initialSummary;
  final Future<SandboxTopUpSummary> Function() onCheckStatus;

  @override
  State<_SandboxPaymentDialog> createState() => _SandboxPaymentDialogState();
}

class _SandboxPaymentDialogState extends State<_SandboxPaymentDialog> {
  late SandboxTopUpSummary _summary = widget.initialSummary;
  bool _isChecking = false;
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expiresAt = _summary.expiresAt;
    final expiresLabel = expiresAt == null
        ? '-'
        : '${expiresAt.day.toString().padLeft(2, '0')}/${expiresAt.month.toString().padLeft(2, '0')}/${expiresAt.year} '
              '${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}';

    return Dialog(
<<<<<<< HEAD
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: theme.colorScheme.primary,
=======
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: const Color(0xFFF8FAFC),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: theme.colorScheme.primary,
                      ),
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pembayaran Sandbox',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Simulasikan pembayaran untuk menambahkan saldo ke akun.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(false),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5EAF1)),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD9001B), Color(0xFFAE0017)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26D9001B),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
<<<<<<< HEAD
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pembayaran',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _TopUpSummaryRow(
                      label: 'Reference',
                      value: _summary.reference,
                    ),
                    const SizedBox(height: 10),
                    _TopUpSummaryRow(
                      label: 'Metode',
                      value: _summary.paymentMethodLabel,
                    ),
                    const SizedBox(height: 10),
                    _TopUpSummaryRow(
                      label: 'Status',
                      value: _statusLabel(_summary.status),
                    ),
                    const SizedBox(height: 10),
                    _TopUpSummaryRow(
                      label: 'Saldo masuk',
                      value: formatRupiah(_summary.amount),
                    ),
                    const SizedBox(height: 10),
                    _TopUpSummaryRow(
                      label: 'Biaya admin',
                      value: formatRupiah(_summary.adminFee),
                    ),
                    const Divider(height: 24),
                    _TopUpSummaryRow(
                      label: 'Total bayar',
                      value: formatRupiah(_summary.totalPayment),
                      emphasized: true,
                    ),
                    const SizedBox(height: 10),
                    _TopUpSummaryRow(
                      label: 'Berlaku sampai',
                      value: expiresLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_summary.paymentMethod == 'qris' &&
                  _summary.providerQrUrl.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Scan QRIS',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _summary.providerQrUrl,
                          height: 220,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 180,
                                alignment: Alignment.center,
                                child: const Text('QR gagal dimuat'),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_summary.paymentMethod == 'virtual_account') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
=======
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total bayar',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatRupiah(summary.totalPayment),
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CheckoutInfoChip(
                            icon: Icons.receipt_long_outlined,
                            label: summary.paymentMethodLabel,
                          ),
                          _CheckoutInfoChip(
                            icon: Icons.schedule_rounded,
                            label: expiresLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE5EAF1)),
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
                  ),
                  child: Column(
                    children: [
                      _TopUpSummaryRow(
<<<<<<< HEAD
                        label: 'Bank',
                        value: _summary.providerBank.isEmpty
                            ? 'BCA'
                            : _summary.providerBank.toUpperCase(),
                      ),
                      const SizedBox(height: 10),
                      _TopUpSummaryRow(
                        label: 'Virtual Account',
                        value: _summary.providerVaNumber.isEmpty
                            ? '-'
                            : _summary.providerVaNumber,
=======
                        label: 'Reference',
                        value: summary.reference,
                      ),
                      const SizedBox(height: 12),
                      _TopUpSummaryRow(
                        label: 'Metode',
                        value: summary.paymentMethodLabel,
                      ),
                      const SizedBox(height: 12),
                      _TopUpSummaryRow(
                        label: 'Saldo masuk',
                        value: formatRupiah(summary.amount),
                      ),
                      const SizedBox(height: 12),
                      _TopUpSummaryRow(
                        label: 'Biaya admin',
                        value: formatRupiah(summary.adminFee),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1),
                      ),
                      _TopUpSummaryRow(
                        label: 'Total bayar',
                        value: formatRupiah(summary.totalPayment),
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
<<<<<<< HEAD
                const SizedBox(height: 16),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 14),
                Text(
                  _errorText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB42318),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isChecking
                          ? null
                          : () => Navigator.of(
                              context,
                            ).pop(_summary.isPaid ? _summary : null),
                      child: Text(_summary.isPaid ? 'Selesai' : 'Tutup'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isChecking || _summary.isPaid
                          ? null
                          : _checkStatus,
                      icon: _isChecking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded),
                      label: Text(_summary.isPaid ? 'Lunas' : 'Cek Status'),
                    ),
                  ),
                ],
              ),
            ],
=======
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Nanti Saja'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Simulasikan Berhasil'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
          ),
        ),
      ),
    );
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isChecking = true;
      _errorText = null;
    });

    try {
      final latest = await widget.onCheckStatus();
      if (!mounted) return;
      setState(() => _summary = latest);
      if (latest.isPaid) {
        Navigator.of(context).pop(latest);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorText = '$error');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Berhasil';
      case 'expired':
        return 'Kedaluwarsa';
      case 'failed':
        return 'Gagal';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Menunggu Pembayaran';
    }
  }
}

class _TopUpSectionTitle extends StatelessWidget {
  const _TopUpSectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TopUpMethodTile extends StatelessWidget {
  const _TopUpMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.30)
                : const Color(0xFFE5EAF1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : const Color(0xFFCBD5E1),
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopUpSummaryRow extends StatelessWidget {
  const _TopUpSummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
          )
        : theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF475569),
            fontWeight: FontWeight.w600,
          );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

class _TopUpAmountChip extends StatelessWidget {
  const _TopUpAmountChip({
    required this.amount,
    required this.selected,
    required this.onTap,
  });

  final int amount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : const Color(0xFFE5EAF1),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          formatRupiah(amount),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? Colors.white : theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.cartItemCount,
    required this.mepuBalance,
    required this.productStocks,
    required this.products,
    required this.categories,
    required this.promotions,
    required this.catalogErrorMessage,
    required this.selectedBranchName,
    required this.selectedBranchSubtitle,
    required this.onOpenProduct,
    required this.onChangeTab,
    required this.onOpenCart,
    required this.onAddToCart,
    required this.onTopUp,
    required this.onOpenSearch,
    required this.onSelectCategory,
    required this.onOpenNotifications,
    required this.onSelectBranch,
  });

  final int cartItemCount;
  final int mepuBalance;
  final Map<String, int> productStocks;
  final List<Product> products;
  final List<String> categories;
  final List<PromoBanner> promotions;
  final String? catalogErrorMessage;
  final String selectedBranchName;
  final String selectedBranchSubtitle;
  final ValueChanged<Product> onOpenProduct;
  final ValueChanged<int> onChangeTab;
  final VoidCallback onOpenCart;
  final ValueChanged<Product> onAddToCart;
  final VoidCallback onTopUp;
  final VoidCallback onOpenSearch;
  final ValueChanged<String> onSelectCategory;
  final VoidCallback onOpenNotifications;
  final VoidCallback onSelectBranch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HomeRedHeader(
              cartItemCount: cartItemCount,
              onOpenCart: onOpenCart,
              onOpenNotifications: onOpenNotifications,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SelectedBranchCard(
                branchName: selectedBranchName,
                branchSubtitle: selectedBranchSubtitle,
                onTap: onSelectBranch,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _MepuPoinBalanceCard(
                balance: mepuBalance,
                onTopUpTap: onTopUp,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: _MepuPoinSearchBar(
                onSearchTap: onOpenSearch,
              ),
            ),
          ),
          if (promotions.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: _MepuPoinBannerCarousel(
                  promotions: promotions,
                  onTap: () => onChangeTab(1),
                ),
              ),
            ),
          if (catalogErrorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: _CatalogErrorCard(message: catalogErrorMessage!),
              ),
            ),
          SliverToBoxAdapter(
            child: _MepuPoinSectionHeader(
              title: 'Kategori Cepat',
              actionLabel: 'Lihat Semua',
              onActionTap: () => onSelectCategory('Semua'),
            ),
          ),
          SliverToBoxAdapter(
            child: _CategoryShortcutList(
              categories: categories,
              onSelectCategory: onSelectCategory,
            ),
          ),
          SliverToBoxAdapter(
            child: _MepuPoinSectionHeader(
              title: 'Produk Unggulan',
              actionLabel: 'Lihat Semua',
              onActionTap: () => onChangeTab(1),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverGrid.builder(
              itemCount: products.isEmpty ? 0 : products.length.clamp(0, 4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (context, index) {
                final product = products[(index + 2) % products.length];
                return _MepuPoinRecommendationCard(
                  product: product,
                  stock: productStocks[product.id] ?? 0,
                  onTap: () => onOpenProduct(product),
                  onAddToCart: () => onAddToCart(product),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: _MepuPoinSectionHeader(
              title: 'Terbaru',
              actionLabel: 'Lihat Semua',
              onActionTap: () => onChangeTab(1),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 190,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _MepuPoinMiniProductCard(
                    product: product,
                    stock: productStocks[product.id] ?? 0,
                    ctaLabel: '+ Keranjang',
                    onTap: () => onAddToCart(product),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeRedHeader extends StatelessWidget {
  const _HomeRedHeader({
    required this.cartItemCount,
    required this.onOpenCart,
    required this.onOpenNotifications,
  });

  final int cartItemCount;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Icon(
            Icons.store_mall_directory_outlined,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            'MepuPoin',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          _MepuPoinHeaderButton(
            icon: Icons.notifications_none_rounded,
            onTap: onOpenNotifications,
          ),
          const SizedBox(width: 8),
          _MepuPoinHeaderButton(
            icon: Icons.shopping_cart_outlined,
            badgeCount: cartItemCount,
            onTap: onOpenCart,
          ),
        ],
      ),
    );
  }
}

class _MepuPoinHeaderButton extends StatelessWidget {
  const _MepuPoinHeaderButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 18, color: const Color(0xFF111827)),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 1,
            top: 0,
            child: _CartCountBadge(count: badgeCount),
          ),
      ],
    );
  }
}

class _CartCountBadge extends StatelessWidget {
  const _CartCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      ),
    );
  }
}

class _MepuPoinBalanceCard extends StatelessWidget {
  const _MepuPoinBalanceCard({required this.balance, required this.onTopUpTap});

  final int balance;
  final VoidCallback onTopUpTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo MepuPoin',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupiah(balance),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onTopUpTap,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
            label: const Text('Isi Saldo'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(112, 42),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MepuPoinSearchBar extends StatelessWidget {
  const _MepuPoinSearchBar({
    required this.onSearchTap,
  });

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onSearchTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, size: 18),
            const SizedBox(width: 8),
            Text(
              'Cari sembako, alat tani, pupuk...',
              style: theme.textTheme.labelMedium?.copyWith(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MepuPoinBannerCarousel extends StatefulWidget {
  const _MepuPoinBannerCarousel({
    required this.promotions,
    required this.onTap,
  });

  final List<PromoBanner> promotions;
  final VoidCallback onTap;

  @override
  State<_MepuPoinBannerCarousel> createState() =>
      _MepuPoinBannerCarouselState();
}

class _MepuPoinBannerCarouselState extends State<_MepuPoinBannerCarousel> {
  final PageController _controller = PageController();
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted ||
          !_controller.hasClients ||
          widget.promotions.length <= 1) {
        return;
      }
      final nextIndex = (_currentIndex + 1) % widget.promotions.length;
      _controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final promotions = widget.promotions;

    return Column(
      children: [
        SizedBox(
          height: 156,
          child: PageView.builder(
            controller: _controller,
            itemCount: promotions.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final slide = promotions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: slide.colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          bottom: -18,
                          child: Icon(
                            slide.icon,
                            color: Colors.white.withValues(alpha: 0.18),
                            size: 118,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Promo Aktif',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              slide.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Text(
                                  'Lihat Promo',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < promotions.length; index++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: _currentIndex == index ? 18 : 7,
                height: 7,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? theme.colorScheme.primary
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CatalogErrorCard extends StatelessWidget {
  const _CatalogErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5C38B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: theme.colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catalog belum tersedia',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF7C5B2A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryShortcutList extends StatelessWidget {
  const _CategoryShortcutList({
    required this.categories,
    required this.onSelectCategory,
  });

  final List<String> categories;
  final ValueChanged<String> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 94,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length <= 1 ? 0 : categories.length - 1,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = categories[index + 1];
          final icon = categoryIcon(category);
          return InkWell(
            onTap: () => onSelectCategory(category),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 82,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MepuPoinSectionHeader extends StatelessWidget {
  const _MepuPoinSectionHeader({
    required this.title,
    this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (actionLabel != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MepuPoinMiniProductCard extends StatelessWidget {
  const _MepuPoinMiniProductCard({
    required this.product,
    required this.stock,
    required this.ctaLabel,
    required this.onTap,
  });

  final Product product;
  final int stock;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 118,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProductMedia(
                product: product,
                borderRadius: BorderRadius.circular(8),
                fit: BoxFit.cover,
                padding: const EdgeInsets.all(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatRupiah(product.price),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stock > 0 ? 'Stok $stock' : 'Stok habis',
              style: theme.textTheme.labelSmall?.copyWith(
                color: stock > 0
                    ? const Color(0xFF15803D)
                    : theme.colorScheme.error,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: stock > 0 ? onTap : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                side: BorderSide(color: theme.colorScheme.primary),
                minimumSize: const Size.fromHeight(26),
                padding: EdgeInsets.zero,
                textStyle: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(ctaLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _MepuPoinRecommendationCard extends StatelessWidget {
  const _MepuPoinRecommendationCard({
    required this.product,
    required this.stock,
    required this.onTap,
    required this.onAddToCart,
  });

  final Product product;
  final int stock;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ProductMedia(
                product: product,
                fit: BoxFit.contain,
                borderRadius: BorderRadius.circular(10),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            formatRupiah(product.price),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            stock > 0 ? 'Stok $stock' : 'Stok habis',
            style: theme.textTheme.labelSmall?.copyWith(
              color: stock > 0
                  ? const Color(0xFF15803D)
                  : theme.colorScheme.error,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          FilledButton(
            onPressed: stock > 0 ? onAddToCart : null,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(32),
              padding: EdgeInsets.zero,
              textStyle: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Beli'),
          ),
        ],
      ),
    );
  }
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.cartItemCount,
    required this.productStocks,
    required this.products,
    required this.categories,
    required this.catalogErrorMessage,
    required this.selectedCategory,
    required this.searchRequestToken,
    required this.selectedBranchName,
    required this.onOpenProduct,
    required this.onOpenCart,
    required this.onAddToCart,
    required this.onSelectBranch,
  });

  final int cartItemCount;
  final Map<String, int> productStocks;
  final List<Product> products;
  final List<String> categories;
  final String? catalogErrorMessage;
  final String selectedCategory;
  final int searchRequestToken;
  final String selectedBranchName;
  final ValueChanged<Product> onOpenProduct;
  final VoidCallback onOpenCart;
  final ValueChanged<Product> onAddToCart;
  final VoidCallback onSelectBranch;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late String selectedCategory = widget.selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String searchQuery = '';
  String sortOption = 'Terpopuler';

  @override
  void didUpdateWidget(covariant ShopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      setState(() => selectedCategory = widget.selectedCategory);
    }
    if (oldWidget.searchRequestToken != widget.searchRequestToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = widget.categories;
    final displayedProducts = _buildSortedProducts();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Text(
                  widget.selectedBranchName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 24,
                  ),
                ),
                const Spacer(),
                _HeaderActionButton(
                  icon: Icons.shopping_cart_outlined,
                  badgeCount: widget.cartItemCount,
                  onTap: widget.onOpenCart,
                ),
                const SizedBox(width: 10),
                _HeaderActionButton(
                  icon: Icons.swap_vert_rounded,
                  onTap: () => _openSortMenuFromButton(context),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: 'Cari produk...',
                  onChanged: (value) =>
                      setState(() => searchQuery = value.trim()),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 46,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return _FilterChip(
                        label: category,
                        icon: categoryIcon(category),
                        selected: selectedCategory == category,
                        onTap: () =>
                            setState(() => selectedCategory = category),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTapDown: (details) =>
                      _openSortMenu(context, details.globalPosition),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _sortIndicatorIcon(),
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Urutkan: $sortOption',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          sliver: displayedProducts.isEmpty
              ? SliverToBoxAdapter(
                  child: _EmptyProductState(
                    category: selectedCategory,
                    searchQuery: searchQuery,
                    errorMessage: widget.catalogErrorMessage,
                    onReset: () => setState(() => selectedCategory = 'Semua'),
                  ),
                )
              : SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = displayedProducts[index];
                    return ProductCard(
                      product: product,
                      stock: widget.productStocks[product.id] ?? 0,
                      variant: ProductCardVariant.catalog,
                      onTap: () => widget.onOpenProduct(product),
                      onAddToCart: () => widget.onAddToCart(product),
                    );
                  }, childCount: displayedProducts.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _openSortMenuFromButton(BuildContext context) async {
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final topRight = Offset(overlayBox.size.width - 24, kToolbarHeight + 24);
    await _openSortMenu(context, topRight);
  }

  Future<void> _openSortMenu(
    BuildContext context,
    Offset globalPosition,
  ) async {
    const options = [
      'Harga Terendah',
      'Harga Tertinggi',
      'Terbaru',
      'Terpopuler',
    ];
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlayBox.size.width - globalPosition.dx,
        overlayBox.size.height - globalPosition.dy,
      ),
      color: Colors.white,
      elevation: 12,
      shadowColor: const Color(0x220F172A),
      surfaceTintColor: Colors.white,
      menuPadding: const EdgeInsets.all(10),
      constraints: const BoxConstraints(minWidth: 196),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      items: [
        for (final option in options)
          PopupMenuItem<String>(
            value: option,
            padding: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: sortOption == option
                    ? const Color(0xFFFFF1F1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sortOption == option
                      ? const Color(0xFFFFD8D8)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    sortOption == option
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: sortOption == option
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF94A3B8),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    option,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: sortOption == option
                          ? const Color(0xFF111827)
                          : const Color(0xFF475569),
                      fontWeight: sortOption == option
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    if (!context.mounted || selected == null || selected == sortOption) return;
    setState(() => sortOption = selected);
  }

  List<Product> _buildSortedProducts() {
    final filteredProducts = selectedCategory == 'Semua'
        ? widget.products
        : widget.products
              .where(
                (product) => productMatchesCategory(product, selectedCategory),
              )
              .toList();
    final normalizedQuery = searchQuery.trim().toLowerCase();
    final queryProducts = normalizedQuery.isEmpty
        ? filteredProducts
        : filteredProducts.where((product) {
            final haystacks = [
              product.name,
              product.description,
              product.badge,
              ...product.categories,
            ];
            return haystacks.any(
              (value) => value.toLowerCase().contains(normalizedQuery),
            );
          }).toList();
    final sortedProducts = List<Product>.of(queryProducts);

    switch (sortOption) {
      case 'Harga Terendah':
        sortedProducts.sort((a, b) => a.price.compareTo(b.price));
      case 'Harga Tertinggi':
        sortedProducts.sort((a, b) => b.price.compareTo(a.price));
      case 'Terbaru':
        sortedProducts.sort((a, b) => b.id.compareTo(a.id));
      case 'Terpopuler':
        sortedProducts.sort(
          (a, b) => b.claimedPercent.compareTo(a.claimedPercent),
        );
    }

    return sortedProducts;
  }

  IconData _sortIndicatorIcon() {
    switch (sortOption) {
      case 'Harga Terendah':
        return Icons.arrow_downward_rounded;
      case 'Harga Tertinggi':
        return Icons.arrow_upward_rounded;
      default:
        return Icons.swap_vert_rounded;
    }
  }
}

class _EmptyProductState extends StatelessWidget {
  const _EmptyProductState({
    required this.category,
    required this.searchQuery,
    required this.errorMessage,
    required this.onReset,
  });

  final String category;
  final String searchQuery;
  final String? errorMessage;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text('Produk tidak ditemukan', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            errorMessage ??
                (searchQuery.isNotEmpty
                    ? 'Tidak ada produk yang cocok dengan pencarian "$searchQuery".'
                    : category == 'Semua'
                    ? 'Belum ada produk untuk ditampilkan.'
                    : 'Belum ada produk untuk kategori $category.'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: onReset,
            child: const Text('Tampilkan Semua'),
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(pinned: true, title: Text('History')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD9001B), Color(0xFF8E0011)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Riwayat transaksi & notifikasi',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pantau top up, promo, dan update akun dalam satu tempat.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.history_toggle_off_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...activities.map((entry) => ActivityTile(entry: entry)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
    required this.orders,
    required this.onOpenOrder,
    required this.onPayOrder,
    required this.onCancelOrder,
  });

  final List<OrderItem> orders;
  final ValueChanged<OrderItem> onOpenOrder;
  final ValueChanged<OrderItem> onPayOrder;
  final Future<void> Function(OrderItem order) onCancelOrder;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final activeOrders = widget.orders
        .where(
          (order) =>
              order.status == 'Being Prepared' ||
              order.status == 'Preparing Pickup' ||
              order.status == 'On Delivery' ||
              order.status == 'Ready for Pickup',
        )
        .toList();
    final historyOrders = widget.orders
        .where(
          (order) =>
              order.status == 'Payment Pending' ||
              order.status == 'Completed' ||
              order.status == 'Cancelled',
        )
        .toList();

    return CustomScrollView(
      slivers: [
        const SliverAppBar(pinned: true, title: Text('Pesanan')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: _SegmentedTabs(
              labels: const ['Pesanan Aktif', 'Histori Pesanan'],
              selectedIndex: selectedTab,
              onChanged: (index) => setState(() => selectedTab = index),
            ),
          ),
        ),
        if (selectedTab == 0) ...[
          if (activeOrders.isEmpty)
            const SliverToBoxAdapter(
              child: _EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada pesanan aktif',
                subtitle: 'Pesanan yang sedang diproses akan muncul di sini.',
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _ActiveOrderProgressCard(
                  order: activeOrders.first,
                  onTrack: () => widget.onOpenOrder(activeOrders.first),
                ),
              ),
            ),
            SliverList.builder(
              itemCount: activeOrders.length,
              itemBuilder: (context, index) {
                final order = activeOrders[index];
                return Padding(
                  padding: EdgeInsets.fromLTRB(20, index == 0 ? 8 : 8, 20, 8),
                  child: OrderCard(
                    order: order,
                    onTap: () => widget.onOpenOrder(order),
                  ),
                );
              },
            ),
          ],
        ] else ...[
          if (historyOrders.isEmpty)
            const SliverToBoxAdapter(
              child: _EmptyState(
                icon: Icons.history_rounded,
                title: 'Belum ada histori pesanan',
                subtitle:
                    'Pesanan selesai dan transaksi lain akan tersimpan di sini.',
              ),
            )
          else
            SliverList.builder(
              itemCount: historyOrders.length,
              itemBuilder: (context, index) {
                final order = historyOrders[index];
                return Padding(
                  padding: EdgeInsets.fromLTRB(20, index == 0 ? 0 : 8, 20, 12),
                  child: order.status == 'Payment Pending'
                      ? _PendingPaymentCard(
                          order: order,
                          onPay: () => widget.onPayOrder(order),
                          onCancel: () =>
                              unawaited(widget.onCancelOrder(order)),
                        )
                      : OrderCard(
                          order: order,
                          onTap: () => widget.onOpenOrder(order),
                        ),
                );
              },
            ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
      child: Column(
        children: [
          Icon(icon, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEEF0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selectedIndex == index
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selectedIndex == index
                          ? Colors.white
                          : const Color(0xFF475569),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingPaymentCard extends StatelessWidget {
  const _PendingPaymentCard({
    required this.order,
    required this.onPay,
    required this.onCancel,
  });

  final OrderItem order;
  final VoidCallback onPay;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isQris =
        (order.paymentMethodCode ?? '') == 'qris' ||
        order.progressLabel.contains('QRIS');
    final isTransferBank =
        (order.paymentMethodCode ?? '').startsWith('transfer_') ||
        order.progressLabel.contains('Virtual Account');
    final isPayAtCoop = order.progressLabel.contains('kasir koperasi');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFFB7791F),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.id, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      isTransferBank || isQris
                          ? 'Batas bayar: 23:14:59'
                          : isPayAtCoop
                          ? 'Bayar saat ambil pesanan di koperasi'
                          : 'Pembayaran menunggu konfirmasi',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFB7791F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Total Pembayaran', style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            formatRupiah(order.total),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            order.progressLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onPay,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    isTransferBank
                        ? 'Konfirmasi Bayar'
                        : isPayAtCoop
                        ? 'Tandai Dibayar'
                        : 'Bayar Sekarang',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Batalkan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderProgressCard extends StatelessWidget {
  const _ActiveOrderProgressCard({required this.order, required this.onTrack});

  final OrderItem order;
  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tracking = _buildTrackingView(order);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.id,
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            tracking.referenceLabel,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (var i = 0; i < tracking.steps.length; i++)
                Expanded(
                  child: _ProgressStep(
                    label: tracking.steps[i].label,
                    done: i <= tracking.activeStepIndex,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            tracking.summary,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onTrack,
            icon: const Icon(Icons.location_searching_rounded),
            label: Text(tracking.trackButtonLabel),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: done ? Colors.white : Colors.white54,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: done ? Colors.white : Colors.white60,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TrackingViewData {
  const _TrackingViewData({
    required this.referenceLabel,
    required this.summary,
    required this.trackButtonLabel,
    required this.activeStepIndex,
    required this.steps,
  });

  final String referenceLabel;
  final String summary;
  final String trackButtonLabel;
  final int activeStepIndex;
  final List<_TrackingStepData> steps;
}

class _TrackingStepData {
  const _TrackingStepData(this.label);

  final String label;
}

_TrackingViewData _buildTrackingView(OrderItem order) {
  if (_isPickupOrder(order)) {
    final steps = const [
      _TrackingStepData('Dikonfirmasi'),
      _TrackingStepData('Disiapkan'),
      _TrackingStepData('Siap Diambil'),
      _TrackingStepData('Selesai'),
    ];
    return _TrackingViewData(
      referenceLabel: 'Kode ambil: PKP-${order.id.split('-').last}',
      summary: order.progressLabel,
      trackButtonLabel: 'Lihat Status Pickup',
      activeStepIndex: _pickupTrackingIndex(order.status),
      steps: steps,
    );
  }

  final steps = const [
    _TrackingStepData('Dikonfirmasi'),
    _TrackingStepData('Dikemas'),
    _TrackingStepData('Dikirim'),
    _TrackingStepData('Sampai'),
  ];
  return _TrackingViewData(
    referenceLabel: 'Resi: MEP-${order.id.replaceAll('ORD-', '')}',
    summary: order.progressLabel,
    trackButtonLabel: 'Lacak Kurir',
    activeStepIndex: _deliveryTrackingIndex(order.status),
    steps: steps,
  );
}

bool _isPickupOrder(OrderItem order) =>
    order.address.contains('Pickup Counter') ||
    order.status == 'Ready for Pickup';

int _deliveryTrackingIndex(String status) {
  switch (status) {
    case 'Completed':
      return 3;
    case 'On Delivery':
      return 2;
    case 'Being Prepared':
      return 1;
    default:
      return 1;
  }
}

class _SelectedBranchCard extends StatelessWidget {
  const _SelectedBranchCard({
    required this.branchName,
    required this.branchSubtitle,
    required this.onTap,
  });

  final String branchName;
  final String branchSubtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8BCB8)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEFEF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.location_city_rounded,
                  color: Color(0xFFD9001B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cabang Aktif',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9A7B76),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      branchName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      branchSubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6D5A58),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFFD9001B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _pickupTrackingIndex(String status) {
  switch (status) {
    case 'Completed':
      return 3;
    case 'Ready for Pickup':
      return 2;
    case 'Preparing Pickup':
      return 1;
    default:
      return 1;
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.mepuBalance,
<<<<<<< HEAD
    required this.vouchers,
=======
    required this.rewardSummary,
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
    required this.onTopUp,
    required this.onEditProfile,
    required this.onOpenSetting,
    required this.onChangeTab,
    required this.onOpenPromo,
    required this.onOpenRewardHistory,
    required this.onOpenFaq,
    required this.onOpenContactSupport,
    required this.onLogout,
  });

  final UserProfile profile;
  final int mepuBalance;
<<<<<<< HEAD
  final List<CheckoutVoucher> vouchers;
=======
  final RewardSummary? rewardSummary;
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
  final VoidCallback onTopUp;
  final VoidCallback onEditProfile;
  final ValueChanged<SettingShortcut> onOpenSetting;
  final ValueChanged<int> onChangeTab;
  final VoidCallback onOpenPromo;
  final VoidCallback onOpenRewardHistory;
  final VoidCallback onOpenFaq;
  final VoidCallback onOpenContactSupport;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          leading: IconButton(
            onPressed: () => onChangeTab(0),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Akun'),
          actions: [
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationHistoryScreen(),
                ),
              ),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        ProfileAvatar(
                          radius: 74,
                          bordered: false,
                          imageUrl: profile.avatarUrl,
                          initials: _initialsFromName(profile.name),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          profile.name,
                          style: theme.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 20,
                              color: Color(0xFF6D5A58),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              profile.phone,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF6D5A58),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.mail_outline_rounded,
                              size: 20,
                              color: Color(0xFF6D5A58),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              profile.email,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF6D5A58),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: onEditProfile,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            minimumSize: const Size(204, 56),
                          ),
                          child: const Text('Edit Profile'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD9001B), Color(0xFFB10017)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SALDO MEPUPOIN',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        formatRupiah(mepuBalance),
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 36,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ProfileActionChip(
                              label: 'Top Up',
                              icon: Icons.add_card_outlined,
                              onTap: onTopUp,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ProfileActionChip(
                              label: 'Vouchers',
                              icon: Icons.confirmation_number_outlined,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      VoucherCenterScreen(vouchers: vouchers),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ProfileActionChip(
                              label: 'Promo',
                              icon: Icons.star_rounded,
                              onTap: onOpenPromo,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE8BCB8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4C7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.stars_rounded,
                              color: Color(0xFFC38B00),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mepu Point',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  rewardSummary?.ruleDescription ??
                                      'Poin reward dari transaksi akan tampil di sini.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF6D5A58),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: onOpenRewardHistory,
                            child: const Text('Riwayat'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _RewardStatTile(
                              label: 'Saldo',
                              value:
                                  '${rewardSummary?.currentBalance ?? 0} poin',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RewardStatTile(
                              label: 'Terkumpul',
                              value:
                                  '${rewardSummary?.lifetimeEarned ?? 0} poin',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _RewardStatTile(
                              label: 'Dipakai',
                              value:
                                  '${rewardSummary?.lifetimeRedeemed ?? 0} poin',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengaturan Akun',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        ...profileSettings.map(
                          (setting) => SettingTile(
                            setting: setting,
                            onTap: () => onOpenSetting(setting),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bantuan', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 18),
                        SupportOption(
                          icon: Icons.live_help_outlined,
                          title: 'FAQ',
                          subtitle: 'Find quick answers',
                          onTap: onOpenFaq,
                        ),
                        const SizedBox(height: 14),
                        SupportButton(
                          label: 'Contact Us',
                          onTap: onOpenContactSupport,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: onLogout,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 70),
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: Icon(
                    Icons.logout_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  label: const Text('Keluar dari Akun'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardStatTile extends StatelessWidget {
  const _RewardStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: const Color(0xFF8A6A2B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class RewardHistoryScreen extends StatefulWidget {
  const RewardHistoryScreen({super.key, required this.summary});

  final RewardSummary? summary;

  @override
  State<RewardHistoryScreen> createState() => _RewardHistoryScreenState();
}

class _RewardHistoryScreenState extends State<RewardHistoryScreen> {
  static const RewardService _rewardService = RewardService();
  bool _isLoading = true;
  String? _errorMessage;
  List<RewardTransactionEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadHistory());
  }

  Future<void> _loadHistory() async {
    try {
      final entries = await _rewardService.getHistory();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = const [];
        _errorMessage =
            'Riwayat Mepu Point belum berhasil dimuat. Coba lagi beberapa saat.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Mepu Point')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD9001B), Color(0xFF8B0011)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo saat ini',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.summary?.currentBalance ?? 0} poin',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 34,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.summary?.ruleDescription ??
                      'Aturan loyalitas aktif akan tampil dari backend.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF5C38B)),
              ),
              child: Column(
                children: [
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _isLoading = true);
                      unawaited(_loadHistory());
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          else if (_entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8BCB8)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada transaksi poin',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Poin akan tercatat setelah pesanan selesai atau saat poin digunakan di checkout.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RewardHistoryTile(entry: entry),
              ),
            ),
        ],
      ),
    );
  }
}

class _RewardHistoryTile extends StatelessWidget {
  const _RewardHistoryTile({required this.entry});

  final RewardTransactionEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = entry.pointsDelta >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8BCB8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPositive
                  ? const Color(0xFFE8FFF1)
                  : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _rewardTransactionIcon(entry.transactionType),
              color: isPositive
                  ? const Color(0xFF15803D)
                  : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _rewardTransactionTitle(entry.transactionType),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.description.isEmpty
                      ? 'Transaksi poin tercatat di sistem.'
                      : entry.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatRewardDate(entry.createdAt.toLocal())}${entry.orderNo.isEmpty ? '' : ' • ${entry.orderNo}'}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF9A7B76),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${entry.pointsDelta} pts',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isPositive
                      ? const Color(0xFF15803D)
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (entry.rupiahValue > 0) ...[
                const SizedBox(height: 4),
                Text(
                  formatRupiah(entry.rupiahValue),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF6D5A58),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.cartItemCount,
    required this.stock,
    required this.rewardEarnLabel,
    required this.catalogProducts,
    required this.productStocks,
    required this.onOpenCart,
    required this.onAddToCart,
    required this.onAddItemsToCart,
    required this.onBuyNow,
  });

  final Product product;
  final int cartItemCount;
  final int stock;
  final String? rewardEarnLabel;
  final List<Product> catalogProducts;
  final Map<String, int> productStocks;
  final VoidCallback onOpenCart;
  final ValueChanged<Product> onAddToCart;
  final ValueChanged<List<Product>> onAddItemsToCart;
  final ValueChanged<List<Product>> onBuyNow;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class VoucherCenterScreen extends StatelessWidget {
  const VoucherCenterScreen({super.key, required this.vouchers});

  final List<CheckoutVoucher> vouchers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usableCount = vouchers.where((voucher) => voucher.isAvailable).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Voucher Saya')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF3C7CC)),
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.confirmation_number_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$usableCount voucher bisa dipakai',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih voucher saat checkout sesuai minimum belanja.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (vouchers.isEmpty)
            const _EmptyVoucherState()
          else
            for (final voucher in vouchers)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _ProfileVoucherCard(voucher: voucher),
              ),
        ],
      ),
    );
  }
}

class _ProfileVoucherCard extends StatelessWidget {
  const _ProfileVoucherCard({required this.voucher});

  final CheckoutVoucher voucher;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = voucher.isAvailable;
    final statusColor = active
        ? const Color(0xFF15803D)
        : voucher.isUsed
        ? const Color(0xFF64748B)
        : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(voucher.icon, color: statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        voucher.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusPill(
                      label: voucher.statusLabel,
                      foreground: statusColor,
                      background: statusColor.withValues(alpha: 0.10),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  voucher.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _VoucherInfoPill(label: voucher.code),
                    _VoucherInfoPill(
                      label: 'Min. ${formatRupiah(voucher.minimumSpend)}',
                    ),
                    _VoucherInfoPill(label: voucher.validityLabel),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherInfoPill extends StatelessWidget {
  const _VoucherInfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF475569),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyVoucherState extends StatelessWidget {
  const _EmptyVoucherState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 42,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada voucher aktif',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Voucher baru akan muncul di sini saat promo tersedia.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class PromoCenterScreen extends StatelessWidget {
  const PromoCenterScreen({super.key, required this.promotions});

  final List<PromoBanner> promotions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Promo MepuPoin')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD9001B), Color(0xFF8B0011)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Promo aktif untuk member',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih promo yang paling cocok untuk belanja kebutuhan kamu minggu ini.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (promotions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8BCB8)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada promo aktif',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Promo dari Supabase akan tampil di sini setelah diaktifkan oleh admin cabang.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final promo in promotions)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE8BCB8)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          promo.icon,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promo.title,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              promo.subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
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
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const faqs = [
      (
        'Bagaimana cara checkout pesanan?',
        'Pilih produk, masukkan ke keranjang, centang item yang dibeli, lalu lanjutkan ke checkout.',
      ),
      (
        'Kenapa metode Bayar di Koperasi tidak selalu tersedia?',
        'Metode ini hanya tersedia untuk pesanan yang diambil langsung di koperasi.',
      ),
      (
        'Bagaimana melacak pesanan?',
        'Buka tab Pesanan, lalu pilih pesanan aktif untuk melihat status kurir atau pickup.',
      ),
      (
        'Bagaimana menggunakan voucher?',
        'Voucher bisa dipilih di halaman checkout selama syarat minimum belanja terpenuhi.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final faq in faqs)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE8BCB8)),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFE8BCB8)),
                ),
                title: Text(
                  faq.$1,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Text(
                      faq.$2,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Hubungi Bantuan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4F5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF3C7CC)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tim support siap membantu',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Senin - Sabtu, 08.00 - 20.00 WIB',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SupportActionCard(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Chat WhatsApp',
            subtitle: '+62 811-9000-1122',
          ),
          const SizedBox(height: 14),
          _SupportActionCard(
            icon: Icons.call_outlined,
            title: 'Telepon Admin',
            subtitle: '(0260) 123-456',
          ),
          const SizedBox(height: 14),
          _SupportActionCard(
            icon: Icons.mail_outline_rounded,
            title: 'Email Support',
            subtitle: 'support@mepupoin.id',
          ),
        ],
      ),
    );
  }
}

class _SupportActionCard extends StatelessWidget {
  const _SupportActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: subtitle));
        _showFeatureSnack(
          context,
          '$subtitle berhasil disalin.',
          title: title,
          icon: Icons.copy_rounded,
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE8BCB8)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final stock = widget.stock;
    final related = widget.catalogProducts
        .where((item) => product.relatedIds.contains(item.id))
        .toList();
    final theme = Theme.of(context);
    final discount = discountPercent(product).clamp(0, 99);
    final soldCount = (product.claimedPercent * 3).clamp(24, 950).toInt();
    final rating = 4.6 + ((product.rewardPoints % 4) * 0.1);
    final selectedCategories = productCategoriesFor(product);
    final subtotal = product.price * quantity;

    return Scaffold(
<<<<<<< HEAD
      backgroundColor: const Color(0xFFF4F6F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 390,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1F2933),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            actions: [
              IconButton(
                onPressed: () => _showFeatureSnack(
                  context,
                  'Link produk siap dibagikan.',
                  title: 'Bagikan Produk',
                  icon: Icons.share_outlined,
                ),
                icon: const Icon(Icons.share_outlined),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: widget.onOpenCart,
                    icon: const Icon(Icons.shopping_cart_outlined),
=======
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        Container(
                          height: 420,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                product.tone.withValues(alpha: 0.95),
                                const Color(0xFF201F1F),
                                product.tone.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                28,
                                68,
                                28,
                                24,
                              ),
                              child: ProductMedia(
                                product: product,
                                borderRadius: BorderRadius.circular(28),
                                fit: BoxFit.contain,
                                iconSize: 132,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 18,
                          left: 18,
                          child: _CircleActionButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ),
                        Positioned(
                          top: 18,
                          right: 18,
                          child: _CircleActionButton(
                            icon: Icons.shopping_cart_outlined,
                            badgeCount: widget.cartItemCount,
                            onTap: widget.onOpenCart,
                          ),
                        ),
                        Positioned(
                          left: 24,
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC9A900),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              product.badge,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: const Color(0xFF221B00),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
                  ),
                  if (widget.cartItemCount > 0)
                    Positioned(
                      right: 4,
                      top: 6,
                      child: _CartCountBadge(count: widget.cartItemCount),
                    ),
                ],
              ),
              const SizedBox(width: 6),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 86, 20, 20),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ProductMedia(
                          product: product,
                          borderRadius: BorderRadius.circular(18),
                          fit: BoxFit.contain,
                          iconSize: 132,
                          padding: const EdgeInsets.all(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var index = 0; index < 4; index++)
                          Container(
                            width: index == 0 ? 24 : 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? const Color(0xFFD9001B)
                                  : const Color(0xFFD6DEE6),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _MarketplaceSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              formatRupiah(product.price),
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 30,
                                color: const Color(0xFFD9001B),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
<<<<<<< HEAD
                            child: Text(
                              '$discount%',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: const Color(0xFFD9001B),
                                fontWeight: FontWeight.w900,
=======
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  color: Color(0xFF221B00),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.rewardEarnLabel ??
                                      'Mepu Point mengikuti aturan belanja aktif',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF221B00),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          StatusPill(
                            label: stock > 0
                                ? 'Stok tersedia: $stock'
                                : 'Stok habis',
                            foreground: stock > 0
                                ? const Color(0xFF116C46)
                                : theme.colorScheme.error,
                            background: stock > 0
                                ? const Color(0xFFDFF5E8)
                                : const Color(0xFFFFE4E6),
                          ),
                          const SizedBox(height: 26),
                          const Divider(color: Color(0xFFE9C7C3)),
                          const SizedBox(height: 22),
                          Text(
                            'Deskripsi Produk',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            product.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.7,
                              color: const Color(0xFF5F4A45),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Produk Terkait',
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 256,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: related.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) => SizedBox(
                                width: 220,
                                child: ProductCard(
                                  product: related[index],
                                  stock:
                                      widget.productStocks[related[index].id] ??
                                      0,
                                  variant: ProductCardVariant.compact,
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ProductDetailScreen(
                                          cartItemCount: widget.cartItemCount,
                                          product: related[index],
                                          stock:
                                              widget
                                                  .productStocks[related[index]
                                                  .id] ??
                                              0,
                                          rewardEarnLabel:
                                              widget.rewardEarnLabel,
                                          catalogProducts:
                                              widget.catalogProducts,
                                          productStocks: widget.productStocks,
                                          onOpenCart: widget.onOpenCart,
                                          onAddToCart: widget.onAddToCart,
                                          onAddItemsToCart:
                                              widget.onAddItemsToCart,
                                          onBuyNow: widget.onBuyNow,
                                        ),
                                      ),
                                    );
                                  },
                                ),
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiah(product.originalPrice),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: const Color(0xFF8A939E),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        product.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MarketplaceChip(
                            icon: Icons.verified_rounded,
                            label: product.badge,
                            color: const Color(0xFFD9001B),
                          ),
                          _MarketplaceChip(
                            icon: Icons.stars_rounded,
                            label: '${product.rewardPoints} poin',
                            color: const Color(0xFFB45309),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '|',
                              style: TextStyle(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                          Text(
                            'Terjual $soldCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '|',
                              style: TextStyle(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                          Text(
                            stock > 0 ? 'Stok $stock' : 'Stok habis',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: stock > 0
                                  ? const Color(0xFFD9001B)
                                  : const Color(0xFFD9001B),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _MarketplaceSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MarketplaceSectionTitle(
                        title: 'Atur Jumlah',
                        trailing: Text(
                          'Subtotal ${formatRupiah(subtotal)}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: const Color(0xFFD9001B),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _QuantityStepper(
                            quantity: quantity,
                            canDecrease: quantity > 1,
                            canIncrease: quantity < stock,
                            onDecrease: () => setState(() => quantity--),
                            onIncrease: () => setState(() => quantity++),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              stock > 0
                                  ? 'Maks. pembelian $stock item'
                                  : 'Produk belum tersedia',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _MarketplaceSection(
                  child: _StoreSummaryPanel(product: product, stock: stock),
                ),
                _MarketplaceSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _MarketplaceSectionTitle(title: 'Pengiriman'),
                      const SizedBox(height: 14),
                      _MarketplaceInfoRow(
                        icon: Icons.location_on_outlined,
                        title: 'Dikirim dari Cabang KDMP',
                        subtitle:
                            'Estimasi tiba hari ini - besok untuk area terdekat.',
                      ),
                      const SizedBox(height: 12),
                      _MarketplaceInfoRow(
                        icon: Icons.local_shipping_outlined,
                        title: 'Ongkir mulai Rp 8.000',
                        subtitle:
                            'Gunakan voucher gratis ongkir jika tersedia di checkout.',
                      ),
                    ],
                  ),
                ),
                _MarketplaceSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _MarketplaceSectionTitle(title: 'Detail Produk'),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final category in selectedCategories)
                            _MarketplaceTag(label: category),
                          _MarketplaceTag(label: 'Diskon $discount%'),
                          _MarketplaceTag(
                            label: '${product.rewardPoints} poin reward',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      for (var i = 0; i < product.highlights.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MarketplaceInfoRow(
                            icon: _featureIcon(i),
                            title: product.highlights[i],
                            subtitle: 'Keunggulan produk koperasi pilihan.',
                            compact: true,
                          ),
                        ),
                    ],
                  ),
                ),
                _MarketplaceSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _MarketplaceSectionTitle(title: 'Deskripsi'),
                      const SizedBox(height: 12),
                      Text(
                        product.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.65,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                if (related.isNotEmpty)
                  _MarketplaceSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _MarketplaceSectionTitle(title: 'Produk Terkait'),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 252,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: related.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) => SizedBox(
                              width: 168,
                              child: ProductCard(
                                product: related[index],
                                stock:
                                    widget.productStocks[related[index].id] ??
                                    0,
                                variant: ProductCardVariant.compact,
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ProductDetailScreen(
                                        cartItemCount: widget.cartItemCount,
                                        product: related[index],
                                        stock:
                                            widget.productStocks[related[index]
                                                .id] ??
                                            0,
                                        productStocks: widget.productStocks,
                                        onOpenCart: widget.onOpenCart,
                                        onAddToCart: widget.onAddToCart,
                                        onAddItemsToCart:
                                            widget.onAddItemsToCart,
                                        onBuyNow: widget.onBuyNow,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 96),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 14,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: stock > 0
                      ? () => widget.onAddItemsToCart(
                          List<Product>.filled(quantity, product),
                        )
                      : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(
                      color: Color(0xFFD9001B),
                      width: 1.6,
                    ),
                    foregroundColor: const Color(0xFFD9001B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('+ Keranjang'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: stock > 0
                      ? () => widget.onBuyNow(
                          List<Product>.filled(quantity, product),
                        )
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFFD9001B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Beli'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketplaceSection extends StatelessWidget {
  const _MarketplaceSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: child,
    );
  }
}

class _MarketplaceSectionTitle extends StatelessWidget {
  const _MarketplaceSectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1F2933),
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _MarketplaceChip extends StatelessWidget {
  const _MarketplaceChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceTag extends StatelessWidget {
  const _MarketplaceTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF475569),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD6DEE6)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: canDecrease ? onDecrease : null,
            icon: const Icon(Icons.remove_rounded),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 38,
            child: Center(
              child: Text(
                '$quantity',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          IconButton(
            onPressed: canIncrease ? onIncrease : null,
            icon: const Icon(Icons.add_rounded),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _StoreSummaryPanel extends StatelessWidget {
  const _StoreSummaryPanel({required this.product, required this.stock});

  final Product product;
  final int stock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: Color(0xFFD9001B),
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'KDMP Official Store',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFFD9001B),
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Online - stok ${stock > 0 ? stock : 0} item - ${productCategory(product)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Kunjungi',
            style: TextStyle(color: Color(0xFFD9001B)),
          ),
        ),
      ],
    );
  }
}

class _MarketplaceInfoRow extends StatelessWidget {
  const _MarketplaceInfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFD9001B),
            size: compact ? 18 : 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF1F2933),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
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

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.items,
    required this.mepuBalance,
    required this.rewardSummary,
    required this.productStocks,
    required this.vouchers,
    required this.onCompletePayment,
    required this.onCancelOrder,
    required this.onPlaceOrder,
  });

  final List<Product> items;
  final int mepuBalance;
  final RewardSummary? rewardSummary;
  final Map<String, int> productStocks;
<<<<<<< HEAD
  final List<CheckoutVoucher> vouchers;
  final Future<OrderItem?> Function(OrderItem order) onCompletePayment;
  final ValueChanged<OrderItem> onCancelOrder;
=======
  final Future<OrderItem?> Function(OrderItem order) onCompletePayment;
  final Future<void> Function(OrderItem order) onCancelOrder;
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
  final Future<OrderItem?> Function(
    List<Product> items,
    String paymentMethod,
    String deliveryMethod,
    String? addressId,
    String address,
    int finalTotal,
<<<<<<< HEAD
    CheckoutVoucher? voucher,
    int voucherDiscount,
=======
    String? voucherLabel,
    int redeemedPoints,
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
  )
  onPlaceOrder;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const RewardService _rewardService = RewardService();
  String deliveryMethod = 'Kirim ke Rumah';
  String paymentMethod = 'Saldo MepuPoin';
  CheckoutVoucher? selectedVoucher;
  bool _useRewardPoints = false;
  bool _isLoadingRewardPreview = false;
  RewardRedeemPreview? _rewardPreview;
  int selectedAddressIndex = 0;
  bool _isLoadingAddresses = true;
  List<CheckoutAddress> deliveryAddresses = [
    const CheckoutAddress(
      id: 'fallback-home',
      label: 'Rumah',
      name: 'Budi Santoso',
      phone: '+62 812-3456-7890',
      address: 'Jl. Merdeka No. 42, RT 03/RW 04, Sukamaju Village',
      icon: Icons.home_outlined,
    ),
    const CheckoutAddress(
      id: 'fallback-work',
      label: 'Kantor',
      name: 'Budi Santoso',
      phone: '+62 812-3456-7890',
      address: 'Jl. Pahlawan No. 10, Kec. Kalijati, Subang',
      icon: Icons.business_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadDeliveryAddresses());
    unawaited(_loadRewardPreview());
  }

  CheckoutAddress get selectedAddress =>
      deliveryAddresses[selectedAddressIndex];

  String? get selectedAddressId => deliveryAddresses.isEmpty
      ? null
      : deliveryAddresses[selectedAddressIndex].id;

  Future<void> _loadDeliveryAddresses() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() => _isLoadingAddresses = false);
        return;
      }

      final rows = await client
          .from('addresses')
          .select()
          .eq('user_id', user.id)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: true);

      final loadedAddresses = rows
          .map<CheckoutAddress>(
            (row) => _toCheckoutAddress(
              SavedAddressResult.fromMap(row, fallbackUserId: user.id),
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        if (loadedAddresses.isNotEmpty) {
          deliveryAddresses = loadedAddresses;
          selectedAddressIndex = 0;
        }
        _isLoadingAddresses = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingAddresses = false);
    }
  }

  CheckoutAddress _toCheckoutAddress(SavedAddressResult address) {
    return CheckoutAddress(
      id: address.id,
      label: address.label,
      name: address.name,
      phone: address.phone,
      address: address.address,
      icon: Icons.location_on_outlined,
    );
  }

  Future<void> _loadRewardPreview() async {
    if (widget.rewardSummary == null) {
      if (!mounted) return;
      setState(() => _rewardPreview = null);
      return;
    }

    setState(() => _isLoadingRewardPreview = true);
    try {
      final subtotal = widget.items.fold<int>(
        0,
        (sum, product) => sum + product.price,
      );
      final deliveryFee = deliveryMethod == 'Kirim ke Rumah' ? 8000 : 0;
      final preview = await _rewardService.previewRedeem(
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        serviceFee: 1500,
        requestedPoints: _useRewardPoints
            ? widget.rewardSummary!.currentBalance
            : 0,
      );
      if (!mounted) return;
      setState(() => _rewardPreview = preview);
    } catch (_) {
      if (!mounted) return;
      setState(() => _rewardPreview = null);
    } finally {
      if (mounted) {
        setState(() => _isLoadingRewardPreview = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupedItems = _groupCheckoutItems(widget.items);
    final subtotal = widget.items.fold<int>(
      0,
      (sum, product) => sum + product.price,
    );
    final deliveryFee = deliveryMethod == 'Kirim ke Rumah' ? 8000 : 0;
    final serviceFee = 1500;
    final voucherDiscount = _voucherDiscount(
      selectedVoucher,
      subtotal,
      deliveryFee,
      serviceFee,
    );
    final rewardDiscount = _useRewardPoints
        ? (_rewardPreview?.discountAmount ?? 0)
        : 0;
    final redeemedPoints = _useRewardPoints
        ? (_rewardPreview?.appliedPoints ?? 0)
        : 0;
    final total =
        (subtotal + deliveryFee + serviceFee - voucherDiscount - rewardDiscount)
            .clamp(0, subtotal + deliveryFee + serviceFee)
            .toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Checkout Pesanan',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 164),
        children: [
          _CheckoutHeroCard(
            itemCount: widget.items.length,
            total: total,
            deliveryMethod: deliveryMethod,
            paymentMethod: paymentMethod,
          ),
          const SizedBox(height: 16),
          _CheckoutSection(
            title: 'Produk Dibeli',
            child: Column(
              children: [
                for (final item in groupedItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE7ECF2)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 58,
                            height: 58,
                            child: ProductMedia(
                              product: item.product,
                              borderRadius: BorderRadius.circular(14),
                              fit: BoxFit.cover,
                              padding: const EdgeInsets.all(6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${formatRupiah(item.product.price)} x ${item.quantity}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                StatusPill(
                                  label:
                                      'Stok tersedia: ${widget.productStocks[item.product.id] ?? 0}',
                                  foreground: const Color(0xFF116C46),
                                  background: const Color(0xFFE8F7EE),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formatRupiah(item.product.price * item.quantity),
                            textAlign: TextAlign.right,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CheckoutSection(
            title: 'Pengiriman',
            child: Column(
              children: [
                _CheckoutOption(
                  title: const Text('Kirim ke Rumah'),
                  subtitle: Text(
                    deliveryAddresses.isEmpty
                        ? 'Belum ada alamat tersimpan'
                        : selectedAddress.address,
                  ),
                  selected: deliveryMethod == 'Kirim ke Rumah',
                  onTap: () => _updateDeliveryMethod(context, 'Kirim ke Rumah'),
                ),
                if (deliveryMethod == 'Kirim ke Rumah') ...[
                  const SizedBox(height: 8),
                  if (_isLoadingAddresses)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    _DeliveryAddressBook(
                      addresses: deliveryAddresses,
                      selectedIndex: selectedAddressIndex,
                      onSelect: (index) =>
                          setState(() => selectedAddressIndex = index),
                      onEdit: _editDeliveryAddress,
                      onAdd: _addDeliveryAddress,
                    ),
                ],
                _CheckoutOption(
                  title: const Text('Ambil di Koperasi'),
                  subtitle: const Text('MepuPoin Sukamaju - Pickup Counter'),
                  selected: deliveryMethod == 'Ambil di Koperasi',
                  onTap: () =>
                      _updateDeliveryMethod(context, 'Ambil di Koperasi'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CheckoutSection(
            title: 'Voucher',
            child: Column(
              children: [
                _VoucherSelector(
                  selectedVoucher: selectedVoucher,
                  subtotal: subtotal,
                  deliveryFee: deliveryFee,
                  serviceFee: serviceFee,
                  vouchers: widget.vouchers,
                  onSelect: (voucher) => setState(() {
                    if (_useRewardPoints) {
                      _useRewardPoints = false;
                      unawaited(_loadRewardPreview());
                      _showFeatureSnack(
                        context,
                        'Redeem Mepu Point dilepas agar voucher dapat digunakan.',
                        title: 'Voucher Dipilih',
                      );
                    }
                    selectedVoucher = voucher;
                  }),
                ),
                if (selectedVoucher != null) ...[
                  const SizedBox(height: 12),
                  _AppliedVoucherCard(
                    voucher: selectedVoucher!,
                    discount: voucherDiscount,
                    onRemove: () => setState(() => selectedVoucher = null),
                  ),
                ],
              ],
            ),
          ),
          if (widget.rewardSummary != null) ...[
            const SizedBox(height: 14),
            _CheckoutSection(
              title: 'Mepu Point',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    value: _useRewardPoints,
                    contentPadding: EdgeInsets.zero,
                    onChanged: _isLoadingRewardPreview
                        ? null
                        : (value) {
                            if (value && selectedVoucher != null) {
                              setState(() => selectedVoucher = null);
                              _showFeatureSnack(
                                context,
                                'Voucher checkout dilepas agar Mepu Point bisa digunakan.',
                                title: 'Mepu Point Aktif',
                              );
                            }
                            setState(() => _useRewardPoints = value);
                            unawaited(_loadRewardPreview());
                          },
                    title: const Text('Gunakan Mepu Point'),
                    subtitle: Text(
                      'Saldo ${widget.rewardSummary!.currentBalance} poin • '
                      '${widget.rewardSummary!.redeemLabel}',
                    ),
                  ),
                  if (_isLoadingRewardPreview)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(minHeight: 3),
                    )
                  else if (_useRewardPoints)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF4D38A)),
                      ),
                      child: Text(
                        redeemedPoints > 0
                            ? '$redeemedPoints poin akan dipakai untuk potongan ${formatRupiah(rewardDiscount)}.'
                            : 'Belum ada poin yang bisa dipakai untuk transaksi ini. Minimal redeem ${widget.rewardSummary!.minRedeemPoints} poin.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF6D5A00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _CheckoutSection(
            title: 'Metode Pembayaran',
            child: Column(
              children: [
                _CheckoutOption(
                  title: const Text('Saldo MepuPoin'),
                  subtitle: Text(
                    'Saldo tersedia ${formatRupiah(widget.mepuBalance)}',
                  ),
                  selected: paymentMethod == 'Saldo MepuPoin',
                  onTap: () => setState(() => paymentMethod = 'Saldo MepuPoin'),
                ),
                _CheckoutOption(
                  title: const Text('Transfer Bank'),
                  subtitle: const Text('Virtual account koperasi'),
                  selected: paymentMethod == 'Transfer Bank',
                  onTap: () => setState(() => paymentMethod = 'Transfer Bank'),
                ),
                _CheckoutOption(
                  title: const Text('QRIS'),
                  subtitle: const Text(
                    'Bayar dengan scan QRIS dari e-wallet atau mobile banking',
                  ),
                  selected: paymentMethod == 'QRIS',
                  onTap: () => setState(() => paymentMethod = 'QRIS'),
                ),
                _CheckoutOption(
                  title: const Text('Bayar di Koperasi'),
                  subtitle: Text(
                    deliveryMethod == 'Kirim ke Rumah'
                        ? 'Tersedia hanya untuk pesanan ambil di koperasi'
                        : 'Bayar saat mengambil pesanan',
                  ),
                  selected: paymentMethod == 'Bayar di Koperasi',
                  enabled: deliveryMethod == 'Ambil di Koperasi',
                  onTap: () =>
                      setState(() => paymentMethod = 'Bayar di Koperasi'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CheckoutSection(
            title: 'Ringkasan Pembayaran',
            child: Column(
              children: [
                _PriceRow(label: 'Subtotal', value: subtotal),
                _PriceRow(label: 'Ongkir', value: deliveryFee),
                _PriceRow(label: 'Biaya layanan', value: serviceFee),
                if (voucherDiscount > 0)
                  _PriceRow(
                    label: 'Voucher',
                    value: -voucherDiscount,
                    isDiscount: true,
                  ),
                if (rewardDiscount > 0)
                  _PriceRow(
                    label: 'Redeem Mepu Point',
                    value: -rewardDiscount,
                    isDiscount: true,
                  ),
                const Divider(height: 24),
                _PriceRow(label: 'Total Bayar', value: total, emphasized: true),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 22,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7ECF2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Bayar',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupiah(total),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              FilledButton.icon(
                onPressed: _placeOrder,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 52),
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Buat Pesanan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final groupedItems = _groupCheckoutItems(widget.items);
    for (final item in groupedItems) {
      final stock = widget.productStocks[item.product.id] ?? 0;
      if (item.quantity > stock) {
        _showFeatureSnack(
          context,
          'Stok ${item.product.name} tersisa $stock. Kurangi jumlah pembelian sebelum checkout.',
          title: 'Stok Tidak Cukup',
          icon: Icons.inventory_2_outlined,
        );
        return;
      }
    }

    final subtotal = widget.items.fold<int>(
      0,
      (sum, product) => sum + product.price,
    );
    final deliveryFee = deliveryMethod == 'Kirim ke Rumah' ? 8000 : 0;
    const serviceFee = 1500;
    final voucherDiscount = _voucherDiscount(
      selectedVoucher,
      subtotal,
      deliveryFee,
      serviceFee,
    );
    final rewardDiscount = _useRewardPoints
        ? (_rewardPreview?.discountAmount ?? 0)
        : 0;
    final redeemedPoints = _useRewardPoints
        ? (_rewardPreview?.appliedPoints ?? 0)
        : 0;
    final total =
        (subtotal + deliveryFee + serviceFee - voucherDiscount - rewardDiscount)
            .clamp(0, subtotal + deliveryFee + serviceFee)
            .toInt();
    if (paymentMethod == 'Saldo MepuPoin' && widget.mepuBalance < total) {
      _showFeatureSnack(
        context,
        'Saldo kamu kurang ${formatRupiah(total - widget.mepuBalance)}. Isi saldo dulu atau pilih metode pembayaran lain.',
        title: 'Saldo Tidak Cukup',
        icon: Icons.account_balance_wallet_outlined,
      );
      return;
    }

    if (deliveryMethod == 'Kirim ke Rumah' && deliveryAddresses.isEmpty) {
      _showFeatureSnack(
        context,
        'Tambahkan alamat pengiriman terlebih dahulu lewat tombol Tambah di Buku Alamat.',
        title: 'Alamat Dibutuhkan',
        icon: Icons.location_on_outlined,
      );
      return;
    }

    final destinationAddress = deliveryMethod == 'Ambil di Koperasi'
        ? 'MepuPoin Sukamaju - Pickup Counter'
        : selectedAddress.address;

    final order = await widget.onPlaceOrder(
      widget.items,
      paymentMethod,
      deliveryMethod,
      selectedAddressId,
      destinationAddress,
      total,
<<<<<<< HEAD
      selectedVoucher,
      voucherDiscount,
=======
      selectedVoucher?.code,
      redeemedPoints,
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
    );
    if (!mounted || order == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TransactionCompletionScreen(
          initialOrder: order,
          onCompletePayment: widget.onCompletePayment,
          onCancelOrder: widget.onCancelOrder,
        ),
      ),
    );
  }

  List<_CheckoutLineItem> _groupCheckoutItems(List<Product> items) {
    final lines = <String, _CheckoutLineItem>{};
    for (final product in items) {
      final existing = lines[product.id];
      lines[product.id] = existing == null
          ? _CheckoutLineItem(product: product, quantity: 1)
          : _CheckoutLineItem(
              product: product,
              quantity: existing.quantity + 1,
            );
    }
    return lines.values.toList();
  }

  void _updateDeliveryMethod(BuildContext context, String method) {
    if (deliveryMethod == method) return;

    final shouldCancelFreeDeliveryVoucher =
        method == 'Ambil di Koperasi' &&
        selectedVoucher != null &&
        _isFreeDeliveryVoucher(selectedVoucher!);

    setState(() {
      deliveryMethod = method;
      if (deliveryMethod == 'Kirim ke Rumah' &&
          paymentMethod == 'Bayar di Koperasi') {
        paymentMethod = 'Saldo MepuPoin';
      }
      if (shouldCancelFreeDeliveryVoucher) {
        selectedVoucher = null;
      }
    });
    unawaited(_loadRewardPreview());

    if (shouldCancelFreeDeliveryVoucher) {
      _showFeatureSnack(
        context,
        'Voucher gratis ongkir dibatalkan karena pesanan diambil langsung di koperasi.',
        title: 'Voucher Dibatalkan',
        icon: Icons.local_shipping_outlined,
      );
    }
  }

  bool _isFreeDeliveryVoucher(CheckoutVoucher voucher) {
    return voucher.code == 'ONGKIRHEMAT';
  }

  Future<void> _editDeliveryAddress() async {
    final selected = await Navigator.of(context).push<SavedAddressResult>(
      MaterialPageRoute<SavedAddressResult>(
        builder: (_) => const ManageAddressesScreen(),
      ),
    );
    if (!mounted || selected == null) return;

    await _loadDeliveryAddresses();
    if (!mounted) return;
    final newIndex = deliveryAddresses.indexWhere(
      (address) =>
          address.address == selected.address &&
          address.label == selected.label,
    );
    if (newIndex >= 0) {
      setState(() => selectedAddressIndex = newIndex);
    }
    _showFeatureSnack(
      context,
      'Alamat pengiriman berhasil diperbarui dari backend.',
      title: 'Alamat Tersimpan',
      icon: Icons.location_on_outlined,
    );
  }

  Future<void> _addDeliveryAddress() async {
    final selected = await Navigator.of(context).push<SavedAddressResult>(
      MaterialPageRoute<SavedAddressResult>(
        builder: (_) => const ManageAddressesScreen(),
      ),
    );
    if (!mounted || selected == null) return;

    await _loadDeliveryAddresses();
    if (!mounted) return;
    final newIndex = deliveryAddresses.indexWhere(
      (address) =>
          address.address == selected.address &&
          address.label == selected.label,
    );
    if (newIndex >= 0) {
      setState(() => selectedAddressIndex = newIndex);
    }
    _showFeatureSnack(
      context,
      'Alamat backend berhasil dipilih untuk pengiriman.',
      title: 'Alamat Ditambahkan',
      icon: Icons.add_location_alt_outlined,
    );
  }
}

class _CheckoutLineItem {
  const _CheckoutLineItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;
}

class TransactionCompletionScreen extends StatefulWidget {
  const TransactionCompletionScreen({
    super.key,
    required this.initialOrder,
    required this.onCompletePayment,
    required this.onCancelOrder,
  });

  final OrderItem initialOrder;
  final Future<OrderItem?> Function(OrderItem order) onCompletePayment;
<<<<<<< HEAD
  final ValueChanged<OrderItem> onCancelOrder;
=======
  final Future<void> Function(OrderItem order) onCancelOrder;
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)

  @override
  State<TransactionCompletionScreen> createState() =>
      _TransactionCompletionScreenState();
}

class _TransactionCompletionScreenState
    extends State<TransactionCompletionScreen> {
  late OrderItem currentOrder = widget.initialOrder;
  bool _isSubmitting = false;

  bool get _isPending => currentOrder.status == 'Payment Pending';
  bool get _isQris =>
      (currentOrder.paymentMethodCode ?? '') == 'qris' ||
      currentOrder.progressLabel.contains('QRIS');
  bool get _isTransferBank =>
      ((currentOrder.paymentMethodCode ?? '').startsWith('transfer_')) ||
      currentOrder.progressLabel.contains('Virtual Account');
  bool get _isPayAtCoop =>
      currentOrder.progressLabel.contains('kasir koperasi');
  bool get _isPickupOrder =>
      currentOrder.address.contains('Pickup Counter') || _isPayAtCoop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xCCFCF9F8),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: _backToHome,
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(_isPending ? 'Selesaikan Pembayaran' : 'Pesanan Diproses'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
        children: [
          _buildPremiumHero(context),
          const SizedBox(height: 20),
          _buildStatusCard(context),
          const SizedBox(height: 20),
          if (_isTransferBank) ...[
            _buildVirtualAccountCard(context),
            const SizedBox(height: 20),
          ],
          if (_isPayAtCoop) ...[
            _buildPickupInstructionCard(context),
            const SizedBox(height: 20),
          ],
          _buildOrderSummaryCard(context),
          const SizedBox(height: 20),
          _buildNextStepsCard(context),
          const SizedBox(height: 20),
          _buildSupportCard(context),
        ],
      ),
      bottomNavigationBar: _buildPremiumBottomBar(context),
    );
  }

  Widget _buildPremiumHero(BuildContext context) {
    final theme = Theme.of(context);
    final heroGradient = _isPending
        ? const [Color(0xFFFFF8E7), Color(0xFFFFE4A3), Color(0xFFFFF3D0)]
        : const [Color(0xFFE60023), Color(0xFFB7001A), Color(0xFF780011)];
    final foreground = _isPending ? const Color(0xFF503D00) : Colors.white;
    final mutedForeground = _isPending
        ? const Color(0xFF765B00)
        : Colors.white.withValues(alpha: 0.78);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1FE60023),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -42,
            child: _GlassCircle(size: 132, color: Colors.white),
          ),
          Positioned(
            right: 16,
            bottom: 12,
            child: Icon(
              Icons.verified_rounded,
              color: Colors.white.withValues(alpha: _isPending ? 0.28 : 0.13),
              size: 92,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: _isPending ? 0.72 : 0.16,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      _isPending
                          ? Icons.account_balance_wallet_outlined
                          : Icons.check_circle_rounded,
                      color: foreground,
                      size: 30,
                    ),
                  ),
                  const Spacer(),
                  _PremiumBadge(
                    label: _isPending
                        ? 'Menunggu Pembayaran'
                        : 'Pembayaran Berhasil',
                    foregroundColor: foreground,
                    backgroundColor: Colors.white.withValues(
                      alpha: _isPending ? 0.6 : 0.16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                _isPending
                    ? 'Selesaikan pembayaran agar pesanan diproses'
                    : 'Pembayaran diterima, pesanan sedang diproses',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No. pesanan ${currentOrder.id}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                currentOrder.progressLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: mutedForeground,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(spacing: 10, runSpacing: 10, children: _buildSummaryChips()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return _PremiumSection(
      title: 'Status Pesanan',
      subtitle: 'Informasi pembayaran dan pengiriman terbaru.',
      child: Column(
        children: [
          _PremiumTimelineTile(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Metode pembayaran',
            value: _paymentMethodLabel(),
            active: true,
          ),
          _PremiumTimelineTile(
            icon: _isPickupOrder
                ? Icons.storefront_outlined
                : Icons.local_shipping_outlined,
            label: _isPickupOrder ? 'Metode penerimaan' : 'Metode pengiriman',
            value: _isPickupOrder ? 'Ambil di koperasi' : 'Diantar ke alamat',
            active: true,
          ),
          _PremiumTimelineTile(
            icon: Icons.schedule_outlined,
            label: _isPickupOrder ? 'Estimasi siap diambil' : 'Estimasi tiba',
            value: _estimatedFulfillmentText(),
            active: _isPending,
          ),
          _PremiumTimelineTile(
            icon: Icons.verified_user_outlined,
            label: 'Status saat ini',
            value: _statusText(),
            active: !_isPending,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualAccountCard(BuildContext context) {
    final theme = Theme.of(context);
    return _PremiumSection(
      title: 'Pembayaran Virtual Account',
      subtitle: 'Transfer sesuai nominal agar verifikasi lebih cepat.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PaymentNumberCard(
            title: 'BNI Virtual Account',
            value: _extractVirtualAccount(currentOrder),
            trailing: IconButton(
              onPressed: () {
                _showFeatureSnack(
                  context,
                  'Nomor virtual account siap disalin.',
                  title: 'Nomor VA',
                  icon: Icons.copy_rounded,
                );
              },
              icon: const Icon(Icons.copy_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E7),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFFE0A3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nominal pembayaran',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF765B00),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatRupiah(currentOrder.total),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (currentOrder.paymentExpiresAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Berlaku sampai ${_formatPaymentExpiry(currentOrder.paymentExpiresAt!)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF765B00),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
<<<<<<< HEAD
    );
  }

  Widget _buildPickupInstructionCard(BuildContext context) {
    return _PremiumSection(
      title: 'Instruksi Ambil di Koperasi',
      subtitle: 'Tunjukkan kode pengambilan ke petugas koperasi.',
      child: _PaymentNumberCard(
        title: 'Kode pengambilan',
        value: 'PKP-${currentOrder.id.split('-').last}',
        trailing: const Icon(
          Icons.storefront_rounded,
          color: Color(0xFFE60023),
=======
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              if (_isPending) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await widget.onCancelOrder(currentOrder);
                      if (!mounted) return;
                      navigator.popUntil((route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Batalkan'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: _isPending ? _completeTransaction : _backToHome,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: Text(
                    _isPending
                        ? (_isTransferBank
                              ? 'Saya Sudah Bayar'
                              : 'Selesaikan Transaksi')
                        : 'Kembali ke Beranda',
                  ),
                ),
              ),
            ],
          ),
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildOrderSummaryCard(BuildContext context) {
    return _PremiumSection(
      title: 'Ringkasan Pesanan',
      subtitle: 'Detail transaksi yang akan diproses koperasi.',
      child: Column(
        children: [
          _PriceRow(
            label: 'Total Tagihan',
            value: currentOrder.total,
            emphasized: true,
          ),
          const SizedBox(height: 8),
          InfoRow(label: 'Alamat / Pickup', value: currentOrder.address),
          InfoRow(label: 'Waktu pesanan', value: currentOrder.createdAt),
          InfoRow(label: 'Item', value: currentOrder.items.join(', ')),
        ],
      ),
    );
  }

  Widget _buildNextStepsCard(BuildContext context) {
    return _PremiumSection(
      title: _isPending ? 'Cara Menyelesaikan' : 'Langkah Berikutnya',
      subtitle: _isPending
          ? 'Selesaikan pembayaran sebelum batas waktu.'
          : 'Pantau status pesanan secara berkala.',
      child: Column(
        children: [
          _NextStepTile(
            icon: _isPending
                ? Icons.payments_outlined
                : Icons.inventory_2_outlined,
            title: _isPending
                ? 'Bayar sesuai nominal'
                : 'Tim koperasi menyiapkan pesanan',
            subtitle: _isPending
                ? 'Gunakan nomor pembayaran yang tertera dan pastikan nominalnya sama.'
                : (_isPickupOrder
                      ? 'Barang akan disiapkan sebelum siap diambil di koperasi.'
                      : 'Barang akan dicek dan dikemas sebelum diserahkan ke kurir.'),
          ),
          const SizedBox(height: 14),
          _NextStepTile(
            icon: _isPending
                ? Icons.verified_outlined
                : (_isPickupOrder
                      ? Icons.notifications_active_outlined
                      : Icons.local_shipping_outlined),
            title: _isPending
                ? 'Konfirmasi setelah pembayaran'
                : (_isPickupOrder
                      ? 'Kamu akan mendapat notifikasi'
                      : 'Status kurir muncul di tab Pesanan'),
            subtitle: _isPending
                ? 'Tekan tombol “Saya Sudah Bayar” setelah transfer berhasil.'
                : (_isPickupOrder
                      ? 'Datang ke koperasi sesuai jam operasional.'
                      : 'Pantau pergerakan pesanan dari tab Pesanan Aktif.'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8BCB8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFDAD7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Color(0xFFE60023),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Butuh bantuan? Hubungi admin koperasi jika ada kendala pembayaran atau pengiriman.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5E3F3C),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBottomBar(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          border: Border.all(color: const Color(0xFFE8BCB8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1AE60023),
              blurRadius: 28,
              offset: Offset(0, -10),
            ),
          ],
        ),
        child: Row(
          children: [
            if (_isPending) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          widget.onCancelOrder(currentOrder);
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    foregroundColor: theme.colorScheme.primary,
                    side: const BorderSide(color: Color(0xFFE8BCB8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Batalkan'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _isSubmitting
                    ? null
                    : (_isPending ? _completeTransaction : _backToHome),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFFE60023),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  _isSubmitting
                      ? 'Memeriksa...'
                      : _isPending
                      ? (_isTransferBank
                            ? 'Saya Sudah Bayar'
                            : 'Selesaikan Transaksi')
                      : 'Kembali ke Beranda',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeTransaction() async {
    setState(() => _isSubmitting = true);
    final updatedOrder = await widget.onCompletePayment(currentOrder);
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      if (updatedOrder != null) {
        currentOrder = updatedOrder;
      }
    });
=======
  Future<void> _completeTransaction() async {
    final updatedOrder = await widget.onCompletePayment(currentOrder);
    if (updatedOrder == null || !mounted) return;
    setState(() => currentOrder = updatedOrder);
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
  }

  void _backToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  List<Widget> _buildSummaryChips() {
    final textColor = _isPending ? const Color(0xFF6D4C00) : Colors.white;
    final backgroundColor = _isPending
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.14);

    return [
      _StatusChip(
        icon: Icons.receipt_long_outlined,
        label: formatRupiah(currentOrder.total),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
      ),
      _StatusChip(
        icon: _isPickupOrder
            ? Icons.storefront_outlined
            : Icons.local_shipping_outlined,
        label: _isPickupOrder ? 'Pickup koperasi' : 'Diantar kurir',
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
      ),
      _StatusChip(
        icon: Icons.schedule_outlined,
        label: _estimatedFulfillmentText(),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
      ),
    ];
  }

  String _paymentMethodLabel() {
    if (_isQris) {
      return 'QRIS';
    }
    if (_isTransferBank) {
      final bank = (currentOrder.providerBank ?? '').trim();
      return bank.isEmpty
          ? 'Transfer Bank Virtual Account'
          : 'Transfer Bank ${bank.toUpperCase()} Virtual Account';
    }
    if (_isPayAtCoop) return 'Bayar di Koperasi';
    return 'Saldo MepuPoin';
  }

  String _estimatedFulfillmentText() {
    if (_isPending && (_isTransferBank || _isQris)) {
      return 'Bayar dalam 1 x 24 jam';
    }
    if (_isPending && _isPayAtCoop) return 'Bayar saat pengambilan';
    if (_isPickupOrder) return 'Siap diambil hari ini, 15.00 - 18.00';
    return 'Tiba hari ini, 16.00 - 19.00';
  }

  String _statusText() {
    if (_isPending) return 'Menunggu pembayaran dari kamu';
    if (_isPickupOrder) return 'Pesanan sedang disiapkan untuk pickup';
    return 'Pesanan sedang diproses menuju pengiriman';
  }

  String _extractVirtualAccount(OrderItem order) {
    final savedVa = (order.providerVaNumber ?? '').trim();
    if (savedVa.isNotEmpty) return savedVa;
    final match = RegExp(r'(\d{8,})').firstMatch(order.progressLabel);
    return match?.group(1) ?? '880800000000';
  }

  String _formatPaymentExpiry(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foregroundColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCircle extends StatelessWidget {
  const _GlassCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.22),
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.44)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: foregroundColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSection extends StatelessWidget {
  const _PremiumSection({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8BCB8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5E3F3C),
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _PremiumTimelineTile extends StatelessWidget {
  const _PremiumTimelineTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.active,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool active;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active ? const Color(0xFFE60023) : const Color(0xFF936E6B);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFFFDAD7)
                      : const Color(0xFFF6F3F2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: const Color(0xFFE8BCB8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF765B00),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w900,
                      height: 1.25,
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
}

class _PaymentNumberCard extends StatelessWidget {
  const _PaymentNumberCard({
    required this.title,
    required this.value,
    required this.trailing,
  });

  final String title;
  final String value;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E2E1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF5E3F3C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFFE60023),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _NextStepTile extends StatelessWidget {
  const _NextStepTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeliveryAddressBook extends StatelessWidget {
  const _DeliveryAddressBook({
    required this.addresses,
    required this.selectedIndex,
    required this.onSelect,
    required this.onEdit,
    required this.onAdd,
  });

  final List<CheckoutAddress> addresses;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Buku Alamat',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onAdd,
                      icon: const Icon(
                        Icons.add_location_alt_outlined,
                        size: 18,
                      ),
                      label: const Text('Tambah'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < addresses.length; index++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == addresses.length - 1 ? 0 : 10,
                    ),
                    child: _DeliveryAddressTile(
                      address: addresses[index],
                      selected: selectedIndex == index,
                      onSelect: () => onSelect(index),
                      onEdit: selectedIndex == index ? onEdit : null,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryAddressTile extends StatelessWidget {
  const _DeliveryAddressTile({
    required this.address,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
  });

  final CheckoutAddress address;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.45)
                : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(address.icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          address.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected
                            ? theme.colorScheme.primary
                            : const Color(0xFFCBD5E1),
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${address.name} - ${address.phone}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.address,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(
                          Icons.edit_location_alt_outlined,
                          size: 16,
                        ),
                        label: const Text('Edit Alamat Ini'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditDeliveryAddressDialog extends StatefulWidget {
  const _EditDeliveryAddressDialog({required this.title});

  final String title;

  @override
  State<_EditDeliveryAddressDialog> createState() =>
      _EditDeliveryAddressDialogState();
}

class _EditDeliveryAddressDialogState
    extends State<_EditDeliveryAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _selectedIcon = Icons.location_on_outlined;
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
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.edit_location_alt_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Masukkan alamat tujuan yang jelas agar pesanan mudah dikirim.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _labelController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Label Alamat',
                      hintText: 'Contoh: Rumah, Kantor, Kos',
                      prefixIcon: Icon(Icons.bookmark_border_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Label alamat wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nama Penerima',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Nama penerima belum valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 10) {
                        return 'Nomor telepon belum valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    minLines: 3,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Lengkap',
                      hintText:
                          'Nama jalan, nomor rumah, desa/kecamatan, patokan',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      final address = value?.trim() ?? '';
                      if (address.length < 12) {
                        return 'Alamat terlalu singkat';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Ikon alamat',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _CheckoutAddressIconOption(
                        icon: Icons.home_outlined,
                        selected: _selectedIcon == Icons.home_outlined,
                        onTap: () =>
                            setState(() => _selectedIcon = Icons.home_outlined),
                      ),
                      _CheckoutAddressIconOption(
                        icon: Icons.business_outlined,
                        selected: _selectedIcon == Icons.business_outlined,
                        onTap: () => setState(
                          () => _selectedIcon = Icons.business_outlined,
                        ),
                      ),
                      _CheckoutAddressIconOption(
                        icon: Icons.people_outline_rounded,
                        selected: _selectedIcon == Icons.people_outline_rounded,
                        onTap: () => setState(
                          () => _selectedIcon = Icons.people_outline_rounded,
                        ),
                      ),
                      _CheckoutAddressIconOption(
                        icon: Icons.location_on_outlined,
                        selected: _selectedIcon == Icons.location_on_outlined,
                        onTap: () => setState(
                          () => _selectedIcon = Icons.location_on_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saveAddress,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveAddress() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      CheckoutAddress(
        id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        label: _labelController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        icon: _selectedIcon,
      ),
    );
  }
}

class _CheckoutAddressIconOption extends StatelessWidget {
  const _CheckoutAddressIconOption({
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: selected ? theme.colorScheme.primary : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

int _voucherDiscount(
  CheckoutVoucher? voucher,
  int subtotal,
  int deliveryFee,
  int serviceFee,
) {
  if (voucher == null || subtotal < voucher.minimumSpend) return 0;
  return voucher
      .calculateDiscount(subtotal, deliveryFee, serviceFee)
      .clamp(0, subtotal + deliveryFee + serviceFee)
      .toInt();
}

class _VoucherSelector extends StatelessWidget {
  const _VoucherSelector({
    required this.selectedVoucher,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.vouchers,
    required this.onSelect,
  });

  final CheckoutVoucher? selectedVoucher;
  final int subtotal;
  final int deliveryFee;
  final int serviceFee;
  final List<CheckoutVoucher> vouchers;
  final ValueChanged<CheckoutVoucher> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final voucher in vouchers)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Builder(
              builder: (context) {
                final eligible =
                    subtotal >= voucher.minimumSpend && voucher.isAvailable;
                final selected = selectedVoucher?.code == voucher.code;
                final discount = _voucherDiscount(
                  voucher,
                  subtotal,
                  deliveryFee,
                  serviceFee,
                );

                return InkWell(
                  onTap: eligible ? () => onSelect(voucher) : null,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary.withValues(alpha: 0.08)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.36)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: eligible
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.10,
                                  )
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            voucher.icon,
                            color: eligible
                                ? theme.colorScheme.primary
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      voucher.title,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: eligible
                                                ? const Color(0xFF111827)
                                                : const Color(0xFF94A3B8),
                                          ),
                                    ),
                                  ),
                                  Text(
                                    voucher.code,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                voucher.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: eligible
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                voucher.isUsed || voucher.isExpired
                                    ? voucher.statusLabel
                                    : eligible
                                    ? 'Hemat ${formatRupiah(discount)}'
                                    : 'Min. belanja ${formatRupiah(voucher.minimumSpend)}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: eligible
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB45309),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : eligible
                              ? Icons.radio_button_unchecked_rounded
                              : Icons.lock_outline_rounded,
                          color: selected
                              ? theme.colorScheme.primary
                              : const Color(0xFFCBD5E1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _AppliedVoucherCard extends StatelessWidget {
  const _AppliedVoucherCard({
    required this.voucher,
    required this.discount,
    required this.onRemove,
  });

  final CheckoutVoucher voucher;
  final int discount;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.confirmation_number_outlined,
            color: Color(0xFF15803D),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${voucher.code} dipakai, hemat ${formatRupiah(discount)}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFF166534),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          TextButton(onPressed: onRemove, child: const Text('Hapus')),
        ],
      ),
    );
  }
}

class _CheckoutHeroCard extends StatelessWidget {
  const _CheckoutHeroCard({
    required this.itemCount,
    required this.total,
    required this.deliveryMethod,
    required this.paymentMethod,
  });

  final int itemCount;
  final int total;
  final String deliveryMethod;
  final String paymentMethod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkas, cepat, dan siap dibayar',
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pastikan metode pengiriman, pembayaran, dan total pesanan sudah sesuai.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _CheckoutHeroStat(
                  label: 'Item',
                  value: '$itemCount produk',
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CheckoutHeroStat(
                  label: 'Total',
                  value: formatRupiah(total),
                  icon: Icons.receipt_long_outlined,
                  accent: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CheckoutInfoChip(
                icon: deliveryMethod == 'Kirim ke Rumah'
                    ? Icons.local_shipping_outlined
                    : Icons.storefront_outlined,
                label: deliveryMethod,
              ),
              _CheckoutInfoChip(
                icon: Icons.account_balance_wallet_outlined,
                label: paymentMethod,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutHeroStat extends StatelessWidget {
  const _CheckoutHeroStat({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFFFF3F3) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent ? const Color(0xFFFFD8D8) : const Color(0xFFE7ECF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: accent ? theme.colorScheme.primary : const Color(0xFF64748B),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: accent ? theme.colorScheme.primary : const Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutInfoChip extends StatelessWidget {
  const _CheckoutInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7ECF2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  const _CheckoutSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _CheckoutOption extends StatelessWidget {
  const _CheckoutOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final Widget title;
  final Widget subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: !enabled
              ? const Color(0xFFF8FAFC)
              : selected
              ? theme.colorScheme.primary.withValues(alpha: 0.07)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: !enabled
                ? const Color(0xFFE2E8F0)
                : selected
                ? theme.colorScheme.primary.withValues(alpha: 0.45)
                : const Color(0xFFE7ECF2),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: !enabled
                      ? const Color(0xFFCBD5E1)
                      : selected
                      ? theme.colorScheme.primary
                      : const Color(0xFF94A3B8),
                  width: 1.8,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: (theme.textTheme.titleMedium ?? const TextStyle())
                        .copyWith(
                          fontWeight: FontWeight.w700,
                          color: enabled
                              ? const Color(0xFF111827)
                              : const Color(0xFF94A3B8),
                        ),
                    child: title,
                  ),
                  const SizedBox(height: 4),
                  DefaultTextStyle(
                    style:
                        theme.textTheme.bodyMedium?.copyWith(
                          color: enabled
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                          height: 1.4,
                        ) ??
                        const TextStyle(),
                    child: subtitle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.isDiscount = false,
  });

  final String label;
  final int value;
  final bool emphasized;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
          )
        : theme.textTheme.bodyLarge?.copyWith(
            color: isDiscount ? const Color(0xFF15803D) : const Color(0xFF475569),
            fontWeight: isDiscount ? FontWeight.w800 : FontWeight.w600,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            isDiscount ? '-${formatRupiah(value.abs())}' : formatRupiah(value),
            style: style,
          ),
        ],
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final OrderItem order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tracking = _buildTrackingView(order);
    final isPickupOrder = _isPickupOrder(order);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD9001B), Color(0xFF970014)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.status,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  order.id,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatusNode(
                        label: tracking.steps[0].label,
                        active: true,
                      ),
                    ),
                    Expanded(
                      child: _StatusNode(
                        label: tracking.steps[1].label,
                        active: tracking.activeStepIndex >= 1,
                      ),
                    ),
                    Expanded(
                      child: _StatusNode(
                        label: tracking.steps[2].label,
                        active: tracking.activeStepIndex >= 2,
                      ),
                    ),
                    Expanded(
                      child: _StatusNode(
                        label: tracking.steps[3].label,
                        active: tracking.activeStepIndex >= 3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InfoPanel(
            title: 'Order Summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(label: 'Items', value: order.items.join(', ')),
                InfoRow(label: 'Created', value: order.createdAt),
                InfoRow(label: 'Total', value: formatRupiah(order.total)),
                InfoRow(label: 'Status note', value: order.progressLabel),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _InfoPanel(
            title: isPickupOrder ? 'Status Pengambilan' : 'Lacak Kurir',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.address, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          order.progressLabel,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF3C7CC)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tracking.referenceLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (var i = 0; i < tracking.steps.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i == tracking.steps.length - 1 ? 0 : 12,
                          ),
                          child: _TrackingTimelineTile(
                            label: tracking.steps[i].label,
                            note: _timelineNoteForStep(
                              order: order,
                              stepIndex: i,
                              isPickupOrder: isPickupOrder,
                            ),
                            active: i <= tracking.activeStepIndex,
                            isLast: i == tracking.steps.length - 1,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => _showFeatureSnack(
              context,
              isPickupOrder
                  ? 'Status pengambilan ${order.id} sudah diperbarui.'
                  : 'Kurir untuk pesanan ${order.id} sedang dipantau.',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              isPickupOrder
                  ? 'Perbarui Status Pickup'
                  : 'Segarkan Status Pengiriman',
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingTimelineTile extends StatelessWidget {
  const _TrackingTimelineTile({
    required this.label,
    required this.note,
    required this.active,
    required this.isLast,
  });

  final String label;
  final String note;
  final bool active;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = active ? theme.colorScheme.primary : const Color(0xFFCBD5E1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Column(
            children: [
              Icon(
                active
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: accent,
                size: 20,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 34,
                  margin: const EdgeInsets.only(top: 4),
                  color: accent.withValues(alpha: active ? 0.65 : 1),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: active
                        ? const Color(0xFF111827)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _timelineNoteForStep({
  required OrderItem order,
  required int stepIndex,
  required bool isPickupOrder,
}) {
  if (isPickupOrder) {
    const pickupNotes = [
      'Pesanan sudah diterima oleh sistem koperasi.',
      'Tim toko sedang menyiapkan barang untuk diambil.',
      'Pesanan siap diambil di counter koperasi.',
      'Pesanan sudah selesai diambil.',
    ];
    return stepIndex == _pickupTrackingIndex(order.status)
        ? order.progressLabel
        : pickupNotes[stepIndex];
  }

  const deliveryNotes = [
    'Pesanan sudah dikonfirmasi dan menunggu proses gudang.',
    'Barang sedang dikemas oleh tim koperasi.',
    'Kurir sedang menuju alamat pengantaran.',
    'Pesanan sudah diterima di alamat tujuan.',
  ];
  return stepIndex == _deliveryTrackingIndex(order.status)
      ? order.progressLabel
      : deliveryNotes[stepIndex];
}

class SettingDetailScreen extends StatelessWidget {
  const SettingDetailScreen({super.key, required this.setting});

  final SettingShortcut setting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(setting.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    setting.icon,
                    color: theme.colorScheme.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                Text(setting.title, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 10),
                Text(
                  setting.subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF6D5A58),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Halaman ini sudah siap dipakai sebagai titik lanjut pengembangan. Kamu bisa menambahkan form, integrasi backend, atau validasi data dari sini.',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _emailController = TextEditingController(text: widget.profile.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ProfileAvatar(
                      radius: 56,
                      bordered: false,
                      imageUrl: _initialsAvatarKey,
                      initials: _initialsFromName(_nameController.text.trim()),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Perbarui Data Akun',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Informasi ini digunakan untuk pesanan, notifikasi, dan verifikasi akun.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Nama minimal 3 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      if (phone.length < 10) {
                        return 'Nomor telepon belum valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (!email.contains('@') || !email.contains('.')) {
                        return 'Email belum valid';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: FilledButton.icon(
            onPressed: _saveProfile,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Simpan Perubahan'),
          ),
        ),
      ),
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      UserProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        avatarUrl: _initialsAvatarKey,
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.items,
    required this.errorMessage,
    required this.onReload,
    required this.onClearCart,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    required this.onCheckout,
  });

  final List<CartLine> items;
  final String? errorMessage;
  final Future<List<CartLine>> Function() onReload;
  final Future<List<CartLine>> Function({bool showFeedback}) onClearCart;
  final Future<List<CartLine>> Function(String cartItemId) onRemoveItem;
  final Future<List<CartLine>> Function(String cartItemId, int quantity)
  onUpdateQuantity;
  final Future<List<CartLine>> Function(List<CartLine> selectedItems)
  onCheckout;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartLine> cartEntries = List<CartLine>.of(widget.items);
  late final Set<String> selectedCartItemIds = {
    for (final entry in cartEntries) entry.id,
  };
  bool _isMutating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSelected =
        cartEntries.isNotEmpty &&
        selectedCartItemIds.length == cartEntries.length;
    final totalPrice = cartEntries.fold<int>(0, (total, entry) {
      if (!selectedCartItemIds.contains(entry.id)) {
        return total;
      }
      return total + (entry.product.price * entry.quantity);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [
          TextButton(
            onPressed: cartEntries.isEmpty || _isMutating ? null : _clearCart,
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
      body: cartEntries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.errorMessage == null
                          ? Icons.shopping_cart_outlined
                          : Icons.wifi_off_rounded,
                      size: 84,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.errorMessage == null
                          ? 'Keranjang masih kosong'
                          : 'Keranjang belum tersedia',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.errorMessage ??
                          'Tambahkan produk favorit dari Home atau Shop.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (widget.errorMessage != null) ...[
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: _isMutating ? null : _reloadCart,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                CheckboxListTile(
                  value: allSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        selectedCartItemIds
                          ..clear()
                          ..addAll(cartEntries.map((entry) => entry.id));
                      } else {
                        selectedCartItemIds.clear();
                      }
                    });
                  },
                  title: const Text('Pilih Semua'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < cartEntries.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Builder(
                      builder: (context) {
                        final entry = cartEntries[index];
                        final product = entry.product;
                        return Dismissible(
                          key: ValueKey(entry.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) => _removeEntry(entry),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: selectedCartItemIds.contains(entry.id),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value ?? false) {
                                        selectedCartItemIds.add(entry.id);
                                      } else {
                                        selectedCartItemIds.remove(entry.id);
                                      }
                                    });
                                  },
                                ),
                                SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: ProductMedia(
                                    product: product,
                                    borderRadius: BorderRadius.circular(12),
                                    fit: BoxFit.cover,
                                    padding: const EdgeInsets.all(6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        formatRupiah(product.price),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _QuantityMiniButton(
                                            icon: Icons.remove,
                                            onTap:
                                                entry.quantity > 1 &&
                                                    !_isMutating
                                                ? () => _changeQuantity(
                                                    entry,
                                                    entry.quantity - 1,
                                                  )
                                                : null,
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Text('${entry.quantity}'),
                                          ),
                                          _QuantityMiniButton(
                                            icon: Icons.add,
                                            onTap: _isMutating
                                                ? null
                                                : () => _changeQuantity(
                                                    entry,
                                                    entry.quantity + 1,
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _isMutating
                                      ? null
                                      : () => unawaited(_removeEntry(entry)),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(totalPrice),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: totalPrice == 0 || _isMutating ? null : _checkout,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(138, 52),
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reloadCart() async {
    setState(() => _isMutating = true);
    try {
      final updated = await widget.onReload();
      if (!mounted) return;
      setState(() {
        cartEntries = List<CartLine>.of(updated);
        selectedCartItemIds
          ..clear()
          ..addAll(updated.map((entry) => entry.id));
      });
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _clearCart() async {
    setState(() => _isMutating = true);
    try {
      final updated = await widget.onClearCart(showFeedback: true);
      if (!mounted) return;
      setState(() {
        cartEntries = List<CartLine>.of(updated);
        selectedCartItemIds
          ..clear()
          ..addAll(updated.map((entry) => entry.id));
      });
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<bool> _removeEntry(CartLine entry) async {
    setState(() => _isMutating = true);
    try {
      final updated = await widget.onRemoveItem(entry.id);
      if (!mounted) return false;
      setState(() {
        cartEntries = List<CartLine>.of(updated);
        selectedCartItemIds
          ..remove(entry.id)
          ..removeWhere(
            (id) => !updated.any((updatedEntry) => updatedEntry.id == id),
          );
      });
      _showFeatureSnack(
        context,
        '${entry.product.name} dihapus dari keranjang.',
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _changeQuantity(CartLine entry, int newQuantity) async {
    if (newQuantity < 1) return;
    setState(() => _isMutating = true);
    try {
      final updated = await widget.onUpdateQuantity(entry.id, newQuantity);
      if (!mounted) return;
      setState(() {
        cartEntries = List<CartLine>.of(updated);
      });
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  Future<void> _checkout() async {
    setState(() => _isMutating = true);
    try {
      final updated = await widget.onCheckout(_selectedProducts());
      if (!mounted) return;
      setState(() {
        cartEntries = List<CartLine>.of(updated);
        selectedCartItemIds
          ..clear()
          ..addAll(updated.map((entry) => entry.id));
      });
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  List<CartLine> _selectedProducts() {
    return cartEntries
        .where((entry) => selectedCartItemIds.contains(entry.id))
        .toList(growable: false);
  }
}

class _QuantityMiniButton extends StatelessWidget {
  const _QuantityMiniButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap == null ? const Color(0xFF94A3B8) : null,
        ),
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.onChangeTab});

  final ValueChanged<int> onChangeTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD9001B), Color(0xFF8B0011)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -22,
            right: -34,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 18,
            child: Container(
              width: 102,
              height: 102,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Balance',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rp 450,000',
                          style: theme.textTheme.displayLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MepuPoin Points',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.stars_rounded,
                            color: Color(0xFFFFD54F),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '1,250',
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: const Color(0xFFFFE16D),
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      label: 'Top Up',
                      icon: Icons.account_balance_wallet_outlined,
                      onTap: () => onChangeTab(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      label: 'Pay',
                      icon: Icons.payments_outlined,
                      onTap: () => onChangeTab(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      label: 'Transfer',
                      icon: Icons.send_rounded,
                      onTap: () => _showFeatureSnack(
                        context,
                        'Transfer saldo MepuPoin siap digunakan.',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      label: 'Pesanan',
                      icon: Icons.local_shipping_outlined,
                      onTap: () => onChangeTab(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class PromoCard extends StatelessWidget {
  const PromoCard({super.key, required this.banner});

  final PromoBanner banner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: 352,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (banner.imageUrl case final String imageUrl)
              NetworkImageBox(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                fallback: PromoPlaceholder(banner: banner),
              )
            else
              PromoPlaceholder(banner: banner),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Icon(
                banner.icon,
                color: Colors.white.withValues(alpha: 0.9),
                size: 34,
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    banner.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    banner.subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryButton extends StatelessWidget {
  const CategoryButton({super.key, required this.category});

  final CategoryItem category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            category.icon,
            color: theme.colorScheme.primary,
            size: 29,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          category.label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge,
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.stock,
    this.onAddToCart,
    this.variant = ProductCardVariant.flashSale,
  });

  final Product product;
  final int? stock;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final ProductCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCatalog = variant == ProductCardVariant.catalog;
    final isCompact = variant == ProductCardVariant.compact;
    final currentStock = stock;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: EdgeInsets.all(isCompact ? 10 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE8BCB8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ProductMedia(
                product: product,
                borderRadius: BorderRadius.circular(18),
                fit: isCompact ? BoxFit.cover : BoxFit.contain,
                padding: EdgeInsets.all(isCompact ? 8 : 14),
              ),
            ),
            SizedBox(height: isCompact ? 10 : 12),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  (isCompact
                          ? theme.textTheme.titleSmall
                          : theme.textTheme.titleMedium)
                      ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              formatRupiah(product.price),
              style:
                  (isCompact
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.titleLarge)
                      ?.copyWith(color: theme.colorScheme.primary),
            ),
            if (isCatalog) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      currentStock == null
                          ? 'Stock: ${100 - product.claimedPercent} remaining'
                          : currentStock > 0
                          ? 'Stok tersedia: $currentStock'
                          : 'Stok habis',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: currentStock == 0
                            ? theme.colorScheme.error
                            : const Color(0xFF1A7F42),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: currentStock == 0 ? null : onAddToCart,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: currentStock == 0
                            ? const Color(0xFFCBD5E1)
                            : theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ] else if (!isCompact) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: product.claimedPercent / 100,
                  minHeight: 7,
                  color: theme.colorScheme.primary,
                  backgroundColor: const Color(0xFFE1E3E4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${product.claimedPercent}% Claimed',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum ProductCardVariant { flashSale, catalog, compact }

class CooperativeCard extends StatelessWidget {
  const CooperativeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8BCB8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 82,
              height: 82,
              child: NetworkImageBox(
                imageUrl: _cooperativeImageUrl,
                fit: BoxFit.cover,
                fallback: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFCEE6D0), Color(0xFF9CC3A5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.store_mall_directory_rounded,
                    size: 42,
                    color: Color(0xFF245C33),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cooperative Unit: Sukamaju Village',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '500m away • Jl. Merdeka No. 42',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6D5A58),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: const [
                    StatusPill(
                      label: 'IN STOCK',
                      foreground: Color(0xFF1A7F42),
                      background: Color(0xFFDFF5E8),
                    ),
                    StatusPill(
                      label: 'PICKUP READY',
                      foreground: Color(0xFF7B6200),
                      background: Color(0xFFF9EFB4),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.primary),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.navigation_outlined,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class NetworkImageBox extends StatelessWidget {
  const NetworkImageBox({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.fallback,
  });

  final String imageUrl;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: fit,
      alignment: alignment,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return fallback ??
            const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) {
        return fallback ?? const ColoredBox(color: Color(0xFFF3F4F5));
      },
    );
  }
}

class ProductMedia extends StatelessWidget {
  const ProductMedia({
    super.key,
    required this.product,
    this.borderRadius,
    this.fit = BoxFit.contain,
    this.padding = const EdgeInsets.all(14),
    this.iconSize = 76,
  });

  final Product product;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final EdgeInsets padding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      borderRadius: borderRadius ?? BorderRadius.circular(18),
      gradient: LinearGradient(
        colors: [product.tone.withValues(alpha: 0.22), Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );

    if (product.imageUrl case final String imageUrl) {
      return DecoratedBox(
        decoration: decoration,
        child: Center(
          child: Padding(
            padding: padding,
            child: NetworkImageBox(
              imageUrl: imageUrl,
              fit: fit,
              alignment: Alignment.center,
              fallback: Center(
                child: Icon(product.icon, size: iconSize, color: product.tone),
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            product.tone.withValues(alpha: 0.92),
            product.tone.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(product.icon, size: iconSize, color: Colors.white),
      ),
    );
  }
}

class PromoPlaceholder extends StatelessWidget {
  const PromoPlaceholder({super.key, required this.banner});

  final PromoBanner banner;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: banner.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          banner.icon,
          size: 72,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.onChanged,
  });

  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.radius,
    this.bordered = true,
    this.imageUrl = _initialsAvatarKey,
    this.initials = 'BS',
  });

  final double radius;
  final bool bordered;
  final String imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final imageRadius = bordered ? radius - 2 : radius - 6;
    final isInitialsOnly = imageUrl == _initialsAvatarKey;
    final isNetworkImage =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    return CircleAvatar(
      radius: radius,
      backgroundColor: bordered ? const Color(0xFFD9001B) : Colors.white,
      child: CircleAvatar(
        radius: imageRadius,
        backgroundColor: const Color(0xFFE8ECEF),
        child: ClipOval(
          child: SizedBox.expand(
            child: isInitialsOnly
                ? ColoredBox(
                    color: const Color(0xFF25313B),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: radius * 0.36,
                        ),
                      ),
                    ),
                  )
                : isNetworkImage
                ? NetworkImageBox(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    fallback: ColoredBox(
                      color: const Color(0xFF25313B),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: radius * 0.36,
                          ),
                        ),
                      ),
                    ),
                  )
                : Image.file(
                    File(imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return ColoredBox(
                        color: const Color(0xFF25313B),
                        child: Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: radius * 0.36,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

String _initialsFromName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'MP';
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length.clamp(0, 2))
        .toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: _CartCountBadge(count: badgeCount),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.primary : const Color(0xFFECEFF1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : const Color(0xFF2E3132),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected ? Colors.white : const Color(0xFF2E3132),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KdmpBottomNavigationBar extends StatelessWidget {
  const KdmpBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_filled, 'Home'),
      (Icons.storefront_rounded, 'Shop'),
      (Icons.local_shipping_outlined, 'Pesanan'),
      (Icons.person_outline_rounded, 'Akun'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _BottomNavItem(
                  icon: items[i].$1,
                  label: items[i].$2,
                  selected: currentIndex == i,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: selected ? 54 : 40,
              height: selected ? 54 : 40,
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF6B5A56),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: selected
                    ? theme.colorScheme.primary
                    : const Color(0xFF6B5A56),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityTile extends StatelessWidget {
  const ActivityTile({super.key, required this.entry});

  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(entry.icon, color: entry.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(entry.subtitle, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(entry.time, style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final OrderItem order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8BCB8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.title, style: theme.textTheme.titleMedium),
                ),
                StatusPill(
                  label: order.status,
                  foreground: order.status == 'Completed'
                      ? const Color(0xFF116C46)
                      : const Color(0xFFD9001B),
                  background: order.status == 'Completed'
                      ? const Color(0xFFDFF5E8)
                      : const Color(0xFFFCE1E4),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(order.createdAt, style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(
              formatRupiah(order.total),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(order.progressLabel, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  const SettingTile({super.key, required this.setting, required this.onTap});

  final SettingShortcut setting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(setting.icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 18),
            Expanded(
              child: Text(setting.title, style: theme.textTheme.titleMedium),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9F7E79)),
          ],
        ),
      ),
    );
  }
}

class ProfileActionChip extends StatelessWidget {
  const ProfileActionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniStatCard extends StatelessWidget {
  const MiniStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Card(
        child: SizedBox(
          height: 164,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 34),
              ),
              const SizedBox(height: 18),
              Text(label, style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class SupportOption extends StatelessWidget {
  const SupportOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8BCB8)),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6D5A58),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupportButton extends StatelessWidget {
  const SupportButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFFE4E5E7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(label, style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}

<<<<<<< HEAD
class FeatureCard extends StatelessWidget {
  const FeatureCard({super.key, required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8BCB8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
=======
class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: const Color(0xFF2A2727)),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: _CartCountBadge(count: badgeCount),
          ),
      ],
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
    );
  }
}

class _StatusNode extends StatelessWidget {
  const _StatusNode({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          active ? Icons.check_circle : Icons.radio_button_unchecked,
          color: active ? Colors.white : Colors.white54,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: active ? Colors.white : Colors.white60,
          ),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionTap,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(title, style: theme.textTheme.headlineMedium),
          if (trailing case final Widget trailingWidget) trailingWidget,
          const Spacer(),
          if (actionLabel != null)
            TextButton(onPressed: onActionTap, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String formatRupiah(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'Rp ${buffer.toString()}';
}

String productCategory(Product product) {
  return productCategoriesFor(product).first;
}

bool productMatchesCategory(Product product, String category) {
  return category == 'Semua' ||
      productCategoriesFor(product).contains(category);
}

List<String> productCategoriesFor(Product product) {
  return product.categories.isEmpty ? const ['Lainnya'] : product.categories;
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Makanan':
      return Icons.restaurant_outlined;
    case 'Minuman':
      return Icons.local_cafe_outlined;
    case 'Sembako':
      return Icons.shopping_basket_outlined;
    case 'Olahraga':
      return Icons.sports_soccer_outlined;
    case 'Elektronik':
      return Icons.devices_outlined;
    case 'Fashion':
      return Icons.checkroom_outlined;
    default:
      return Icons.apps_rounded;
  }
}

IconData _voucherIconFromName(String name) {
  switch (name) {
    case 'local_shipping':
      return Icons.local_shipping_outlined;
    case 'percent':
      return Icons.percent_rounded;
    case 'premium':
      return Icons.workspace_premium_outlined;
    case 'basket':
      return Icons.shopping_basket_outlined;
    default:
      return Icons.confirmation_number_outlined;
  }
}

int discountPercent(Product product) {
  final discount = product.originalPrice - product.price;
  return ((discount / product.originalPrice) * 100).round();
}

IconData _rewardTransactionIcon(String transactionType) {
  switch (transactionType) {
    case 'redeem':
      return Icons.redeem_rounded;
    case 'adjustment':
      return Icons.tune_rounded;
    case 'expired':
      return Icons.timer_off_outlined;
    case 'earn':
    default:
      return Icons.stars_rounded;
  }
}

String _rewardTransactionTitle(String transactionType) {
  switch (transactionType) {
    case 'redeem':
      return 'Redeem Point';
    case 'adjustment':
      return 'Adjustment Point';
    case 'expired':
      return 'Point Expired';
    case 'earn':
    default:
      return 'Earn Point';
  }
}

String _formatRewardDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${date.day} ${months[date.month - 1]} ${date.year}, ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
}

