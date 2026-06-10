import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'theme.dart';

const _defaultAvatarUrl =
    'https://lh3.googleusercontent.com/aida-public/AB6AXuBK38PfAiyHOiE6kMysiQgsdlCCaiTZUI4b6gmDIwhe7ReUvEF9AOZtc7zqWWpVxTvrZR01xBh3zwriMDBPGCAo8CThIn0t0ntISl8DH-ep3Z-QGr7OWGhZ3xzhTCYILlx9u9FIcdh72iy8WgdEZ-5Ow0Z7K3GctB5GWYGI-vV-GtzOo52Gm493KbofV8djVAmlUkGGmTVDG9cAGxX5fu1r6zYUEtMTvVVdJdvfWy0C3YN2beA5eJaitKgtJFVoqPaqkjSAbfMpshmD';

class KdmpApp extends StatefulWidget {
  const KdmpApp({super.key, this.startAuthenticated = false});

  final bool startAuthenticated;

  @override
  State<KdmpApp> createState() => _KdmpAppState();
}

class _KdmpAppState extends State<KdmpApp> {
  late _AuthUser _registeredUser = const _AuthUser(
    profile: UserProfile(
      name: 'Budi Speed',
      phone: '+62 812-3456-7890',
      email: 'budi.santoso@email.com',
      avatarUrl: _defaultAvatarUrl,
    ),
    password: 'mepupoin123',
  );
  _AuthUser? _currentUser;

  @override
  void initState() {
    super.initState();
    if (widget.startAuthenticated) {
      _currentUser = _registeredUser;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MepuPoin',
      debugShowCheckedModeBanner: false,
      theme: buildKdmpTheme(),
      scrollBehavior: const _KdmpScrollBehavior(),
      home: _currentUser == null
          ? AuthScreen(
              initialEmail: _registeredUser.profile.email,
              initialPassword: _registeredUser.password,
              onLogin: _handleLogin,
              onSignUp: _handleSignUp,
            )
          : HomeShell(
              initialProfile: _currentUser!.profile,
              onLogout: _handleLogout,
              onProfileChanged: _handleProfileChanged,
            ),
    );
  }

  String? _handleLogin({required String email, required String password}) {
    final matchesEmail =
        _registeredUser.profile.email.toLowerCase() == email.toLowerCase();
    final matchesPassword = _registeredUser.password == password;
    if (!matchesEmail || !matchesPassword) {
      return 'Email atau kata sandi tidak sesuai.';
    }
    setState(() => _currentUser = _registeredUser);
    return null;
  }

  String? _handleSignUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) {
    if (_registeredUser.profile.email.toLowerCase() == email.toLowerCase()) {
      return 'Email ini sudah terdaftar. Silakan login.';
    }
    final newUser = _AuthUser(
      profile: UserProfile(
        name: name,
        phone: phone,
        email: email,
        avatarUrl: '__initials__',
      ),
      password: password,
    );
    setState(() {
      _registeredUser = newUser;
      _currentUser = newUser;
    });
    return null;
  }

  void _handleLogout() {
    setState(() => _currentUser = null);
  }

  void _handleProfileChanged(UserProfile updatedProfile) {
    setState(() {
      if (_currentUser == null) return;
      _currentUser = _currentUser!.copyWith(profile: updatedProfile);
      _registeredUser = _registeredUser.copyWith(profile: updatedProfile);
    });
  }
}

class _AuthUser {
  const _AuthUser({required this.profile, required this.password});

  final UserProfile profile;
  final String password;

  _AuthUser copyWith({UserProfile? profile, String? password}) {
    return _AuthUser(
      profile: profile ?? this.profile,
      password: password ?? this.password,
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.onLogin,
    required this.onSignUp,
    this.initialEmail = '',
    this.initialPassword = '',
  });

  final String? Function({required String email, required String password})
  onLogin;
  final String? Function({
    required String name,
    required String phone,
    required String email,
    required String password,
  })
  onSignUp;
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
                    'Masuk ke akun MepuPoin',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Belanja kebutuhan koperasi, kelola pesanan, dan pantau transaksi dalam satu aplikasi.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
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
                onPressed: _submitLogin,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('Login'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Akun demo: budi.santoso@email.com / mepupoin123',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
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
                onPressed: _submitSignUp,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('Sign Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitLogin() {
    if (!_loginFormKey.currentState!.validate()) return;
    final error = widget.onLogin(
      email: _loginEmailController.text.trim(),
      password: _loginPasswordController.text.trim(),
    );
    if (error != null) {
      setState(() => _loginError = error);
    }
  }

  void _submitSignUp() {
    if (!_signUpFormKey.currentState!.validate()) return;
    final error = widget.onSignUp(
      name: _signUpNameController.text.trim(),
      phone: _signUpPhoneController.text.trim(),
      email: _signUpEmailController.text.trim(),
      password: _signUpPasswordController.text.trim(),
    );
    if (error != null) {
      setState(() => _signUpError = error);
    }
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
