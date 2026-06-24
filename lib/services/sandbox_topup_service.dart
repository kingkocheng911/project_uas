import 'package:supabase_flutter/supabase_flutter.dart';

class SandboxTopUpService {
  const SandboxTopUpService();

  Future<SandboxTopUpSummary> createTopUp({
    required int amount,
    required String method,
  }) async {
    final response = await Supabase.instance.client.functions.invoke(
      'sandbox-start-topup',
      body: {'amount': amount, 'method': method},
    );

    if (response.status != 200 || response.data == null) {
      throw Exception(
        _errorMessage(response.data, 'Gagal membuat top up sandbox.'),
      );
    }

    return SandboxTopUpSummary.fromMap(
      Map<String, dynamic>.from(response.data),
    );
  }

  Future<SandboxTopUpSummary> syncTopUp(String topupId) async {
    final response = await Supabase.instance.client.functions.invoke(
      'sandbox-sync-topup',
      body: {'topup_id': topupId},
    );

    if (response.status != 200 || response.data == null) {
      throw Exception(
        _errorMessage(response.data, 'Gagal sinkronisasi status top up.'),
      );
    }

    return SandboxTopUpSummary.fromMap(
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

class SandboxTopUpSummary {
  const SandboxTopUpSummary({
    required this.topupId,
    required this.amount,
    required this.adminFee,
    required this.totalPayment,
    required this.paymentMethod,
    required this.status,
    required this.reference,
    required this.instruction,
    required this.expiresAt,
    required this.paidAt,
    required this.providerOrderId,
    required this.providerTransactionId,
    required this.providerPaymentType,
    required this.providerPaymentCode,
    required this.providerVaNumber,
    required this.providerBank,
    required this.providerQrUrl,
    required this.providerStatus,
    required this.walletBalance,
  });

  factory SandboxTopUpSummary.fromMap(Map<String, dynamic> row) {
    return SandboxTopUpSummary(
      topupId: (row['topup_id'] ?? row['id'] ?? '').toString(),
      amount: (row['amount'] as num?)?.toInt() ?? 0,
      adminFee: (row['admin_fee'] as num?)?.toInt() ?? 0,
      totalPayment: (row['total_payment'] as num?)?.toInt() ?? 0,
      paymentMethod: (row['payment_method'] ?? '').toString(),
      status: (row['status'] ?? '').toString(),
      reference: (row['sandbox_reference'] ?? '').toString(),
      instruction: (row['payment_instruction'] ?? '').toString(),
      expiresAt: _parseDateTime(row['expires_at']),
      paidAt: _parseDateTime(row['paid_at']),
      providerOrderId: (row['provider_order_id'] ?? '').toString(),
      providerTransactionId: (row['provider_transaction_id'] ?? '').toString(),
      providerPaymentType: (row['provider_payment_type'] ?? '').toString(),
      providerPaymentCode: (row['provider_payment_code'] ?? '').toString(),
      providerVaNumber: (row['provider_va_number'] ?? '').toString(),
      providerBank: (row['provider_bank'] ?? '').toString(),
      providerQrUrl: (row['provider_qr_url'] ?? '').toString(),
      providerStatus: (row['provider_status'] ?? '').toString(),
      walletBalance: (row['wallet_balance'] as num?)?.toInt() ?? 0,
    );
  }

  final String topupId;
  final int amount;
  final int adminFee;
  final int totalPayment;
  final String paymentMethod;
  final String status;
  final String reference;
  final String instruction;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final String providerOrderId;
  final String providerTransactionId;
  final String providerPaymentType;
  final String providerPaymentCode;
  final String providerVaNumber;
  final String providerBank;
  final String providerQrUrl;
  final String providerStatus;
  final int walletBalance;

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isExpired => status == 'expired';
  bool get isFailed => status == 'failed' || status == 'cancelled';

  String get paymentMethodLabel {
    if (paymentMethod == 'qris') return 'QRIS';
    return 'Virtual Account';
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
