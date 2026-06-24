import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../catalog_repository.dart';
import '../mock_data.dart';
import '../models.dart';
import 'manage_addresses_screen.dart';
import 'notification_history_screen.dart';
import 'notification_settings_screen.dart';
import 'payment_methods_screen.dart';
import 'security_settings_screen.dart';

const _cooperativeImageUrl =
    'https://images.unsplash.com/photo-1516321497487-e288fb19713f?auto=format&fit=crop&w=600&q=80';
const _initialsAvatarKey = '__initials__';

List<String> get productCategories => [
  'Semua',
  ...categories.map((category) => category.label),
];

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
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.minimumSpend,
    required this.calculateDiscount,
  });

  final String code;
  final String title;
  final String description;
  final IconData icon;
  final int minimumSpend;
  final int Function(int subtotal, int deliveryFee, int serviceFee)
  calculateDiscount;
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

class _CustomerOrderSnapshot {
  const _CustomerOrderSnapshot({required this.name, required this.phone});

  final String name;
  final String? phone;
}

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
    calculateDiscount: _freeDeliveryDiscount,
  ),
  CheckoutVoucher(
    code: 'MEPU10',
    title: 'Diskon Belanja 10%',
    description: 'Maksimal potongan Rp 25.000',
    icon: Icons.percent_rounded,
    minimumSpend: 100000,
    calculateDiscount: _tenPercentDiscount,
  ),
  CheckoutVoucher(
    code: 'ANGGOTA15',
    title: 'Voucher Anggota',
    description: 'Potongan langsung Rp 15.000',
    icon: Icons.workspace_premium_outlined,
    minimumSpend: 75000,
    calculateDiscount: _memberVoucherDiscount,
  ),
];

int _freeDeliveryDiscount(int subtotal, int deliveryFee, int serviceFee) {
  return deliveryFee.clamp(0, 8000).toInt();
}

int _tenPercentDiscount(int subtotal, int deliveryFee, int serviceFee) {
  return (subtotal * 0.10).round().clamp(0, 25000).toInt();
}

int _memberVoucherDiscount(int subtotal, int deliveryFee, int serviceFee) {
  return 15000.clamp(0, subtotal + deliveryFee + serviceFee).toInt();
}

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
  int _currentIndex = 0;
  int _mepuBalance = 0;
  String _shopSelectedCategory = 'Semua';
  late UserProfile _profile;
  late final Map<String, int> _productStocks = _createStocks(products);
  final List<Product> _cartItems = [];
  final List<OrderItem> _orderItems = List<OrderItem>.of(orders);
  List<_UserBranchOption> _branches = const [];
  String? _selectedBranchId;
  String _selectedBranchName = 'Pilih Cabang';
  String _selectedBranchSubtitle = 'Pilih cabang KDMP terdekat';

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    unawaited(_initializeBranchSelection());
    unawaited(_loadWalletBalance());
    unawaited(_loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(
        cartItemCount: _cartItems.length,
        mepuBalance: _mepuBalance,
        productStocks: _productStocks,
        products: products,
        categories: productCategories,
        selectedBranchName: _selectedBranchName,
        selectedBranchSubtitle: _selectedBranchSubtitle,
        onOpenProduct: _openProduct,
        onChangeTab: _changeTab,
        onOpenCart: _openCart,
        onAddToCart: _addToCart,
        onTopUp: _openTopUpDialog,
        onSelectCategory: _openShopCategory,
        onOpenNotifications: _openNotifications,
        onSelectBranch: _handleSelectBranchTap,
      ),
      ShopScreen(
        cartItemCount: _cartItems.length,
        productStocks: _productStocks,
        products: products,
        categories: productCategories,
        selectedCategory: _shopSelectedCategory,
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
        onTopUp: _openTopUpDialog,
        onEditProfile: _openEditProfile,
        onOpenSetting: _openSetting,
        onChangeTab: _changeTab,
        onOpenPromo: _openPromoCenter,
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

  void _handleSelectBranchTap() {
    unawaited(_openBranchSelector());
  }

  Future<void> _initializeBranchSelection() async {
    await _loadBranches();
    await _loadCatalog();
  }

  Future<void> _loadBranches() async {
    try {
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
            ? 'Pilih cabang KDMP terdekat'
            : selectedBranch.subtitle;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _branches = const [];
        _selectedBranchId = null;
        _selectedBranchName = 'Pilih Cabang';
        _selectedBranchSubtitle = 'Pilih cabang KDMP terdekat';
      });
    }
  }

  Future<void> _loadCatalog() async {
    try {
      final snapshot = await _catalogRepository.load(
        branchId: _selectedBranchId,
      );
      final loadedCategories = List<CategoryItem>.of(snapshot.categories);
      final loadedProducts = List<Product>.of(snapshot.products);
      if (!mounted) return;
      setState(() {
        categories
          ..clear()
          ..addAll(loadedCategories);
        products
          ..clear()
          ..addAll(loadedProducts);
        _productStocks
          ..clear()
          ..addAll(_createStocks(loadedProducts));
        if (!productCategories.contains(_shopSelectedCategory)) {
          _shopSelectedCategory = 'Semua';
        }
      });
    } catch (_) {
      // Keep fallback catalog if remote load fails.
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
      // Keep local fallback balance if remote load fails.
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
      // Keep local fallback orders if remote load fails.
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
    }
  }

  void _setWalletBalance(int newBalance) {
    setState(() => _mepuBalance = newBalance.clamp(0, 2147483647));
    unawaited(_persistWalletBalance(_mepuBalance));
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
          cartItemCount: _cartItems.length,
          product: product,
          stock: _stockOf(product),
          productStocks: _productStocks,
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
          items: List<Product>.of(_cartItems),
          onCartChanged: _setCartItems,
          onCheckout: (items) => _openCheckout(items, clearCart: true),
        ),
      ),
    );
  }

  void _addToCart(Product product) {
    if (!_hasAvailableStock([product], includeCartItems: true)) return;
    setState(() => _cartItems.add(product));
    _showFeatureSnack(
      context,
      '${product.name} ditambahkan ke keranjang.',
      title: 'Produk Ditambahkan',
      icon: Icons.shopping_cart_checkout_rounded,
    );
  }

  void _addItemsToCart(List<Product> items) {
    if (items.isEmpty) return;
    if (!_hasAvailableStock(items, includeCartItems: true)) return;
    setState(() => _cartItems.addAll(items));
    final firstProduct = items.first;
    final message = items.length == 1
        ? '${firstProduct.name} ditambahkan ke keranjang.'
        : '${firstProduct.name} x ${items.length} ditambahkan ke keranjang.';
    _showFeatureSnack(
      context,
      message,
      title: 'Produk Ditambahkan',
      icon: Icons.shopping_cart_checkout_rounded,
    );
  }

  void _buyNow(List<Product> items) {
    _openCheckout(items, clearCart: false);
  }

  void _openCheckout(List<Product> items, {required bool clearCart}) {
    if (items.isEmpty) return;
    if (!_hasAvailableStock(items, includeCartItems: false)) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutScreen(
          items: List<Product>.of(items),
          mepuBalance: _mepuBalance,
          productStocks: _productStocks,
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
                voucherLabel,
              ) async {
                final order = await _createOrder(
                  checkoutItems,
                  paymentMethod: paymentMethod,
                  deliveryMethod: deliveryMethod,
                  addressId: addressId,
                  address: address,
                  finalTotal: finalTotal,
                  voucherLabel: voucherLabel,
                );
                if (order == null) return null;
                setState(() {
                  _orderItems.insert(0, order);
                  _decreaseStock(checkoutItems);
                  if (paymentMethod == 'Saldo MepuPoin') {
                    _mepuBalance -= finalTotal;
                  }
                  if (clearCart) _cartItems.clear();
                });
                if (paymentMethod == 'Saldo MepuPoin') {
                  unawaited(_persistWalletBalance(_mepuBalance));
                }
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
                unawaited(_loadOrders());
                return order;
              },
        ),
      ),
    );
  }

  Future<OrderItem?> _createOrder(
    List<Product> items, {
    required String paymentMethod,
    required String deliveryMethod,
    String? addressId,
    required String address,
    required int finalTotal,
    String? voucherLabel,
  }) async {
    if (_canUseSupabase) {
      try {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user == null) return null;

        final groupedItems = _summarizeProducts(items);
        final orderType = deliveryMethod == 'Ambil di Koperasi'
            ? 'pickup'
            : 'delivery';
        final paymentStatus = paymentMethod == 'Saldo MepuPoin'
            ? 'paid'
            : 'unpaid';
        final orderStatus = paymentStatus == 'paid' ? 'processing' : 'pending';
        final paymentMethodId = await _paymentMethodIdForCheckout(
          paymentMethod,
        );
        final branchContext = await _resolveCheckoutBranchContext();
        final customerSnapshot = await _resolveCustomerOrderSnapshot(user.id);
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
              'discount_total': 0,
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

        final orderNo = (orderRow['order_no'] ?? '').toString();
        return OrderItem(
          id: orderNo,
          title: groupedItems.length == 1
              ? groupedItems.first
              : '${groupedItems.first} + ${groupedItems.length - 1} produk',
          status: _displayOrderStatus(
            orderStatus: orderStatus,
            paymentStatus: paymentStatus,
            orderType: orderType,
          ),
          createdAt: _formatBackendOrderDate(orderRow['placed_at']),
          total: finalTotal,
          progressLabel: _backendProgressLabel(
            orderNo: orderNo,
            orderStatus: orderStatus,
            paymentStatus: paymentStatus,
            orderType: orderType,
            paymentCode: _paymentMethodCodeForCheckout(paymentMethod),
            paymentName: paymentMethod,
          ),
          address: orderType == 'pickup'
              ? '${branchContext.branchName} - Pickup Counter'
              : address,
          items: [
            ...groupedItems,
            if (voucherLabel != null) 'Voucher: $voucherLabel',
          ],
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
        'Cabang KDMP belum tersedia dari backend.',
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
                'Pilih Cabang KDMP',
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
        ? 'Pesanan KDMP'
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
      ),
      address: _backendOrderAddress(
        orderType: orderType,
        addressRow: addressRow,
        row: row,
      ),
      items: items,
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
      case 'Bayar di Koperasi':
        return 'cash';
      default:
        return 'wallet';
    }
  }

  Future<String?> _paymentMethodIdForCheckout(String paymentMethod) async {
    final paymentCode = _paymentMethodCodeForCheckout(paymentMethod);
    if (paymentCode == 'wallet') return null;

    final row = await Supabase.instance.client
        .from('payment_methods')
        .select('id')
        .eq('code', paymentCode)
        .maybeSingle();
    return row?['id']?.toString();
  }

  Future<_CheckoutBranchContext> _resolveCheckoutBranchContext() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    const fallbackBranchName = 'KDMP Solo Banjarsari';

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

  Future<_CustomerOrderSnapshot> _resolveCustomerOrderSnapshot(
    String userId,
  ) async {
    final row = await Supabase.instance.client
        .from('profiles')
        .select('full_name, phone')
        .eq('id', userId)
        .maybeSingle();

    final fullName = (row?['full_name'] ?? _profile.name).toString().trim();
    final phone = (row?['phone'] ?? _profile.phone).toString().trim();

    return _CustomerOrderSnapshot(
      name: fullName.isEmpty ? _profile.name : fullName,
      phone: phone.isEmpty || phone == '-' ? null : phone,
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
  }) {
    if (orderStatus == 'cancelled') {
      return 'Pesanan dibatalkan.';
    }
    if (orderStatus == 'completed') {
      return 'Pesanan selesai dan transaksi berhasil.';
    }
    if (paymentStatus != 'paid' && orderStatus == 'pending') {
      if (paymentCode.startsWith('transfer_')) {
        final suffix = orderNo.replaceAll(RegExp(r'[^0-9]'), '');
        final vaSuffix = suffix.length > 8
            ? suffix.substring(suffix.length - 8)
            : suffix.padLeft(8, '0');
        final bankName = paymentName.isEmpty ? 'Bank' : paymentName;
        return 'Virtual Account $bankName 8808$vaSuffix';
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

  bool _hasAvailableStock(
    List<Product> items, {
    required bool includeCartItems,
  }) {
    final requestedCounts = _countProducts(items);
    final cartCounts = includeCartItems
        ? _countProducts(_cartItems)
        : <String, int>{};
    for (final entry in requestedCounts.entries) {
      final product = products.firstWhere((item) => item.id == entry.key);
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

  void _setCartItems(List<Product> items) {
    setState(() {
      _cartItems
        ..clear()
        ..addAll(items);
    });
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
      final createdResult = await Supabase.instance.client.rpc(
        'create_wallet_topup',
        params: {
          'p_amount': request.amount,
          'p_payment_method': _walletPaymentMethodCode(request.method),
        },
      );
      final createdRow = _rpcRow(createdResult);
      if (createdRow == null) {
        throw Exception('Transaksi top up sandbox tidak dapat dibuat.');
      }

      if (!mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SandboxPaymentDialog(
          summary: _SandboxTopUpSummary.fromRow(createdRow),
        ),
      );
      if (!mounted) return;

      if (confirmed != true) {
        _showFeatureSnack(
          context,
          'Transaksi sandbox disimpan sebagai pending. Anda bisa lanjutkan lagi nanti.',
          title: 'Menunggu Pembayaran',
          icon: Icons.schedule_outlined,
        );
        return;
      }

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
        'Sandbox sukses. Saldo bertambah ${formatRupiah(request.amount)} dan sekarang ${formatRupiah(newBalance)}.',
        title: 'Top Up Berhasil',
        icon: Icons.account_balance_wallet_outlined,
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;
      _showFeatureSnack(
        context,
        error.message,
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

  Map<String, dynamic>? _rpcRow(dynamic result) {
    if (result is Map<String, dynamic>) return result;
    if (result is List &&
        result.isNotEmpty &&
        result.first is Map<String, dynamic>) {
      return result.first as Map<String, dynamic>;
    }
    return null;
  }

  String _walletPaymentMethodCode(String method) {
    return method == 'QRIS' ? 'qris' : 'virtual_account';
  }

  OrderItem? _payOrder(OrderItem order) {
    final index = _orderItems.indexWhere((item) => item.id == order.id);
    if (index == -1) return null;
    final usesMepuBalance = order.progressLabel.contains('Saldo MepuPoin');
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
    }
    late final OrderItem updatedOrder;
    setState(() {
      if (usesMepuBalance) {
        _mepuBalance -= order.total;
      }
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

  void _cancelOrder(OrderItem order) {
    if (_canUseSupabase) {
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PromoCenterScreen()));
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

Future<void> _showVoucherList(BuildContext context) {
  return _showFeatureSnack(
    context,
    'Voucher tersedia: ONGKIRHEMAT, MEPU10, dan ANGGOTA15. Gunakan saat checkout sesuai syarat minimum belanja.',
    title: 'Voucher Anggota',
    icon: Icons.confirmation_number_outlined,
  );
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Material(
            color: Colors.white,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFD9001B), Color(0xFF8B0011)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Colors.white,
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
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Saldo masuk instan setelah pembayaran berhasil.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saldo yang akan masuk',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white70,
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                              const Divider(height: 24),
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
                                onPressed: _submit,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(52),
                                  backgroundColor: theme.colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
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

class _SandboxTopUpSummary {
  const _SandboxTopUpSummary({
    required this.topupId,
    required this.amount,
    required this.adminFee,
    required this.totalPayment,
    required this.paymentMethod,
    required this.status,
    required this.reference,
    required this.instruction,
    required this.expiresAt,
  });

  factory _SandboxTopUpSummary.fromRow(Map<String, dynamic> row) {
    return _SandboxTopUpSummary(
      topupId: (row['topup_id'] ?? '').toString(),
      amount: (row['amount'] as num?)?.toInt() ?? 0,
      adminFee: (row['admin_fee'] as num?)?.toInt() ?? 0,
      totalPayment: (row['total_payment'] as num?)?.toInt() ?? 0,
      paymentMethod: (row['payment_method'] ?? '').toString(),
      status: (row['status'] ?? '').toString(),
      reference: (row['sandbox_reference'] ?? '').toString(),
      instruction: (row['payment_instruction'] ?? '').toString(),
      expiresAt: DateTime.tryParse((row['expires_at'] ?? '').toString()),
    );
  }

  final String topupId;
  final int amount;
  final int adminFee;
  final int totalPayment;
  final String paymentMethod;
  final String status;
  final String reference;
  final String instruction;
  final DateTime? expiresAt;

  String get paymentMethodLabel {
    if (paymentMethod == 'qris') return 'QRIS Sandbox';
    return 'Virtual Account Sandbox';
  }
}

class _SandboxPaymentDialog extends StatelessWidget {
  const _SandboxPaymentDialog({required this.summary});

  final _SandboxTopUpSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expiresAt = summary.expiresAt;
    final expiresLabel = expiresAt == null
        ? '-'
        : '${expiresAt.day.toString().padLeft(2, '0')}/${expiresAt.month.toString().padLeft(2, '0')}/${expiresAt.year} '
              '${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
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
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pembayaran Sandbox',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Transaksi top up sudah dibuat sebagai sandbox. Simulasikan pembayaran berhasil untuk menambah saldo ke akun Anda.',
              style: theme.textTheme.bodyMedium,
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
                    value: summary.reference,
                  ),
                  const SizedBox(height: 10),
                  _TopUpSummaryRow(
                    label: 'Metode',
                    value: summary.paymentMethodLabel,
                  ),
                  const SizedBox(height: 10),
                  _TopUpSummaryRow(
                    label: 'Saldo masuk',
                    value: formatRupiah(summary.amount),
                  ),
                  const SizedBox(height: 10),
                  _TopUpSummaryRow(
                    label: 'Biaya admin',
                    value: formatRupiah(summary.adminFee),
                  ),
                  const Divider(height: 24),
                  _TopUpSummaryRow(
                    label: 'Total bayar',
                    value: formatRupiah(summary.totalPayment),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Text(
                summary.instruction,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF9A3412),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Nanti Saja'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Simulasikan Berhasil'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.38)
                : const Color(0xFFE2E8F0),
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
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
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
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? theme.colorScheme.primary
                  : const Color(0xFFCBD5E1),
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
        ? theme.textTheme.titleMedium?.copyWith(
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
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          formatRupiah(amount),
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? Colors.white : theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
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
    required this.selectedBranchName,
    required this.selectedBranchSubtitle,
    required this.onOpenProduct,
    required this.onChangeTab,
    required this.onOpenCart,
    required this.onAddToCart,
    required this.onTopUp,
    required this.onSelectCategory,
    required this.onOpenNotifications,
    required this.onSelectBranch,
  });

  final int cartItemCount;
  final int mepuBalance;
  final Map<String, int> productStocks;
  final List<Product> products;
  final List<String> categories;
  final String selectedBranchName;
  final String selectedBranchSubtitle;
  final ValueChanged<Product> onOpenProduct;
  final ValueChanged<int> onChangeTab;
  final VoidCallback onOpenCart;
  final ValueChanged<Product> onAddToCart;
  final VoidCallback onTopUp;
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
                onSearchTap: () => _showFeatureSnack(
                  context,
                  'Pencarian produk MepuPoin siap digunakan.',
                ),
                onFilterTap: () =>
                    _showFeatureSnack(context, 'Filter produk siap digunakan.'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _MepuPoinDeliveryActions(onShopTap: () => onChangeTab(1)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: _MepuPoinBannerCarousel(onTap: () => onChangeTab(1)),
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
    required this.onFilterTap,
  });

  final VoidCallback onSearchTap;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: InkWell(
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
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(Icons.tune_rounded, size: 18),
          ),
        ),
      ],
    );
  }
}

class _MepuPoinDeliveryActions extends StatelessWidget {
  const _MepuPoinDeliveryActions({required this.onShopTap});

  final VoidCallback onShopTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MepuPoinPillAction(
            label: 'Kirim ke Rumah',
            icon: Icons.local_shipping_outlined,
            active: true,
            onTap: onShopTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MepuPoinPillAction(
            label: 'Ambil di Koperasi',
            icon: Icons.storefront_rounded,
            active: false,
            onTap: onShopTap,
          ),
        ),
      ],
    );
  }
}

class _MepuPoinPillAction extends StatelessWidget {
  const _MepuPoinPillAction({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = active
        ? theme.colorScheme.primary
        : const Color(0xFF475569);

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: active ? const Color(0xFFFFD8D8) : const Color(0xFFE2E8F0),
        ),
        minimumSize: const Size.fromHeight(34),
        textStyle: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _MepuPoinBannerCarousel extends StatefulWidget {
  const _MepuPoinBannerCarousel({required this.onTap});

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
      if (!mounted || !_controller.hasClients) return;
      final nextIndex = (_currentIndex + 1) % _bannerSlides.length;
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

    return Column(
      children: [
        SizedBox(
          height: 156,
          child: PageView.builder(
            controller: _controller,
            itemCount: _bannerSlides.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final slide = _bannerSlides[index];
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
                              slide.eyebrow,
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
                                  slide.cta,
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
            for (var index = 0; index < _bannerSlides.length; index++)
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

class _BannerSlide {
  const _BannerSlide({
    required this.eyebrow,
    required this.title,
    required this.cta,
    required this.icon,
    required this.colors,
  });

  final String eyebrow;
  final String title;
  final String cta;
  final IconData icon;
  final List<Color> colors;
}

const _bannerSlides = <_BannerSlide>[
  _BannerSlide(
    eyebrow: 'Promo Hari Ini',
    title: 'Diskon 50% Pupuk dan Sembako',
    cta: 'Belanja Sekarang',
    icon: Icons.local_offer_rounded,
    colors: [Color(0xFFE21F26), Color(0xFF9F0016)],
  ),
  _BannerSlide(
    eyebrow: 'Gratis Ongkir',
    title: 'Kirim ke rumah untuk belanja harian',
    cta: 'Cek Voucher',
    icon: Icons.local_shipping_outlined,
    colors: [Color(0xFF00608E), Color(0xFF003A5A)],
  ),
  _BannerSlide(
    eyebrow: 'Produk Baru',
    title: 'Pilihan alat tani dan kebutuhan rumah',
    cta: 'Lihat Produk',
    icon: Icons.storefront_rounded,
    colors: [Color(0xFF166534), Color(0xFF0F3D25)],
  ),
];

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
                fit: BoxFit.cover,
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
    required this.selectedCategory,
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
  final String selectedCategory;
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
  String sortOption = 'Terpopuler';

  @override
  void didUpdateWidget(covariant ShopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      selectedCategory = widget.selectedCategory;
    }
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
                  icon: Icons.store_mall_directory_outlined,
                  onTap: widget.onSelectBranch,
                ),
                const SizedBox(width: 10),
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
                const SearchField(hintText: 'Cari produk...'),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        for (final option in options)
          PopupMenuItem<String>(
            value: option,
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
                const SizedBox(width: 10),
                Text(option),
              ],
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
    final sortedProducts = List<Product>.of(filteredProducts);

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
  const _EmptyProductState({required this.category, required this.onReset});

  final String category;
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
            'Belum ada produk untuk kategori $category.',
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
  final ValueChanged<OrderItem> onCancelOrder;

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
                          onCancel: () => widget.onCancelOrder(order),
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
    final isTransferBank = order.progressLabel.contains('Virtual Account');
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
                      isTransferBank
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
    required this.onTopUp,
    required this.onEditProfile,
    required this.onOpenSetting,
    required this.onChangeTab,
    required this.onOpenPromo,
    required this.onOpenFaq,
    required this.onOpenContactSupport,
    required this.onLogout,
  });

  final UserProfile profile;
  final int mepuBalance;
  final VoidCallback onTopUp;
  final VoidCallback onEditProfile;
  final ValueChanged<SettingShortcut> onOpenSetting;
  final ValueChanged<int> onChangeTab;
  final VoidCallback onOpenPromo;
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
                              onTap: () => _showVoucherList(context),
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

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.cartItemCount,
    required this.stock,
    required this.productStocks,
    required this.onOpenCart,
    required this.onAddToCart,
    required this.onAddItemsToCart,
    required this.onBuyNow,
  });

  final Product product;
  final int cartItemCount;
  final int stock;
  final Map<String, int> productStocks;
  final VoidCallback onOpenCart;
  final ValueChanged<Product> onAddToCart;
  final ValueChanged<List<Product>> onAddItemsToCart;
  final ValueChanged<List<Product>> onBuyNow;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class PromoCenterScreen extends StatelessWidget {
  const PromoCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const promos = [
      (
        'Gratis Ongkir Anggota',
        'Potongan ongkir sampai Rp 8.000 untuk pembelian kebutuhan harian.',
        Icons.local_shipping_outlined,
      ),
      (
        'Flash Sale Poin Member',
        'Tukar poin untuk harga spesial produk koperasi pilihan.',
        Icons.workspace_premium_outlined,
      ),
      (
        'Hemat Belanja Mingguan',
        'Diskon bundling untuk sembako dan produk rumah tangga.',
        Icons.shopping_basket_outlined,
      ),
    ];

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
          for (final promo in promos)
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
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(promo.$3, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(promo.$1, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            promo.$2,
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
    final related = products
        .where((item) => product.relatedIds.contains(item.id))
        .toList();
    final theme = Theme.of(context);
    final discount = discountPercent(product).clamp(0, 99);
    final soldCount = (product.claimedPercent * 3).clamp(24, 950).toInt();
    final rating = 4.6 + ((product.rewardPoints % 4) * 0.1);
    final selectedCategories = productCategoriesFor(product);
    final subtotal = product.price * quantity;

    return Scaffold(
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
                            child: Text(
                              '$discount%',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: const Color(0xFFD9001B),
                                fontWeight: FontWeight.w900,
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
    required this.productStocks,
    required this.onCompletePayment,
    required this.onCancelOrder,
    required this.onPlaceOrder,
  });

  final List<Product> items;
  final int mepuBalance;
  final Map<String, int> productStocks;
  final OrderItem? Function(OrderItem order) onCompletePayment;
  final ValueChanged<OrderItem> onCancelOrder;
  final Future<OrderItem?> Function(
    List<Product> items,
    String paymentMethod,
    String deliveryMethod,
    String? addressId,
    String address,
    int finalTotal,
    String? voucherLabel,
  )
  onPlaceOrder;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String deliveryMethod = 'Kirim ke Rumah';
  String paymentMethod = 'Saldo MepuPoin';
  CheckoutVoucher? selectedVoucher;
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
    final total = (subtotal + deliveryFee + serviceFee - voucherDiscount)
        .clamp(0, subtotal + deliveryFee + serviceFee)
        .toInt();

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
        children: [
          _CheckoutSection(
            title: 'Produk Dibeli',
            child: Column(
              children: [
                for (final item in groupedItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 58,
                          height: 58,
                          child: ProductMedia(
                            product: item.product,
                            borderRadius: BorderRadius.circular(12),
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
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${formatRupiah(item.product.price)} x ${item.quantity}',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Stok tersedia: ${widget.productStocks[item.product.id] ?? 0}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: const Color(0xFF15803D),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatRupiah(item.product.price * item.quantity),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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
                  onSelect: (voucher) => setState(() {
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
                    Text('Total Bayar', style: theme.textTheme.labelMedium),
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
              FilledButton.icon(
                onPressed: _placeOrder,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(160, 52),
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
    final total = (subtotal + deliveryFee + serviceFee - voucherDiscount)
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
      selectedVoucher?.code,
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
  final OrderItem? Function(OrderItem order) onCompletePayment;
  final ValueChanged<OrderItem> onCancelOrder;

  @override
  State<TransactionCompletionScreen> createState() =>
      _TransactionCompletionScreenState();
}

class _TransactionCompletionScreenState
    extends State<TransactionCompletionScreen> {
  late OrderItem currentOrder = widget.initialOrder;

  bool get _isPending => currentOrder.status == 'Payment Pending';
  bool get _isTransferBank =>
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
              ],
            ),
          ),
        ],
      ),
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
        ),
      ),
    );
  }

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
                  onPressed: () {
                    widget.onCancelOrder(currentOrder);
                    Navigator.of(context).popUntil((route) => route.isFirst);
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
                onPressed: _isPending ? _completeTransaction : _backToHome,
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
                  _isPending
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

  void _completeTransaction() {
    final updatedOrder = widget.onCompletePayment(currentOrder);
    if (updatedOrder == null || !mounted) return;
    setState(() => currentOrder = updatedOrder);
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
    if (_isTransferBank) return 'Transfer Bank BNI Virtual Account';
    if (_isPayAtCoop) return 'Bayar di Koperasi';
    return 'Saldo MepuPoin';
  }

  String _estimatedFulfillmentText() {
    if (_isPending && _isTransferBank) return 'Bayar dalam 1 x 24 jam';
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
    final match = RegExp(r'(\d{8,})').firstMatch(order.progressLabel);
    return match?.group(1) ?? '880800000000';
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
    required this.onSelect,
  });

  final CheckoutVoucher? selectedVoucher;
  final int subtotal;
  final int deliveryFee;
  final int serviceFee;
  final ValueChanged<CheckoutVoucher> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final voucher in _checkoutVouchers)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Builder(
              builder: (context) {
                final eligible = subtotal >= voucher.minimumSpend;
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
                                eligible
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

class _CheckoutSection extends StatelessWidget {
  const _CheckoutSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
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
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: !enabled
                  ? const Color(0xFFCBD5E1)
                  : selected
                  ? theme.colorScheme.primary
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: (theme.textTheme.titleMedium ?? const TextStyle())
                        .copyWith(
                          color: enabled ? null : const Color(0xFF94A3B8),
                        ),
                    child: title,
                  ),
                  const SizedBox(height: 3),
                  DefaultTextStyle(
                    style:
                        theme.textTheme.bodyMedium?.copyWith(
                          color: enabled
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
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
            color: isDiscount ? const Color(0xFF15803D) : null,
            fontWeight: isDiscount ? FontWeight.w800 : null,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
              isPickupOrder ? 'Perbarui Status Pickup' : 'Segarkan Tracking',
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
    required this.onCartChanged,
    required this.onCheckout,
  });

  final List<Product> items;
  final ValueChanged<List<Product>> onCartChanged;
  final ValueChanged<List<Product>> onCheckout;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final List<_CartEntry> cartEntries = _groupCartItems(widget.items);
  late final Set<String> selectedProductIds = {
    for (final entry in cartEntries) entry.product.id,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allSelected =
        cartEntries.isNotEmpty &&
        selectedProductIds.length == cartEntries.length;
    final totalPrice = cartEntries.fold<int>(0, (total, entry) {
      if (!selectedProductIds.contains(entry.product.id)) {
        return total;
      }
      return total + (entry.product.price * entry.quantity);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [
          TextButton(
            onPressed: cartEntries.isEmpty
                ? null
                : () {
                    setState(() {
                      cartEntries.clear();
                      selectedProductIds.clear();
                    });
                    _notifyCartChanged();
                    _showFeatureSnack(context, 'Keranjang dikosongkan.');
                  },
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
                      Icons.shopping_cart_outlined,
                      size: 84,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Keranjang masih kosong',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tambahkan produk favorit dari Home atau Shop.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
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
                        selectedProductIds
                          ..clear()
                          ..addAll(
                            cartEntries.map((entry) => entry.product.id),
                          );
                      } else {
                        selectedProductIds.clear();
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
                          key: ValueKey(product.id),
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
                          onDismissed: (_) {
                            _removeEntryAt(index);
                          },
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
                                  value: selectedProductIds.contains(
                                    product.id,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value ?? false) {
                                        selectedProductIds.add(product.id);
                                      } else {
                                        selectedProductIds.remove(product.id);
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
                                            onTap: entry.quantity > 1
                                                ? () => _changeQuantity(
                                                    index,
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
                                            onTap: () => _changeQuantity(
                                              index,
                                              entry.quantity + 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _removeEntryAt(index);
                                    _showFeatureSnack(
                                      context,
                                      '${product.name} dihapus dari keranjang.',
                                    );
                                  },
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
                onPressed: totalPrice == 0
                    ? null
                    : () => widget.onCheckout(_selectedProducts()),
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

  List<_CartEntry> _groupCartItems(List<Product> items) {
    final entries = <String, _CartEntry>{};
    for (final product in items) {
      final existing = entries[product.id];
      entries[product.id] = existing == null
          ? _CartEntry(product: product, quantity: 1)
          : _CartEntry(product: product, quantity: existing.quantity + 1);
    }
    return entries.values.toList();
  }

  void _removeEntryAt(int index) {
    if (index < 0 || index >= cartEntries.length) return;
    setState(() {
      selectedProductIds.remove(cartEntries[index].product.id);
      cartEntries.removeAt(index);
    });
    _notifyCartChanged();
  }

  void _changeQuantity(int index, int newQuantity) {
    if (index < 0 || index >= cartEntries.length || newQuantity < 1) return;
    setState(() {
      cartEntries[index] = _CartEntry(
        product: cartEntries[index].product,
        quantity: newQuantity,
      );
    });
    _notifyCartChanged();
  }

  List<Product> _selectedProducts() {
    final selected = <Product>[];
    for (final entry in cartEntries) {
      if (!selectedProductIds.contains(entry.product.id)) continue;
      selected.addAll(List<Product>.filled(entry.quantity, entry.product));
    }
    return selected;
  }

  void _notifyCartChanged() {
    final items = <Product>[];
    for (final entry in cartEntries) {
      items.addAll(List<Product>.filled(entry.quantity, entry.product));
    }
    widget.onCartChanged(items);
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

class _CartEntry {
  const _CartEntry({required this.product, required this.quantity});

  final Product product;
  final int quantity;
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
    this.fallback,
  });

  final String imageUrl;
  final BoxFit fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: fit,
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
        child: Padding(
          padding: padding,
          child: NetworkImageBox(
            imageUrl: imageUrl,
            fit: fit,
            fallback: Center(
              child: Icon(product.icon, size: iconSize, color: product.tone),
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
  const SearchField({super.key, required this.hintText});

  final String hintText;

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

int discountPercent(Product product) {
  final discount = product.originalPrice - product.price;
  return ((discount / product.originalPrice) * 100).round();
}

IconData _featureIcon(int index) {
  const icons = [
    Icons.eco_outlined,
    Icons.groups_outlined,
    Icons.verified_outlined,
    Icons.local_shipping_outlined,
  ];
  return icons[index % icons.length];
}
