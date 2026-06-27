import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_support.dart';

class OrderService {
  OrderService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  Future<OrderPlacementResult> placeOrder({
    required List<Map<String, dynamic>> items,
    required String paymentMethodCode,
    required String orderType,
    String? branchId,
    String? addressId,
    String? deliveryLabel,
    String? deliveryAddress,
    String? notes,
    int serviceFee = 1500,
    int redeemPoints = 0,
  }) async {
    try {
      final rows = await runBackendAction(
        'OrderService.placeOrder',
        () => client.rpc(
          'customer_place_order',
          params: {
            'p_items': items,
            'p_payment_method_code': paymentMethodCode,
            'p_order_type': orderType,
            'p_requested_branch_id': _normalizeUuid(branchId),
            'p_address_id': _normalizeUuid(addressId),
            'p_delivery_label': _normalizeText(deliveryLabel),
            'p_delivery_address': _normalizeText(deliveryAddress),
            'p_notes': _normalizeText(notes),
            'p_service_fee': serviceFee,
            'p_redeem_points': redeemPoints,
          },
        ),
      );

      final row = _extractSingleRow(rows);
      return OrderPlacementResult.fromRow(row);
    } catch (error) {
      throw Exception(
        friendlyBackendMessage(
          error,
          fallback: 'Pesanan gagal dibuat. Coba lagi beberapa saat.',
        ),
      );
    }
  }

  Future<OrderStatusResult> payOrder(String orderNo) async {
    try {
      final rows = await runBackendAction(
        'OrderService.payOrder',
        () => client.rpc('customer_pay_order', params: {'p_order_no': orderNo}),
      );
      return OrderStatusResult.fromRow(_extractSingleRow(rows));
    } catch (error) {
      throw Exception(
        friendlyBackendMessage(
          error,
          fallback: 'Pembayaran pesanan gagal diproses.',
        ),
      );
    }
  }

  Future<OrderStatusResult> cancelOrder(String orderNo) async {
    try {
      final rows = await runBackendAction(
        'OrderService.cancelOrder',
        () => client.rpc(
          'customer_cancel_order',
          params: {'p_order_no': orderNo},
        ),
      );
      return OrderStatusResult.fromRow(_extractSingleRow(rows));
    } catch (error) {
      throw Exception(
        friendlyBackendMessage(error, fallback: 'Pesanan gagal dibatalkan.'),
      );
    }
  }

  Future<AdminOrderStatusResult> updateBranchOrderStatus({
    required String orderId,
    required String nextStatus,
    String? courierName,
    String? courierPhone,
  }) async {
    try {
      final rows = await runBackendAction(
        'OrderService.updateBranchOrderStatus',
        () => client.rpc(
          'branch_admin_update_order_status',
          params: {
            'p_order_id': orderId,
            'p_next_status': nextStatus,
            'p_courier_name': _normalizeText(courierName),
            'p_courier_phone': _normalizeText(courierPhone),
          },
        ),
      );
      return AdminOrderStatusResult.fromRow(_extractSingleRow(rows));
    } catch (error) {
      throw Exception(
        friendlyBackendMessage(
          error,
          fallback: 'Status pesanan gagal diperbarui.',
        ),
      );
    }
  }

  Map<String, dynamic> _extractSingleRow(dynamic rows) {
    if (rows is List && rows.isNotEmpty && rows.first is Map) {
      return Map<String, dynamic>.from(rows.first as Map);
    }
    throw Exception('Respons order dari server tidak valid.');
  }

  String? _normalizeText(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _normalizeUuid(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

class OrderPlacementResult {
  const OrderPlacementResult({
    required this.orderId,
    required this.orderNo,
    required this.placedAt,
    required this.orderStatus,
    required this.paymentStatus,
    required this.orderType,
    required this.grandTotal,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    required this.branchId,
    required this.branchName,
    required this.walletBalance,
    required this.rewardBalance,
    required this.rewardPointsRedeemed,
    required this.rewardDiscountTotal,
  });

  factory OrderPlacementResult.fromRow(Map<String, dynamic> row) {
    return OrderPlacementResult(
      orderId: (row['order_id'] ?? '').toString(),
      orderNo: (row['order_no'] ?? '').toString(),
      placedAt:
          DateTime.tryParse((row['placed_at'] ?? '').toString()) ??
          DateTime.now(),
      orderStatus: (row['order_status'] ?? 'pending').toString(),
      paymentStatus: (row['payment_status'] ?? 'unpaid').toString(),
      orderType: (row['order_type'] ?? 'delivery').toString(),
      grandTotal: (row['grand_total'] as num?)?.toInt() ?? 0,
      subtotal: (row['subtotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (row['delivery_fee'] as num?)?.toInt() ?? 0,
      serviceFee: (row['service_fee'] as num?)?.toInt() ?? 0,
      branchId: (row['branch_id'] ?? '').toString(),
      branchName: (row['branch_name'] ?? '').toString(),
      walletBalance: (row['wallet_balance'] as num?)?.toInt() ?? 0,
      rewardBalance: (row['reward_balance'] as num?)?.toInt() ?? 0,
      rewardPointsRedeemed:
          (row['reward_points_redeemed'] as num?)?.toInt() ?? 0,
      rewardDiscountTotal: (row['reward_discount_total'] as num?)?.toInt() ?? 0,
    );
  }

  final String orderId;
  final String orderNo;
  final DateTime placedAt;
  final String orderStatus;
  final String paymentStatus;
  final String orderType;
  final int grandTotal;
  final int subtotal;
  final int deliveryFee;
  final int serviceFee;
  final String branchId;
  final String branchName;
  final int walletBalance;
  final int rewardBalance;
  final int rewardPointsRedeemed;
  final int rewardDiscountTotal;
}

class OrderStatusResult {
  const OrderStatusResult({
    required this.orderId,
    required this.orderNo,
    required this.orderStatus,
    required this.paymentStatus,
    required this.orderType,
    this.completedAt,
  });

  factory OrderStatusResult.fromRow(Map<String, dynamic> row) {
    return OrderStatusResult(
      orderId: (row['order_id'] ?? '').toString(),
      orderNo: (row['order_no'] ?? '').toString(),
      orderStatus: (row['order_status'] ?? '').toString(),
      paymentStatus: (row['payment_status'] ?? '').toString(),
      orderType: (row['order_type'] ?? 'delivery').toString(),
      completedAt: DateTime.tryParse((row['completed_at'] ?? '').toString()),
    );
  }

  final String orderId;
  final String orderNo;
  final String orderStatus;
  final String paymentStatus;
  final String orderType;
  final DateTime? completedAt;
}

class AdminOrderStatusResult {
  const AdminOrderStatusResult({
    required this.orderId,
    required this.orderStatus,
    required this.paymentStatus,
    this.courierName,
    this.courierPhone,
    this.completedAt,
  });

  factory AdminOrderStatusResult.fromRow(Map<String, dynamic> row) {
    return AdminOrderStatusResult(
      orderId: (row['order_id'] ?? '').toString(),
      orderStatus: (row['order_status'] ?? '').toString(),
      paymentStatus: (row['payment_status'] ?? '').toString(),
      courierName: (row['courier_name'] ?? '').toString().trim().isEmpty
          ? null
          : (row['courier_name'] ?? '').toString().trim(),
      courierPhone: (row['courier_phone'] ?? '').toString().trim().isEmpty
          ? null
          : (row['courier_phone'] ?? '').toString().trim(),
      completedAt: DateTime.tryParse((row['completed_at'] ?? '').toString()),
    );
  }

  final String orderId;
  final String orderStatus;
  final String paymentStatus;
  final String? courierName;
  final String? courierPhone;
  final DateTime? completedAt;
}
