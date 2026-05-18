import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../widgets/app_planet_logo.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/lessons_tab.dart';

class DashboardScreen extends StatefulWidget {
  final String email;
  final String uid;
  final bool   needsProfileSetup;

  const DashboardScreen({
    super.key,
    required this.email,
    required this.uid,
    this.needsProfileSetup = false,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  Future<void> _signOut(BuildContext context) async {
    await SessionService.clear();
    await AuthService.signOutGoogle();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF071520),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.primary.withOpacity(0.25)),
        ),
        title: const Text('Deconectare',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Ești sigur că vrei să te deconectezi?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anulează',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _signOut(context);
            },
            child: const Text('Deconectează',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const LessonsTab();
      case 1:
        return const _PlaceholderTab(
            icon: Icons.view_in_ar_rounded, label: 'Laborator VR');
      case 2:
        return const _PlaceholderTab(
            icon: Icons.leaderboard_rounded, label: 'Clasament');
      case 3:
        return _AccountTab(
          email: widget.email,
          onSignOut: () => _confirmSignOut(context),
        );
      default:
        return const SizedBox.expand();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width    = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const CosmicBackground(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(email: widget.email, isMobile: isMobile),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String email;
  final bool   isMobile;

  const _TopBar({required this.email, required this.isMobile});

  @override
  Widget build(BuildContext context) {
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
          ClipOval(child: AppPlanetLogo(size: isMobile ? 30 : 34)),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'ASTRO',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
              TextSpan(
                text: 'LAB',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 0.8,
                ),
              ),
            ]),
          ),
          const Spacer(),
          Container(
            width: isMobile ? 32 : 36,
            height: isMobile ? 32 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.18),
              border:
              Border.all(color: AppColors.primary.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                email.isNotEmpty ? email[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Account Tab ───────────────────────────────────────────────────────────────

class _AccountTab extends StatelessWidget {
  final String       email;
  final VoidCallback onSignOut;

  const _AccountTab({required this.email, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final width    = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    // Lățime conținut: full pe mobil mic, 88% tablet, max 520 desktop
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

              // ── Card identitate utilizator ──
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF071520),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.28), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
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
                        color: AppColors.primary.withOpacity(0.14),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.45),
                            width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          email.isNotEmpty
                              ? email[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 22,
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
                          const Text(
                            'Utilizator AstroLab',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            email,
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

              // ── Card acțiuni ──
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF071520),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.18), width: 1),
                ),
                child: Column(
                  children: [
                    _accountRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Profil',
                      onTap: () {},
                    ),
                    _divider(),
                    _accountRow(
                      icon: Icons.notifications_outlined,
                      label: 'Notificări',
                      onTap: () {},
                    ),
                    _divider(),
                    _accountRow(
                      icon: Icons.lock_outline_rounded,
                      label: 'Securitate',
                      onTap: () {},
                    ),
                    _divider(),
                    _accountRow(
                      icon: Icons.help_outline_rounded,
                      label: 'Ajutor & Suport',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Buton deconectare ──
              OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded,
                    size: 18, color: Colors.redAccent),
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
                      color: Colors.redAccent.withOpacity(0.45), width: 1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  backgroundColor: Colors.redAccent.withOpacity(0.06),
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
    color: AppColors.primary.withOpacity(0.10),
    indent: 56,
  );

  Widget _accountRow({
    required IconData     icon,
    required String       label,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 18),
            ],
          ),
        ),
      );
}

// ── Placeholder Tab ───────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String   label;

  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 52, color: AppColors.primary.withOpacity(0.30)),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'În curând',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  final int               selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.menu_book_rounded,   label: 'Lecții'),
    _NavItem(icon: Icons.view_in_ar_rounded,  label: 'Laborator VR'),
    _NavItem(icon: Icons.leaderboard_rounded, label: 'Clasament'),
    _NavItem(icon: Icons.person_rounded,      label: 'Profilul meu'),
  ];

  @override
  Widget build(BuildContext context) {
    final width    = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071520),
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withOpacity(0.20),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: isMobile ? 62 : 68,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item     = _items[i];
              final selected = i == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  splashColor: AppColors.primary.withOpacity(0.10),
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Linie indicator sus
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        width: selected ? 20 : 0,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      AnimatedScale(
                        scale: selected ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          item.icon,
                          size: isMobile ? 21 : 23,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isMobile ? 9.5 : 10.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMuted,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String   label;
  const _NavItem({required this.icon, required this.label});
}