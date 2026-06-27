import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models.dart';
import 'backend_support.dart';

class CartService {
  const CartService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  Future<CartSnapshot> load() async {
    final user = _requireUser();
    try {
      final rows = await runBackendAction(
        'CartService.load',
        () => client
            .from('cart_items')
            .select(_cartSelect)
            .eq('user_id', user.id)
            .order('created_at'),
        retryOnce: true,
      );
      return _snapshotFromRows(rows);
    } catch (error) {
      throw CartException(
        friendlyBackendMessage(error, fallback: 'Keranjang belum bisa dimuat.'),
      );
    }
  }

  Future<CartSnapshot> addProduct({
    required Product product,
    int quantity = 1,
  }) async {
    if (quantity < 1) {
      throw const CartException('Jumlah produk tidak valid.');
    }

    final user = _requireUser();
    final branchProductId = product.branchProductId;
    if (branchProductId == null || branchProductId.isEmpty) {
      throw const CartException('Produk belum terhubung ke cabang aktif.');
    }

    try {
      final branchProductRow = await _loadBranchProductRow(branchProductId);
      final availableStock =
          (branchProductRow['stock_on_hand'] as num?)?.toInt() ?? 0;
      final existing = await runBackendAction(
        'CartService.addProduct.lookupExisting',
        () => client
            .from('cart_items')
            .select('id, quantity')
            .eq('user_id', user.id)
            .eq('branch_product_id', branchProductId)
            .maybeSingle(),
      );
      final existingQuantity = (existing?['quantity'] as num?)?.toInt() ?? 0;
      final requestedQuantity = existingQuantity + quantity;

      if (requestedQuantity > availableStock) {
        throw CartException(
          'Stok ${product.name} tersisa $availableStock. Kurangi jumlah pembelian atau pilih produk lain.',
        );
      }

      if (existing == null) {
        await runBackendAction(
          'CartService.addProduct.insert',
          () => client.from('cart_items').insert({
            'user_id': user.id,
            'branch_product_id': branchProductId,
            'quantity': quantity,
          }),
        );
      } else {
        await runBackendAction(
          'CartService.addProduct.update',
          () => client
              .from('cart_items')
              .update({'quantity': requestedQuantity})
              .eq('id', existing['id']),
        );
      }
    } on PostgrestException catch (error) {
      AppLogger.error(
        'CartService.addProduct',
        error,
        extra: {'branchProductId': branchProductId, 'quantity': quantity},
      );
      throw CartException(_friendlyPostgrestMessage(error));
    } catch (error, stackTrace) {
      AppLogger.error(
        'CartService.addProduct',
        error,
        stackTrace: stackTrace,
        extra: {'branchProductId': branchProductId, 'quantity': quantity},
      );
      if (error is CartException) rethrow;
      throw CartException(
        friendlyBackendMessage(
          error,
          fallback: 'Produk gagal ditambahkan ke keranjang.',
        ),
      );
    }

    return load();
  }

  Future<CartSnapshot> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    if (quantity < 1) {
      throw const CartException('Jumlah produk minimal 1.');
    }

    final user = _requireUser();
    final row = await _loadCartItemRow(user.id, cartItemId);
    final product = _productFromCartRow(row);
    final branchProduct = _branchProductFromCartRow(row);
    final availableStock =
        (branchProduct['stock_on_hand'] as num?)?.toInt() ?? 0;

    if (quantity > availableStock) {
      throw CartException(
        'Stok ${product.name} tersisa $availableStock. Sesuaikan jumlah keranjang Anda.',
      );
    }

    try {
      await runBackendAction(
        'CartService.updateQuantity',
        () => client
            .from('cart_items')
            .update({'quantity': quantity})
            .eq('id', cartItemId)
            .eq('user_id', user.id),
      );
      return load();
    } catch (error) {
      if (error is CartException) rethrow;
      throw CartException(
        friendlyBackendMessage(
          error,
          fallback: 'Jumlah produk gagal diperbarui.',
        ),
      );
    }
  }

  Future<CartSnapshot> removeItem(String cartItemId) async {
    final user = _requireUser();
    try {
      await runBackendAction(
        'CartService.removeItem',
        () => client
            .from('cart_items')
            .delete()
            .eq('id', cartItemId)
            .eq('user_id', user.id),
      );
      return load();
    } catch (error) {
      throw CartException(
        friendlyBackendMessage(
          error,
          fallback: 'Item keranjang gagal dihapus.',
        ),
      );
    }
  }

  Future<CartSnapshot> clear() async {
    final user = _requireUser();
    try {
      await runBackendAction(
        'CartService.clear',
        () => client.from('cart_items').delete().eq('user_id', user.id),
      );
      return const CartSnapshot(items: []);
    } catch (error) {
      throw CartException(
        friendlyBackendMessage(error, fallback: 'Keranjang gagal dikosongkan.'),
      );
    }
  }

  Future<CartSnapshot> removeItems(List<String> cartItemIds) async {
    if (cartItemIds.isEmpty) return load();
    final user = _requireUser();
    try {
      await runBackendAction(
        'CartService.removeItems',
        () => client
            .from('cart_items')
            .delete()
            .eq('user_id', user.id)
            .inFilter('id', cartItemIds),
      );
      return load();
    } catch (error) {
      throw CartException(
        friendlyBackendMessage(
          error,
          fallback: 'Beberapa item keranjang gagal dihapus.',
        ),
      );
    }
  }

  Future<CartCheckoutValidation> validateCheckout(
    List<CartLine> selectedLines,
  ) async {
    if (selectedLines.isEmpty) {
      throw const CartException('Pilih minimal satu produk untuk checkout.');
    }

    final user = _requireUser();
    final selectedIds = selectedLines
        .map((line) => line.id)
        .toList(growable: false);
    final rows = await runBackendAction(
      'CartService.validateCheckout',
      () => client
          .from('cart_items')
          .select(_cartSelect)
          .eq('user_id', user.id)
          .inFilter('id', selectedIds)
          .order('created_at'),
      retryOnce: true,
    );

    final snapshot = _snapshotFromRows(rows);
    if (snapshot.items.length != selectedLines.length) {
      throw const CartException(
        'Sebagian item keranjang berubah. Muat ulang keranjang lalu coba lagi.',
      );
    }

    final selectedMap = {for (final line in selectedLines) line.id: line};
    final changedProducts = <String>[];
    for (final line in snapshot.items) {
      final availableStock = line.product.stock;
      if (line.quantity > availableStock) {
        throw CartException(
          'Stok ${line.product.name} tersisa $availableStock. Sesuaikan jumlah sebelum checkout.',
        );
      }

      final previous = selectedMap[line.id];
      if (previous == null) continue;
      if (previous.product.price != line.product.price ||
          previous.product.originalPrice != line.product.originalPrice) {
        changedProducts.add(line.product.name);
      }
    }

    return CartCheckoutValidation(
      items: snapshot.items,
      changedProducts: changedProducts,
    );
  }

  Future<Map<String, dynamic>> _loadBranchProductRow(
    String branchProductId,
  ) async {
    final row = await runBackendAction(
      'CartService.loadBranchProductRow',
      () => client
          .from('branch_products')
          .select(
            'id, branch_id, selling_price, original_price, stock_on_hand, '
            'products!inner(id, name, claimed_percent, reward_points, badge, '
            'description, icon_name, tone_hex, image_url, category_labels, '
            'highlights, related_ids, is_active)',
          )
          .eq('id', branchProductId)
          .eq('is_active', true)
          .maybeSingle(),
      retryOnce: true,
    );

    if (row == null) {
      throw const CartException(
        'Produk tidak tersedia lagi di cabang aktif. Muat ulang katalog lalu coba lagi.',
      );
    }
    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> _loadCartItemRow(
    String userId,
    String cartItemId,
  ) async {
    final row = await runBackendAction(
      'CartService.loadCartItemRow',
      () => client
          .from('cart_items')
          .select(_cartSelect)
          .eq('user_id', userId)
          .eq('id', cartItemId)
          .maybeSingle(),
      retryOnce: true,
    );

    if (row == null) {
      throw const CartException('Item keranjang tidak ditemukan.');
    }
    return Map<String, dynamic>.from(row);
  }

  CartSnapshot _snapshotFromRows(List<dynamic> rows) {
    final items = rows
        .map<CartLine?>((row) => _lineFromRow(Map<String, dynamic>.from(row)))
        .whereType<CartLine>()
        .toList(growable: false);
    return CartSnapshot(items: items);
  }

  CartLine? _lineFromRow(Map<String, dynamic> row) {
    final id = (row['id'] ?? '').toString();
    final quantity = (row['quantity'] as num?)?.toInt() ?? 0;
    if (id.isEmpty || quantity < 1) return null;

    final branchProduct = _branchProductFromCartRow(row);
    final product = _productFromBranchProductRow(branchProduct);
    if (product == null) return null;

    return CartLine(
      id: id,
      branchId: (branchProduct['branch_id'] ?? '').toString(),
      branchProductId: (branchProduct['id'] ?? '').toString(),
      quantity: quantity,
      product: product,
    );
  }

  Map<String, dynamic> _branchProductFromCartRow(Map<String, dynamic> row) {
    if (row['branch_products'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(row['branch_products'] as Map);
    }
    throw const CartException('Data keranjang dari server tidak valid.');
  }

  Product _productFromCartRow(Map<String, dynamic> row) {
    final branchProduct = _branchProductFromCartRow(row);
    final product = _productFromBranchProductRow(branchProduct);
    if (product == null) {
      throw const CartException('Produk di keranjang tidak lagi tersedia.');
    }
    return product;
  }

  Product? _productFromBranchProductRow(Map<String, dynamic> branchProduct) {
    final productRow = branchProduct['products'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(branchProduct['products'] as Map)
        : const <String, dynamic>{};
    if (productRow.isEmpty) return null;
    if (productRow['is_active'] == false) return null;

    final categoryLabels = productRow['category_labels'] is List
        ? (productRow['category_labels'] as List)
              .map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    final highlights = productRow['highlights'] is List
        ? (productRow['highlights'] as List)
              .map((item) => item.toString())
              .toList(growable: false)
        : const <String>[];
    final relatedIds = productRow['related_ids'] is List
        ? (productRow['related_ids'] as List)
              .map((item) => item.toString())
              .toList(growable: false)
        : const <String>[];

    return Product(
      id: (productRow['id'] ?? '').toString(),
      name: (productRow['name'] ?? '').toString(),
      price: (branchProduct['selling_price'] as num?)?.toInt() ?? 0,
      originalPrice: (branchProduct['original_price'] as num?)?.toInt() ?? 0,
      stock: (branchProduct['stock_on_hand'] as num?)?.toInt() ?? 0,
      claimedPercent: (productRow['claimed_percent'] as num?)?.toInt() ?? 0,
      rewardPoints: (productRow['reward_points'] as num?)?.toInt() ?? 0,
      badge: (productRow['badge'] ?? '').toString(),
      description: (productRow['description'] ?? '').toString(),
      icon: _productIconFromName((productRow['icon_name'] ?? '').toString()),
      tone: _colorFromHex((productRow['tone_hex'] ?? '#8B0011').toString()),
      categories: categoryLabels.isEmpty ? const ['Lainnya'] : categoryLabels,
      imageUrl: (productRow['image_url'] as String?)?.trim().isEmpty ?? true
          ? null
          : (productRow['image_url'] as String),
      highlights: highlights,
      relatedIds: relatedIds,
      branchId: (branchProduct['branch_id'] ?? '').toString(),
      branchProductId: (branchProduct['id'] ?? '').toString(),
    );
  }

  User _requireUser() {
    final user = client.auth.currentUser;
    if (user == null) {
      throw const CartException(
        'Sesi login tidak ditemukan. Silakan masuk kembali.',
      );
    }
    return user;
  }

  String _friendlyPostgrestMessage(PostgrestException error) {
    final message = error.message.trim();
    final lowerMessage = message.toLowerCase();
    final code = error.code?.trim().toUpperCase() ?? '';
    if (code == 'PGRST205' && lowerMessage.contains('cart_items')) {
      return 'Fitur keranjang belum aktif di database yang sedang dipakai aplikasi. Terapkan migration cart_items di Supabase terlebih dahulu.';
    }
    if (message.contains('satu cabang')) {
      return 'Keranjang Anda berisi produk dari cabang lain. Kosongkan keranjang untuk melanjutkan.';
    }
    return message.isEmpty ? 'Operasi keranjang gagal diproses.' : message;
  }
}

class CartSnapshot {
  const CartSnapshot({required this.items});

  final List<CartLine> items;

  int get totalItems => items.fold<int>(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  String? get branchId => items.isEmpty ? null : items.first.branchId;
}

class CartLine {
  const CartLine({
    required this.id,
    required this.branchId,
    required this.branchProductId,
    required this.quantity,
    required this.product,
  });

  final String id;
  final String branchId;
  final String branchProductId;
  final int quantity;
  final Product product;
}

class CartCheckoutValidation {
  const CartCheckoutValidation({
    required this.items,
    required this.changedProducts,
  });

  final List<CartLine> items;
  final List<String> changedProducts;

  bool get hasPriceChanges => changedProducts.isNotEmpty;
}

class CartException implements Exception {
  const CartException(this.message);

  final String message;

  @override
  String toString() => message;
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

const String _cartSelect =
    'id, quantity, '
    'branch_products!inner('
    'id, branch_id, selling_price, original_price, stock_on_hand, '
    'products!inner('
    'id, name, claimed_percent, reward_points, badge, description, '
    'icon_name, tone_hex, image_url, category_labels, highlights, related_ids, is_active'
    '))';
