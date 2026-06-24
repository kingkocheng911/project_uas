import 'package:supabase_flutter/supabase_flutter.dart';

class SandboxOrderPaymentService {
  const SandboxOrderPaymentService();

  Future<SandboxOrderPaymentSummary> createPayment({
    required String orderNo,
  }) async {
    final response = await Supabase.instance.client.functions.invoke(
      'sandbox-start-order-payment',
      body: {'order_no': orderNo},
    );

    if (response.status != 200 || response.data == null) {
      throw Exception(
        _errorMessage(
          response.data,
          'Gagal membuat transaksi sandbox untuk pesanan.',
        ),
      );
    }

    return SandboxOrderPaymentSummary.fromMap(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<SandboxOrderPaymentSummary> syncPayment({
    required String orderNo,
  }) async {
    final response = await Supabase.instance.client.functions.invoke(
      'sandbox-sync-order-payment',
      body: {'order_no': orderNo},
    );

    if (response.status != 200 || response.data == null) {
      throw Exception(
        _errorMessage(
          response.data,
          'Gagal memeriksa status pembayaran pesanan.',
        ),
      );
    }

    return SandboxOrderPaymentSummary.fromMap(
      Map<String, dynamic>.from(response.data),
    );
  }

  String _errorMessage(dynamic data, String fallback) {
    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }
    return fallback;
  }
}

class SandboxOrderPaymentSummary {
  const SandboxOrderPaymentSummary({
    required this.orderId,
    required this.orderNo,
    required this.orderStatus,
    required this.paymentStatus,
    required this.totalPayment,
    required this.paymentMethodCode,
    required this.paymentMethodName,
    required this.providerOrderId,
    required this.providerTransactionId,
    required this.providerPaymentType,
    required this.providerPaymentCode,
    required this.providerVaNumber,
    required this.providerBank,
    required this.providerQrUrl,
    required this.providerStatus,
    required this.paymentExpiresAt,
    required this.paymentPaidAt,
  });

  factory SandboxOrderPaymentSummary.fromMap(Map<String, dynamic> row) {
    return SandboxOrderPaymentSummary(
      orderId: (row['order_id'] ?? '').toString(),
      orderNo: (row['order_no'] ?? '').toString(),
      orderStatus: (row['order_status'] ?? '').toString(),
      paymentStatus: (row['payment_status'] ?? '').toString(),
      totalPayment: (row['total_payment'] as num?)?.toInt() ?? 0,
      paymentMethodCode: (row['payment_method_code'] ?? '').toString(),
      paymentMethodName: (row['payment_method_name'] ?? '').toString(),
      providerOrderId: (row['provider_order_id'] ?? '').toString(),
      providerTransactionId: (row['provider_transaction_id'] ?? '').toString(),
      providerPaymentType: (row['provider_payment_type'] ?? '').toString(),
      providerPaymentCode: (row['provider_payment_code'] ?? '').toString(),
      providerVaNumber: (row['provider_va_number'] ?? '').toString(),
      providerBank: (row['provider_bank'] ?? '').toString(),
      providerQrUrl: (row['provider_qr_url'] ?? '').toString(),
      providerStatus: (row['provider_status'] ?? '').toString(),
      paymentExpiresAt: _parseDateTime(row['payment_expires_at']),
      paymentPaidAt: _parseDateTime(row['payment_paid_at']),
    );
  }

  final String orderId;
  final String orderNo;
  final String orderStatus;
  final String paymentStatus;
  final int totalPayment;
  final String paymentMethodCode;
  final String paymentMethodName;
  final String providerOrderId;
  final String providerTransactionId;
  final String providerPaymentType;
  final String providerPaymentCode;
  final String providerVaNumber;
  final String providerBank;
  final String providerQrUrl;
  final String providerStatus;
  final DateTime? paymentExpiresAt;
  final DateTime? paymentPaidAt;

  bool get isPaid => paymentStatus == 'paid';
  bool get isPending =>
      paymentStatus == 'unpaid' && providerStatus == 'pending';
  bool get isFailed => paymentStatus == 'failed' || orderStatus == 'cancelled';

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
