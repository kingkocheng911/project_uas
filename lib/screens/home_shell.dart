import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../mock_data.dart';
import '../models.dart';

const _profileImageUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBK38PfAiyHOiE6kMysiQgsdlCCaiTZUI4b6gmDIwhe7ReUvEF9AOZtc7zqWWpVxTvrZR01xBh3zwriMDBPGCAo8CThIn0t0ntISl8DH-ep3Z-QGr7OWGhZ3xzhTCYILlx9u9FIcdh72iy8WgdEZ-5Ow0Z7K3GctB5GWYGI-vV-GtzOo52Gm493KbofV8djVAmlUkGGmTVDG9cAGxX5fu1r6zYUEtMTvVVdJdvfWy0C3YN2beA5eJaitKgtJFVoqPaqkjSAbfMpshmD';
const _cooperativeImageUrl =
    'https://images.unsplash.com/photo-1516321497487-e288fb19713f?auto=format&fit=crop&w=600&q=80';

const _initialProductStocks = <String, int>{
  'rice': 24,
  'oil': 36,
  'smartband': 12,
  'honey': 18,
  'coffee': 28,
  'powerbank': 10,
};

class UserProfile {
  const UserProfile({
    required this.name,
    required this.phone,
    required this.email,
  });

  final String name;
  final String phone;
  final String email;
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
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  int _mepuBalance = 150000;
  UserProfile _profile = const UserProfile(
    name: 'Budi Speed',
    phone: '+62 812-3456-7890',
    email: 'budi.santoso@email.com',
  );
  final Map<String, int> _productStocks = Map<String, int>.of(
    _initialProductStocks,
  );
  final List<Product> _cartItems = [];
  final List<OrderItem> _orderItems = List<OrderItem>.of(orders);
  final Map<String, List<Product>> _orderProducts = {};

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(
        cartItemCount: _cartItems.length,
        mepuBalance: _mepuBalance,
        productStocks: _productStocks,
        onOpenProduct: _openProduct,
        onChangeTab: _changeTab,
        onOpenCart: _openCart,
        onAddToCart: _addToCart,
        onTopUp: _openTopUpDialog,
      ),
      ShopScreen(
        cartItemCount: _cartItems.length,
        productStocks: _productStocks,
        onOpenProduct: _openProduct,
        onOpenCart: _openCart,
        onAddToCart: _addToCart,
      ),
      const HistoryScreen(),
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
          onRemoveItem: _removeFromCart,
          onClearCart: _clearCart,
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
          onPlaceOrder:
              (
                checkoutItems,
                paymentMethod,
                deliveryMethod,
                address,
                finalTotal,
                voucherLabel,
              ) {
                final order = _createOrder(
                  checkoutItems,
                  paymentMethod: paymentMethod,
                  deliveryMethod: deliveryMethod,
                  address: address,
                  finalTotal: finalTotal,
                  voucherLabel: voucherLabel,
                );
                setState(() {
                  _orderItems.insert(0, order);
                  _orderProducts[order.id] = List<Product>.of(checkoutItems);
                  _decreaseStock(checkoutItems);
                  if (clearCart) _cartItems.clear();
                  _currentIndex = 3;
                });
                return order;
              },
        ),
      ),
    );
  }

  OrderItem _createOrder(
    List<Product> items, {
    required String paymentMethod,
    required String deliveryMethod,
    required String address,
    required int finalTotal,
    String? voucherLabel,
  }) {
    final groupedItems = _summarizeProducts(items);
    final orderItems = [
      ...groupedItems,
      if (voucherLabel != null) 'Voucher: $voucherLabel',
    ];
    final itemTitle = groupedItems.length == 1
        ? groupedItems.first
        : '${groupedItems.first} + ${groupedItems.length - 1} produk';

    return OrderItem(
      id: _generateOrderId(),
      title: itemTitle,
      status: 'Payment Pending',
      createdAt: _formatOrderDate(DateTime.now()),
      total: finalTotal,
      progressLabel: 'Menunggu pembayaran via $paymentMethod',
      address: deliveryMethod == 'Ambil di Koperasi'
          ? 'MepuPoin Sukamaju - Pickup Counter'
          : address,
      items: orderItems,
    );
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

  void _increaseStock(List<Product> items) {
    final counts = _countProducts(items);
    for (final entry in counts.entries) {
      _productStocks[entry.key] =
          (_productStocks[entry.key] ?? 0) + entry.value;
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

  void _removeFromCart(int index) {
    if (index < 0 || index >= _cartItems.length) return;
    setState(() => _cartItems.removeAt(index));
  }

  void _clearCart() {
    setState(_cartItems.clear);
  }

  Future<void> _openTopUpDialog() async {
    final amount = await showDialog<int>(
      context: context,
      builder: (_) => const _TopUpDialog(),
    );
    if (!mounted || amount == null || amount <= 0) return;

    setState(() => _mepuBalance += amount);
    _showFeatureSnack(
      context,
      'Saldo bertambah ${formatRupiah(amount)}. Saldo sekarang ${formatRupiah(_mepuBalance)}.',
      title: 'Top Up Berhasil',
      icon: Icons.account_balance_wallet_outlined,
    );
  }

  void _payOrder(OrderItem order) {
    final index = _orderItems.indexWhere((item) => item.id == order.id);
    if (index == -1) return;
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
      return;
    }
    setState(() {
      if (usesMepuBalance) {
        _mepuBalance -= order.total;
      }
      _orderItems[index] = OrderItem(
        id: order.id,
        title: order.title,
        status: 'On Delivery',
        createdAt: order.createdAt,
        total: order.total,
        progressLabel: 'Pembayaran berhasil, pesanan sedang diproses',
        address: order.address,
        items: order.items,
      );
    });
    _showFeatureSnack(
      context,
      'Pembayaran berhasil. Pesanan masuk ke Aktif.',
      title: 'Pembayaran Berhasil',
      icon: Icons.verified_rounded,
    );
  }

  void _cancelOrder(OrderItem order) {
    final cancelledItems = _orderProducts.remove(order.id) ?? const <Product>[];
    setState(() {
      _orderItems.removeWhere((item) => item.id == order.id);
      _increaseStock(cancelledItems);
    });
    _showFeatureSnack(
      context,
      'Pesanan ${order.id} dibatalkan.',
      title: 'Pesanan Dibatalkan',
      icon: Icons.cancel_outlined,
    );
  }

  void _openOrder(OrderItem order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => OrderDetailScreen(order: order)),
    );
  }

  void _openSetting(SettingShortcut setting) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingDetailScreen(setting: setting),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    final updatedProfile = await Navigator.of(context).push<UserProfile>(
      MaterialPageRoute<UserProfile>(
        builder: (_) => EditProfileScreen(profile: _profile),
      ),
    );
    if (!mounted || updatedProfile == null) return;

    setState(() => _profile = updatedProfile);
    _showFeatureSnack(
      context,
      'Data profil berhasil diperbarui.',
      title: 'Profil Tersimpan',
      icon: Icons.verified_user_outlined,
    );
  }
}

Future<void> _showFeatureSnack(
  BuildContext context,
  String message, {
  String title = 'Informasi',
  IconData icon = Icons.info_outline_rounded,
  String actionLabel = 'Mengerti',
  VoidCallback? onAction,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _ProfessionalPopup(
      icon: icon,
      title: title,
      message: message,
      primaryLabel: actionLabel,
      onPrimary: () {
        Navigator.of(dialogContext).pop();
        onAction?.call();
      },
    ),
  );
}

class _ProfessionalPopup extends StatelessWidget {
  const _ProfessionalPopup({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.child,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
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
                      color: theme.colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(18),
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
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (child case final Widget content) ...[
                const SizedBox(height: 18),
                content,
              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onPrimary,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(primaryLabel),
              ),
            ],
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
    Navigator.of(context).pop(amount);
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
    required this.onOpenProduct,
    required this.onChangeTab,
    required this.onOpenCart,
    required this.onAddToCart,
    required this.onTopUp,
  });

  final int cartItemCount;
  final int mepuBalance;
  final Map<String, int> productStocks;
  final ValueChanged<Product> onOpenProduct;
  final ValueChanged<int> onChangeTab;
  final VoidCallback onOpenCart;
  final ValueChanged<Product> onAddToCart;
  final VoidCallback onTopUp;

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
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              onActionTap: () => onChangeTab(1),
            ),
          ),
          SliverToBoxAdapter(
            child: _MepuPoinShortcutGrid(onTap: () => onChangeTab(1)),
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
              itemCount: 4,
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
  const _HomeRedHeader({required this.cartItemCount, required this.onOpenCart});

  final int cartItemCount;
  final VoidCallback onOpenCart;

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
            onTap: () =>
                _showFeatureSnack(context, 'Notifikasi MepuPoin siap dibuka.'),
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

class _MepuPoinShortcutGrid extends StatelessWidget {
  const _MepuPoinShortcutGrid({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const shortcuts = [
      (Icons.devices_outlined, 'Elektronik'),
      (Icons.checkroom_outlined, 'Fashion'),
      (Icons.restaurant_outlined, 'Makanan'),
      (Icons.sports_soccer_outlined, 'Olahraga'),
      (Icons.home_work_outlined, 'Rumah'),
      (Icons.more_horiz_rounded, 'Lainnya'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: SizedBox(
        height: 82,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: shortcuts.length,
          separatorBuilder: (_, _) => const SizedBox(width: 14),
          itemBuilder: (context, index) {
            final shortcut = shortcuts[index];
            return SizedBox(
              width: 68,
              child: _MepuPoinShortcutItem(
                icon: shortcut.$1,
                label: shortcut.$2,
                onTap: onTap,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MepuPoinShortcutItem extends StatelessWidget {
  const _MepuPoinShortcutItem({
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
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, size: 19, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF334155),
              fontSize: 10,
              fontWeight: FontWeight.w700,
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
    required this.onOpenProduct,
    required this.onOpenCart,
    required this.onAddToCart,
  });

  final int cartItemCount;
  final Map<String, int> productStocks;
  final ValueChanged<Product> onOpenProduct;
  final VoidCallback onOpenCart;
  final ValueChanged<Product> onAddToCart;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String selectedCategory = 'Semua';
  String sortOption = 'Terpopuler';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = [
      'Semua',
      'Elektronik',
      'Fashion',
      'Makanan',
      'Olahraga',
      'Rumah',
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Icon(
                  Icons.menu_rounded,
                  color: theme.colorScheme.primary,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Text(
                  'MepuPoin',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
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
                  icon: Icons.sort_rounded,
                  onTap: () => _openSortSheet(context),
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
                        icon: index == 0
                            ? Icons.apps_rounded
                            : Icons.category_outlined,
                        selected: selectedCategory == category,
                        onTap: () =>
                            setState(() => selectedCategory = category),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.sort_rounded,
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
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                stock: widget.productStocks[product.id] ?? 0,
                variant: ProductCardVariant.catalog,
                onTap: () => widget.onOpenProduct(product),
                onAddToCart: () => widget.onAddToCart(product),
              );
            }, childCount: products.length),
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

  void _openSortSheet(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final options = [
          'Harga Terendah',
          'Harga Tertinggi',
          'Terbaru',
          'Terpopuler',
        ];
        return _ProfessionalPopup(
          icon: Icons.sort_rounded,
          title: 'Urutkan Produk',
          message: 'Pilih urutan katalog yang ingin ditampilkan.',
          primaryLabel: 'Tutup',
          onPrimary: () => Navigator.of(dialogContext).pop(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in options)
                _PopupOptionTile(
                  label: option,
                  selected: sortOption == option,
                  onTap: () {
                    setState(() => sortOption = option);
                    Navigator.of(dialogContext).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PopupOptionTile extends StatelessWidget {
  const _PopupOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? theme.colorScheme.primary
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected
                      ? theme.colorScheme.primary
                      : const Color(0xFF111827),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
    final pendingOrders = widget.orders
        .where((order) => order.status == 'Payment Pending')
        .toList();
    final activeOrders = widget.orders
        .where((order) => order.status != 'Payment Pending')
        .toList();

    return CustomScrollView(
      slivers: [
        const SliverAppBar(pinned: true, title: Text('Transaksi')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: _SegmentedTabs(
              labels: const ['Pembayaran Pending', 'Aktif'],
              selectedIndex: selectedTab,
              onChanged: (index) => setState(() => selectedTab = index),
            ),
          ),
        ),
        if (selectedTab == 0) ...[
          if (pendingOrders.isEmpty)
            const SliverToBoxAdapter(
              child: _EmptyState(
                icon: Icons.payments_outlined,
                title: 'Tidak ada pembayaran pending',
                subtitle:
                    'Checkout produk dari keranjang untuk membuat transaksi baru.',
              ),
            )
          else
            SliverList.builder(
              itemCount: pendingOrders.length,
              itemBuilder: (context, index) {
                final order = pendingOrders[index];
                return Padding(
                  padding: EdgeInsets.fromLTRB(20, index == 0 ? 0 : 8, 20, 12),
                  child: _PendingPaymentCard(
                    order: order,
                    onPay: () => widget.onPayOrder(order),
                    onCancel: () => widget.onCancelOrder(order),
                  ),
                );
              },
            ),
        ] else ...[
          if (activeOrders.isEmpty)
            const SliverToBoxAdapter(
              child: _EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada pesanan aktif',
                subtitle: 'Pesanan yang sudah dibayar akan muncul di sini.',
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
                      'Batas bayar: 23:14:59',
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
                  child: const Text('Bayar Sekarang'),
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
            'Resi: MEP-240608-8821',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Expanded(child: _ProgressStep(label: 'Dikonfirmasi', done: true)),
              Expanded(child: _ProgressStep(label: 'Diproses', done: true)),
              Expanded(child: _ProgressStep(label: 'Dikirim', done: true)),
              Expanded(child: _ProgressStep(label: 'Tiba', done: false)),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onTrack,
            icon: const Icon(Icons.location_searching_rounded),
            label: const Text('Lacak Pesanan'),
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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
    required this.mepuBalance,
    required this.onTopUp,
    required this.onEditProfile,
    required this.onOpenSetting,
  });

  final UserProfile profile;
  final int mepuBalance;
  final VoidCallback onTopUp;
  final VoidCallback onEditProfile;
  final ValueChanged<SettingShortcut> onOpenSetting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          leading: IconButton(
            onPressed: () =>
                _showFeatureSnack(context, 'Kamu sudah berada di tab Akun.'),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Akun'),
          actions: [
            IconButton(
              onPressed: () => onOpenSetting(profileSettings.last),
              icon: const Icon(Icons.settings_outlined),
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
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const ProfileAvatar(radius: 74, bordered: false),
                            Positioned(
                              right: -6,
                              bottom: 6,
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: theme.colorScheme.primary,
                                child: const Icon(
                                  Icons.photo_camera_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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
                              onTap: () => _showFeatureSnack(
                                context,
                                'Promo MepuPoin siap dibuka.',
                              ),
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
                Row(
                  children: [
                    Expanded(
                      child: MiniStatCard(
                        icon: Icons.receipt_long_outlined,
                        label: 'History',
                        onTap: () => _showFeatureSnack(
                          context,
                          'Riwayat aktivitas siap dibuka.',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MiniStatCard(
                        icon: Icons.remove_red_eye_outlined,
                        label: 'Viewed',
                        onTap: () => _showFeatureSnack(
                          context,
                          'Produk yang dilihat siap dibuka.',
                        ),
                      ),
                    ),
                  ],
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
                          onTap: () => _showFeatureSnack(
                            context,
                            'FAQ MepuPoin siap dibuka.',
                          ),
                        ),
                        const SizedBox(height: 14),
                        SupportButton(
                          label: 'Contact Us',
                          onTap: () => _showFeatureSnack(
                            context,
                            'Tim support MepuPoin siap dihubungi.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: () => _showFeatureSnack(
                    context,
                    'Sesi akun MepuPoin tetap aman.',
                  ),
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

    return Scaffold(
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
                          right: 86,
                          child: _CircleActionButton(
                            icon: Icons.share_outlined,
                            onTap: () => _showFeatureSnack(
                              context,
                              'Link produk siap dibagikan.',
                            ),
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
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      transform: Matrix4.translationValues(0, -18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                formatRupiah(product.price),
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontSize: 32,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 18),
                              Text(
                                formatRupiah(product.originalPrice),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: const Color(0xFF7F6B67),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDD61),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars_rounded,
                                  color: Color(0xFF221B00),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Get ${product.rewardPoints} Points',
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
                          const SizedBox(height: 26),
                          GridView.builder(
                            itemCount: product.highlights.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisExtent: 110,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                ),
                            itemBuilder: (context, index) => FeatureCard(
                              label: product.highlights[index],
                              icon: _featureIcon(index),
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
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE8BCB8))),
              ),
              child: Column(
                children: [
                  Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F2F3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: IconButton(
                            onPressed: quantity > 1
                                ? () => setState(() => quantity--)
                                : null,
                            icon: const Icon(Icons.remove_rounded),
                          ),
                        ),
                        Text(
                          '$quantity',
                          style: theme.textTheme.headlineMedium,
                        ),
                        Expanded(
                          child: IconButton(
                            onPressed: quantity < stock
                                ? () => setState(() => quantity++)
                                : null,
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: stock > 0
                              ? () => widget.onAddItemsToCart(
                                  List<Product>.filled(quantity, product),
                                )
                              : null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(62),
                            side: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('Tambah ke Keranjang'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: stock > 0
                              ? () => widget.onBuyNow(
                                  List<Product>.filled(quantity, product),
                                )
                              : null,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(62),
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text('Beli Sekarang'),
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
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.items,
    required this.mepuBalance,
    required this.productStocks,
    required this.onPlaceOrder,
  });

  final List<Product> items;
  final int mepuBalance;
  final Map<String, int> productStocks;
  final OrderItem Function(
    List<Product> items,
    String paymentMethod,
    String deliveryMethod,
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
  final address = 'Jl. Merdeka No. 42, Sukamaju Village';

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
    final total = (subtotal + deliveryFee + serviceFee - voucherDiscount).clamp(
      0,
      subtotal + deliveryFee + serviceFee,
    ).toInt();

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
                  subtitle: Text(address),
                  selected: deliveryMethod == 'Kirim ke Rumah',
                  onTap: () =>
                      setState(() => deliveryMethod = 'Kirim ke Rumah'),
                ),
                _CheckoutOption(
                  title: const Text('Ambil di Koperasi'),
                  subtitle: const Text('MepuPoin Sukamaju - Pickup Counter'),
                  selected: deliveryMethod == 'Ambil di Koperasi',
                  onTap: () =>
                      setState(() => deliveryMethod = 'Ambil di Koperasi'),
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
                  subtitle: const Text('Bayar saat mengambil pesanan'),
                  selected: paymentMethod == 'Bayar di Koperasi',
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
                onPressed: () => _placeOrder(context),
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

  void _placeOrder(BuildContext context) {
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
    final total = (subtotal + deliveryFee + serviceFee - voucherDiscount).clamp(
      0,
      subtotal + deliveryFee + serviceFee,
    ).toInt();
    if (paymentMethod == 'Saldo MepuPoin' && widget.mepuBalance < total) {
      _showFeatureSnack(
        context,
        'Saldo kamu kurang ${formatRupiah(total - widget.mepuBalance)}. Isi saldo dulu atau pilih metode pembayaran lain.',
        title: 'Saldo Tidak Cukup',
        icon: Icons.account_balance_wallet_outlined,
      );
      return;
    }

    final order = widget.onPlaceOrder(
      widget.items,
      paymentMethod,
      deliveryMethod,
      address,
      total,
      selectedVoucher?.code,
    );
    _showFeatureSnack(
      context,
      '${order.id} menunggu pembayaran. Lanjutkan dari tab Transaksi.',
      title: 'Pesanan Berhasil Dibuat',
      icon: Icons.check_circle_outline_rounded,
      actionLabel: 'Lihat Transaksi',
      onAction: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
}

class _CheckoutLineItem {
  const _CheckoutLineItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;
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
                                ? theme.colorScheme.primary.withValues(alpha: 0.10)
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
          const Icon(Icons.confirmation_number_outlined, color: Color(0xFF15803D)),
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
  });

  final Widget title;
  final Widget subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? theme.colorScheme.primary
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: theme.textTheme.titleMedium ?? const TextStyle(),
                    child: title,
                  ),
                  const SizedBox(height: 3),
                  DefaultTextStyle(
                    style:
                        theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
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
                      child: _StatusNode(label: 'Order Placed', active: true),
                    ),
                    Expanded(
                      child: _StatusNode(label: 'Prepared', active: true),
                    ),
                    Expanded(
                      child: _StatusNode(
                        label: 'Delivery',
                        active: order.status != 'Ready for Pickup',
                      ),
                    ),
                    Expanded(
                      child: _StatusNode(
                        label: 'Done',
                        active: order.status == 'Completed',
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
            title: 'Delivery / Pickup',
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
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => _showFeatureSnack(
              context,
              'Pelacakan pesanan ${order.id} siap dibuka.',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text('Track Order'),
          ),
        ],
      ),
    );
  }
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
                    const ProfileAvatar(radius: 56, bordered: false),
                    Positioned(
                      right: -4,
                      bottom: 2,
                      child: Material(
                        color: theme.colorScheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _showFeatureSnack(
                            context,
                            'Fitur ubah foto profil siap dikembangkan.',
                            title: 'Foto Profil',
                            icon: Icons.photo_camera_outlined,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.photo_camera_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
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
      ),
    );
  }
}

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.items,
    required this.onRemoveItem,
    required this.onClearCart,
    required this.onCheckout,
  });

  final List<Product> items;
  final ValueChanged<int> onRemoveItem;
  final VoidCallback onClearCart;
  final ValueChanged<List<Product>> onCheckout;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final List<Product> cartProducts = List<Product>.of(widget.items);
  late bool selectAll = cartProducts.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPrice = selectAll
        ? cartProducts.fold<int>(0, (total, product) => total + product.price)
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [
          TextButton(
            onPressed: cartProducts.isEmpty
                ? null
                : () {
                    widget.onClearCart();
                    setState(cartProducts.clear);
                    _showFeatureSnack(context, 'Keranjang dikosongkan.');
                  },
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
      body: cartProducts.isEmpty
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
                  value: selectAll,
                  onChanged: (value) =>
                      setState(() => selectAll = value ?? false),
                  title: const Text('Pilih Semua'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < cartProducts.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Builder(
                      builder: (context) {
                        final product = cartProducts[index];
                        return Dismissible(
                          key: ValueKey('${product.id}-$index'),
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
                            widget.onRemoveItem(index);
                            setState(() => cartProducts.removeAt(index));
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
                                  value: selectAll,
                                  onChanged: (value) => setState(
                                    () => selectAll = value ?? false,
                                  ),
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
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Text('1'),
                                          ),
                                          _QuantityMiniButton(icon: Icons.add),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    widget.onRemoveItem(index);
                                    setState(
                                      () => cartProducts.removeAt(index),
                                    );
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
                    : () => widget.onCheckout(List<Product>.of(cartProducts)),
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
}

class _QuantityMiniButton extends StatelessWidget {
  const _QuantityMiniButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16),
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
                      label: 'History',
                      icon: Icons.history_rounded,
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
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProductMedia(
                      product: product,
                      borderRadius: BorderRadius.circular(18),
                      fit: isCompact ? BoxFit.cover : BoxFit.contain,
                      padding: EdgeInsets.all(isCompact ? 8 : 14),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9001B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isCatalog
                            ? product.badge
                            : '${discountPercent(product)}% OFF',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
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
  const ProfileAvatar({super.key, required this.radius, this.bordered = true});

  final double radius;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final imageRadius = bordered ? radius - 2 : radius - 6;
    return CircleAvatar(
      radius: radius,
      backgroundColor: bordered ? const Color(0xFFD9001B) : Colors.white,
      child: CircleAvatar(
        radius: imageRadius,
        backgroundColor: const Color(0xFFE8ECEF),
        child: ClipOval(
          child: SizedBox.expand(
            child: NetworkImageBox(
              imageUrl: _profileImageUrl,
              fit: BoxFit.cover,
              fallback: ColoredBox(
                color: const Color(0xFF25313B),
                child: Center(
                  child: Text(
                    'BS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: radius * 0.36,
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
      (Icons.history_rounded, 'History'),
      (Icons.receipt_long_outlined, 'Transaksi'),
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
