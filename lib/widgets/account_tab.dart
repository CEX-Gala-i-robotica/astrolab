import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import '../screens/AchievementsScreen.dart';
import '../services/session_service.dart';
import '../screens/profile_edit_screen.dart';
import '../screens/test_history_screen.dart';

class AccountTab extends StatefulWidget {
  final String email;
  final String firstName;
  final String lastName;
  final VoidCallback onSignOut;
  final Future<void> Function() onProfileUpdated;

  const AccountTab({
    super.key,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.onSignOut,
    required this.onProfileUpdated,
  });

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  String _uid   = '';
  String _token = '';

  @override
  void initState() {
    super.initState();
    _loadUidToken();
  }

  Future<void> _loadUidToken() async {
    final session = await SessionService.load();
    if (!mounted) return;
    setState(() {
      _uid   = session?.uid   ?? '';
      _token = session?.token ?? '';
    });
  }

  String get _initials {
    final f  = widget.firstName.trim();
    final l  = widget.lastName.trim();
    final fi = f.isNotEmpty ? f[0].toUpperCase() : '';
    final li = l.isNotEmpty ? l[0].toUpperCase() : '';
    final result = '$fi$li';
    return result.isEmpty
        ? (widget.email.isNotEmpty ? widget.email[0].toUpperCase() : '?')
        : result;
  }

  String get _displayName {
    final f = widget.firstName.trim();
    final l = widget.lastName.trim();
    if (f.isEmpty && l.isEmpty) return 'Utilizator AstroLab';
    return '$f $l'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final width    = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final double maxWidth = width < 480
        ? double.infinity
        : width < 800
        ? width * 0.88
        : 520.0;
    final double hPad = isMobile ? 20 : 48;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionLabel('Contul meu'),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF071520),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 32,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            widget.email,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _sectionLabel('Setări'),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF071520),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _accountRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Profil',
                      subtitle: 'Modifică datele personale',
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileEditScreen(),
                          ),
                        );
                        // Notifică dashboard-ul să reîncarce datele (actualizează și TopBar)
                        await widget.onProfileUpdated();
                      },
                    ),
                    _divider(),
                    _accountRow(
                      icon: Icons.history_rounded,
                      label: 'Istoric teste și exerciții',
                      subtitle: 'Vezi toate rezultatele tale',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TestHistoryScreen(),
                        ),
                      ),
                    ),
                    _divider(),
                    _accountRow(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Realizări',
                      subtitle: 'Vezi certificatele obținute',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AchievementsScreen(
                            uid:       _uid,
                            token:     _token,
                            firstName: widget.firstName,
                            lastName:  widget.lastName,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: widget.onSignOut,
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  'Deconectare',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: Colors.redAccent.withValues(alpha: 0.45),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.06),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.textMuted,
      letterSpacing: 1.4,
    ),
  );

  Widget _divider() => Divider(
    height: 0,
    color: AppColors.primary.withValues(alpha: 0.10),
    indent: 56,
  );

  Widget _accountRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ),
        ),
      );
}