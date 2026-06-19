import 'dart:async';

import 'package:flutter/foundation.dart'; // 1. Tambahkan untuk mendeteksi kIsWeb
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import UI Dashboard Web yang sudah kita buat sebelumnya
import 'screens/superadmin/dashboard_overview.dart';
import 'screens/home_shell.dart';
import 'theme.dart';
import 'screens/admin/dashboard/admin_dashboard.dart';
import 'screens/admin/dashboard/dashboard_overview.dart';
import 'screens/admin/dashboard/dashboard_stats.dart';

import 'screens/admin/products/product_list_screen.dart';
import 'screens/admin/products/add_product_screen.dart';
import 'screens/admin/products/edit_product_screen.dart';

const _defaultAvatarUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBK38PfAiyHOiE6kMysiQgsdlCCaiTZUI4b6gmDIwhe7ReUvEF9AOZtc7zqWWpVxTvrZR01xBh3zwriMDBPGCAo8CThIn0t0ntISl8DH-ep3Z-QGr7OWGhZ3xzhTCYILlx9u9FIcdh72iy8WgdEZ-5Ow0Z7K3GctB5GWYGI-vV-GtzOo52Gm493KbofV8djVAmlUkGGmTVDG9cAGxX5fu1r6zYUEtMTvVVdJdvfWy0C3YN2beA5eJaitKgtJFVoqPaqkjSAbfMpshmD';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: '',
);

bool get isSupabaseConfigured =>
    supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

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
            final user = data.session?.user;
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
           : _mockAdmin.profile;
          
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
      return const Scaffold(
        body: Center(
          child: Text('Courier Dashboard'),
        ),
      );

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
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          return 'Login gagal. Coba lagi beberapa saat.';
        }

        final profile = await _profileFromSupabaseUser(user);

        // 3. Proteksi Web Dashboard: Validasi role saat masuk via Web
        if (kIsWeb && profile != null) {
          if (profile.role != 'superadmin' && profile.role != 'admin') {
            await Supabase.instance.client.auth.signOut(); // Log out otomatis
            return 'Akses ditolak. Halaman ini khusus untuk manajemen Admin MepuPoin.';
          }
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
  if (_mockAdmin.profile.email.toLowerCase() ==
          email.toLowerCase() &&
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
        await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': name,
            'phone': phone,
            'avatar_url': '__initials__',
            'role': 'user', // Set default registrasi luar sebagai user biasa
          },
        );
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          return 'Akun dibuat, tapi sesi belum aktif. Coba login kembali.';
        }
        final profile = await _profileFromSupabaseUser(user);
        setState(() => _activeProfile = profile);
        return null;
      } on AuthException catch (error) {
        return error.message;
      } catch (_) {
        return 'Tidak dapat membuat akun di Supabase saat ini.';
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
          await client.from('profiles').upsert({
            'id': user.id,
            'full_name': updatedProfile.name,
            'phone': updatedProfile.phone == '-' ? null : updatedProfile.phone,
            'avatar_url': updatedProfile.avatarUrl,
          });
        }
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            email: updatedProfile.email,
          ),
        );
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
      final row = await client
          .from('profiles')
          .select('full_name, phone, avatar_url, role')
          .eq('id', user.id)
          .maybeSingle();

      if (row == null) {
        return fallbackProfile;
      }

      final name = (row['full_name'] ?? '').toString().trim();
      final phone = (row['phone'] ?? '').toString().trim();
      final avatarUrl = (row['avatar_url'] ?? '').toString().trim();
      final role = _roleFromProfileRow(row, fallbackRole: fallbackProfile.role);

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
    final role = (metadata['role'] ?? 'user').toString();

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
  }) {
    final role = (row['role'] ?? '').toString().trim().toLowerCase();
    switch (role) {
      case 'superadmin':
        return 'superadmin';
      case 'admin':
        return 'admin';
      case 'user':
        return 'user';
      default:
        return fallbackRole;
    }
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
              const _SetupHintCard(
                title: 'Mode Demo Aktif',
                message:
                    'Supabase belum dikonfigurasi. Aplikasi masih memakai akun lokal demo sampai SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY dikirim lewat dart-define.',
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
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submittingLogin ? null : _submitLogin,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(_submittingLogin ? 'Memproses...' : 'Login'),
              ),
            ),
            if (!widget.usingSupabase) ...[
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
                onPressed: _submittingSignUp ? null : _submitSignUp,
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
