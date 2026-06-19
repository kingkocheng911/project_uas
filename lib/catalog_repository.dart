import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class CatalogSnapshot {
  const CatalogSnapshot({
    required this.categories,
    required this.products,
  });

  final List<CategoryItem> categories;
  final List<Product> products;
}

class CatalogRepository {
  const CatalogRepository();

  Future<CatalogSnapshot> load() async {
    try {
      final client = Supabase.instance.client;
      final categoryRows = await client
          .from('categories')
          .select('id, label, icon_name, sort_order, is_active')
          .eq('is_active', true)
          .order('sort_order');
      final productRows = await client
          .from('products')
          .select(
            'id, name, price, original_price, stock, claimed_percent, reward_points, '
            'badge, description, icon_name, tone_hex, image_url, category_labels, '
            'highlights, related_ids, sort_order, is_active, category_id',
          )
          .eq('is_active', true)
          .order('sort_order');

      final activeCategoryLabels = categoryRows
          .map<String>(_categoryLabelFromRow)
          .where((label) => label.isNotEmpty)
          .toSet();

      final mappedProducts = productRows
          .map<Product?>(
            (row) => _productFromRow(
              row,
              activeCategoryLabels: activeCategoryLabels,
            ),
          )
          .whereType<Product>()
          .where((product) => product.name.isNotEmpty)
          .toList();

      return CatalogSnapshot(
        categories: categoryRows
            .map<CategoryItem>(
              (row) => CategoryItem(
                label: _categoryLabelFromRow(row),
                icon: _categoryIconFromName(
                  (row['icon_name'] ?? '').toString(),
                ),
              ),
            )
            .where((item) => item.label.isNotEmpty)
            .toList(),
        products: mappedProducts,
      );
    } catch (_) {
      // Supabase not configured or query failed: keep local dev catalog only.
      return const CatalogSnapshot(
        categories: [],
        products: [],
      );
    }
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
    final categoryLabels = row['category_labels'] is List
        ? (row['category_labels'] as List)
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

    final highlights = row['highlights'] is List
        ? (row['highlights'] as List).map((item) => item.toString()).toList()
        : const <String>[];
    final relatedIds = row['related_ids'] is List
        ? (row['related_ids'] as List).map((item) => item.toString()).toList()
        : const <String>[];

    return Product(
      id: (row['id'] ?? '').toString(),
      name: (row['name'] ?? '').toString(),
      price: (row['price'] as num?)?.toInt() ?? 0,
      originalPrice: (row['original_price'] as num?)?.toInt() ?? 0,
      stock: (row['stock'] as num?)?.toInt() ?? 0,
      claimedPercent: (row['claimed_percent'] as num?)?.toInt() ?? 0,
      rewardPoints: (row['reward_points'] as num?)?.toInt() ?? 0,
      badge: (row['badge'] ?? '').toString(),
      description: (row['description'] ?? '').toString(),
      icon: _productIconFromName((row['icon_name'] ?? '').toString()),
      tone: _colorFromHex((row['tone_hex'] ?? '#8B0011').toString()),
      categories: normalizedCategories.isEmpty
          ? const ['Lainnya']
          : normalizedCategories,
      imageUrl: (row['image_url'] as String?)?.trim().isEmpty ?? true
          ? null
          : (row['image_url'] as String),
      highlights: highlights,
      relatedIds: relatedIds,
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

Color _colorFromHex(String hex) {
  final normalized = hex.replaceAll('#', '').trim();
  final value = normalized.length == 6 ? 'FF$normalized' : normalized;
  return Color(int.tryParse(value, radix: 16) ?? 0xFF8B0011);
}
