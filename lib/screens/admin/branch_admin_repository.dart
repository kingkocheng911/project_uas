import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/backend_support.dart';
import 'orders/admin_order_models.dart';

class BranchAdminRepository {
  BranchAdminRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  BranchAdminAssignment? _assignmentCache;
  String? _assignmentCacheUserId;
  DateTime? _assignmentCachedAt;
  static const Duration _assignmentCacheTtl = Duration(minutes: 1);
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

    if (_assignmentCache != null &&
        _assignmentCacheUserId == user.id &&
        _assignmentCachedAt != null &&
        DateTime.now().difference(_assignmentCachedAt!) < _assignmentCacheTtl) {
      return _assignmentCache!;
    }

    final assignment = await runBackendAction(
      'BranchAdminRepository.loadAssignment.assignment',
      () => _client
          .from('branch_admins')
          .select('branch_id')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .order('is_primary', ascending: false)
          .limit(1)
          .maybeSingle(),
      retryOnce: true,
    );

    final branchId = assignment?['branch_id']?.toString();
    if (branchId == null || branchId.isEmpty) {
      throw Exception('Akun admin ini belum terhubung ke cabang aktif.');
    }

    final branchRow = await runBackendAction(
      'BranchAdminRepository.loadAssignment.branch',
      () => _client
          .from('branches')
          .select('id, code, name, address, district, city')
          .eq('id', branchId)
          .maybeSingle(),
      retryOnce: true,
    );

    final branch = branchRow is Map<String, dynamic>
        ? Map<String, dynamic>.from(branchRow)
        : const <String, dynamic>{};

    final result = BranchAdminAssignment(
      branchId: branchId,
      code: (branch['code'] ?? '').toString(),
      name: (branch['name'] ?? 'Cabang MepuPoin').toString(),
      address: (branch['address'] ?? '-').toString(),
      district: (branch['district'] ?? '').toString(),
      city: (branch['city'] ?? '').toString(),
    );
    _assignmentCache = result;
    _assignmentCacheUserId = user.id;
    _assignmentCachedAt = DateTime.now();
    return result;
  }

  Future<BranchAdminDashboardData> loadDashboardData() async {
    final assignment = await loadAssignment();
    final summaryRows = await runBackendAction(
      'BranchAdminRepository.loadDashboardData.summary',
      () => _client.rpc('branch_admin_dashboard_summary'),
      retryOnce: true,
    );
    final summary =
        summaryRows is List &&
            summaryRows.isNotEmpty &&
            summaryRows.first is Map
        ? Map<String, dynamic>.from(summaryRows.first as Map)
        : const <String, dynamic>{};

    final orderRows = await loadBranchOrders(assignment.branchId, limit: 50);

    final orders = orderRows
        .map<AdminOrder>(
          (row) => AdminOrder.fromRow(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);

    return BranchAdminDashboardData(
      assignment: assignment,
      totalProducts: (summary['total_products'] as num?)?.toInt() ?? 0,
      lowStockProducts: (summary['low_stock_products'] as num?)?.toInt() ?? 0,
      outOfStockProducts:
          (summary['out_of_stock_products'] as num?)?.toInt() ?? 0,
      totalStockUnits: (summary['total_stock_units'] as num?)?.toInt() ?? 0,
      pendingOrders: (summary['pending_orders'] as num?)?.toInt() ?? 0,
      processingOrders: (summary['processing_orders'] as num?)?.toInt() ?? 0,
      deliveryOrders: (summary['delivery_orders'] as num?)?.toInt() ?? 0,
      completedOrders: (summary['completed_orders'] as num?)?.toInt() ?? 0,
      todayOrderCount: (summary['total_orders_today'] as num?)?.toInt() ?? 0,
      todayRevenue: (summary['today_revenue'] as num?)?.toInt() ?? 0,
      todaySales: (summary['total_sales_today'] as num?)?.toInt() ?? 0,
      recentOrders: orders.take(5).toList(growable: false),
    );
  }

  Future<List<BranchAdminCategory>> loadCategories() async {
    final rows = await runBackendAction(
      'BranchAdminRepository.loadCategories',
      () => _client
          .from('categories')
          .select('id, label, icon_name, sort_order, is_active')
          .eq('is_active', true)
          .order('sort_order'),
      retryOnce: true,
    );

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

  Future<List<BranchAdminProduct>> loadProducts({
    String? search,
    String? categoryLabel,
    String stockFilter = 'all',
  }) async {
    final assignment = await loadAssignment();
    final normalizedSearch = search?.trim() ?? '';
    final normalizedCategory = categoryLabel?.trim() ?? '';
    List<String>? productIds;

    if (normalizedSearch.isNotEmpty ||
        (normalizedCategory.isNotEmpty && normalizedCategory != 'Semua')) {
      var productQuery = _client
          .from('products')
          .select('id')
          .eq('is_active', true);

      if (normalizedSearch.isNotEmpty) {
        productQuery = productQuery.or(
          'name.ilike.%$normalizedSearch%,category_labels.cs.{"$normalizedSearch"}',
        );
      }

      if (normalizedCategory.isNotEmpty && normalizedCategory != 'Semua') {
        productQuery = productQuery.contains('category_labels', <String>[
          normalizedCategory,
        ]);
      }

      final productRows = await runBackendAction(
        'BranchAdminRepository.loadProducts.lookupIds',
        () => productQuery,
        retryOnce: true,
      );
      productIds = productRows
          .map<String>((row) => (row['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      if (productIds.isEmpty) {
        return const <BranchAdminProduct>[];
      }
    }

    final rows = await runBackendAction(
      'BranchAdminRepository.loadProducts.rows',
      () => _client
          .from('branch_products')
          .select(
            'id, product_id, selling_price, original_price, stock_on_hand, '
            'min_stock_alert, is_active, is_featured, updated_at, '
            'products(name, description, unit, brand, badge, category_labels)',
          )
          .eq('branch_id', assignment.branchId)
          .order('updated_at', ascending: false),
      retryOnce: true,
    );

    return rows
        .map<BranchAdminProduct>(
          (row) => BranchAdminProduct.fromRow(
            Map<String, dynamic>.from(row),
            branchId: assignment.branchId,
          ),
        )
        .where((product) {
          if (productIds != null && !productIds.contains(product.productId)) {
            return false;
          }
          switch (stockFilter) {
            case 'low_stock':
              return product.stockOnHand > 0 && product.isLowStock;
            case 'out_of_stock':
              return product.stockOnHand <= 0;
            case 'inactive':
              return !product.isActive;
            case 'featured':
              return product.isFeatured;
            default:
              return true;
          }
        })
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
    final movementRows = await runBackendAction(
      'BranchAdminRepository.loadStockSnapshot.movements',
      () => _client
          .from('stock_movements')
          .select(
            'id, branch_product_id, product_id, movement_type, qty_change, '
            'qty_before, qty_after, reference_type, notes, created_at, '
            'products(name)',
          )
          .eq('branch_id', assignment.branchId)
          .order('created_at', ascending: false)
          .limit(40),
      retryOnce: true,
    );

    final movements = movementRows
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

  Future<BranchReportSummary> loadReportSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    final summaryRows = await runBackendAction(
      'BranchAdminRepository.loadReportSummary.summary',
      () => _client.rpc(
        'branch_admin_report_summary',
        params: {'p_from': _dateOnly(from), 'p_to': _dateOnly(to)},
      ),
      retryOnce: true,
    );
    final topProductRows = await runBackendAction(
      'BranchAdminRepository.loadReportSummary.topProducts',
      () => _client.rpc(
        'branch_admin_report_top_products',
        params: {
          'p_from': _dateOnly(from),
          'p_to': _dateOnly(to),
          'p_limit': 5,
        },
      ),
      retryOnce: true,
    );

    final summary =
        summaryRows is List &&
            summaryRows.isNotEmpty &&
            summaryRows.first is Map
        ? Map<String, dynamic>.from(summaryRows.first as Map)
        : const <String, dynamic>{};
    final topProducts = topProductRows is List
        ? topProductRows
              .whereType<Map>()
              .map(
                (row) =>
                    BranchTopProduct.fromRow(Map<String, dynamic>.from(row)),
              )
              .toList(growable: false)
        : const <BranchTopProduct>[];

    return BranchReportSummary(
      branchName: (summary['branch_name'] ?? 'Cabang MepuPoin').toString(),
      from: from,
      to: to,
      dailySales: (summary['daily_sales'] as num?)?.toInt() ?? 0,
      dailyTransactions: (summary['daily_transactions'] as num?)?.toInt() ?? 0,
      completedTransactions:
          (summary['completed_transactions'] as num?)?.toInt() ?? 0,
      grossRevenue: (summary['gross_revenue'] as num?)?.toInt() ?? 0,
      topProducts: topProducts,
    );
  }

  Future<List<BranchPromotion>> loadPromotions() async {
    final assignment = await loadAssignment();
    final rows = await runBackendAction(
      'BranchAdminRepository.loadPromotions',
      () => _client
          .from('promotions')
          .select(
            'id, branch_id, title, description, promo_type, promo_scope, '
            'discount_value, min_purchase, max_discount, quota_total, quota_used, '
            'start_at, end_at, is_active, created_at',
          )
          .eq('branch_id', assignment.branchId)
          .order('created_at', ascending: false),
      retryOnce: true,
    );

    return rows
        .map<BranchPromotion>(
          (row) => BranchPromotion.fromRow(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  Future<void> upsertPromotion({
    String? promotionId,
    required String title,
    String? description,
    required String promoType,
    required int discountValue,
    int? minPurchase,
    int? maxDiscount,
    required DateTime startAt,
    required DateTime endAt,
    required bool isActive,
  }) async {
    try {
      await runBackendAction(
        'BranchAdminRepository.upsertPromotion',
        () => _client.rpc(
          'branch_admin_upsert_promotion',
          params: {
            'p_promotion_id': _normalizeUuid(promotionId),
            'p_title': title,
            'p_description': description?.trim(),
            'p_promo_type': promoType,
            'p_promo_scope': 'all_products',
            'p_discount_value': discountValue,
            'p_min_purchase': minPurchase,
            'p_max_discount': maxDiscount,
            'p_start_at': startAt.toUtc().toIso8601String(),
            'p_end_at': endAt.toUtc().toIso8601String(),
            'p_is_active': isActive,
          },
        ),
      );
    } catch (error) {
      throw Exception(
        friendlyBackendMessage(error, fallback: 'Promo cabang gagal disimpan.'),
      );
    }
  }

  Future<void> togglePromotion({
    required String promotionId,
    required bool isActive,
  }) async {
    try {
      await runBackendAction(
        'BranchAdminRepository.togglePromotion',
        () => _client.rpc(
          'branch_admin_toggle_promotion',
          params: {'p_promotion_id': promotionId, 'p_is_active': isActive},
        ),
      );
    } catch (error) {
      throw Exception(
        friendlyBackendMessage(
          error,
          fallback: 'Status promo cabang gagal diperbarui.',
        ),
      );
    }
  }

  Future<void> adjustStock({
    required String branchProductId,
    required int qtyChange,
    required String movementType,
    String? notes,
  }) async {
    try {
      await runBackendAction(
        'BranchAdminRepository.adjustStock',
        () => _client.rpc(
          'branch_admin_adjust_stock',
          params: {
            'p_branch_product_id': branchProductId,
            'p_qty_change': qtyChange,
            'p_movement_type': movementType,
            'p_notes': notes,
          },
        ),
      );
    } catch (error) {
      AppLogger.error(
        'BranchAdminRepository.adjustStock',
        error,
        extra: {
          'branchProductId': branchProductId,
          'qtyChange': qtyChange,
          'movementType': movementType,
        },
      );
      throw Exception(
        friendlyBackendMessage(
          error,
          fallback: 'Penyesuaian stok gagal diproses.',
        ),
      );
    }
  }

  Future<List<BranchCustomerSummary>> loadCustomers() async {
    final assignment = await loadAssignment();
    final rows = await runBackendAction(
      'BranchAdminRepository.loadCustomers',
      () => _client
          .from('orders')
          .select(
            'customer_name, customer_phone, grand_total, placed_at, order_status',
          )
          .eq('branch_id', assignment.branchId)
          .order('placed_at', ascending: false),
      retryOnce: true,
    );

    final summaries = <String, BranchCustomerSummary>{};

    for (final row in rows) {
      final map = Map<String, dynamic>.from(row);
      final name = (map['customer_name'] ?? 'Pelanggan MepuPoin')
          .toString()
          .trim();
      final phone = (map['customer_phone'] ?? '').toString().trim();
      final key = '${name.toLowerCase()}|$phone';
      final total = (map['grand_total'] as num?)?.toInt() ?? 0;
      final placedAt =
          DateTime.tryParse((map['placed_at'] ?? '').toString()) ??
          DateTime.now();
      final isCompleted = (map['order_status'] ?? '').toString() == 'completed';

      final current = summaries[key];
      summaries[key] = BranchCustomerSummary(
        name: name.isEmpty ? 'Pelanggan MepuPoin' : name,
        phone: phone,
        totalOrders: (current?.totalOrders ?? 0) + 1,
        completedOrders:
            (current?.completedOrders ?? 0) + (isCompleted ? 1 : 0),
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
      final rows = await runBackendAction(
        'BranchAdminRepository.loadBranchOrders',
        () => query,
        retryOnce: true,
      );
      return rows
          .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
          .toList();
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

  String _dateOnly(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    return normalized.toIso8601String().split('T').first;
  }

  String? _normalizeUuid(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
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
    final parts = [
      district,
      city,
    ].where((part) => part.trim().isNotEmpty).toList();
    return parts.isEmpty ? address : parts.join(', ');
  }

  String get initials {
    final words = name
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
    required this.outOfStockProducts,
    required this.totalStockUnits,
    required this.pendingOrders,
    required this.processingOrders,
    required this.deliveryOrders,
    required this.completedOrders,
    required this.todayOrderCount,
    required this.todaySales,
    required this.todayRevenue,
    required this.recentOrders,
  });

  final BranchAdminAssignment assignment;
  final int totalProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final int totalStockUnits;
  final int pendingOrders;
  final int processingOrders;
  final int deliveryOrders;
  final int completedOrders;
  final int todayOrderCount;
  final int todaySales;
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
    final product = row['products'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(row['products'] as Map)
        : const <String, dynamic>{};
    final labels = product['category_labels'] is List
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
          DateTime.tryParse((row['updated_at'] ?? '').toString()) ??
          DateTime.now(),
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
    final product = row['products'] is Map<String, dynamic>
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
          DateTime.tryParse((row['created_at'] ?? '').toString()) ??
          DateTime.now(),
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

class BranchReportSummary {
  const BranchReportSummary({
    required this.branchName,
    required this.from,
    required this.to,
    required this.dailySales,
    required this.dailyTransactions,
    required this.completedTransactions,
    required this.grossRevenue,
    required this.topProducts,
  });

  final String branchName;
  final DateTime from;
  final DateTime to;
  final int dailySales;
  final int dailyTransactions;
  final int completedTransactions;
  final int grossRevenue;
  final List<BranchTopProduct> topProducts;
}

class BranchTopProduct {
  const BranchTopProduct({
    required this.productId,
    required this.productName,
    required this.totalQty,
    required this.totalRevenue,
  });

  factory BranchTopProduct.fromRow(Map<String, dynamic> row) {
    return BranchTopProduct(
      productId: (row['product_id'] ?? '').toString(),
      productName: (row['product_name'] ?? 'Produk').toString(),
      totalQty: (row['total_qty'] as num?)?.toInt() ?? 0,
      totalRevenue: (row['total_revenue'] as num?)?.toInt() ?? 0,
    );
  }

  final String productId;
  final String productName;
  final int totalQty;
  final int totalRevenue;
}

class BranchPromotion {
  const BranchPromotion({
    required this.id,
    required this.title,
    required this.description,
    required this.promoType,
    required this.discountValue,
    required this.minPurchase,
    required this.maxDiscount,
    required this.startAt,
    required this.endAt,
    required this.isActive,
  });

  factory BranchPromotion.fromRow(Map<String, dynamic> row) {
    return BranchPromotion(
      id: (row['id'] ?? '').toString(),
      title: (row['title'] ?? '').toString(),
      description: (row['description'] ?? '').toString(),
      promoType: (row['promo_type'] ?? 'percentage').toString(),
      discountValue: (row['discount_value'] as num?)?.toInt() ?? 0,
      minPurchase: (row['min_purchase'] as num?)?.toInt(),
      maxDiscount: (row['max_discount'] as num?)?.toInt(),
      startAt:
          DateTime.tryParse((row['start_at'] ?? '').toString()) ??
          DateTime.now(),
      endAt:
          DateTime.tryParse((row['end_at'] ?? '').toString()) ?? DateTime.now(),
      isActive: row['is_active'] == true,
    );
  }

  final String id;
  final String title;
  final String description;
  final String promoType;
  final int discountValue;
  final int? minPurchase;
  final int? maxDiscount;
  final DateTime startAt;
  final DateTime endAt;
  final bool isActive;
}
