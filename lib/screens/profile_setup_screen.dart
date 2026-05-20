import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/cosmic_background.dart';

enum AstronomyLevel { beginner, intermediate, expert }

class ProfileSetupScreen extends StatefulWidget {
  final String token;
  final String uid;
  final String email;
  final ValueChanged<AstronomyLevel> onComplete;

  const ProfileSetupScreen({
    super.key,
    required this.token,
    required this.uid,
    required this.email,
    required this.onComplete,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _classValue = '5';
  AstronomyLevel? _level;
  bool _levelStep = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _birthDateCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked == null) return;
    _birthDateCtrl.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  void _next() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _levelStep = true;
      _error = null;
    });
  }

  Future<void> _finish() async {
    final level = _level;
    if (level == null || _busy) {
      setState(() => _error = 'Alege nivelul estimat de astronomie.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final err = await AuthService.saveProfileSetup(
      token: widget.token,
      uid: widget.uid,
      profile: {
        'email': widget.email,
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'birthDate': _birthDateCtrl.text.trim(),
        'class': _classValue,
        'phone': _phoneCtrl.text.trim(),
        'astronomyLevel': level.name,
      },
    );

    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }
    widget.onComplete(level);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 640;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const CosmicBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 32,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 22 : 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFF071520),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.10),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                    child: _levelStep ? _levelForm() : _profileForm(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _title('Completeaza profilul'),
          const SizedBox(height: 18),
          _textField(_firstNameCtrl, 'Nume', Icons.badge_outlined),
          const SizedBox(height: 12),
          _textField(_lastNameCtrl, 'Prenume', Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _textField(
            _usernameCtrl,
            'Username',
            Icons.alternate_email_rounded,
            validator: _usernameValidator,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _birthDateCtrl,
            readOnly: true,
            onTap: _pickDate,
            validator: _required,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _inputDecoration('Data nasterii', Icons.event_rounded),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _classValue,
            dropdownColor: const Color(0xFF071520),
            decoration: _inputDecoration('Clasa', Icons.school_outlined),
            style: const TextStyle(color: AppColors.textPrimary),
            items: [
              for (var i = 5; i <= 12; i++)
                DropdownMenuItem(value: '$i', child: Text('Clasa $i')),
              const DropdownMenuItem(
                value: 'universitate',
                child: Text('Universitate'),
              ),
              const DropdownMenuItem(
                value: 'profesor',
                child: Text('Profesor'),
              ),
            ],
            onChanged: (v) => setState(() => _classValue = v ?? '5'),
          ),
          const SizedBox(height: 12),
          _textField(
            _phoneCtrl,
            'Numar de telefon',
            Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          if (_error != null) _errorBox(),
          const SizedBox(height: 20),
          _primaryButton('Next', Icons.arrow_forward_rounded, _next),
        ],
      ),
    );
  }

  Widget _levelForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _title('Nivelul tau de astronomie'),
        const SizedBox(height: 16),
        _levelTile(
          AstronomyLevel.beginner,
          'Incepator',
          'Înveți astronomie și astrofizică de la 0 la 100',
        ),
        _levelTile(
          AstronomyLevel.intermediate,
          'Intermediar',
          'Cunosc bazele astronomiei și vreau să știu mai multe',
        ),
        _levelTile(
          AstronomyLevel.expert,
          'Expert',
          'Am nevoie de o aplicație care să mă ajute să mă pregătesc de Olimpiada Națională',
        ),
        if (_error != null) _errorBox(),
        const SizedBox(height: 18),
        _primaryButton('Continua', Icons.check_rounded, _finish, busy: _busy),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _busy ? null : () => setState(() => _levelStep = false),
          child: const Text('Inapoi'),
        ),
      ],
    );
  }

  Widget _title(String text) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Bun venit in AstroLab',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );

  Widget _textField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator ?? _required,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: _inputDecoration(label, icon),
    );
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'Camp obligatoriu';
    return null;
  }

  String? _usernameValidator(String? v) {
    final value = v?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return 'Camp obligatoriu';
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(value)) {
      return '3-20 caractere: litere, cifre sau _';
    }
    return null;
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 19),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.16)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.55)),
      ),
    );
  }

  Widget _levelTile(AstronomyLevel level, String title, String subtitle) {
    final selected = _level == level;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _level = level),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.16)
                : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withOpacity(0.55)
                  : AppColors.primary.withOpacity(0.14),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBox() => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      _error!,
      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
    ),
  );

  Widget _primaryButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool busy = false,
  }) {
    return ElevatedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
