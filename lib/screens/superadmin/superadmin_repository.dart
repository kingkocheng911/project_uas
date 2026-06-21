import 'package:supabase_flutter/supabase_flutter.dart';

class SuperadminRepository {
  SuperadminRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<SuperadminBranchRecord>> loadBranches() async {
    final branchRows = await _client
        .from('branches')
        .select(
          'id, code, name, phone, email, address, province, city, district, '
          'postal_code, is_active, opened_at, created_at',
        )
        .order('name');

    final adminAccounts = await loadBranchAdminAccounts();

    final latestPerformanceRows = await _client
        .from('branch_performance')
        .select(
          'branch_id, total_orders, gross_revenue, performance_score, period_date',
        )
        .eq('period_type', 'daily')
        .order('period_date', ascending: false);

    final branchAdmins = <String, List<String>>{};
    final branchPrimaryAccounts = <String, SuperadminBranchAdminAccount>{};
    for (final account in adminAccounts) {
      if (!account.isActive) continue;
      final fullName = account.fullName.trim();
      if (fullName.isNotEmpty) {
        branchAdmins.putIfAbsent(account.branchId, () => <String>[]).add(fullName);
      }
      final current = branchPrimaryAccounts[account.branchId];
      if (current == null || account.isPrimary) {
        branchPrimaryAccounts[account.branchId] = account;
      }
    }

    final latestPerformanceByBranch = <String, Map<String, dynamic>>{};
    for (final row in latestPerformanceRows) {
      final branchId = (row['branch_id'] ?? '').toString();
      if (branchId.isEmpty || latestPerformanceByBranch.containsKey(branchId)) {
        continue;
      }
      latestPerformanceByBranch[branchId] = Map<String, dynamic>.from(row);
    }

    return branchRows.map<SuperadminBranchRecord>((row) {
      final map = Map<String, dynamic>.from(row);
      final id = (map['id'] ?? '').toString();
      final adminNames = branchAdmins[id] ?? const <String>[];
      final performance = latestPerformanceByBranch[id];
      final primaryAccount = branchPrimaryAccounts[id];
      return SuperadminBranchRecord(
        id: id,
        code: (map['code'] ?? '').toString(),
        name: (map['name'] ?? '').toString(),
        phone: (map['phone'] ?? '').toString(),
        email: (map['email'] ?? '').toString(),
        address: (map['address'] ?? '').toString(),
        province: (map['province'] ?? '').toString(),
        city: (map['city'] ?? '').toString(),
        district: (map['district'] ?? '').toString(),
        postalCode: (map['postal_code'] ?? '').toString(),
        isActive: map['is_active'] != false,
        openedAt: (map['opened_at'] ?? '').toString(),
        activeAdminNames: adminNames,
        primaryAdminEmail: primaryAccount?.email ?? '',
        primaryAdminName: primaryAccount?.fullName ?? '',
        primaryAdminPhone: primaryAccount?.phone ?? '',
        totalOrders: (performance?['total_orders'] as num?)?.toInt() ?? 0,
        grossRevenue: (performance?['gross_revenue'] as num?)?.toInt() ?? 0,
        performanceScore:
            (performance?['performance_score'] as num?)?.round() ?? 0,
      );
    }).toList(growable: false);
  }

  Future<String> saveBranch(SuperadminBranchDraft draft, {String? branchId}) async {
    final payload = draft.toDatabaseMap();
    if (branchId == null) {
      final inserted = await _client
          .from('branches')
          .insert(payload)
          .select('id')
          .single();
      final createdBranchId = (inserted['id'] ?? '').toString();
      if (createdBranchId.isEmpty) {
        throw Exception('ID cabang baru tidak ditemukan setelah proses simpan.');
      }
      if (draft.shouldCreateAdminCredentials) {
        await upsertBranchAdminCredentials(
          branchId: createdBranchId,
          email: draft.adminLoginEmail.trim(),
          password: draft.adminLoginPassword.trim(),
          fullName: draft.resolvedAdminLoginName,
          phone: draft.resolvedAdminLoginPhone,
        );
      }
      return createdBranchId;
    }
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
  }

  Future<void> setBranchActive(String branchId, {required bool isActive}) async {
    await _client
        .from('branches')
        .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', branchId);
  }

  Future<List<SuperadminAdminRecord>> loadAdminAssignments() async {
    final accounts = await loadBranchAdminAccounts();
    return accounts
        .map(
          (account) => SuperadminAdminRecord(
            id: account.branchAdminId,
            branchId: account.branchId,
            userId: account.userId,
            branchName: account.branchName,
            branchCode: account.branchCode,
            fullName: account.fullName,
            phone: account.phone,
            email: account.email,
            adminRole: account.adminRole,
            isPrimary: account.isPrimary,
            isActive: account.isActive,
            profileIsActive: true,
          ),
        )
        .toList(growable: false);
  }

  Future<List<SuperadminBranchAdminAccount>> loadBranchAdminAccounts() async {
    final rows = await _client.rpc('superadmin_list_branch_admin_accounts');

    return rows.map<SuperadminBranchAdminAccount>((row) {
      final map = Map<String, dynamic>.from(row);
      return SuperadminBranchAdminAccount(
        branchAdminId: (map['branch_admin_id'] ?? '').toString(),
        branchId: (map['branch_id'] ?? '').toString(),
        branchName: (map['branch_name'] ?? '').toString(),
        branchCode: (map['branch_code'] ?? '').toString(),
        userId: (map['user_id'] ?? '').toString(),
        fullName: (map['full_name'] ?? '').toString(),
        phone: (map['phone'] ?? '').toString(),
        email: (map['email'] ?? '').toString(),
        adminRole: (map['admin_role'] ?? '').toString(),
        isPrimary: map['is_primary'] == true,
        isActive: map['is_active'] == true,
      );
    }).toList(growable: false);
  }

  Future<SuperadminBranchAdminAccount?> loadPrimaryBranchAdminAccount(
    String branchId,
  ) async {
    final accounts = await loadBranchAdminAccounts();
    final matches = accounts
        .where((account) => account.branchId == branchId && account.isActive)
        .toList(growable: false);
    if (matches.isEmpty) return null;
    matches.sort((a, b) {
      final primaryCompare = (b.isPrimary ? 1 : 0).compareTo(a.isPrimary ? 1 : 0);
      if (primaryCompare != 0) return primaryCompare;
      return a.fullName.compareTo(b.fullName);
    });
    return matches.first;
  }

  Future<SuperadminBranchAdminAccount> upsertBranchAdminCredentials({
    required String branchId,
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String adminRole = 'branch_admin',
    bool isPrimary = true,
  }) async {
    final rows = await _client.rpc(
      'superadmin_upsert_branch_admin_credentials',
      params: {
        'p_branch_id': branchId,
        'p_email': email,
        'p_password': password,
        'p_full_name': fullName,
        'p_phone': phone,
        'p_admin_role': adminRole,
        'p_is_primary': isPrimary,
      },
    );

    if (rows is! List || rows.isEmpty) {
      throw Exception('Backend tidak mengembalikan data akun admin cabang.');
    }

    final createdRow = Map<String, dynamic>.from(rows.first as Map);
    return SuperadminBranchAdminAccount(
      branchAdminId: (createdRow['branch_admin_id'] ?? '').toString(),
      branchId: branchId,
      branchName: '',
      branchCode: '',
      userId: (createdRow['user_id'] ?? '').toString(),
      fullName: (createdRow['full_name'] ?? fullName).toString(),
      phone: phone ?? '',
      email: (createdRow['email'] ?? email).toString(),
      adminRole: adminRole,
      isPrimary: isPrimary,
      isActive: true,
    );
  }

  Future<List<SuperadminProfileCandidate>> loadAdminCandidates() async {
    final rows = await _client
        .from('profiles')
        .select('id, full_name, phone, role, role_type, is_active, default_branch_id')
        .order('full_name');

    return rows.map<SuperadminProfileCandidate>((row) {
      final map = Map<String, dynamic>.from(row);
      return SuperadminProfileCandidate(
        id: (map['id'] ?? '').toString(),
        fullName: (map['full_name'] ?? '').toString(),
        phone: (map['phone'] ?? '').toString(),
        role: (map['role'] ?? '').toString(),
        roleType: (map['role_type'] ?? '').toString(),
        isActive: map['is_active'] != false,
        defaultBranchId: (map['default_branch_id'] ?? '').toString(),
      );
    }).where((candidate) {
      final role = candidate.role.toLowerCase();
      final roleType = candidate.roleType.toLowerCase();
      return role != 'superadmin' && roleType != 'super_admin';
    }).toList(growable: false);
  }

  Future<void> saveAdminAssignment(
    SuperadminAdminDraft draft, {
    String? assignmentId,
  }) async {
    final payload = {
      'branch_id': draft.branchId,
      'user_id': draft.userId,
      'admin_role': draft.adminRole,
      'is_primary': draft.isPrimary,
      'is_active': draft.isActive,
      'revoked_at': draft.isActive ? null : DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (assignmentId == null) {
      await _client.from('branch_admins').insert({
        ...payload,
        'assigned_at': DateTime.now().toIso8601String(),
      });
    } else {
      await _client.from('branch_admins').update(payload).eq('id', assignmentId);
    }

    await _client.from('profiles').update({
      'role': draft.isActive ? 'admin' : 'user',
      'role_type': draft.isActive ? 'admin' : 'customer',
      'default_branch_id': draft.branchId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', draft.userId);
  }

  Future<void> deactivateAdminAssignment(
    String assignmentId, {
    required String userId,
  }) async {
    await _client.from('branch_admins').update({
      'is_active': false,
      'revoked_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', assignmentId);

    final activeAssignments = await _client
        .from('branch_admins')
        .select('id')
        .eq('user_id', userId)
        .eq('is_active', true)
        .limit(1);

    if (activeAssignments.isEmpty) {
      await _client.from('profiles').update({
        'role': 'user',
        'role_type': 'customer',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    }
  }

  Future<SuperadminDashboardOverviewData> loadDashboardOverview() async {
    final branches = await loadBranches();
    final adminAssignments = await loadAdminAssignments();
    final profiles = await _client
        .from('profiles')
        .select('role, role_type, created_at');
    final orders = await _client
        .from('orders')
        .select('branch_id, grand_total, payment_status, order_status, placed_at');

    final totalBranches = branches.length;
    final activeBranches = branches.where((branch) => branch.isActive).length;
    final totalAdmins = adminAssignments.where((admin) => admin.isActive).length;
    final totalCustomers = profiles.where((row) {
      final role = (row['role'] ?? '').toString().toLowerCase();
      final roleType = (row['role_type'] ?? '').toString().toLowerCase();
      return roleType == 'customer' || role == 'user';
    }).length;

    var paidRevenue = 0;
    var totalOrders = 0;
    final branchRevenue = <String, int>{};
    final branchCompleted = <String, int>{};
    final branchOrders = <String, int>{};
    final dayBuckets = <String, int>{};

    for (final raw in orders) {
      final row = Map<String, dynamic>.from(raw);
      final branchId = (row['branch_id'] ?? '').toString();
      final amount = (row['grand_total'] as num?)?.toInt() ?? 0;
      final paymentStatus = (row['payment_status'] ?? '').toString().toLowerCase();
      final orderStatus = (row['order_status'] ?? '').toString().toLowerCase();
      final placedAt = DateTime.tryParse((row['placed_at'] ?? '').toString());

      totalOrders += 1;
      branchOrders[branchId] = (branchOrders[branchId] ?? 0) + 1;

      if (orderStatus == 'completed') {
        branchCompleted[branchId] = (branchCompleted[branchId] ?? 0) + 1;
      }

      if (paymentStatus == 'paid') {
        paidRevenue += amount;
        branchRevenue[branchId] = (branchRevenue[branchId] ?? 0) + amount;
        if (placedAt != null) {
          final key =
              '${placedAt.day.toString().padLeft(2, '0')}/${placedAt.month.toString().padLeft(2, '0')}';
          dayBuckets[key] = (dayBuckets[key] ?? 0) + amount;
        }
      }
    }

    final rankedBranches = branches.map((branch) {
      final revenue = branchRevenue[branch.id] ?? branch.grossRevenue;
      final orderCount = branchOrders[branch.id] ?? branch.totalOrders;
      final completedCount = branchCompleted[branch.id] ?? 0;
      final completionRate = orderCount == 0
          ? 0
          : ((completedCount / orderCount) * 100).round();
      final derivedScore = branch.performanceScore > 0
          ? branch.performanceScore
          : ((completionRate * 0.6) + ((revenue > 0 ? 100 : 0) * 0.4)).round();
      return SuperadminRankedBranch(
        branch: branch,
        revenue: revenue,
        totalOrders: orderCount,
        completedOrders: completedCount,
        score: derivedScore.clamp(0, 100),
      );
    }).toList()
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        final revenueCompare = b.revenue.compareTo(a.revenue);
        if (revenueCompare != 0) return revenueCompare;
        return a.branch.name.compareTo(b.branch.name);
      });

    final revenueSeries = rankedBranches.take(6).map((item) {
      final shortLabel = item.branch.name.length > 10
          ? item.branch.name.substring(0, 10)
          : item.branch.name;
      return SuperadminChartPoint(
        label: shortLabel,
        value: item.revenue,
      );
    }).toList(growable: false);

    final growthSeries = dayBuckets.entries
        .map((entry) => SuperadminChartPoint(label: entry.key, value: entry.value))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    return SuperadminDashboardOverviewData(
      totalBranches: totalBranches,
      activeBranches: activeBranches,
      totalAdmins: totalAdmins,
      totalCustomers: totalCustomers,
      paidRevenue: paidRevenue,
      totalOrders: totalOrders,
      avgPerformance: rankedBranches.isEmpty
          ? 0
          : (rankedBranches.fold<int>(0, (sum, item) => sum + item.score) /
                    rankedBranches.length)
                .round(),
      rankedBranches: rankedBranches,
      revenueSeries: revenueSeries,
      growthSeries: growthSeries.take(7).toList(growable: false),
    );
  }

  Future<List<SuperadminPromotionRecord>> loadPromotions() async {
    final rows = await _client
        .from('promotions')
        .select(
          'id, branch_id, title, description, promo_type, promo_scope, '
          'discount_value, min_purchase, max_discount, quota_total, quota_used, '
          'start_at, end_at, is_active, created_at',
        )
        .order('created_at', ascending: false);

    final branchIds = rows
        .map((row) => (row['branch_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final branchRows = branchIds.isEmpty
        ? const <dynamic>[]
        : await _client
              .from('branches')
              .select('id, name')
              .inFilter('id', branchIds);
    final branchMap = <String, String>{
      for (final row in branchRows)
        (row['id'] ?? '').toString(): (row['name'] ?? '').toString(),
    };

    return rows.map<SuperadminPromotionRecord>((raw) {
      final row = Map<String, dynamic>.from(raw);
      final branchId = (row['branch_id'] ?? '').toString();
      return SuperadminPromotionRecord(
        id: (row['id'] ?? '').toString(),
        branchId: branchId,
        branchName: branchMap[branchId] ?? '',
        title: (row['title'] ?? '').toString(),
        description: (row['description'] ?? '').toString(),
        promoType: (row['promo_type'] ?? '').toString(),
        promoScope: (row['promo_scope'] ?? '').toString(),
        discountValue: (row['discount_value'] as num?)?.toInt() ?? 0,
        minPurchase: (row['min_purchase'] as num?)?.toInt() ?? 0,
        maxDiscount: (row['max_discount'] as num?)?.toInt() ?? 0,
        quotaTotal: (row['quota_total'] as num?)?.toInt() ?? 0,
        quotaUsed: (row['quota_used'] as num?)?.toInt() ?? 0,
        startAt: DateTime.tryParse((row['start_at'] ?? '').toString()),
        endAt: DateTime.tryParse((row['end_at'] ?? '').toString()),
        isActive: row['is_active'] == true,
      );
    }).toList(growable: false);
  }

  Future<void> savePromotion(
    SuperadminPromotionDraft draft, {
    String? promotionId,
  }) async {
    final payload = {
      'branch_id': draft.promoScope == 'branch' ? draft.branchId : null,
      'title': draft.title.trim(),
      'description': draft.description.trim().isEmpty ? null : draft.description.trim(),
      'promo_type': draft.promoType,
      'promo_scope': draft.promoScope,
      'discount_value': draft.discountValue,
      'min_purchase': draft.minPurchase <= 0 ? null : draft.minPurchase,
      'max_discount': draft.maxDiscount <= 0 ? null : draft.maxDiscount,
      'quota_total': draft.quotaTotal <= 0 ? null : draft.quotaTotal,
      'start_at': draft.startAt.toIso8601String(),
      'end_at': draft.endAt.toIso8601String(),
      'is_active': draft.isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (promotionId == null) {
      final userId = _client.auth.currentUser?.id;
      await _client.from('promotions').insert({
        ...payload,
        'created_by': userId,
      });
      return;
    }

    await _client.from('promotions').update(payload).eq('id', promotionId);
  }

  Future<void> setPromotionActive(
    String promotionId, {
    required bool isActive,
  }) async {
    await _client
        .from('promotions')
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', promotionId);
  }

  Future<List<SuperadminUserRecord>> loadUsers() async {
    final profileRows = await _client
        .from('profiles')
        .select(
          'id, full_name, phone, role, role_type, is_active, wallet_balance, created_at',
        )
        .order('created_at', ascending: false);

    final userProfiles = profileRows.where((raw) {
      final row = Map<String, dynamic>.from(raw);
      final role = (row['role'] ?? '').toString().toLowerCase();
      final roleType = (row['role_type'] ?? '').toString().toLowerCase();
      return roleType == 'customer' || role == 'user';
    }).map((raw) => Map<String, dynamic>.from(raw)).toList(growable: false);

    final userIds = userProfiles
        .map((row) => (row['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final orders = userIds.isEmpty
        ? const <dynamic>[]
        : await _client
              .from('orders')
              .select('user_id, grand_total, payment_status, placed_at')
              .inFilter('user_id', userIds);
    final topups = userIds.isEmpty
        ? const <dynamic>[]
        : await _client
              .from('wallet_topups')
              .select('user_id, amount, status, created_at')
              .inFilter('user_id', userIds);

    final paidSpent = <String, int>{};
    final totalOrders = <String, int>{};
    final lastOrderAt = <String, DateTime>{};
    for (final raw in orders) {
      final row = Map<String, dynamic>.from(raw);
      final userId = (row['user_id'] ?? '').toString();
      if (userId.isEmpty) continue;
      totalOrders[userId] = (totalOrders[userId] ?? 0) + 1;
      if ((row['payment_status'] ?? '').toString().toLowerCase() == 'paid') {
        paidSpent[userId] = (paidSpent[userId] ?? 0) + ((row['grand_total'] as num?)?.toInt() ?? 0);
      }
      final placedAt = DateTime.tryParse((row['placed_at'] ?? '').toString());
      if (placedAt != null) {
        final current = lastOrderAt[userId];
        if (current == null || placedAt.isAfter(current)) {
          lastOrderAt[userId] = placedAt;
        }
      }
    }

    final totalTopups = <String, int>{};
    for (final raw in topups) {
      final row = Map<String, dynamic>.from(raw);
      final userId = (row['user_id'] ?? '').toString();
      if (userId.isEmpty) continue;
      if ((row['status'] ?? '').toString().toLowerCase() == 'paid') {
        totalTopups[userId] = (totalTopups[userId] ?? 0) + ((row['amount'] as num?)?.toInt() ?? 0);
      }
    }

    return userProfiles.map<SuperadminUserRecord>((row) {
      final id = (row['id'] ?? '').toString();
      return SuperadminUserRecord(
        id: id,
        fullName: (row['full_name'] ?? '').toString(),
        phone: (row['phone'] ?? '').toString(),
        walletBalance: (row['wallet_balance'] as num?)?.toInt() ?? 0,
        isActive: row['is_active'] != false,
        totalOrders: totalOrders[id] ?? 0,
        totalSpent: paidSpent[id] ?? 0,
        totalTopup: totalTopups[id] ?? 0,
        lastOrderAt: lastOrderAt[id],
      );
    }).toList(growable: false);
  }

  Future<SuperadminReportsSummary> loadReportsSummary() async {
    final branches = await loadBranches();
    final orders = await _client
        .from('orders')
        .select('branch_id, grand_total, payment_status, order_status, placed_at');
    final orderItems = await _client
        .from('order_items')
        .select('product_name, qty, subtotal');
    final topups = await _client
        .from('wallet_topups')
        .select('amount, status');

    var paidRevenue = 0;
    var totalOrders = 0;
    var completedOrders = 0;
    final branchRevenue = <String, int>{};
    for (final raw in orders) {
      final row = Map<String, dynamic>.from(raw);
      totalOrders += 1;
      if ((row['order_status'] ?? '').toString().toLowerCase() == 'completed') {
        completedOrders += 1;
      }
      if ((row['payment_status'] ?? '').toString().toLowerCase() == 'paid') {
        final amount = (row['grand_total'] as num?)?.toInt() ?? 0;
        paidRevenue += amount;
        final branchId = (row['branch_id'] ?? '').toString();
        if (branchId.isNotEmpty) {
          branchRevenue[branchId] = (branchRevenue[branchId] ?? 0) + amount;
        }
      }
    }

    var itemsSold = 0;
    final productSales = <String, int>{};
    for (final raw in orderItems) {
      final row = Map<String, dynamic>.from(raw);
      final qty = (row['qty'] as num?)?.toInt() ?? 0;
      final productName = (row['product_name'] ?? '').toString();
      itemsSold += qty;
      if (productName.isNotEmpty) {
        productSales[productName] = (productSales[productName] ?? 0) + qty;
      }
    }

    var totalTopups = 0;
    for (final raw in topups) {
      final row = Map<String, dynamic>.from(raw);
      if ((row['status'] ?? '').toString().toLowerCase() == 'paid') {
        totalTopups += (row['amount'] as num?)?.toInt() ?? 0;
      }
    }

    final branchReports = branches.map((branch) {
      return SuperadminBranchReport(
        branchName: branch.name,
        location: [branch.district, branch.city]
            .where((item) => item.trim().isNotEmpty)
            .join(', '),
        revenue: branchRevenue[branch.id] ?? 0,
        status: branch.isActive ? 'Active' : 'Suspended',
      );
    }).toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    final topProducts = productSales.entries
        .map((entry) => SuperadminTopProduct(name: entry.key, quantity: entry.value))
        .toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    return SuperadminReportsSummary(
      totalRevenue: paidRevenue,
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      itemsSold: itemsSold,
      totalTopups: totalTopups,
      branchReports: branchReports,
      topProducts: topProducts.take(5).toList(growable: false),
    );
  }
}

class SuperadminBranchRecord {
  const SuperadminBranchRecord({
    required this.id,
    required this.code,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.province,
    required this.city,
    required this.district,
    required this.postalCode,
    required this.isActive,
    required this.openedAt,
    required this.activeAdminNames,
    required this.primaryAdminEmail,
    required this.primaryAdminName,
    required this.primaryAdminPhone,
    required this.totalOrders,
    required this.grossRevenue,
    required this.performanceScore,
  });

  final String id;
  final String code;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String province;
  final String city;
  final String district;
  final String postalCode;
  final bool isActive;
  final String openedAt;
  final List<String> activeAdminNames;
  final String primaryAdminEmail;
  final String primaryAdminName;
  final String primaryAdminPhone;
  final int totalOrders;
  final int grossRevenue;
  final int performanceScore;
}

class SuperadminBranchDraft {
  const SuperadminBranchDraft({
    required this.code,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.province,
    required this.city,
    required this.district,
    required this.postalCode,
    required this.isActive,
    this.adminLoginName = '',
    this.adminLoginEmail = '',
    this.adminLoginPassword = '',
    this.adminLoginPhone = '',
  });

  final String code;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String province;
  final String city;
  final String district;
  final String postalCode;
  final bool isActive;
  final String adminLoginName;
  final String adminLoginEmail;
  final String adminLoginPassword;
  final String adminLoginPhone;

  bool get shouldCreateAdminCredentials =>
      adminLoginEmail.trim().isNotEmpty && adminLoginPassword.trim().isNotEmpty;

  String get resolvedAdminLoginName {
    final trimmed = adminLoginName.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return 'Admin ${name.trim()}';
  }

  String? get resolvedAdminLoginPhone {
    final explicitPhone = adminLoginPhone.trim();
    if (explicitPhone.isNotEmpty) return explicitPhone;
    final branchPhone = phone.trim();
    return branchPhone.isEmpty ? null : branchPhone;
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'code': code.trim(),
      'name': name.trim(),
      'phone': _nullable(phone),
      'email': _nullable(email),
      'address': address.trim(),
      'province': _nullable(province),
      'city': _nullable(city),
      'district': _nullable(district),
      'postal_code': _nullable(postalCode),
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class SuperadminAdminRecord {
  const SuperadminAdminRecord({
    required this.id,
    required this.branchId,
    required this.userId,
    required this.branchName,
    required this.branchCode,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.adminRole,
    required this.isPrimary,
    required this.isActive,
    required this.profileIsActive,
  });

  final String id;
  final String branchId;
  final String userId;
  final String branchName;
  final String branchCode;
  final String fullName;
  final String phone;
  final String email;
  final String adminRole;
  final bool isPrimary;
  final bool isActive;
  final bool profileIsActive;
}

class SuperadminBranchAdminAccount {
  const SuperadminBranchAdminAccount({
    required this.branchAdminId,
    required this.branchId,
    required this.branchName,
    required this.branchCode,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.adminRole,
    required this.isPrimary,
    required this.isActive,
  });

  final String branchAdminId;
  final String branchId;
  final String branchName;
  final String branchCode;
  final String userId;
  final String fullName;
  final String phone;
  final String email;
  final String adminRole;
  final bool isPrimary;
  final bool isActive;
}

class SuperadminProfileCandidate {
  const SuperadminProfileCandidate({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.roleType,
    required this.isActive,
    required this.defaultBranchId,
  });

  final String id;
  final String fullName;
  final String phone;
  final String role;
  final String roleType;
  final bool isActive;
  final String defaultBranchId;
}

class SuperadminAdminDraft {
  const SuperadminAdminDraft({
    required this.userId,
    required this.branchId,
    required this.adminRole,
    required this.isPrimary,
    required this.isActive,
  });

  final String userId;
  final String branchId;
  final String adminRole;
  final bool isPrimary;
  final bool isActive;
}

class SuperadminDashboardOverviewData {
  const SuperadminDashboardOverviewData({
    required this.totalBranches,
    required this.activeBranches,
    required this.totalAdmins,
    required this.totalCustomers,
    required this.paidRevenue,
    required this.totalOrders,
    required this.avgPerformance,
    required this.rankedBranches,
    required this.revenueSeries,
    required this.growthSeries,
  });

  final int totalBranches;
  final int activeBranches;
  final int totalAdmins;
  final int totalCustomers;
  final int paidRevenue;
  final int totalOrders;
  final int avgPerformance;
  final List<SuperadminRankedBranch> rankedBranches;
  final List<SuperadminChartPoint> revenueSeries;
  final List<SuperadminChartPoint> growthSeries;
}

class SuperadminRankedBranch {
  const SuperadminRankedBranch({
    required this.branch,
    required this.revenue,
    required this.totalOrders,
    required this.completedOrders,
    required this.score,
  });

  final SuperadminBranchRecord branch;
  final int revenue;
  final int totalOrders;
  final int completedOrders;
  final int score;
}

class SuperadminChartPoint {
  const SuperadminChartPoint({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;
}

class SuperadminPromotionRecord {
  const SuperadminPromotionRecord({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.title,
    required this.description,
    required this.promoType,
    required this.promoScope,
    required this.discountValue,
    required this.minPurchase,
    required this.maxDiscount,
    required this.quotaTotal,
    required this.quotaUsed,
    required this.startAt,
    required this.endAt,
    required this.isActive,
  });

  final String id;
  final String branchId;
  final String branchName;
  final String title;
  final String description;
  final String promoType;
  final String promoScope;
  final int discountValue;
  final int minPurchase;
  final int maxDiscount;
  final int quotaTotal;
  final int quotaUsed;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isActive;
}

class SuperadminPromotionDraft {
  const SuperadminPromotionDraft({
    required this.title,
    required this.description,
    required this.promoType,
    required this.promoScope,
    required this.branchId,
    required this.discountValue,
    required this.minPurchase,
    required this.maxDiscount,
    required this.quotaTotal,
    required this.startAt,
    required this.endAt,
    required this.isActive,
  });

  final String title;
  final String description;
  final String promoType;
  final String promoScope;
  final String branchId;
  final int discountValue;
  final int minPurchase;
  final int maxDiscount;
  final int quotaTotal;
  final DateTime startAt;
  final DateTime endAt;
  final bool isActive;
}

class SuperadminUserRecord {
  const SuperadminUserRecord({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.walletBalance,
    required this.isActive,
    required this.totalOrders,
    required this.totalSpent,
    required this.totalTopup,
    required this.lastOrderAt,
  });

  final String id;
  final String fullName;
  final String phone;
  final int walletBalance;
  final bool isActive;
  final int totalOrders;
  final int totalSpent;
  final int totalTopup;
  final DateTime? lastOrderAt;
}

class SuperadminReportsSummary {
  const SuperadminReportsSummary({
    required this.totalRevenue,
    required this.totalOrders,
    required this.completedOrders,
    required this.itemsSold,
    required this.totalTopups,
    required this.branchReports,
    required this.topProducts,
  });

  final int totalRevenue;
  final int totalOrders;
  final int completedOrders;
  final int itemsSold;
  final int totalTopups;
  final List<SuperadminBranchReport> branchReports;
  final List<SuperadminTopProduct> topProducts;
}

class SuperadminBranchReport {
  const SuperadminBranchReport({
    required this.branchName,
    required this.location,
    required this.revenue,
    required this.status,
  });

  final String branchName;
  final String location;
  final int revenue;
  final String status;
}

class SuperadminTopProduct {
  const SuperadminTopProduct({
    required this.name,
    required this.quantity,
  });

  final String name;
  final int quantity;
}
