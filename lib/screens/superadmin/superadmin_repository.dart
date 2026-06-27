import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/backend_support.dart';

class SuperadminRepository {
  SuperadminRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<SuperadminDashboardSummary> loadDashboardSummary() async {
    final rows = await runBackendAction(
      'SuperadminRepository.loadDashboardSummary',
      () => _client.rpc('superadmin_global_dashboard_summary'),
      retryOnce: true,
    );
    final map = _singleRow(rows);
    return SuperadminDashboardSummary.fromRow(map);
  }

<<<<<<< HEAD
  Future<String> saveBranch(SuperadminBranchDraft draft, {String? branchId}) async {
    if (branchId == null) {
      if (draft.shouldCreateAdminCredentials) {
        final rows = await _client.rpc(
          'superadmin_create_branch_with_admin',
          params: {
            'p_code': draft.code.trim(),
            'p_name': draft.name.trim(),
            'p_phone': draft._nullable(draft.phone),
            'p_email': draft._nullable(draft.email),
            'p_address': draft.address.trim(),
            'p_province': draft._nullable(draft.province),
            'p_city': draft._nullable(draft.city),
            'p_district': draft._nullable(draft.district),
            'p_postal_code': draft._nullable(draft.postalCode),
            'p_is_active': draft.isActive,
            'p_admin_full_name': draft.resolvedAdminLoginName,
            'p_admin_email': draft.adminLoginEmail.trim(),
            'p_admin_password': draft.adminLoginPassword.trim(),
            'p_admin_phone': draft.resolvedAdminLoginPhone,
          },
        );

        if (rows is! List || rows.isEmpty) {
          throw Exception('Backend tidak mengembalikan hasil pembuatan cabang.');
        }
        final createdRow = Map<String, dynamic>.from(rows.first as Map);
        final createdBranchId = (createdRow['branch_id'] ?? '').toString();
        if (createdBranchId.isEmpty) {
          throw Exception('ID cabang baru tidak ditemukan setelah proses simpan.');
        }
        return createdBranchId;
      }

      final payload = draft.toDatabaseMap();
      final inserted = await _client.from('branches').insert(payload).select('id').single();
      final createdBranchId = (inserted['id'] ?? '').toString();
      if (createdBranchId.isEmpty) {
        throw Exception('ID cabang baru tidak ditemukan setelah proses simpan.');
      }
      return createdBranchId;
    }
    final payload = draft.toDatabaseMap();
    await _client.from('branches').update(payload).eq('id', branchId);
    if (draft.shouldCreateAdminCredentials) {
      await upsertBranchAdminCredentials(
        branchId: branchId,
        email: draft.adminLoginEmail.trim(),
        password: draft.adminLoginPassword.trim(),
        fullName: draft.resolvedAdminLoginName,
        phone: draft.resolvedAdminLoginPhone,
      );
    }
    return branchId;
=======
  Future<SuperadminKpiSummary> loadKpiSummary() async {
    final rows = await runBackendAction(
      'SuperadminRepository.loadKpiSummary',
      () => _client.rpc('superadmin_kpi_summary'),
      retryOnce: true,
    );
    final map = _singleRow(rows);
    return SuperadminKpiSummary.fromRow(map);
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
  }

  Future<List<SuperadminBranchMonitoringRecord>> loadBranchMonitoring() async {
    final rows = await runBackendAction(
      'SuperadminRepository.loadBranchMonitoring',
      () => _client.rpc('superadmin_branch_monitoring'),
      retryOnce: true,
    );
    return _rows(
      rows,
    ).map(SuperadminBranchMonitoringRecord.fromRow).toList(growable: false);
  }

  Future<List<SuperadminBranchPerformanceRecord>>
  loadBranchPerformance() async {
    final rows = await runBackendAction(
      'SuperadminRepository.loadBranchPerformance',
      () => _client.rpc('superadmin_branch_performance'),
      retryOnce: true,
    );
    return _rows(
      rows,
    ).map(SuperadminBranchPerformanceRecord.fromRow).toList(growable: false);
  }

  Future<List<SuperadminAdminMonitoringRecord>> loadAdminMonitoring() async {
    final rows = await runBackendAction(
      'SuperadminRepository.loadAdminMonitoring',
      () => _client.rpc('superadmin_admin_monitoring'),
      retryOnce: true,
    );
    return _rows(
      rows,
    ).map(SuperadminAdminMonitoringRecord.fromRow).toList(growable: false);
  }

  Future<SuperadminAnalyticsBundle> loadAnalytics() async {
    final results = await Future.wait<dynamic>([
      runBackendAction(
        'SuperadminRepository.loadAnalytics.monthlyRevenue',
        () => _client.rpc('superadmin_monthly_revenue_chart'),
        retryOnce: true,
      ),
      runBackendAction(
        'SuperadminRepository.loadAnalytics.dailyTransactions',
        () => _client.rpc('superadmin_daily_transactions_chart'),
        retryOnce: true,
      ),
      runBackendAction(
        'SuperadminRepository.loadAnalytics.categoryDistribution',
        () => _client.rpc('superadmin_category_distribution_chart'),
        retryOnce: true,
      ),
      runBackendAction(
        'SuperadminRepository.loadAnalytics.paymentDistribution',
        () => _client.rpc('superadmin_payment_distribution_chart'),
        retryOnce: true,
      ),
      runBackendAction(
        'SuperadminRepository.loadAnalytics.rewardDistribution',
        () => _client.rpc('superadmin_reward_distribution_chart'),
        retryOnce: true,
      ),
    ]);
    final monthlyRevenueRows = results[0];
    final dailyTransactionRows = results[1];
    final categoryRows = results[2];
    final paymentRows = results[3];
    final rewardRows = results[4];

    return SuperadminAnalyticsBundle(
      monthlyRevenue: _rows(
        monthlyRevenueRows,
      ).map(SuperadminChartDatum.fromAmountRow).toList(growable: false),
      dailyTransactions: _rows(
        dailyTransactionRows,
      ).map(SuperadminChartDatum.fromAmountRow).toList(growable: false),
      categoryDistribution: _rows(
        categoryRows,
      ).map(SuperadminChartDatum.fromAmountRow).toList(growable: false),
      paymentDistribution: _rows(
        paymentRows,
      ).map(SuperadminChartDatum.fromAmountRow).toList(growable: false),
      rewardDistribution: _rows(
        rewardRows,
      ).map(SuperadminChartDatum.fromAmountRow).toList(growable: false),
    );
  }

  Future<void> upsertBranch({
    String? branchId,
    required String code,
    required String name,
    required String phone,
    required String email,
    required String address,
    required String province,
    required String city,
    required String district,
    required String postalCode,
    required bool isActive,
  }) async {
    try {
      await runBackendAction(
        'SuperadminRepository.upsertBranch',
        () => _client.rpc(
          'superadmin_upsert_branch',
          params: {
            'p_branch_id': _nullable(branchId),
            'p_code': code.trim(),
            'p_name': name.trim(),
            'p_phone': phone.trim(),
            'p_email': email.trim(),
            'p_address': address.trim(),
            'p_province': province.trim(),
            'p_city': city.trim(),
            'p_district': district.trim(),
            'p_postal_code': postalCode.trim(),
            'p_is_active': isActive,
          },
        ),
      );
    } catch (error) {
      throw Exception(
        friendlyBackendMessage(error, fallback: 'Data cabang gagal disimpan.'),
      );
    }
  }

  Future<void> setBranchActive({
    required String branchId,
    required bool isActive,
  }) async {
    try {
      await runBackendAction(
        'SuperadminRepository.setBranchActive',
        () => _client.rpc(
          'superadmin_set_branch_active',
          params: {'p_branch_id': branchId, 'p_is_active': isActive},
        ),
      );
    } catch (error) {
      throw Exception(
        friendlyBackendMessage(
          error,
          fallback: 'Status cabang gagal diperbarui.',
        ),
      );
    }
  }

  List<Map<String, dynamic>> _rows(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Map<String, dynamic> _singleRow(dynamic value) {
    final rows = _rows(value);
    if (rows.isEmpty) return const <String, dynamic>{};
    return rows.first;
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

class SuperadminDashboardSummary {
  const SuperadminDashboardSummary({
    required this.totalBranches,
    required this.activeBranches,
    required this.totalCustomers,
    required this.totalBranchAdmins,
    required this.totalTransactionsToday,
    required this.totalRevenueToday,
    required this.totalRevenueMonth,
    required this.totalProducts,
    required this.outOfStockProducts,
    required this.lowStockProducts,
  });

  factory SuperadminDashboardSummary.fromRow(Map<String, dynamic> row) {
    return SuperadminDashboardSummary(
      totalBranches: (row['total_branches'] as num?)?.toInt() ?? 0,
      activeBranches: (row['active_branches'] as num?)?.toInt() ?? 0,
      totalCustomers: (row['total_customers'] as num?)?.toInt() ?? 0,
      totalBranchAdmins: (row['total_branch_admins'] as num?)?.toInt() ?? 0,
      totalTransactionsToday:
          (row['total_transactions_today'] as num?)?.toInt() ?? 0,
      totalRevenueToday: (row['total_revenue_today'] as num?)?.toInt() ?? 0,
      totalRevenueMonth: (row['total_revenue_month'] as num?)?.toInt() ?? 0,
      totalProducts: (row['total_products'] as num?)?.toInt() ?? 0,
      outOfStockProducts: (row['out_of_stock_products'] as num?)?.toInt() ?? 0,
      lowStockProducts: (row['low_stock_products'] as num?)?.toInt() ?? 0,
    );
  }

  final int totalBranches;
  final int activeBranches;
  final int totalCustomers;
  final int totalBranchAdmins;
  final int totalTransactionsToday;
  final int totalRevenueToday;
  final int totalRevenueMonth;
  final int totalProducts;
  final int outOfStockProducts;
  final int lowStockProducts;
}

class SuperadminKpiSummary {
  const SuperadminKpiSummary({
    required this.averageOrderValue,
    required this.conversionOrder,
    required this.repeatCustomer,
    required this.totalRewardRedeemed,
    required this.totalRewardEarned,
  });

  factory SuperadminKpiSummary.fromRow(Map<String, dynamic> row) {
    return SuperadminKpiSummary(
      averageOrderValue: (row['average_order_value'] as num?)?.toDouble() ?? 0,
      conversionOrder: (row['conversion_order'] as num?)?.toDouble() ?? 0,
      repeatCustomer: (row['repeat_customer'] as num?)?.toInt() ?? 0,
      totalRewardRedeemed: (row['total_reward_redeemed'] as num?)?.toInt() ?? 0,
      totalRewardEarned: (row['total_reward_earned'] as num?)?.toInt() ?? 0,
    );
  }

  final double averageOrderValue;
  final double conversionOrder;
  final int repeatCustomer;
  final int totalRewardRedeemed;
  final int totalRewardEarned;
}

class SuperadminBranchMonitoringRecord {
  const SuperadminBranchMonitoringRecord({
    required this.branchId,
    required this.branchCode,
    required this.branchName,
    required this.phone,
    required this.email,
    required this.address,
    required this.province,
    required this.city,
    required this.district,
    required this.postalCode,
    required this.isActive,
    required this.transactionsToday,
    required this.revenueToday,
    required this.pendingOrders,
    required this.totalStock,
    required this.outOfStockProducts,
    required this.lowStockProducts,
    required this.healthStatus,
  });

  factory SuperadminBranchMonitoringRecord.fromRow(Map<String, dynamic> row) {
    return SuperadminBranchMonitoringRecord(
      branchId: (row['branch_id'] ?? '').toString(),
      branchCode: (row['branch_code'] ?? '').toString(),
      branchName: (row['branch_name'] ?? '').toString(),
      phone: (row['phone'] ?? '').toString(),
      email: (row['email'] ?? '').toString(),
      address: (row['address'] ?? '').toString(),
      province: (row['province'] ?? '').toString(),
      city: (row['city'] ?? '').toString(),
      district: (row['district'] ?? '').toString(),
      postalCode: (row['postal_code'] ?? '').toString(),
      isActive: row['is_active'] != false,
      transactionsToday: (row['transactions_today'] as num?)?.toInt() ?? 0,
      revenueToday: (row['revenue_today'] as num?)?.toInt() ?? 0,
      pendingOrders: (row['pending_orders'] as num?)?.toInt() ?? 0,
      totalStock: (row['total_stock'] as num?)?.toInt() ?? 0,
      outOfStockProducts: (row['out_of_stock_products'] as num?)?.toInt() ?? 0,
      lowStockProducts: (row['low_stock_products'] as num?)?.toInt() ?? 0,
      healthStatus: (row['health_status'] ?? 'Normal').toString(),
    );
  }

  final String branchId;
  final String branchCode;
  final String branchName;
  final String phone;
  final String email;
  final String address;
  final String province;
  final String city;
  final String district;
  final String postalCode;
  final bool isActive;
  final int transactionsToday;
  final int revenueToday;
  final int pendingOrders;
  final int totalStock;
  final int outOfStockProducts;
  final int lowStockProducts;
  final String healthStatus;
}

class SuperadminBranchPerformanceRecord {
  const SuperadminBranchPerformanceRecord({
    required this.branchId,
    required this.branchName,
    required this.revenueToday,
    required this.revenueMonth,
    required this.previousRevenueMonth,
    required this.transactionsToday,
    required this.transactionsMonth,
    required this.growthPercent,
    required this.performanceScore,
  });

  factory SuperadminBranchPerformanceRecord.fromRow(Map<String, dynamic> row) {
    return SuperadminBranchPerformanceRecord(
      branchId: (row['branch_id'] ?? '').toString(),
      branchName: (row['branch_name'] ?? '').toString(),
      revenueToday: (row['revenue_today'] as num?)?.toInt() ?? 0,
      revenueMonth: (row['revenue_month'] as num?)?.toInt() ?? 0,
      previousRevenueMonth:
          (row['previous_revenue_month'] as num?)?.toInt() ?? 0,
      transactionsToday: (row['transactions_today'] as num?)?.toInt() ?? 0,
      transactionsMonth: (row['transactions_month'] as num?)?.toInt() ?? 0,
      growthPercent: (row['growth_percent'] as num?)?.toDouble() ?? 0,
      performanceScore: (row['performance_score'] as num?)?.toDouble() ?? 0,
    );
  }

  final String branchId;
  final String branchName;
  final int revenueToday;
  final int revenueMonth;
  final int previousRevenueMonth;
  final int transactionsToday;
  final int transactionsMonth;
  final double growthPercent;
  final double performanceScore;
}

class SuperadminAdminMonitoringRecord {
  const SuperadminAdminMonitoringRecord({
    required this.branchAdminId,
    required this.branchId,
    required this.branchName,
    required this.branchCode,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.adminRole,
    required this.isPrimary,
    required this.isActive,
    required this.lastLoginAt,
    required this.managedTransactions,
  });

  factory SuperadminAdminMonitoringRecord.fromRow(Map<String, dynamic> row) {
    return SuperadminAdminMonitoringRecord(
      branchAdminId: (row['branch_admin_id'] ?? '').toString(),
      branchId: (row['branch_id'] ?? '').toString(),
      branchName: (row['branch_name'] ?? '').toString(),
      branchCode: (row['branch_code'] ?? '').toString(),
      fullName: (row['full_name'] ?? '').toString(),
      email: (row['email'] ?? '').toString(),
      phone: (row['phone'] ?? '').toString(),
      adminRole: (row['admin_role'] ?? '').toString(),
      isPrimary: row['is_primary'] == true,
      isActive: row['is_active'] == true,
      lastLoginAt: DateTime.tryParse((row['last_login_at'] ?? '').toString()),
      managedTransactions: (row['managed_transactions'] as num?)?.toInt() ?? 0,
    );
  }

  final String branchAdminId;
  final String branchId;
  final String branchName;
  final String branchCode;
  final String fullName;
  final String email;
  final String phone;
  final String adminRole;
  final bool isPrimary;
  final bool isActive;
  final DateTime? lastLoginAt;
  final int managedTransactions;
}

class SuperadminAnalyticsBundle {
  const SuperadminAnalyticsBundle({
    required this.monthlyRevenue,
    required this.dailyTransactions,
    required this.categoryDistribution,
    required this.paymentDistribution,
    required this.rewardDistribution,
  });

  final List<SuperadminChartDatum> monthlyRevenue;
  final List<SuperadminChartDatum> dailyTransactions;
  final List<SuperadminChartDatum> categoryDistribution;
  final List<SuperadminChartDatum> paymentDistribution;
  final List<SuperadminChartDatum> rewardDistribution;
}

class SuperadminChartDatum {
  const SuperadminChartDatum({required this.label, required this.amount});

  factory SuperadminChartDatum.fromAmountRow(Map<String, dynamic> row) {
    return SuperadminChartDatum(
      label: (row['label'] ?? '').toString(),
      amount: (row['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  final String label;
  final double amount;
}
