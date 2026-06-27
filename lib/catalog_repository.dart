import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';
import 'services/backend_support.dart';

class CatalogSnapshot {
  const CatalogSnapshot({
    required this.categories,
    required this.products,
    required this.promotions,
  });

  final List<CategoryItem> categories;
  final List<Product> products;
  final List<PromoBanner> promotions;
}

class CatalogRepository {
  const CatalogRepository();

  static List<CategoryItem>? _cachedCategories;
  static DateTime? _categoriesCachedAt;
  static final Map<String, _CachedPromotions> _promotionCache =
      <String, _CachedPromotions>{};

  static const Duration _cacheTtl = Duration(minutes: 1);

  Future<CatalogSnapshot> load({required String? branchId}) async {
    final client = Supabase.instance.client;
    final results = await Future.wait<dynamic>([
      _loadCategories(client),
      _loadPromotions(client, branchId: branchId),
    ]);
    final mappedCategories = results[0] as List<CategoryItem>;
    final mappedPromotions = results[1] as List<PromoBanner>;

    if (branchId == null || branchId.isEmpty) {
      return CatalogSnapshot(
        categories: mappedCategories,
        products: const [],
        promotions: mappedPromotions,
      );
    }

    final branchProductRows = await runBackendAction(
      'CatalogRepository.loadProducts',
      () => client
          .from('branch_products')
          .select(
            'id, branch_id, selling_price, original_price, stock_on_hand, is_featured, '
            'products(id, name, claimed_percent, reward_points, badge, description, '
            'icon_name, tone_hex, image_url, category_labels, highlights, related_ids, is_active)',
          )
          .eq('branch_id', branchId)
          .eq('is_active', true)
          .order('is_featured', ascending: false)
          .order('updated_at', ascending: false),
      retryOnce: true,
    );

    final activeCategoryLabels = mappedCategories
        .map((category) => category.label)
        .toSet();

    final mappedProducts = branchProductRows
        .map<Product?>(
          (row) =>
              _productFromRow(row, activeCategoryLabels: activeCategoryLabels),
        )
        .whereType<Product>()
        .where((product) => product.name.isNotEmpty)
        .toList(growable: false);

    return CatalogSnapshot(
      categories: mappedCategories,
      products: mappedProducts,
      promotions: mappedPromotions,
    );
  }

  Future<List<CategoryItem>> _loadCategories(SupabaseClient client) async {
    final now = DateTime.now();
    if (_cachedCategories != null &&
        _categoriesCachedAt != null &&
        now.difference(_categoriesCachedAt!) < _cacheTtl) {
      return _cachedCategories!;
    }

    final categoryRows = await runBackendAction(
      'CatalogRepository.loadCategories',
      () => client
          .from('categories')
          .select('id, label, icon_name, sort_order, is_active')
          .eq('is_active', true)
          .order('sort_order'),
      retryOnce: true,
    );

    final mappedCategories = categoryRows
        .map<CategoryItem>(
          (row) => CategoryItem(
            label: _categoryLabelFromRow(row),
            icon: _categoryIconFromName((row['icon_name'] ?? '').toString()),
          ),
        )
        .where((item) => item.label.isNotEmpty)
        .toList(growable: false);

    _cachedCategories = mappedCategories;
    _categoriesCachedAt = now;
    return mappedCategories;
  }

  Future<List<PromoBanner>> _loadPromotions(
    SupabaseClient client, {
    required String? branchId,
  }) async {
    final cacheKey = branchId?.trim().isEmpty ?? true
        ? '__all__'
        : branchId!.trim();
    final now = DateTime.now();
    final cached = _promotionCache[cacheKey];
    if (cached != null && now.difference(cached.cachedAt) < _cacheTtl) {
      return cached.promotions;
    }

    final promotionRows = await runBackendAction(
      'CatalogRepository.loadPromotions',
      () => client
          .from('promotions')
          .select(
            'id, branch_id, title, description, promo_type, promo_scope, '
            'discount_value, start_at, end_at, is_active',
          )
          .eq('is_active', true)
          .order('created_at', ascending: false),
      retryOnce: true,
    );

    final mappedPromotions = promotionRows
        .map<PromoBanner?>(
          (row) => _promotionFromRow(
            Map<String, dynamic>.from(row),
            branchId: branchId,
          ),
        )
        .whereType<PromoBanner>()
        .toList(growable: false);

    _promotionCache[cacheKey] = _CachedPromotions(
      promotions: mappedPromotions,
      cachedAt: now,
    );
    return mappedPromotions;
  }

  String _categoryLabelFromRow(Map<String, dynamic> row) {
    final legacyLabel = (row['label'] ?? '').toString().trim();
    final newName = (row['name'] ?? '').toString().trim();
    return legacyLabel.isNotEmpty ? legacyLabel : newName;
  }

  Product? _productFromRow(
    Map<String, dynamic> row, {
    required Set<String> activeCategoryLabels,
  }) {
    final productRow = row['products'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(row['products'] as Map)
        : const <String, dynamic>{};

    if (productRow.isEmpty) return null;
    if (productRow['is_active'] == false) return null;

    final categoryLabels = productRow['category_labels'] is List
        ? (productRow['category_labels'] as List)
              .map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .toList()
        : const <String>[];
    final normalizedCategories = categoryLabels
        .where(activeCategoryLabels.contains)
        .toList();

    if (activeCategoryLabels.isNotEmpty && normalizedCategories.isEmpty) {
      return null;
    }

    final highlights = productRow['highlights'] is List
        ? (productRow['highlights'] as List)
              .map((item) => item.toString())
              .toList()
        : const <String>[];
    final relatedIds = productRow['related_ids'] is List
        ? (productRow['related_ids'] as List)
              .map((item) => item.toString())
              .toList()
        : const <String>[];

    return Product(
      id: (productRow['id'] ?? '').toString(),
      name: (productRow['name'] ?? '').toString(),
      price: (row['selling_price'] as num?)?.toInt() ?? 0,
      originalPrice: (row['original_price'] as num?)?.toInt() ?? 0,
      stock: (row['stock_on_hand'] as num?)?.toInt() ?? 0,
      claimedPercent: (productRow['claimed_percent'] as num?)?.toInt() ?? 0,
      rewardPoints: (productRow['reward_points'] as num?)?.toInt() ?? 0,
      badge: (productRow['badge'] ?? '').toString(),
      description: (productRow['description'] ?? '').toString(),
      icon: _productIconFromName((productRow['icon_name'] ?? '').toString()),
      tone: _colorFromHex((productRow['tone_hex'] ?? '#8B0011').toString()),
      categories: normalizedCategories.isEmpty
          ? const ['Lainnya']
          : normalizedCategories,
      imageUrl: (productRow['image_url'] as String?)?.trim().isEmpty ?? true
          ? null
          : (productRow['image_url'] as String),
      branchId: (row['branch_id'] ?? '').toString(),
      branchProductId: (row['id'] ?? '').toString(),
      highlights: highlights,
      relatedIds: relatedIds,
    );
  }

  PromoBanner? _promotionFromRow(
    Map<String, dynamic> row, {
    required String? branchId,
  }) {
    final title = (row['title'] ?? '').toString().trim();
    if (title.isEmpty) return null;

    final promoBranchId = (row['branch_id'] ?? '').toString().trim();
    if (promoBranchId.isNotEmpty &&
        branchId != null &&
        branchId.isNotEmpty &&
        promoBranchId != branchId) {
      return null;
    }

    final startAt = DateTime.tryParse((row['start_at'] ?? '').toString());
    final endAt = DateTime.tryParse((row['end_at'] ?? '').toString());
    final now = DateTime.now().toUtc();
    if (startAt != null && startAt.toUtc().isAfter(now)) return null;
    if (endAt != null && endAt.toUtc().isBefore(now)) return null;

    final promoType = (row['promo_type'] ?? '').toString().trim().toLowerCase();
    final discountValue = (row['discount_value'] as num?)?.toInt() ?? 0;
    final description = (row['description'] ?? '').toString().trim();

    return PromoBanner(
      title: title,
      subtitle: description.isEmpty
          ? _promotionSubtitle(
              promoType: promoType,
              discountValue: discountValue,
            )
          : description,
      icon: _promotionIconFromType(promoType),
      colors: _promotionColorsFromType(promoType),
    );
  }
}

IconData _categoryIconFromName(String name) {
  switch (name) {
    case 'local_cafe_outlined':
      return Icons.local_cafe_outlined;
    case 'local_pharmacy_outlined':
      return Icons.local_pharmacy_outlined;
    case 'spa_outlined':
      return Icons.spa_outlined;
    case 'shopping_basket_outlined':
      return Icons.shopping_basket_outlined;
    case 'handyman_outlined':
      return Icons.handyman_outlined;
    case 'sports_soccer_outlined':
      return Icons.sports_soccer_outlined;
    case 'devices_outlined':
      return Icons.devices_outlined;
    case 'checkroom_outlined':
      return Icons.checkroom_outlined;
    case 'restaurant_outlined':
    default:
      return Icons.restaurant_outlined;
  }
}

IconData _productIconFromName(String name) {
  switch (name) {
    case 'water_drop_outlined':
      return Icons.water_drop_outlined;
    case 'watch_outlined':
      return Icons.watch_outlined;
    case 'emoji_food_beverage_outlined':
      return Icons.emoji_food_beverage_outlined;
    case 'coffee_outlined':
      return Icons.coffee_outlined;
    case 'local_cafe_outlined':
      return Icons.local_cafe_outlined;
    case 'local_pharmacy_outlined':
      return Icons.local_pharmacy_outlined;
    case 'spa_outlined':
      return Icons.spa_outlined;
    case 'restaurant_outlined':
      return Icons.restaurant_outlined;
    case 'shopping_basket_outlined':
      return Icons.shopping_basket_outlined;
    case 'battery_charging_full_rounded':
      return Icons.battery_charging_full_rounded;
    case 'rice_bowl_rounded':
    default:
      return Icons.rice_bowl_rounded;
  }
}

IconData _promotionIconFromType(String promoType) {
  switch (promoType) {
    case 'free_shipping':
      return Icons.local_shipping_outlined;
    case 'point_exchange':
      return Icons.workspace_premium_outlined;
    case 'bundle':
      return Icons.shopping_basket_outlined;
    case 'discount':
    default:
      return Icons.local_offer_outlined;
  }
}

List<Color> _promotionColorsFromType(String promoType) {
  switch (promoType) {
    case 'free_shipping':
      return const [Color(0xFF00608E), Color(0xFF003A5A)];
    case 'point_exchange':
      return const [Color(0xFF7A0014), Color(0xFFD9001B)];
    case 'bundle':
      return const [Color(0xFF166534), Color(0xFF0F3D25)];
    case 'discount':
    default:
      return const [Color(0xFFE21F26), Color(0xFF9F0016)];
  }
}

String _promotionSubtitle({
  required String promoType,
  required int discountValue,
}) {
  switch (promoType) {
    case 'free_shipping':
      return 'Potongan ongkir untuk belanja kebutuhan harian.';
    case 'point_exchange':
      return 'Tukar MepuPoint untuk harga lebih hemat.';
    case 'bundle':
      return 'Promo bundling untuk produk pilihan cabang.';
    case 'discount':
    default:
      return discountValue > 0
          ? 'Diskon hingga $discountValue% untuk produk pilihan.'
          : 'Promo belanja aktif dari cabang MepuPoin.';
  }
}

Color _colorFromHex(String hex) {
  final normalized = hex.replaceAll('#', '').trim();
  final value = normalized.length == 6 ? 'FF$normalized' : normalized;
  return Color(int.tryParse(value, radix: 16) ?? 0xFF8B0011);
}

class _CachedPromotions {
  const _CachedPromotions({required this.promotions, required this.cachedAt});

  final List<PromoBanner> promotions;
  final DateTime cachedAt;
}
