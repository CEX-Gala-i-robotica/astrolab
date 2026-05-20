import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../services/session_service.dart';
import '../widgets/app_planet_logo.dart';
import '../widgets/cosmic_background.dart';
import 'dashboard_screen.dart';

/// Ecran complet de autentificare / înregistrare
/// Logică identică cu Login.cs + SignUp.cs din proiectul C# WPF
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────────────────────
  bool _isLogin = true;
  bool _busy = false;
  bool _obscure = true;
  bool _rememberMe = false;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMsg;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadSavedSession();
  }

  /// [Login.cs → LoadRememberedCredentials]
  Future<void> _loadSavedSession() async {
    final s = await SessionService.load();
    if (s != null && s.rememberMe && s.email.isNotEmpty) {
      setState(() {
        _rememberMe = true;
        _emailCtrl.text = s.email;
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── SUBMIT ─────────────────────────────────────────────────────────────────
  /// [Login.cs → LoginButton_Click] + [SignUp.cs → SignUpButton_Click]
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_busy) return;

    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    setState(() {
      _busy = true;
      _errorMsg = null;
    });

    final result = _isLogin
        ? await AuthService.signIn(email, password)
        : await AuthService.signUp(email, password);

    if (!mounted) return;

    if (result.ok) {
      // Salvare sesiune [Login.cs → SaveSession]
      await SessionService.save(
        email: email,
        idToken: result.idToken!,
        uid: result.uid!,
        rememberMe: _rememberMe,
        refreshToken: result.refreshToken ?? '',
      );

      await _openDashboardOrSetup(result.idToken!, result.uid!, email);
    } else {
      setState(() {
        _busy = false;
        _errorMsg = result.error;
      });
    }
  }

  /// [Login.cs → OpenDashboardOrSetup]
  Future<void> _openDashboardOrSetup(
    String token,
    String uid,
    String email,
  ) async {
    await ProgressService.configureRemote(uid: uid, token: token);
    final needsSetup = await AuthService.needsProfileSetup(token, uid);
    if (!mounted) return;

    // Navigare către Dashboard — înlocuiește ecranul curent
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => DashboardScreen(
          email: email,
          uid: uid,
          idToken: token,
          needsProfileSetup: needsSetup,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// [Login.cs → ForgotPasswordLink_Click]
  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMsg = 'Introdu email-ul pentru a reseta parola.');
      return;
    }
    setState(() {
      _busy = true;
      _errorMsg = null;
    });
    final err = await AuthService.sendPasswordReset(email);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      _showSnack('Email de resetare trimis! Verifică căsuța de email.');
    } else {
      setState(
        () => _errorMsg =
            'Nu am putut trimite emailul. Verifică adresa introdusă.',
      );
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const CosmicBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 0,
                    vertical: 32,
                  ),
                  child: _card(isMobile, size),
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(bool isMobile, Size size) {
    final cardW = isMobile ? double.infinity : 440.0;

    return Container(
      width: cardW,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: const Color(0xFF071520),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.12),
            blurRadius: 60,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cardHeader(),
            const SizedBox(height: 28),
            _tabBar(),
            const SizedBox(height: 24),
            _emailField(),
            const SizedBox(height: 14),
            _passwordField(),
            if (_isLogin) ...[const SizedBox(height: 6), _forgotPasswordBtn()],
            if (!_isLogin) ...[const SizedBox(height: 8), _rememberMeRow()],
            if (_isLogin) ...[const SizedBox(height: 4), _rememberMeRow()],
            if (_errorMsg != null) ...[
              const SizedBox(height: 12),
              _errorBanner(),
            ],
            const SizedBox(height: 22),
            _submitButton(),
            const SizedBox(height: 20),
            _dividerOr(),
            const SizedBox(height: 16),
            _socialButtons(),
          ],
        ),
      ),
    );
  }

  // ── Widgets componente ────────────────────────────────────────────────────

  Widget _cardHeader() => Row(
    children: [
      ClipOval(child: AppPlanetLogo(size: 40)),
      const SizedBox(width: 12),
      RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'ASTRO',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 0.8,
              ),
            ),
            TextSpan(
              text: 'LAB',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _tabBar() => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        _tab(
          'Autentificare',
          _isLogin,
          () => setState(() {
            _isLogin = true;
            _errorMsg = null;
          }),
        ),
        _tab(
          'Cont nou',
          !_isLogin,
          () => setState(() {
            _isLogin = false;
            _errorMsg = null;
          }),
        ),
      ],
    ),
  );

  Widget _tab(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: active
              ? Border.all(
                  color: AppColors.primary.withOpacity(0.35),
                  width: 0.5,
                )
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    ),
  );

  Widget _emailField() => _inputField(
    controller: _emailCtrl,
    hint: 'Email',
    icon: Icons.email_outlined,
    obscure: false,
    validator: (v) {
      if (v == null || v.trim().isEmpty) return 'Email obligatoriu';
      if (!v.contains('@')) return 'Email invalid';
      return null;
    },
  );

  Widget _passwordField() => _inputField(
    controller: _passCtrl,
    hint: 'Parolă',
    icon: Icons.lock_outline_rounded,
    obscure: _obscure,
    suffixIcon: IconButton(
      icon: Icon(
        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.textMuted,
        size: 18,
      ),
      onPressed: () => setState(() => _obscure = !_obscure),
    ),
    validator: (v) {
      if (v == null || v.isEmpty) return 'Parola obligatorie';
      if (!_isLogin && v.length < 6) return 'Minim 6 caractere';
      return null;
    },
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    obscureText: obscure,
    validator: validator,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primary.withOpacity(0.55),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
    ),
  );

  Widget _forgotPasswordBtn() => Align(
    alignment: Alignment.centerRight,
    child: TextButton(
      onPressed: _busy ? null : _forgotPassword,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
      ),
      child: const Text(
        'Ai uitat parola?',
        style: TextStyle(fontSize: 12, color: AppColors.secondary),
      ),
    ),
  );

  Widget _rememberMeRow() => Row(
    children: [
      SizedBox(
        width: 20,
        height: 20,
        child: Checkbox(
          value: _rememberMe,
          onChanged: (v) => setState(() => _rememberMe = v ?? false),
          activeColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      const SizedBox(width: 8),
      const Text(
        'Ține-mă minte',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
    ],
  );

  Widget _errorBanner() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.red.withOpacity(0.3), width: 0.5),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Colors.redAccent,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _errorMsg!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _submitButton() => _GradientButton(
    label: _isLogin ? 'Intră în platformă' : 'Creează cont',
    busy: _busy,
    onPressed: _submit,
  );

  Widget _dividerOr() => Row(
    children: [
      Expanded(child: Divider(color: AppColors.primary.withOpacity(0.15))),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'sau',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ),
      Expanded(child: Divider(color: AppColors.primary.withOpacity(0.15))),
    ],
  );

  Widget _socialButtons() => _SocialBtn(
    label: 'Continuă cu Google',
    icon: Icons.g_mobiledata_rounded,
    onTap: _busy ? () {} : _signInWithGoogle,
    fullWidth: true,
  );

  /// [Login.cs → GoogleLoginButton_Click]
  Future<void> _signInWithGoogle() async {
    setState(() {
      _busy = true;
      _errorMsg = null;
    });

    final result = await AuthService.signInWithGoogle();

    if (!mounted) return;

    if (result.ok) {
      await SessionService.save(
        email: result.email!,
        idToken: result.idToken!,
        uid: result.uid!,
        rememberMe: true,
        refreshToken: result.refreshToken ?? '',
      );
      await _openDashboardOrSetup(result.idToken!, result.uid!, result.email!);
    } else {
      setState(() {
        _busy = false;
        _errorMsg = result.error;
      });
    }
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  final String label;
  final bool busy;
  final VoidCallback onPressed;
  const _GradientButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hov = true),
    onExit: (_) => setState(() => _hov = false),
    child: GestureDetector(
      onTap: widget.busy ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _hov
                ? [const Color(0xFF00C8F0), const Color(0xFF90E0EF)]
                : [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(_hov ? 0.45 : 0.22),
              blurRadius: _hov ? 24 : 12,
            ),
          ],
        ),
        child: Center(
          child: widget.busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool fullWidth;

  const _SocialBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.textSecondary, size: 22),
      label: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: AppColors.primary.withOpacity(0.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
