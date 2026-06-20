import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'orders/admin_order_models.dart';

class BranchAdminRepository {
  BranchAdminRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _orderSelectWithSnapshots = '''
          id,
          order_no,
          user_id,
          branch_id,
          customer_name,
          customer_phone,
          order_type,
          order_status,
          payment_status,
          subtotal,
          delivery_fee,
          discount_total,
          grand_total,
          notes,
          placed_at,
          delivery_label,
          delivery_address,
          courier_name,
          courier_phone,
          order_items(product_name, qty, unit_price, subtotal)
        ''';
  static const String _orderSelectLegacy = '''
          id,
          order_no,
          user_id,
          branch_id,
          order_type,
          order_status,
          payment_status,
          subtotal,
          delivery_fee,
          discount_total,
          grand_total,
          notes,
          placed_at,
          order_items(product_name, qty, unit_price, subtotal)
        ''';

  Future<BranchAdminAssignment> loadAssignment() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Admin belum login ke Supabase.');
    }

    final assignment = await _client
        .from('branch_admins')
        .select('branch_id, branches(id, code, name, address, district, city)')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .order('is_primary', ascending: false)
        .limit(1)
        .maybeSingle();

    final branchId = assignment?['branch_id']?.toString();
    if (branchId == null || branchId.isEmpty) {
      throw Exception('Akun admin ini belum terhubung ke cabang aktif.');
    }

    final branch =
        assignment?['branches'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(assignment!['branches'] as Map)
            : const <String, dynamic>{};

    return BranchAdminAssignment(
      branchId: branchId,
      code: (branch['code'] ?? '').toString(),
      name: (branch['name'] ?? 'Cabang KDMP').toString(),
      address: (branch['address'] ?? '-').toString(),
      district: (branch['district'] ?? '').toString(),
      city: (branch['city'] ?? '').toString(),
    );
  }

  Future<BranchAdminDashboardData> loadDashboardData() async {
    final assignment = await loadAssignment();
    final productRows = await _client
        .from('branch_products')
        .select(
          'id, product_id, selling_price, original_price, stock_on_hand, '
          'min_stock_alert, is_active, is_featured, updated_at, '
          'products(name, description, unit, brand, badge, category_labels)',
        )
        .eq('branch_id', assignment.branchId)
        .order('updated_at', ascending: false);

    final orderRows = await loadBranchOrders(assignment.branchId, limit: 50);

    final products =
        productRows
            .map<BranchAdminProduct>(
              (row) => BranchAdminProduct.fromRow(
                Map<String, dynamic>.from(row),
                branchId: assignment.branchId,
              ),
            )
            .toList(growable: false);

    final orders =
        orderRows
            .map<AdminOrder>(
              (row) => AdminOrder.fromRow(Map<String, dynamic>.from(row)),
            )
            .toList(growable: false);

    final now = DateTime.now();
    final todayOrders =
        orders
            .where(
              (order) =>
                  order.placedAt.year == now.year &&
                  order.placedAt.month == now.month &&
                  order.placedAt.day == now.day,
            )
            .toList(growable: false);

    final completedTodayRevenue = todayOrders
        .where((order) => order.orderStatus == 'completed')
        .fold<int>(0, (sum, order) => sum + order.grandTotal);

    final pendingOrders =
        orders.where((order) => order.orderStatus == 'pending').length;
    final processingOrders =
        orders
            .where(
              (order) =>
                  order.orderStatus == 'confirmed' ||
                  order.orderStatus == 'processing',
            )
            .length;
    final deliveryOrders =
        orders
            .where(
              (order) =>
                  order.orderStatus == 'out_for_delivery' ||
                  order.orderStatus == 'ready_pickup',
            )
            .length;
    final completedOrders =
        orders.where((order) => order.orderStatus == 'completed').length;
    final lowStockProducts =
        products
            .where(
              (product) =>
                  product.isActive &&
                  product.stockOnHand <= product.effectiveMinStockAlert,
            )
            .length;

    return BranchAdminDashboardData(
      assignment: assignment,
      totalProducts: products.where((product) => product.isActive).length,
      lowStockProducts: lowStockProducts,
      totalStockUnits: products.fold<int>(
        0,
        (sum, product) => sum + product.stockOnHand,
      ),
      pendingOrders: pendingOrders,
      processingOrders: processingOrders,
      deliveryOrders: deliveryOrders,
      completedOrders: completedOrders,
      todayOrderCount: todayOrders.length,
      todayRevenue: completedTodayRevenue,
      recentOrders: orders.take(5).toList(growable: false),
    );
  }

  Future<List<BranchAdminCategory>> loadCategories() async {
    final rows = await _client
        .from('categories')
        .select('id, label, icon_name, sort_order, is_active')
        .eq('is_active', true)
        .order('sort_order');

    return rows
        .map<BranchAdminCategory>(
          (row) => BranchAdminCategory(
            id: (row['id'] ?? '').toString(),
            label: (row['label'] ?? '').toString(),
            iconName: (row['icon_name'] ?? '').toString(),
          ),
        )
        .where((category) => category.label.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<BranchAdminProduct>> loadProducts() async {
    final assignment = await loadAssignment();
    final rows = await _client
        .from('branch_products')
        .select(
          'id, product_id, selling_price, original_price, stock_on_hand, '
          'min_stock_alert, is_active, is_featured, updated_at, '
          'products(name, description, unit, brand, badge, category_labels)',
        )
        .eq('branch_id', assignment.branchId)
        .order('updated_at', ascending: false);

    return rows
        .map<BranchAdminProduct>(
          (row) => BranchAdminProduct.fromRow(
            Map<String, dynamic>.from(row),
            branchId: assignment.branchId,
          ),
        )
        .toList(growable: false);
  }

  Future<void> createProduct({
    required String name,
    required String categoryLabel,
    required int sellingPrice,
    required int originalPrice,
    required int initialStock,
    required String description,
    required String unit,
    required String brand,
    required int minStockAlert,
    required bool isFeatured,
  }) async {
    final assignment = await loadAssignment();
    await _client.rpc(
      'branch_admin_create_product',
      params: {
        'p_branch_id': assignment.branchId,
        'p_name': name,
        'p_category_label': categoryLabel,
        'p_price': sellingPrice,
        'p_original_price': originalPrice,
        'p_stock': initialStock,
        'p_description': description,
        'p_unit': unit,
        'p_brand': brand,
        'p_min_stock_alert': minStockAlert,
        'p_is_featured': isFeatured,
      },
    );
  }

  Future<void> updateProduct({
    required String branchProductId,
    required String name,
    required String categoryLabel,
    required int sellingPrice,
    required int originalPrice,
    required String description,
    required String unit,
    required String brand,
    required int minStockAlert,
    required bool isFeatured,
    required bool isActive,
  }) async {
    await _client.rpc(
      'branch_admin_update_product',
      params: {
        'p_branch_product_id': branchProductId,
        'p_name': name,
        'p_category_label': categoryLabel,
        'p_price': sellingPrice,
        'p_original_price': originalPrice,
        'p_description': description,
        'p_unit': unit,
        'p_brand': brand,
        'p_min_stock_alert': minStockAlert,
        'p_is_featured': isFeatured,
        'p_is_active': isActive,
      },
    );
  }

  Future<void> archiveProduct(String branchProductId) async {
    await _client
        .from('branch_products')
        .update({'is_active': false})
        .eq('id', branchProductId);
  }

  Future<BranchStockSnapshot> loadStockSnapshot() async {
    final assignment = await loadAssignment();
    final products = await loadProducts();
    final movementRows = await _client
        .from('stock_movements')
        .select(
          'id, branch_product_id, product_id, movement_type, qty_change, '
          'qty_before, qty_after, reference_type, notes, created_at, '
          'products(name)',
        )
        .eq('branch_id', assignment.branchId)
        .order('created_at', ascending: false)
        .limit(40);

    final movements =
        movementRows
            .map<StockMovementEntry>(
              (row) => StockMovementEntry.fromRow(Map<String, dynamic>.from(row)),
            )
            .toList(growable: false);

    return BranchStockSnapshot(
      assignment: assignment,
      products: products,
      movements: movements,
    );
  }

  Future<void> adjustStock({
    required String branchProductId,
    required int qtyChange,
    required String movementType,
    String? notes,
  }) async {
    await _client.rpc(
      'branch_admin_adjust_stock',
      params: {
        'p_branch_product_id': branchProductId,
        'p_qty_change': qtyChange,
        'p_movement_type': movementType,
        'p_notes': notes,
      },
    );
  }

  Future<List<BranchCustomerSummary>> loadCustomers() async {
    final assignment = await loadAssignment();
    final rows = await _client
        .from('orders')
        .select('customer_name, customer_phone, grand_total, placed_at, order_status')
        .eq('branch_id', assignment.branchId)
        .order('placed_at', ascending: false);

    final summaries = <String, BranchCustomerSummary>{};

    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final name = (map['customer_name'] ?? 'Pelanggan KDMP').toString().trim();
      final phone = (map['customer_phone'] ?? '').toString().trim();
      final key = '${name.toLowerCase()}|$phone';
      final total = (map['grand_total'] as num?)?.toInt() ?? 0;
      final placedAt =
          DateTime.tryParse((map['placed_at'] ?? '').toString()) ?? DateTime.now();
      final isCompleted = (map['order_status'] ?? '').toString() == 'completed';

      final current = summaries[key];
      summaries[key] = BranchCustomerSummary(
        name: name.isEmpty ? 'Pelanggan KDMP' : name,
        phone: phone,
        totalOrders: (current?.totalOrders ?? 0) + 1,
        completedOrders: (current?.completedOrders ?? 0) + (isCompleted ? 1 : 0),
        totalSpent: (current?.totalSpent ?? 0) + (isCompleted ? total : 0),
        lastOrderAt: current == null || placedAt.isAfter(current.lastOrderAt)
            ? placedAt
            : current.lastOrderAt,
      );
    }

    final result = summaries.values.toList(growable: false);
    result.sort((a, b) => b.lastOrderAt.compareTo(a.lastOrderAt));
    return result;
  }

  Future<List<Map<String, dynamic>>> loadBranchOrders(
    String branchId, {
    int? limit,
  }) async {
    Future<List<Map<String, dynamic>>> runQuery(String selectClause) async {
      var query = _client
          .from('orders')
          .select(selectClause)
          .eq('branch_id', branchId)
          .order('placed_at', ascending: false);
      if (limit != null) {
        query = query.limit(limit);
      }
      final rows = await query;
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList();
    }

    try {
      return await runQuery(_orderSelectWithSnapshots);
    } on PostgrestException catch (error) {
      final message = error.message.toLowerCase();
      final missingSnapshotColumn =
          message.contains('customer_name') ||
          message.contains('customer_phone') ||
          message.contains('delivery_label') ||
          message.contains('delivery_address') ||
          message.contains('courier_name') ||
          message.contains('courier_phone');
      if (!missingSnapshotColumn) rethrow;
      return runQuery(_orderSelectLegacy);
    }
  }
}

class BranchAdminAssignment {
  const BranchAdminAssignment({
    required this.branchId,
    required this.code,
    required this.name,
    required this.address,
    required this.district,
    required this.city,
  });

  final String branchId;
  final String code;
  final String name;
  final String address;
  final String district;
  final String city;

  String get shortLocation {
    final parts = [district, city].where((part) => part.trim().isNotEmpty).toList();
    return parts.isEmpty ? address : parts.join(', ');
  }

  String get initials {
    final words =
        name
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty && word.toLowerCase() != 'kdmp')
            .take(2)
            .toList();
    if (words.isEmpty) return 'AD';
    return words.map((word) => word[0].toUpperCase()).join();
  }
}

class BranchAdminDashboardData {
  const BranchAdminDashboardData({
    required this.assignment,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.totalStockUnits,
    required this.pendingOrders,
    required this.processingOrders,
    required this.deliveryOrders,
    required this.completedOrders,
    required this.todayOrderCount,
    required this.todayRevenue,
    required this.recentOrders,
  });

  final BranchAdminAssignment assignment;
  final int totalProducts;
  final int lowStockProducts;
  final int totalStockUnits;
  final int pendingOrders;
  final int processingOrders;
  final int deliveryOrders;
  final int completedOrders;
  final int todayOrderCount;
  final int todayRevenue;
  final List<AdminOrder> recentOrders;
}

class BranchAdminCategory {
  const BranchAdminCategory({
    required this.id,
    required this.label,
    required this.iconName,
  });

  final String id;
  final String label;
  final String iconName;
}

class BranchAdminProduct {
  const BranchAdminProduct({
    required this.branchProductId,
    required this.branchId,
    required this.productId,
    required this.name,
    required this.categoryLabel,
    required this.description,
    required this.sellingPrice,
    required this.originalPrice,
    required this.stockOnHand,
    required this.minStockAlert,
    required this.isActive,
    required this.isFeatured,
    required this.unit,
    required this.brand,
    required this.badge,
    required this.updatedAt,
  });

  factory BranchAdminProduct.fromRow(
    Map<String, dynamic> row, {
    required String branchId,
  }) {
    final product =
        row['products'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(row['products'] as Map)
            : const <String, dynamic>{};
    final labels =
        product['category_labels'] is List
            ? (product['category_labels'] as List)
                .map((item) => item.toString())
                .where((item) => item.isNotEmpty)
                .toList()
            : const <String>[];

    return BranchAdminProduct(
      branchProductId: (row['id'] ?? '').toString(),
      branchId: branchId,
      productId: (row['product_id'] ?? '').toString(),
      name: (product['name'] ?? '').toString(),
      categoryLabel: labels.isEmpty ? 'Tanpa Kategori' : labels.first,
      description: (product['description'] ?? '').toString(),
      sellingPrice: (row['selling_price'] as num?)?.toInt() ?? 0,
      originalPrice: (row['original_price'] as num?)?.toInt() ?? 0,
      stockOnHand: (row['stock_on_hand'] as num?)?.toInt() ?? 0,
      minStockAlert: (row['min_stock_alert'] as num?)?.toInt() ?? 0,
      isActive: row['is_active'] != false,
      isFeatured: row['is_featured'] == true,
      unit: (product['unit'] ?? 'pcs').toString(),
      brand: (product['brand'] ?? '').toString(),
      badge: (product['badge'] ?? '').toString(),
      updatedAt:
          DateTime.tryParse((row['updated_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  final String branchProductId;
  final String branchId;
  final String productId;
  final String name;
  final String categoryLabel;
  final String description;
  final int sellingPrice;
  final int originalPrice;
  final int stockOnHand;
  final int minStockAlert;
  final bool isActive;
  final bool isFeatured;
  final String unit;
  final String brand;
  final String badge;
  final DateTime updatedAt;

  bool get isLowStock => stockOnHand <= effectiveMinStockAlert;
  int get effectiveMinStockAlert => minStockAlert <= 0 ? 5 : minStockAlert;
}

class BranchStockSnapshot {
  const BranchStockSnapshot({
    required this.assignment,
    required this.products,
    required this.movements,
  });

  final BranchAdminAssignment assignment;
  final List<BranchAdminProduct> products;
  final List<StockMovementEntry> movements;
}

class StockMovementEntry {
  const StockMovementEntry({
    required this.id,
    required this.branchProductId,
    required this.productId,
    required this.productName,
    required this.movementType,
    required this.qtyChange,
    required this.qtyBefore,
    required this.qtyAfter,
    required this.referenceType,
    required this.createdAt,
    this.notes,
  });

  factory StockMovementEntry.fromRow(Map<String, dynamic> row) {
    final product =
        row['products'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(row['products'] as Map)
            : const <String, dynamic>{};
    return StockMovementEntry(
      id: (row['id'] ?? '').toString(),
      branchProductId: (row['branch_product_id'] ?? '').toString(),
      productId: (row['product_id'] ?? '').toString(),
      productName: (product['name'] ?? 'Produk').toString(),
      movementType: (row['movement_type'] ?? '').toString(),
      qtyChange: (row['qty_change'] as num?)?.toInt() ?? 0,
      qtyBefore: (row['qty_before'] as num?)?.toInt() ?? 0,
      qtyAfter: (row['qty_after'] as num?)?.toInt() ?? 0,
      referenceType: (row['reference_type'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((row['created_at'] ?? '').toString()) ?? DateTime.now(),
      notes: (row['notes'] ?? '').toString().trim().isEmpty
          ? null
          : (row['notes'] ?? '').toString().trim(),
    );
  }

  final String id;
  final String branchProductId;
  final String productId;
  final String productName;
  final String movementType;
  final int qtyChange;
  final int qtyBefore;
  final int qtyAfter;
  final String referenceType;
  final DateTime createdAt;
  final String? notes;

  Color get tone {
    switch (movementType) {
      case 'purchase':
      case 'adjustment_in':
      case 'opening':
        return const Color(0xFF1A7F42);
      case 'sale':
      case 'adjustment_out':
        return const Color(0xFFD9001B);
      default:
        return const Color(0xFF1565C0);
    }
  }

  String get label {
    switch (movementType) {
      case 'opening':
        return 'Stok awal';
      case 'purchase':
        return 'Restock';
      case 'sale':
        return 'Penjualan';
      case 'adjustment_in':
        return 'Penyesuaian masuk';
      case 'adjustment_out':
        return 'Penyesuaian keluar';
      case 'return':
        return 'Retur';
      default:
        return movementType;
    }
  }
}

class BranchCustomerSummary {
  const BranchCustomerSummary({
    required this.name,
    required this.phone,
    required this.totalOrders,
    required this.completedOrders,
    required this.totalSpent,
    required this.lastOrderAt,
  });

  final String name;
  final String phone;
  final int totalOrders;
  final int completedOrders;
  final int totalSpent;
  final DateTime lastOrderAt;
}
