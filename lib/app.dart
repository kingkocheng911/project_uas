import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/superadmin/dashboard_overview.dart';
import 'screens/home_shell.dart';
import 'theme.dart';
import 'screens/admin/dashboard/admin_dashboard.dart';

const _defaultAvatarUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBK38PfAiyHOiE6kMysiQgsdlCCaiTZUI4b6gmDIwhe7ReUvEF9AOZtc7zqWWpVxTvrZR01xBh3zwriMDBPGCAo8CThIn0t0ntISl8DH-ep3Z-QGr7OWGhZ3xzhTCYILlx9u9FIcdh72iy8WgdEZ-5Ow0Z7K3GctB5GWYGI-vV-GtzOo52Gm493KbofV8djVAmlUkGGmTVDG9cAGxX5fu1r6zYUEtMTvVVdJdvfWy0C3YN2beA5eJaitKgtJFVoqPaqkjSAbfMpshmD';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: '',
);

bool get isSupabaseConfigured =>
    _isValidSupabaseUrl(supabaseUrl) &&
    _isValidSupabasePublishableKey(supabasePublishableKey);

bool get hasSupabaseConfigValues =>
    supabaseUrl.trim().isNotEmpty || supabasePublishableKey.trim().isNotEmpty;

bool get hasInvalidSupabaseConfig =>
    hasSupabaseConfigValues && !isSupabaseConfigured;

String get supabaseConfigStatusMessage {
  if (isSupabaseConfigured) {
    return 'Supabase aktif dan siap digunakan.';
  }

  if (hasInvalidSupabaseConfig) {
    return 'Konfigurasi Supabase masih placeholder atau tidak valid. Aplikasi memakai akun lokal demo sampai SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY benar.';
  }

  return 'Supabase belum dikonfigurasi. Aplikasi memakai akun lokal demo sampai SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY dikirim lewat dart-define.';
}

bool _isValidSupabaseUrl(String value) {
  final normalized = value.trim().toLowerCase();
  final uri = Uri.tryParse(normalized);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    return false;
  }

  const invalidMarkers = [
    'your_project',
    'your-project',
    'your_project_ref',
    'your-supabase',
    'example.supabase.co',
  ];
  if (invalidMarkers.any(normalized.contains)) {
    return false;
  }

  return uri.scheme == 'https' && uri.host.endsWith('.supabase.co');
}

bool _isValidSupabasePublishableKey(String value) {
  final normalized = value.trim();
  final lower = normalized.toLowerCase();
  if (normalized.isEmpty) {
    return false;
  }

  const invalidMarkers = [
    'your_supabase',
    'your_publishable',
    'publishable_key',
    'anon-key',
  ];
  if (invalidMarkers.any(lower.contains)) {
    return false;
  }

  return normalized.startsWith('sb_publishable_') ||
      normalized.split('.').length >= 3;
}

class KdmpApp extends StatefulWidget {
  const KdmpApp({
    super.key,
    this.startAuthenticated = false,
    this.forceMockAuth = false,
  });

  final bool startAuthenticated;
  final bool forceMockAuth;

  @override
  State<KdmpApp> createState() => _KdmpAppState();
}

class _KdmpAppState extends State<KdmpApp> {
  late _MockAuthUser _mockRegisteredUser = const _MockAuthUser(
    profile: UserProfile(
      name: 'Budi Speed',
      phone: '+62 812-3456-7890',
      email: 'budi.santoso@email.com',
      avatarUrl: _defaultAvatarUrl,
      role: 'user',
    ),
    password: 'mepupoin123',
  );

  // Buat akun demo khusus superadmin untuk keperluan testing local web dashboard tanpa Supabase
  final _MockAuthUser _mockSuperAdmin = const _MockAuthUser(
    profile: UserProfile(
      name: 'Safitri Novitasari',
      phone: '+62 811-2233-4455',
      email: 'admin@mepupoin.com',
      avatarUrl: _defaultAvatarUrl,
      role: 'superadmin',
    ),
    password: 'superadmin123',
  );

  //admin
  final _MockAuthUser _mockAdmin = const _MockAuthUser(
    profile: UserProfile(
      name: 'Admin Cabang Sukamaju',
      phone: '+62 811-1111-2222',
      email: 'admincabang@mepupoin.com',
      avatarUrl: _defaultAvatarUrl,
      role: 'admin',
    ),
    password: 'admin123',
  );

  UserProfile? _activeProfile;
  StreamSubscription<AuthState>? _authSubscription;

  bool get _useSupabase => isSupabaseConfigured && !widget.forceMockAuth;

  @override
  void initState() {
    super.initState();
    if (_useSupabase) {
      final currentUser = Supabase.instance.client.auth.currentUser;
      _activeProfile = _profileFallbackFromSupabaseUser(currentUser);
      unawaited(_syncActiveProfile(currentUser));
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((data) async {
            final user =
                data.session?.user ?? Supabase.instance.client.auth.currentUser;
            if (!mounted) return;
            setState(() {
              _activeProfile = _profileFallbackFromSupabaseUser(user);
            });
            await _syncActiveProfile(user);
          });
    } else if (widget.startAuthenticated) {
      // Jika di web, default langsung gunakan profil superadmin mock
      _activeProfile = kIsWeb
          ? _mockSuperAdmin.profile
          : _mockRegisteredUser.profile;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MepuPoin',
      debugShowCheckedModeBanner: false,
      theme: buildKdmpTheme(),
      scrollBehavior: const _KdmpScrollBehavior(),
      // 2. Lakukan percabangan Home berdasarkan platform (Web vs Mobile)
      home: _activeProfile == null
          ? AuthScreen(
              initialEmail: _useSupabase
                  ? ''
                  : (kIsWeb
                        ? _mockSuperAdmin.profile.email
                        : _mockRegisteredUser.profile.email),
              initialPassword: _useSupabase
                  ? ''
                  : (kIsWeb
                        ? _mockSuperAdmin.password
                        : _mockRegisteredUser.password),
              onLogin: _handleLogin,
              onSignUp: _handleSignUp,
              usingSupabase: _useSupabase,
              setupMessage: supabaseConfigStatusMessage,
            )
          : _buildHomeByRole(),
    );
  }

  Widget _buildHomeByRole() {
    if (_activeProfile == null) {
      return const SizedBox.shrink();
    }

    switch (_activeProfile!.role) {
      case 'superadmin':
        return const SuperAdminDashboardOverview();

      case 'admin':
        return const AdminDashboard();

      case 'courier':
        return const Scaffold(body: Center(child: Text('Courier Dashboard')));

      case 'user':
      default:
        return HomeShell(
          initialProfile: _activeProfile!,
          onLogout: () => unawaited(_handleLogout()),
          onProfileChanged: (profile) =>
              unawaited(_handleProfileChanged(profile)),
        );
    }
  }

  Future<String?> _handleLogin({
    required String email,
    required String password,
  }) async {
    if (_useSupabase) {
      try {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = response.user ?? Supabase.instance.client.auth.currentUser;
        if (user == null) {
          return 'Login gagal. Coba lagi beberapa saat.';
        }

        await _ensureUserData(user, fallbackName: _nameFromEmail(email));
        final profile = await _profileFromSupabaseUser(user);
        if (profile == null) {
          return 'Profil akun belum berhasil dimuat. Coba login kembali.';
        }

        setState(() => _activeProfile = profile);
        return null;
      } on AuthException catch (error) {
        return error.message;
      } catch (_) {
        return 'Tidak dapat login ke Supabase saat ini.';
      }
    }

    // Alur otentikasi lokal untuk mode Demo/Mock
    if (kIsWeb) {
      // Validasi mock superadmin untuk web
      final matchesEmail =
          _mockSuperAdmin.profile.email.toLowerCase() == email.toLowerCase();
      final matchesPassword = _mockSuperAdmin.password == password;
      if (!matchesEmail || !matchesPassword) {
        return 'Email atau kata sandi Superadmin salah.';
      }
      setState(() => _activeProfile = _mockSuperAdmin.profile);
    } else {
      // LOGIN ADMIN
      if (_mockAdmin.profile.email.toLowerCase() == email.toLowerCase() &&
          _mockAdmin.password == password) {
        setState(() => _activeProfile = _mockAdmin.profile);
        return null;
      }
    }
    // LOGIN USER
    if (_mockRegisteredUser.profile.email.toLowerCase() ==
            email.toLowerCase() &&
        _mockRegisteredUser.password == password) {
      setState(() => _activeProfile = _mockRegisteredUser.profile);
      return null;
    }

    return 'Email atau password salah';
  }

  Future<String?> _handleSignUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    // Blokir pendaftaran mandiri (Sign Up) dari panel web superadmin
    if (kIsWeb) {
      return 'Pendaftaran akun admin baru hanya bisa dilakukan oleh Superadmin di dalam sistem.';
    }

    if (_useSupabase) {
      try {
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': name,
            'phone': phone,
            'avatar_url': '__initials__',
            'role': 'user',
            'role_type': 'customer',
          },
        );

        final signedUpUser = response.user;
        Session? session = response.session;
        User? user = session?.user ?? signedUpUser;

        if (session == null) {
          final signInResponse = await Supabase.instance.client.auth
              .signInWithPassword(email: email, password: password);
          session = signInResponse.session;
          user =
              signInResponse.user ?? Supabase.instance.client.auth.currentUser;
        }

        if (user == null) {
          return 'Akun dibuat, tapi sesi belum aktif. Coba login kembali.';
        }

        await _ensureUserData(user, fallbackName: name, fallbackPhone: phone);
        final profile = await _profileFromSupabaseUser(user);
        if (profile == null) {
          return 'Akun berhasil dibuat, tetapi profil belum siap. Silakan login ulang.';
        }
        setState(() => _activeProfile = profile);
        return null;
      } on AuthException catch (error) {
        return error.message;
      } catch (error) {
        return 'Tidak dapat membuat akun di Supabase saat ini. $error';
      }
    }

    if (_mockRegisteredUser.profile.email.toLowerCase() ==
        email.toLowerCase()) {
      return 'Email ini sudah terdaftar. Silakan login.';
    }
    final newUser = _MockAuthUser(
      profile: UserProfile(
        name: name,
        phone: phone,
        email: email,
        avatarUrl: '__initials__',
        role: 'user',
      ),
      password: password,
    );
    setState(() {
      _mockRegisteredUser = newUser;
      _activeProfile = newUser.profile;
    });
    return null;
  }

  Future<void> _handleLogout() async {
    if (_useSupabase) {
      await Supabase.instance.client.auth.signOut();
    }
    if (!mounted) return;
    setState(() => _activeProfile = null);
  }

  Future<void> _handleProfileChanged(UserProfile updatedProfile) async {
    if (_useSupabase) {
      try {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user != null) {
          final role = _profileRoleValue(updatedProfile.role);
          await client.from('profiles').upsert({
            'id': user.id,
            'full_name': updatedProfile.name,
            'phone': updatedProfile.phone == '-' ? null : updatedProfile.phone,
            'avatar_url': updatedProfile.avatarUrl,
            'role': role,
            'role_type': _profileRoleType(updatedProfile.role),
            'is_active': true,
          });
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(
              email: updatedProfile.email,
              data: {
                'full_name': updatedProfile.name,
                'phone': updatedProfile.phone == '-'
                    ? null
                    : updatedProfile.phone,
                'avatar_url': updatedProfile.avatarUrl,
                'role': role,
                'role_type': _profileRoleType(updatedProfile.role),
              },
            ),
          );
        }
      } catch (_) {
        // Keep local UI responsive even if remote sync fails.
      }
    } else {
      _mockRegisteredUser = _mockRegisteredUser.copyWith(
        profile: updatedProfile,
      );
    }

    if (!mounted) return;
    setState(() => _activeProfile = updatedProfile);
  }

  Future<void> _syncActiveProfile(User? user) async {
    final profile = await _profileFromSupabaseUser(user);
    if (!mounted) return;
    setState(() => _activeProfile = profile);
  }

  Future<UserProfile?> _profileFromSupabaseUser(User? user) async {
    if (user == null) return null;
    final fallbackProfile = _profileFallbackFromSupabaseUser(user)!;
    final client = Supabase.instance.client;

    try {
      await _ensureUserData(
        user,
        fallbackName: fallbackProfile.name,
        fallbackPhone: fallbackProfile.phone == '-'
            ? null
            : fallbackProfile.phone,
      );

      final row = await client
          .from('profiles')
          .select('full_name, phone, avatar_url, role, role_type')
          .eq('id', user.id)
          .maybeSingle();

      if (row == null) {
        return fallbackProfile;
      }

      final branchAdminRows = await client
          .from('branch_admins')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_active', true)
          .limit(1);

      final name = (row['full_name'] ?? '').toString().trim();
      final phone = (row['phone'] ?? '').toString().trim();
      final avatarUrl = (row['avatar_url'] ?? '').toString().trim();
      final role = _roleFromProfileRow(
        row,
        fallbackRole: fallbackProfile.role,
        isBranchAdmin: branchAdminRows.isNotEmpty,
      );

      return UserProfile(
        name: name.isEmpty ? fallbackProfile.name : name,
        phone: phone.isEmpty ? fallbackProfile.phone : phone,
        email: user.email ?? '',
        avatarUrl: avatarUrl.isEmpty ? fallbackProfile.avatarUrl : avatarUrl,
        role: role,
      );
    } catch (_) {
      return fallbackProfile;
    }
  }

  UserProfile? _profileFallbackFromSupabaseUser(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? <String, dynamic>{};
    final name = (metadata['full_name'] ?? metadata['name'] ?? '')
        .toString()
        .trim();
    final phone = (metadata['phone'] ?? '').toString().trim();
    final avatarUrl = (metadata['avatar_url'] ?? '__initials__').toString();

    // Ambil data 'role' dari metadata user di Supabase (default: user)
    final role = _roleFromMetadata(metadata);

    return UserProfile(
      name: name.isEmpty ? _nameFromEmail(user.email ?? 'Member') : name,
      phone: phone.isEmpty ? '-' : phone,
      email: user.email ?? '',
      avatarUrl: avatarUrl.isEmpty ? '__initials__' : avatarUrl,
      role: role,
    );
  }

  String _roleFromProfileRow(
    Map<String, dynamic> row, {
    required String fallbackRole,
    required bool isBranchAdmin,
  }) {
    final role = (row['role'] ?? '').toString().trim().toLowerCase();
    final roleType = (row['role_type'] ?? '').toString().trim().toLowerCase();

    if (role == 'superadmin' || role == 'super_admin') return 'superadmin';
    if (roleType == 'superadmin' || roleType == 'super_admin') {
      return 'superadmin';
    }
    if (isBranchAdmin || role == 'admin' || roleType == 'admin') return 'admin';
    if (roleType == 'customer' || role == 'user') return 'user';
    return fallbackRole;
  }

  String _roleFromMetadata(Map<String, dynamic> metadata) {
    final rawRoleType = (metadata['role_type'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final rawRole = (metadata['role'] ?? '').toString().trim().toLowerCase();

    if (rawRole == 'superadmin' || rawRole == 'super_admin') {
      return 'superadmin';
    }
    if (rawRoleType == 'superadmin' || rawRoleType == 'super_admin') {
      return 'superadmin';
    }
    if (rawRole == 'admin' || rawRoleType == 'admin') return 'admin';
    return 'user';
  }

  String _profileRoleType(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return 'super_admin';
      case 'admin':
        return 'admin';
      default:
        return 'customer';
    }
  }

  String _profileRoleValue(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return 'superadmin';
      case 'admin':
        return 'admin';
      default:
        return 'user';
    }
  }

  Future<void> _ensureUserData(
    User user, {
    String? fallbackName,
    String? fallbackPhone,
  }) async {
    final client = Supabase.instance.client;
    final metadata = user.userMetadata ?? <String, dynamic>{};
    final existingProfile = await client
        .from('profiles')
        .select('role, role_type')
        .eq('id', user.id)
        .maybeSingle();
    final profileName =
        (metadata['full_name'] ?? metadata['name'] ?? fallbackName ?? '')
            .toString()
            .trim();
    final profilePhone = (metadata['phone'] ?? fallbackPhone ?? '')
        .toString()
        .trim();
    final avatarUrl = (metadata['avatar_url'] ?? '__initials__')
        .toString()
        .trim();
    final metadataRole = _roleFromMetadata(metadata);
    final existingRole = (existingProfile?['role'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final existingRoleType = (existingProfile?['role_type'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final resolvedRole = existingRole == 'superadmin' ||
            existingRole == 'super_admin' ||
            existingRoleType == 'superadmin' ||
            existingRoleType == 'super_admin'
        ? 'superadmin'
        : existingRole == 'admin' || existingRoleType == 'admin'
        ? 'admin'
        : metadataRole;
    final roleType = _profileRoleType(resolvedRole);
    final role = _profileRoleValue(resolvedRole);

    await client.from('profiles').upsert({
      'id': user.id,
      'full_name': profileName.isEmpty
          ? _nameFromEmail(user.email ?? 'Member')
          : profileName,
      'phone': profilePhone.isEmpty ? null : profilePhone,
      'avatar_url': avatarUrl.isEmpty ? '__initials__' : avatarUrl,
      'role': role,
      'role_type': roleType,
      'is_active': true,
    });

    await client.from('notification_settings').upsert({'user_id': user.id});
  }

  String _nameFromEmail(String email) {
    final handle = email.split('@').first.replaceAll('.', ' ').trim();
    if (handle.isEmpty) return 'Member Baru';
    return handle
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

// Komponen kelas internal pembantu bawaan dari file aslimu tetap dipertahankan di bawah...
class _MockAuthUser {
  const _MockAuthUser({required this.profile, required this.password});
  final UserProfile profile;
  final String password;

  _MockAuthUser copyWith({UserProfile? profile, String? password}) {
    return _MockAuthUser(
      profile: profile ?? this.profile,
      password: password ?? this.password,
    );
  }
}

// Sisa komponen UI seperti AuthScreen, _AuthCard, dll tetap biarkan seperti aslinya.

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onLogin,
    required this.onSignUp,
    required this.usingSupabase,
    required this.setupMessage,
    this.initialEmail = '',
    this.initialPassword = '',
  });

  final Future<String?> Function({
    required String email,
    required String password,
  })
  onLogin;
  final Future<String?> Function({
    required String name,
    required String phone,
    required String email,
    required String password,
  })
  onSignUp;
  final bool usingSupabase;
  final String setupMessage;
  final String initialEmail;
  final String initialPassword;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  late final TextEditingController _loginEmailController;
  late final TextEditingController _loginPasswordController;
  final _signUpNameController = TextEditingController();
  final _signUpPhoneController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmController = TextEditingController();
  int _selectedTab = 0;
  String? _loginError;
  String? _signUpError;
  bool _submittingLogin = false;
  bool _submittingSignUp = false;
  bool _obscureLoginPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureSignUpConfirm = true;

  @override
  void initState() {
    super.initState();
    _loginEmailController = TextEditingController(text: widget.initialEmail);
    _loginPasswordController = TextEditingController(
      text: widget.initialPassword,
    );
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpPhoneController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD9001B), Color(0xFF9E1123)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1AD9001B),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Selamat Datang di MepuPoin',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masuk atau buat akun untuk belanja kebutuhan koperasi, memantau pesanan, dan mengelola transaksi dengan lebih mudah.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _AuthHeroChip(
                        icon: Icons.inventory_2_outlined,
                        label: 'Produk Harian',
                      ),
                      _AuthHeroChip(
                        icon: Icons.local_shipping_outlined,
                        label: 'Lacak Pesanan',
                      ),
                      _AuthHeroChip(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Pembayaran Mudah',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!widget.usingSupabase) ...[
              const SizedBox(height: 16),
              _SetupHintCard(
                title: 'Mode Demo Aktif',
                message: widget.setupMessage,
              ),
            ],
            const SizedBox(height: 20),
            _AuthSegmentedTabs(
              selectedIndex: _selectedTab,
              onChanged: (index) => setState(() {
                _selectedTab = index;
                _loginError = null;
                _signUpError = null;
              }),
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _selectedTab == 0
                  ? _buildLoginCard(context)
                  : _buildSignUpCard(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return _AuthCard(
      key: const ValueKey('login-card'),
      title: 'Masuk ke Akun',
      subtitle: 'Gunakan email dan kata sandi yang sudah terdaftar.',
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _loginEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _loginPasswordController,
              obscureText: _obscureLoginPassword,
              decoration: InputDecoration(
                labelText: 'Kata Sandi',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _obscureLoginPassword = !_obscureLoginPassword,
                  ),
                  icon: Icon(
                    _obscureLoginPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: _validatePassword,
            ),
            if (_loginError != null) ...[
              const SizedBox(height: 14),
              _AuthErrorText(message: _loginError!),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submittingLogin ? null : _submitLogin,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(_submittingLogin ? 'Memproses...' : 'Masuk'),
              ),
            ),
            if (!widget.usingSupabase) ...[
              const SizedBox(height: 12),
              Text(
                'Akun uji coba: budi.santoso@email.com / mepupoin123',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpCard(BuildContext context) {
    return _AuthCard(
      key: const ValueKey('signup-card'),
      title: 'Daftar Akun Baru',
      subtitle:
          'Lengkapi data berikut untuk mulai berbelanja dan memantau pesanan.',
      child: Form(
        key: _signUpFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _signUpNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Nama minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _signUpPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return 'Nomor telepon belum valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _signUpEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _signUpPasswordController,
              obscureText: _obscureSignUpPassword,
              decoration: InputDecoration(
                labelText: 'Kata Sandi',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _obscureSignUpPassword = !_obscureSignUpPassword,
                  ),
                  icon: Icon(
                    _obscureSignUpPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _signUpConfirmController,
              obscureText: _obscureSignUpConfirm,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Kata Sandi',
                prefixIcon: const Icon(Icons.verified_user_outlined),
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _obscureSignUpConfirm = !_obscureSignUpConfirm,
                  ),
                  icon: Icon(
                    _obscureSignUpConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value != _signUpPasswordController.text) {
                  return 'Konfirmasi kata sandi belum sama';
                }
                return null;
              },
            ),
            if (_signUpError != null) ...[
              const SizedBox(height: 14),
              _AuthErrorText(message: _signUpError!),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submittingSignUp ? null : _submitSignUp,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(_submittingSignUp ? 'Memproses...' : 'Daftar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() {
      _submittingLogin = true;
      _loginError = null;
    });
    final error = await widget.onLogin(
      email: _loginEmailController.text.trim(),
      password: _loginPasswordController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _submittingLogin = false;
      _loginError = error;
    });
  }

  Future<void> _submitSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;
    setState(() {
      _submittingSignUp = true;
      _signUpError = null;
    });
    final error = await widget.onSignUp(
      name: _signUpNameController.text.trim(),
      phone: _signUpPhoneController.text.trim(),
      email: _signUpEmailController.text.trim(),
      password: _signUpPasswordController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _submittingSignUp = false;
      _signUpError = error;
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Email belum valid';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    return null;
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _AuthSegmentedTabs extends StatelessWidget {
  const _AuthSegmentedTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const labels = ['Masuk', 'Daftar'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selectedIndex == index
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selectedIndex == index
                          ? Colors.white
                          : const Color(0xFF475569),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AuthErrorText extends StatelessWidget {
  const _AuthErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3C7CC)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFB42318),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SetupHintCard extends StatelessWidget {
  const _SetupHintCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2D07A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF7A5A00),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF7A5A00)),
          ),
        ],
      ),
    );
  }
}

class _AuthHeroChip extends StatelessWidget {
  const _AuthHeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _KdmpScrollBehavior extends MaterialScrollBehavior {
  const _KdmpScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
