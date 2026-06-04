import 'package:flutter/material.dart';

import '../mock_data.dart';
import '../models.dart';

const _profileImageUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBK38PfAiyHOiE6kMysiQgsdlCCaiTZUI4b6gmDIwhe7ReUvEF9AOZtc7zqWWpVxTvrZR01xBh3zwriMDBPGCAo8CThIn0t0ntISl8DH-ep3Z-QGr7OWGhZ3xzhTCYILlx9u9FIcdh72iy8WgdEZ-5Ow0Z7K3GctB5GWYGI-vV-GtzOo52Gm493KbofV8djVAmlUkGGmTVDG9cAGxX5fu1r6zYUEtMTvVVdJdvfWy0C3YN2beA5eJaitKgtJFVoqPaqkjSAbfMpshmD';
const _cooperativeImageUrl =
    'https://images.unsplash.com/photo-1516321497487-e288fb19713f?auto=format&fit=crop&w=600&q=80';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      DashboardScreen(onOpenProduct: _openProduct, onChangeTab: _changeTab),
      ShopScreen(onOpenProduct: _openProduct),
      const HistoryScreen(),
      OrdersScreen(onOpenOrder: _openOrder),
      ProfileScreen(onOpenSetting: _openSetting),
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
        builder: (_) => ProductDetailScreen(product: product),
      ),
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
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenProduct,
    required this.onChangeTab,
  });

  final ValueChanged<Product> onOpenProduct;
  final ValueChanged<int> onChangeTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  'KDMP',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                _HeaderActionButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () => onChangeTab(2),
                ),
                const SizedBox(width: 10),
                const ProfileAvatar(radius: 23),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const SearchField(
              hintText: 'Search products or cooperatives',
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: BalanceCard(onChangeTab: onChangeTab),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 196,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              scrollDirection: Axis.horizontal,
              itemCount: promos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) => PromoCard(banner: promos[index]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Categories',
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 32) / 5;
                return Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: categories
                      .map(
                        (category) => SizedBox(
                          width: itemWidth,
                          child: CategoryButton(category: category),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Flash Sale',
            actionLabel: 'View All',
            onActionTap: () => onChangeTab(1),
            trailing: Container(
              margin: const EdgeInsets.only(left: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '02:26:59',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 262,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) => SizedBox(
                width: 188,
                child: ProductCard(
                  product: products[index],
                  onTap: () => onOpenProduct(products[index]),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SectionHeader(
            title: 'Nearby Cooperative',
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 14),
          ),
        ),
        SliverToBoxAdapter(
          child: const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: CooperativeCard(),
          ),
        ),
      ],
    );
  }
}

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, required this.onOpenProduct});

  final ValueChanged<Product> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  'KDMP',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                const _HeaderActionButton(icon: Icons.search_rounded),
                const SizedBox(width: 10),
                const _HeaderActionButton(
                  icon: Icons.notifications_none_rounded,
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
                const SearchField(hintText: 'Search products...'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FilterChip(
                      label: 'Category',
                      icon: Icons.category_outlined,
                      selected: true,
                      onTap: () {},
                    ),
                    _FilterChip(
                      label: 'Price',
                      icon: Icons.payments_outlined,
                      onTap: () {},
                    ),
                    _FilterChip(
                      label: 'Promo',
                      icon: Icons.campaign_outlined,
                      onTap: () {},
                    ),
                    _FilterChip(
                      label: 'More',
                      icon: Icons.tune_rounded,
                      onTap: () {},
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
                variant: ProductCardVariant.catalog,
                onTap: () => onOpenProduct(product),
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
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(pinned: true, title: Text('Activity History')),
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

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, required this.onOpenOrder});

  final ValueChanged<OrderItem> onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(pinned: true, title: Text('Orders')),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE8BCB8)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.local_shipping_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1 pesanan sedang dikirim',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Buka detail untuk lihat status pengiriman terbaru.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6D5A58),
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
        SliverList.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Padding(
              padding: EdgeInsets.fromLTRB(20, index == 0 ? 12 : 8, 20, 8),
              child: OrderCard(order: order, onTap: () => onOpenOrder(order)),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onOpenSetting});

  final ValueChanged<SettingShortcut> onOpenSetting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          leading: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('KDMP Profile'),
          actions: [
            IconButton(
              onPressed: () {},
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
                          'Budi Speed',
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
                              '+62 812-3456-7890',
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
                              'budi.santoso@email.com',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF6D5A58),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: () => onOpenSetting(profileSettings.first),
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
                        'PAYMENT METHOD LINKED',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '1.250.000 Rp',
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 36,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: const [
                          Expanded(
                            child: ProfileActionChip(
                              label: 'History',
                              icon: Icons.history,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ProfileActionChip(
                              label: 'Vouchers',
                              icon: Icons.confirmation_number_outlined,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ProfileActionChip(
                              label: 'Promo',
                              icon: Icons.star_rounded,
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
                          'Account Settings',
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
                  children: const [
                    Expanded(
                      child: MiniStatCard(
                        icon: Icons.receipt_long_outlined,
                        label: 'History',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: MiniStatCard(
                        icon: Icons.remove_red_eye_outlined,
                        label: 'Viewed',
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
                        Text('Support', style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 18),
                        const SupportOption(
                          icon: Icons.live_help_outlined,
                          title: 'FAQ',
                          subtitle: 'Find quick answers',
                        ),
                        const SizedBox(height: 14),
                        const SupportButton(label: 'Contact Us'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                OutlinedButton.icon(
                  onPressed: () {},
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
                  label: const Text('Logout from Account'),
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
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
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
                        const Positioned(
                          top: 18,
                          right: 86,
                          child: _CircleActionButton(
                            icon: Icons.share_outlined,
                          ),
                        ),
                        const Positioned(
                          top: 18,
                          right: 18,
                          child: _CircleActionButton(
                            icon: Icons.shopping_cart_outlined,
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
                          const SizedBox(height: 26),
                          const Divider(color: Color(0xFFE9C7C3)),
                          const SizedBox(height: 22),
                          Text(
                            'Description',
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
                            'Related Cooperative Products',
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
                                  variant: ProductCardVariant.compact,
                                  onTap: () {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute<void>(
                                        builder: (_) => ProductDetailScreen(
                                          product: related[index],
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
                            onPressed: () => setState(() => quantity++),
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
                          onPressed: () {},
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
                          child: const Text('Add to Cart'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(62),
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(Icons.shopping_bag_outlined),
                          label: const Text('Buy Now'),
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
            onPressed: () {},
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
                        'KDMP Points',
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
                      onTap: () {},
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
    this.variant = ProductCardVariant.flashSale,
  });

  final Product product;
  final VoidCallback onTap;
  final ProductCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCatalog = variant == ProductCardVariant.catalog;
    final isCompact = variant == ProductCardVariant.compact;

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
                      'Stock: ${100 - product.claimedPercent} remaining',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1A7F42),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
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
  const _HeaderActionButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
      (Icons.receipt_long_outlined, 'Orders'),
      (Icons.person_outline_rounded, 'Profile'),
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
  const ProfileActionChip({super.key, required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class MiniStatCard extends StatelessWidget {
  const MiniStatCard({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
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
    );
  }
}

class SupportOption extends StatelessWidget {
  const SupportOption({
    super.key,
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

    return Container(
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
    );
  }
}

class SupportButton extends StatelessWidget {
  const SupportButton({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xFFE4E5E7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(label, style: Theme.of(context).textTheme.titleLarge),
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
  const _CircleActionButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
