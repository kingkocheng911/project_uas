import 'package:supabase_flutter/supabase_flutter.dart';

import 'backend_support.dart';

class RewardService {
  const RewardService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get client => _client ?? Supabase.instance.client;

  Future<RewardSummary> getSummary() async {
    try {
      final rows = await runBackendAction(
        'RewardService.getSummary',
        () => client.rpc('customer_get_reward_summary'),
        retryOnce: true,
      );
      return RewardSummary.fromRow(_extractSingleRow(rows));
    } catch (error) {
      throw Exception(
        friendlyBackendMessage(
          error,
          fallback: 'Data Mepu Point belum bisa dimuat.',
        ),
      );
    }
  }

  Future<RewardRedeemPreview> previewRedeem({
    required int subtotal,
    required int deliveryFee,
    required int serviceFee,
    int? requestedPoints,
  }) async {
    try {
      final rows = await runBackendAction(
        'RewardService.previewRedeem',
        () => client.rpc(
          'customer_preview_reward_redeem',
          params: {
            'p_subtotal': subtotal,
            'p_delivery_fee': deliveryFee,
            'p_service_fee': serviceFee,
            'p_requested_points': requestedPoints,
          },
        ),
      );
      return RewardRedeemPreview.fromRow(_extractSingleRow(rows));
    } catch (error) {
      throw Exception(
        friendlyBackendMessage(
          error,
          fallback: 'Preview penukaran poin belum bisa dimuat.',
        ),
      );
    }
  }

  Future<List<RewardTransactionEntry>> getHistory({int limit = 50}) async {
    try {
      final rows = await runBackendAction(
        'RewardService.getHistory',
        () => client.rpc(
          'customer_list_reward_transactions',
          params: {'p_limit': limit},
        ),
        retryOnce: true,
      );
      if (rows is! List) return const [];
      return rows
          .whereType<Map>()
          .map(
            (row) =>
                RewardTransactionEntry.fromRow(Map<String, dynamic>.from(row)),
          )
          .toList(growable: false);
    } catch (error) {
      throw Exception(
        friendlyBackendMessage(
          error,
          fallback: 'Riwayat Mepu Point belum bisa dimuat.',
        ),
      );
    }
  }

  Map<String, dynamic> _extractSingleRow(dynamic rows) {
    if (rows is List && rows.isNotEmpty && rows.first is Map) {
      return Map<String, dynamic>.from(rows.first as Map);
    }
    throw Exception('Respons reward dari server tidak valid.');
  }
}

class RewardSummary {
  const RewardSummary({
    required this.currentBalance,
    required this.lifetimeEarned,
    required this.lifetimeRedeemed,
    required this.earnPoints,
    required this.earnAmountSpent,
    required this.redeemPoints,
    required this.redeemAmount,
    required this.minRedeemPoints,
    required this.ruleName,
    required this.ruleDescription,
  });

  factory RewardSummary.fromRow(Map<String, dynamic> row) {
    return RewardSummary(
      currentBalance: (row['current_balance'] as num?)?.toInt() ?? 0,
      lifetimeEarned: (row['lifetime_earned'] as num?)?.toInt() ?? 0,
      lifetimeRedeemed: (row['lifetime_redeemed'] as num?)?.toInt() ?? 0,
      earnPoints: (row['earn_points'] as num?)?.toInt() ?? 0,
      earnAmountSpent: (row['earn_amount_spent'] as num?)?.toInt() ?? 1,
      redeemPoints: (row['redeem_points'] as num?)?.toInt() ?? 1,
      redeemAmount: (row['redeem_amount'] as num?)?.toInt() ?? 0,
      minRedeemPoints: (row['min_redeem_points'] as num?)?.toInt() ?? 0,
      ruleName: (row['rule_name'] ?? '').toString(),
      ruleDescription: (row['rule_description'] ?? '').toString(),
    );
  }

  final int currentBalance;
  final int lifetimeEarned;
  final int lifetimeRedeemed;
  final int earnPoints;
  final int earnAmountSpent;
  final int redeemPoints;
  final int redeemAmount;
  final int minRedeemPoints;
  final String ruleName;
  final String ruleDescription;

  String get earnLabel =>
      '$earnPoints poin tiap belanja Rp${earnAmountSpent.toString()}';

  String get redeemLabel => '$redeemPoints poin = Rp${redeemAmount.toString()}';
}

class RewardRedeemPreview {
  const RewardRedeemPreview({
    required this.availableBalance,
    required this.requestedPoints,
    required this.appliedPoints,
    required this.discountAmount,
    required this.amountBeforeDiscount,
    required this.amountAfterDiscount,
    required this.minRedeemPoints,
    required this.redeemPoints,
    required this.redeemAmount,
  });

  factory RewardRedeemPreview.fromRow(Map<String, dynamic> row) {
    return RewardRedeemPreview(
      availableBalance: (row['available_balance'] as num?)?.toInt() ?? 0,
      requestedPoints: (row['requested_points'] as num?)?.toInt() ?? 0,
      appliedPoints: (row['applied_points'] as num?)?.toInt() ?? 0,
      discountAmount: (row['discount_amount'] as num?)?.toInt() ?? 0,
      amountBeforeDiscount:
          (row['amount_before_discount'] as num?)?.toInt() ?? 0,
      amountAfterDiscount: (row['amount_after_discount'] as num?)?.toInt() ?? 0,
      minRedeemPoints: (row['min_redeem_points'] as num?)?.toInt() ?? 0,
      redeemPoints: (row['redeem_points'] as num?)?.toInt() ?? 1,
      redeemAmount: (row['redeem_amount'] as num?)?.toInt() ?? 0,
    );
  }

  final int availableBalance;
  final int requestedPoints;
  final int appliedPoints;
  final int discountAmount;
  final int amountBeforeDiscount;
  final int amountAfterDiscount;
  final int minRedeemPoints;
  final int redeemPoints;
  final int redeemAmount;

  bool get canRedeem => appliedPoints > 0 && discountAmount > 0;
}

class RewardTransactionEntry {
  const RewardTransactionEntry({
    required this.id,
    required this.transactionType,
    required this.pointsDelta,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.rupiahValue,
    required this.description,
    required this.referenceType,
    required this.orderNo,
    required this.createdAt,
  });

  factory RewardTransactionEntry.fromRow(Map<String, dynamic> row) {
    return RewardTransactionEntry(
      id: (row['transaction_id'] ?? '').toString(),
      transactionType: (row['transaction_type'] ?? '').toString(),
      pointsDelta: (row['points_delta'] as num?)?.toInt() ?? 0,
      balanceBefore: (row['balance_before'] as num?)?.toInt() ?? 0,
      balanceAfter: (row['balance_after'] as num?)?.toInt() ?? 0,
      rupiahValue: (row['rupiah_value'] as num?)?.toInt() ?? 0,
      description: (row['description'] ?? '').toString(),
      referenceType: (row['reference_type'] ?? '').toString(),
      orderNo: (row['order_no'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((row['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  final String id;
  final String transactionType;
  final int pointsDelta;
  final int balanceBefore;
  final int balanceAfter;
  final int rupiahValue;
  final String description;
  final String referenceType;
  final String orderNo;
  final DateTime createdAt;
}
