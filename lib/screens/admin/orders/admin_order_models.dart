import 'package:flutter/material.dart';

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.orderNo,
    required this.userId,
    required this.branchId,
    required this.customerName,
    required this.customerPhone,
    required this.orderType,
    required this.orderStatus,
    required this.paymentStatus,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountTotal,
    required this.grandTotal,
    required this.placedAt,
    required this.items,
    this.notes,
    this.deliveryLabel,
    this.deliveryAddress,
    this.courierName,
    this.courierPhone,
  });

  factory AdminOrder.fromRow(Map<String, dynamic> row) {
    final itemRows = row['order_items'] is List
        ? List<Map<String, dynamic>>.from(row['order_items'] as List)
        : const <Map<String, dynamic>>[];

    return AdminOrder(
      id: (row['id'] ?? '').toString(),
      orderNo: (row['order_no'] ?? '').toString(),
      userId: (row['user_id'] ?? '').toString(),
      branchId: (row['branch_id'] ?? '').toString(),
      customerName: (row['customer_name'] ?? '').toString().trim().isEmpty
          ? 'Pelanggan KDMP'
          : (row['customer_name'] ?? '').toString().trim(),
      customerPhone: (row['customer_phone'] ?? '').toString().trim(),
      orderType: (row['order_type'] ?? 'delivery').toString(),
      orderStatus: (row['order_status'] ?? 'pending').toString(),
      paymentStatus: (row['payment_status'] ?? 'unpaid').toString(),
      subtotal: (row['subtotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (row['delivery_fee'] as num?)?.toInt() ?? 0,
      discountTotal: (row['discount_total'] as num?)?.toInt() ?? 0,
      grandTotal: (row['grand_total'] as num?)?.toInt() ?? 0,
      placedAt: DateTime.tryParse((row['placed_at'] ?? '').toString()) ??
          DateTime.now(),
      notes: (row['notes'] ?? '').toString().trim().isEmpty
          ? null
          : (row['notes'] ?? '').toString().trim(),
      deliveryLabel: (row['delivery_label'] ?? '').toString().trim().isEmpty
          ? null
          : (row['delivery_label'] ?? '').toString().trim(),
      deliveryAddress:
          (row['delivery_address'] ?? '').toString().trim().isEmpty
              ? null
              : (row['delivery_address'] ?? '').toString().trim(),
      courierName: (row['courier_name'] ?? '').toString().trim().isEmpty
          ? null
          : (row['courier_name'] ?? '').toString().trim(),
      courierPhone: (row['courier_phone'] ?? '').toString().trim().isEmpty
          ? null
          : (row['courier_phone'] ?? '').toString().trim(),
      items: itemRows.map(AdminOrderItem.fromRow).toList(),
    );
  }

  final String id;
  final String orderNo;
  final String userId;
  final String branchId;
  final String customerName;
  final String customerPhone;
  final String orderType;
  final String orderStatus;
  final String paymentStatus;
  final int subtotal;
  final int deliveryFee;
  final int discountTotal;
  final int grandTotal;
  final DateTime placedAt;
  final List<AdminOrderItem> items;
  final String? notes;
  final String? deliveryLabel;
  final String? deliveryAddress;
  final String? courierName;
  final String? courierPhone;

  bool get isPickup => orderType == 'pickup';
  bool get isDelivery => orderType == 'delivery';
  bool get isCompleted => orderStatus == 'completed';
  bool get isCancelled => orderStatus == 'cancelled';
  bool get requiresCourierAssignment =>
      isDelivery &&
      (courierName == null || courierName!.isEmpty) &&
      orderStatus != 'pending' &&
      orderStatus != 'cancelled' &&
      orderStatus != 'completed';

  int get totalItemQuantity =>
      items.fold<int>(0, (sum, item) => sum + item.qty);

  String get statusLabel {
    switch (orderStatus) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Terkonfirmasi';
      case 'processing':
        return 'Diproses';
      case 'ready_pickup':
        return 'Siap Pickup';
      case 'out_for_delivery':
        return 'Dikirim';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return orderStatus;
    }
  }

  String get typeLabel => isPickup ? 'Pickup' : 'Delivery';

  String get paymentLabel {
    switch (paymentStatus) {
      case 'paid':
        return 'Lunas';
      case 'failed':
        return 'Gagal';
      case 'refunded':
        return 'Refund';
      default:
        return 'Belum Lunas';
    }
  }

  String get destinationLabel {
    if (isPickup) return 'Ambil di koperasi';
    if ((deliveryLabel ?? '').isNotEmpty && (deliveryAddress ?? '').isNotEmpty) {
      return '$deliveryLabel - $deliveryAddress';
    }
    return deliveryAddress ?? deliveryLabel ?? '-';
  }

  AdminOrder copyWith({
    String? orderStatus,
    String? paymentStatus,
    String? courierName,
    String? courierPhone,
  }) {
    return AdminOrder(
      id: id,
      orderNo: orderNo,
      userId: userId,
      branchId: branchId,
      customerName: customerName,
      customerPhone: customerPhone,
      orderType: orderType,
      orderStatus: orderStatus ?? this.orderStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discountTotal: discountTotal,
      grandTotal: grandTotal,
      placedAt: placedAt,
      items: items,
      notes: notes,
      deliveryLabel: deliveryLabel,
      deliveryAddress: deliveryAddress,
      courierName: courierName ?? this.courierName,
      courierPhone: courierPhone ?? this.courierPhone,
    );
  }
}

class AdminOrderItem {
  const AdminOrderItem({
    required this.productName,
    required this.qty,
    required this.unitPrice,
    required this.subtotal,
  });

  factory AdminOrderItem.fromRow(Map<String, dynamic> row) {
    return AdminOrderItem(
      productName: (row['product_name'] ?? '').toString(),
      qty: (row['qty'] as num?)?.toInt() ?? 0,
      unitPrice: (row['unit_price'] as num?)?.toInt() ?? 0,
      subtotal: (row['subtotal'] as num?)?.toInt() ?? 0,
    );
  }

  final String productName;
  final int qty;
  final int unitPrice;
  final int subtotal;
}

List<String> availableStatusesFor(AdminOrder order) {
  if (order.isPickup) {
    return const [
      'pending',
      'confirmed',
      'processing',
      'ready_pickup',
      'completed',
      'cancelled',
    ];
  }

  return const [
    'pending',
    'confirmed',
    'processing',
    'out_for_delivery',
    'completed',
    'cancelled',
  ];
}

Color orderStatusColor(String status) {
  switch (status) {
    case 'pending':
      return const Color(0xFFF57C00);
    case 'confirmed':
      return const Color(0xFF6A1B9A);
    case 'processing':
      return const Color(0xFF1565C0);
    case 'ready_pickup':
      return const Color(0xFF00897B);
    case 'out_for_delivery':
      return const Color(0xFF2E7D32);
    case 'completed':
      return const Color(0xFF1B5E20);
    case 'cancelled':
      return const Color(0xFFC62828);
    default:
      return Colors.grey;
  }
}

IconData orderStatusIcon(String status) {
  switch (status) {
    case 'pending':
      return Icons.schedule_rounded;
    case 'confirmed':
      return Icons.verified_outlined;
    case 'processing':
      return Icons.inventory_2_rounded;
    case 'ready_pickup':
      return Icons.storefront_rounded;
    case 'out_for_delivery':
      return Icons.local_shipping_rounded;
    case 'completed':
      return Icons.check_circle_rounded;
    case 'cancelled':
      return Icons.cancel_rounded;
    default:
      return Icons.receipt_long_rounded;
  }
}

String formatCurrency(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'Rp ${amount < 0 ? '-' : ''}${buffer.toString()}';
}

String formatShortDate(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year;
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
