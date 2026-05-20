import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../widgets/cosmic_background.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _classValue = '5';
  bool _busy = false;
  bool _loading = true;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final session = await SessionService.load();
    final profile = await AuthService.loadProfile(
      token: session?.token ?? '',
      uid: session?.uid ?? '',
    );

    final firstName =
        profile?['firstName']?.toString() ?? session?.firstName ?? '';
    final lastName =
        profile?['lastName']?.toString() ?? session?.lastName ?? '';
    final username =
        profile?['username']?.toString() ?? session?.username ?? '';
    final birthDate =
        profile?['birthDate']?.toString() ?? session?.birthDate ?? '';
    final phone = profile?['phone']?.toString() ?? session?.phone ?? '';
    final classValue =
        profile?['class']?.toString() ?? session?.classValue ?? '5';

    if (profile != null) {
      await SessionService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        username: username,
        birthDate: birthDate,
        phone: phone,
        classValue: classValue,
      );
    }

    if (!mounted) return;
    setState(() {
      _firstNameCtrl.text = firstName;
      _lastNameCtrl.text = lastName;
      _usernameCtrl.text = username;
      _birthDateCtrl.text = birthDate;
      _phoneCtrl.text = phone;
      _classValue = classValue;
      _loading = false;
    });
  }

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
    final selected = DateTime.tryParse(_birthDateCtrl.text.trim());
    final picked = await showDatePicker(
      context: context,
      initialDate: selected ?? now,
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked == null) return;
    _birthDateCtrl.text =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });

    final session = await SessionService.load();
    final err = await AuthService.saveProfileSetup(
      token: session?.token ?? '',
      uid: session?.uid ?? '',
      profile: {
        'email': session?.email ?? '',
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'birthDate': _birthDateCtrl.text.trim(),
        'class': _classValue,
        'phone': _phoneCtrl.text.trim(),
        'astronomyLevel': session?.astronomyLevel ?? 'beginner',
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

    await SessionService.updateProfile(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      birthDate: _birthDateCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      classValue: _classValue,
    );

    setState(() {
      _busy = false;
      _success = 'Profil actualizat cu succes!';
    });
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
            child: Column(
              children: [
                _buildTopBar(context, isMobile),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 20 : 32,
                            vertical: 24,
                          ),
                          child: Center(
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
                                      color: AppColors.primary.withOpacity(
                                        0.10,
                                      ),
                                      blurRadius: 40,
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Editează profilul',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _textField(
                                        _firstNameCtrl,
                                        'Nume',
                                        Icons.badge_outlined,
                                      ),
                                      const SizedBox(height: 12),
                                      _textField(
                                        _lastNameCtrl,
                                        'Prenume',
                                        Icons.person_outline_rounded,
                                      ),
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
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: _inputDecoration(
                                          'Data nașterii',
                                          Icons.event_rounded,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        value: _classValue,
                                        dropdownColor: const Color(0xFF071520),
                                        decoration: _inputDecoration(
                                          'Clasa',
                                          Icons.school_outlined,
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                        items: [
                                          for (var i = 5; i <= 12; i++)
                                            DropdownMenuItem(
                                              value: '$i',
                                              child: Text('Clasa $i'),
                                            ),
                                          const DropdownMenuItem(
                                            value: 'universitate',
                                            child: Text('Universitate'),
                                          ),
                                          const DropdownMenuItem(
                                            value: 'profesor',
                                            child: Text('Profesor'),
                                          ),
                                        ],
                                        onChanged: (v) => setState(
                                          () => _classValue = v ?? '5',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _textField(
                                        _phoneCtrl,
                                        'Număr de telefon',
                                        Icons.phone_outlined,
                                        keyboardType: TextInputType.phone,
                                      ),
                                      if (_error != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      if (_success != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          child: Text(
                                            _success!,
                                            style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 20),
                                      ElevatedButton.icon(
                                        onPressed: _busy ? null : _save,
                                        icon: _busy
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.check_rounded,
                                                size: 18,
                                              ),
                                        label: const Text(
                                          'Salvează modificările',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF071520).withOpacity(0.90),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Editează profilul',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

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
    if (v == null || v.trim().isEmpty) return 'Câmp obligatoriu';
    return null;
  }

  String? _usernameValidator(String? v) {
    final value = v?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return 'Câmp obligatoriu';
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
}
