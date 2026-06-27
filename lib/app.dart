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
const _demoAuthOverride = bool.fromEnvironment(
  'ALLOW_DEMO_AUTH',
  defaultValue: true,
);

bool get isSupabaseConfigured =>
<<<<<<< HEAD
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

/// Hasil dari aksi autentikasi (login/sign up/verifikasi).
///
/// - [error] berisi pesan error bila gagal (null bila sukses).
/// - [needsVerification] true bila akun perlu verifikasi email (OTP) dahulu.
/// - [email] email terkait, dipakai untuk membuka layar verifikasi.
class AuthResult {
  const AuthResult._({this.error, this.needsVerification = false, this.email});

  factory AuthResult.success() => const AuthResult._();

  factory AuthResult.error(String message) => AuthResult._(error: message);

  factory AuthResult.needsVerification(String email) =>
      AuthResult._(needsVerification: true, email: email);

  final String? error;
  final bool needsVerification;
  final String? email;

  bool get isSuccess => error == null && !needsVerification;
}
=======
    supabaseUrl.trim().isNotEmpty && supabasePublishableKey.trim().isNotEmpty;

bool get isDemoAuthAllowed => !kReleaseMode && _demoAuthOverride;
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)

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
  bool get _canUseMockAuth => !_useSupabase && isDemoAuthAllowed;

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
<<<<<<< HEAD
    } else if (widget.startAuthenticated) {
      _activeProfile = widget.forceMockAuth
          ? _mockRegisteredUser.profile
          : (kIsWeb ? _mockSuperAdmin.profile : _mockAdmin.profile);
=======
    } else if (widget.startAuthenticated && _canUseMockAuth) {
      // Jika di web, default langsung gunakan profil superadmin mock
      _activeProfile = kIsWeb
          ? _mockSuperAdmin.profile
          : _mockRegisteredUser.profile;
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
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
              onVerifyOtp: _handleVerifyOtp,
              onResendOtp: _handleResendOtp,
              onForgotPassword: _handleForgotPassword,
              usingSupabase: _useSupabase,
<<<<<<< HEAD
              setupMessage: supabaseConfigStatusMessage,
=======
              allowDemoAuth: _canUseMockAuth,
              setupMessage: _setupMessage,
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
            )
          : _buildHomeByRole(),
    );
  }

  String get _setupMessage {
    if (_useSupabase) {
      return 'Masuk dengan akun Supabase aktif.';
    }
    if (_canUseMockAuth) {
      return 'Mode demo aktif untuk development. Jangan gunakan mode ini saat build production.';
    }
    return 'Konfigurasi Supabase wajib diisi untuk build production. Login demo dinonaktifkan.';
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

    if (!_canUseMockAuth) {
      return 'Login demo dinonaktifkan. Isi konfigurasi Supabase untuk melanjutkan.';
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

  Future<AuthResult> _handleSignUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    // Pendaftaran user biasa (customer) tetap diizinkan di web.
    // Hanya akun admin/superadmin yang diblokir untuk mendaftar mandiri.

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

        final session = response.session;
        final user = session?.user ?? response.user;

        // Bila verifikasi email diaktifkan, signUp tidak langsung membuat sesi.
        // Arahkan pengguna ke layar verifikasi OTP.
        if (session == null) {
          return AuthResult.needsVerification(email);
        }

        if (user == null) {
          return AuthResult.needsVerification(email);
        }

        await _ensureUserData(user, fallbackName: name, fallbackPhone: phone);
        final profile = await _profileFromSupabaseUser(user);
        if (profile == null) {
          return AuthResult.error(
            'Akun berhasil dibuat, tetapi profil belum siap. Silakan login ulang.',
          );
        }
        setState(() => _activeProfile = profile);
        return AuthResult.success();
      } on AuthException catch (error) {
        return AuthResult.error(error.message);
      } catch (error) {
        return AuthResult.error(
          'Tidak dapat membuat akun di Supabase saat ini. $error',
        );
      }
    }

    if (!_canUseMockAuth) {
      return 'Pendaftaran demo dinonaktifkan. Isi konfigurasi Supabase untuk melanjutkan.';
    }

    if (_mockRegisteredUser.profile.email.toLowerCase() ==
        email.toLowerCase()) {
      return AuthResult.error('Email ini sudah terdaftar. Silakan login.');
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
    return AuthResult.success();
  }

  /// Verifikasi kode OTP yang dikirim ke email saat pendaftaran.
  Future<AuthResult> _handleVerifyOtp({
    required String email,
    required String token,
  }) async {
    if (!_useSupabase) {
      // Mode demo: anggap verifikasi langsung sukses.
      return AuthResult.success();
    }
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
      final user =
          response.session?.user ?? Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return AuthResult.error('Verifikasi gagal. Coba lagi.');
      }

      await _ensureUserData(user, fallbackName: _nameFromEmail(email));
      final profile = await _profileFromSupabaseUser(user);
      if (profile == null) {
        return AuthResult.error(
          'Akun terverifikasi, tetapi profil belum siap. Silakan login ulang.',
        );
      }
      setState(() => _activeProfile = profile);
      return AuthResult.success();
    } on AuthException catch (error) {
      return AuthResult.error(error.message);
    } catch (_) {
      return AuthResult.error('Tidak dapat memverifikasi kode saat ini.');
    }
  }

  /// Kirim ulang kode verifikasi (OTP) ke email pengguna.
  Future<String?> _handleResendOtp(String email) async {
    if (!_useSupabase) return null;
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (_) {
      return 'Tidak dapat mengirim ulang kode saat ini.';
    }
  }

  /// Kirim email reset kata sandi (lupa password).
  Future<String?> _handleForgotPassword(String email) async {
    if (!_useSupabase) {
      return 'Reset kata sandi hanya tersedia saat terhubung ke Supabase.';
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (_) {
      return 'Tidak dapat mengirim email reset kata sandi saat ini.';
    }
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
          await client.from('profiles').upsert({
            'id': user.id,
            'full_name': updatedProfile.name,
            'phone': updatedProfile.phone == '-' ? null : updatedProfile.phone,
            'avatar_url': updatedProfile.avatarUrl,
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

  Future<void> _ensureUserData(
    User user, {
    String? fallbackName,
    String? fallbackPhone,
  }) async {
    final client = Supabase.instance.client;
    final metadata = user.userMetadata ?? <String, dynamic>{};
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
    final roleType = _profileRoleType(_roleFromMetadata(metadata));

    await client.from('profiles').upsert({
      'id': user.id,
      'full_name': profileName.isEmpty
          ? _nameFromEmail(user.email ?? 'Member')
          : profileName,
      'phone': profilePhone.isEmpty ? null : profilePhone,
      'avatar_url': avatarUrl.isEmpty ? '__initials__' : avatarUrl,
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
    required this.onVerifyOtp,
    required this.onResendOtp,
    required this.onForgotPassword,
    required this.usingSupabase,
<<<<<<< HEAD
=======
    required this.allowDemoAuth,
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
    required this.setupMessage,
    this.initialEmail = '',
    this.initialPassword = '',
  });

  final Future<String?> Function({
    required String email,
    required String password,
  })
  onLogin;
  final Future<AuthResult> Function({
    required String name,
    required String phone,
    required String email,
    required String password,
  })
  onSignUp;
  final Future<AuthResult> Function({
    required String email,
    required String token,
  })
  onVerifyOtp;
  final Future<String?> Function(String email) onResendOtp;
  final Future<String?> Function(String email) onForgotPassword;
  final bool usingSupabase;
<<<<<<< HEAD
=======
  final bool allowDemoAuth;
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD9001B), Color(0xFF8B0011)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.usingSupabase
                        ? 'Masuk dengan Supabase Auth'
                        : 'Masuk ke akun MepuPoin',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.usingSupabase
                        ? 'Akun, sesi login, dan perubahan profil akan disimpan melalui Supabase.'
                        : 'Belanja kebutuhan koperasi, kelola pesanan, dan pantau transaksi dalam satu aplikasi.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.usingSupabase) ...[
              const SizedBox(height: 16),
              _SetupHintCard(
<<<<<<< HEAD
                title: 'Mode Demo Aktif',
=======
                title: widget.allowDemoAuth ? 'Mode Demo Aktif' : 'Konfigurasi Diperlukan',
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
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
      title: 'Login Akun',
      subtitle: 'Masukkan email dan kata sandi untuk melanjutkan.',
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
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Kata Sandi',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: _validatePassword,
            ),
            if (_loginError != null) ...[
              const SizedBox(height: 14),
              _AuthErrorText(message: _loginError!),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _submittingLogin ? null : _showForgotPasswordDialog,
                child: const Text('Lupa kata sandi?'),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _submittingLogin || (!widget.usingSupabase && !widget.allowDemoAuth)
                    ? null
                    : _submitLogin,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(_submittingLogin ? 'Memproses...' : 'Login'),
              ),
            ),
            if (!widget.usingSupabase && widget.allowDemoAuth) ...[
              const SizedBox(height: 12),
              Text(
                'Akun demo: budi.santoso@email.com / mepupoin123',
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
      title: 'Buat Akun Baru',
      subtitle: 'Daftarkan akun untuk mulai belanja dan menyimpan pesanan.',
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
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Kata Sandi',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: _validatePassword,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _signUpConfirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Konfirmasi Kata Sandi',
                prefixIcon: Icon(Icons.verified_user_outlined),
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
                onPressed:
                    _submittingSignUp ||
                        (!widget.usingSupabase && !widget.allowDemoAuth)
                    ? null
                    : _submitSignUp,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(_submittingSignUp ? 'Memproses...' : 'Sign Up'),
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
    final email = _signUpEmailController.text.trim();
    final result = await widget.onSignUp(
      name: _signUpNameController.text.trim(),
      phone: _signUpPhoneController.text.trim(),
      email: email,
      password: _signUpPasswordController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _submittingSignUp = false;
      _signUpError = result.error;
    });

    if (result.needsVerification) {
      await _openVerificationScreen(result.email ?? email);
    }
  }

  /// Buka layar verifikasi OTP. Bila verifikasi sukses, sesi akan aktif dan
  /// halaman auth otomatis tertutup karena _activeProfile sudah terisi.
  Future<void> _openVerificationScreen(String email) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VerificationScreen(
          email: email,
          onVerify: widget.onVerifyOtp,
          onResend: widget.onResendOtp,
        ),
      ),
    );
  }

  /// Tampilkan dialog untuk mengirim email reset kata sandi.
  Future<void> _showForgotPasswordDialog() async {
    final controller = TextEditingController(
      text: _loginEmailController.text.trim(),
    );
    final formKey = GlobalKey<FormState>();
    var submitting = false;
    String? message;
    var isError = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Lupa Kata Sandi'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Masukkan email akunmu. Kami akan mengirim tautan untuk '
                      'mereset kata sandi.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: _validateEmail,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        message!,
                        style: TextStyle(
                          color: isError
                              ? const Color(0xFFB42318)
                              : const Color(0xFF15803D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Tutup'),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            submitting = true;
                            message = null;
                          });
                          final error = await widget.onForgotPassword(
                            controller.text.trim(),
                          );
                          setDialogState(() {
                            submitting = false;
                            if (error == null) {
                              isError = false;
                              message =
                                  'Email reset kata sandi sudah dikirim. '
                                  'Periksa kotak masuk kamu.';
                            } else {
                              isError = true;
                              message = error;
                            }
                          });
                        },
                  child: Text(submitting ? 'Mengirim...' : 'Kirim'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF64748B),
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
    const labels = ['Login', 'Sign Up'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECEEF0),
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

/// Layar verifikasi kode OTP yang dikirim ke email pengguna setelah sign up.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.email,
    required this.onVerify,
    required this.onResend,
  });

  final String email;
  final Future<AuthResult> Function({
    required String email,
    required String token,
  })
  onVerify;
  final Future<String?> Function(String email) onResend;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _submitting = false;
  bool _resending = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
      _info = null;
    });
    final result = await widget.onVerify(
      email: widget.email,
      token: _tokenController.text.trim(),
    );
    if (!mounted) return;
    if (result.isSuccess) {
      // Verifikasi sukses: tutup layar verifikasi. Halaman auth otomatis
      // beralih ke home karena _activeProfile sudah terisi.
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = false;
      _error = result.error ?? 'Verifikasi gagal. Coba lagi.';
    });
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
      _info = null;
    });
    final error = await widget.onResend(widget.email);
    if (!mounted) return;
    setState(() {
      _resending = false;
      if (error == null) {
        _info = 'Kode verifikasi baru sudah dikirim ke email kamu.';
      } else {
        _error = error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi Email')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                color: theme.colorScheme.primary,
                size: 34,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Masukkan Kode Verifikasi',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Kami telah mengirim kode 6 digit ke ${widget.email}. '
              'Masukkan kode tersebut untuk mengaktifkan akunmu.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _tokenController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Kode OTP',
                  prefixIcon: Icon(Icons.pin_outlined),
                  counterText: '',
                ),
                validator: (value) {
                  final token = value?.trim() ?? '';
                  if (token.length < 6) {
                    return 'Kode verifikasi terdiri dari 6 digit';
                  }
                  return null;
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              _AuthErrorText(message: _error!),
            ],
            if (_info != null) ...[
              const SizedBox(height: 14),
              Text(
                _info!,
                style: const TextStyle(
                  color: Color(0xFF15803D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(_submitting ? 'Memverifikasi...' : 'Verifikasi'),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _resending ? null : _resend,
                child: Text(
                  _resending ? 'Mengirim ulang...' : 'Kirim ulang kode',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
