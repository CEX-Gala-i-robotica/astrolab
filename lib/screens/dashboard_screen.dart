import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/curriculum_repository.dart';
import '../services/progress_service.dart';
import '../services/session_service.dart';
import '../widgets/app_planet_logo.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/lessons_tab.dart';
import '../widgets/account_tab.dart';
import 'curiosity_corner_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_setup_screen.dart';
import 'quiz_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String email;
  final String uid;
  final String idToken;
  final bool needsProfileSetup;

  const DashboardScreen({
    super.key,
    required this.email,
    required this.uid,
    this.idToken = '',
    this.needsProfileSetup = false,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late bool _needsProfileSetup;
  String _firstName = '';
  String _lastName  = '';
  String _email     = '';

  @override
  void initState() {
    super.initState();
    _email             = widget.email;
    _needsProfileSetup = widget.needsProfileSetup;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final session = await SessionService.load();
    final profile = await AuthService.loadProfile(
      token: session?.token ?? '',
      uid:   session?.uid   ?? '',
    );

    final firstName  = profile?['firstName']?.toString() ?? session?.firstName  ?? '';
    final lastName   = profile?['lastName']?.toString()  ?? session?.lastName   ?? '';
    final email      = profile?['email']?.toString()     ?? session?.email      ?? widget.email;
    final username   = profile?['username']?.toString()  ?? session?.username   ?? '';
    final birthDate  = profile?['birthDate']?.toString() ?? session?.birthDate  ?? '';
    final phone      = profile?['phone']?.toString()     ?? session?.phone      ?? '';
    final classValue = profile?['class']?.toString()     ?? session?.classValue ?? '5';

    if (profile != null) {
      await SessionService.updateProfile(
        firstName:  firstName,
        lastName:   lastName,
        username:   username,
        birthDate:  birthDate,
        phone:      phone,
        classValue: classValue,
      );
    }

    if (!mounted) return;
    setState(() {
      _firstName = firstName;
      _lastName  = lastName;
      _email     = email;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await SessionService.clear();
    ProgressService.clearRemoteSession();
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
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        title: const Text(
          'Deconectare',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Ești sigur că vrei să te deconectezi?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Anulează',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _signOut(context);
            },
            child: const Text(
              'Deconectează',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_needsProfileSetup) {
      return ProfileSetupScreen(
        token: widget.idToken,
        uid: widget.uid,
        email: widget.email,
        onComplete: _handleSetupComplete,
      );
    }

    // 0 → Lecții, 1 → Clasament, 2 → Colțul curioșilor, 3 → Profilul meu
    switch (_selectedIndex) {
      case 0:
        return const LessonsTab();
      case 1:
        return LeaderboardScreen(uid: widget.uid, token: widget.idToken);
      case 2:
        return const CuriosityCornerScreen();
      case 3:
        return AccountTab(
          email: _email,
          firstName: _firstName,
          lastName: _lastName,
          onSignOut: () => _confirmSignOut(context),
          onProfileUpdated: _loadProfileData,
        );
      default:
        return const SizedBox.expand();
    }
  }

  Future<void> _handleSetupComplete(AstronomyLevel level) async {
    if (level == AstronomyLevel.beginner) {
      await ProgressService.saveCurrentStudy(
        moduleNumber: 1,
        chapterNumber: 1,
        lessonIndex: 0,
        type: 'lesson',
      );
      if (mounted) setState(() => _needsProfileSetup = false);
      return;
    }

    final moduleNumber = level == AstronomyLevel.intermediate ? 1 : 2;
    final module = await CurriculumRepository.loadModule(moduleNumber);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          chapterTitle: 'Evaluare de plasament',
          questions: module.finalQuiz,
          finalQuizModuleNumber: moduleNumber,
          isInitialPlacementQuiz: true,
        ),
      ),
    );
    if (mounted) setState(() => _needsProfileSetup = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_needsProfileSetup) {
      return ProfileSetupScreen(
        token: widget.idToken,
        uid: widget.uid,
        email: widget.email,
        onComplete: _handleSetupComplete,
      );
    }

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
                _TopBar(
                  email: _email,
                  firstName: _firstName,
                  lastName: _lastName,
                  isMobile: isMobile,
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _needsProfileSetup
          ? null
          : _BottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String email;
  final String firstName;
  final String lastName;
  final bool isMobile;

  const _TopBar({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isMobile,
  });

  String get _initials {
    final f  = firstName.trim();
    final l  = lastName.trim();
    final fi = f.isNotEmpty ? f[0].toUpperCase() : '';
    final li = l.isNotEmpty ? l[0].toUpperCase() : '';
    final result = '$fi$li';
    return result.isEmpty
        ? (email.isNotEmpty ? email[0].toUpperCase() : '?')
        : result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF071520).withValues(alpha: 0.90),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          ClipOval(child: AppPlanetLogo(size: isMobile ? 30 : 34)),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              children: [
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
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: isMobile ? 32 : 36,
            height: isMobile ? 32 : 36,
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
                style: TextStyle(
                  fontSize: isMobile ? 11 : 13,
                  fontWeight: FontWeight.w800,
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

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.selectedIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.menu_book_rounded,       label: 'Lecții'),
    _NavItem(icon: Icons.leaderboard_rounded,     label: 'Clasament'),
    _NavItem(icon: Icons.psychology_alt_rounded,  label: 'Colțul curioșilor'),
    _NavItem(icon: Icons.person_rounded,          label: 'Profilul meu'),
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
            color: AppColors.primary.withValues(alpha: 0.20),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.07),
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
                  splashColor: AppColors.primary.withValues(alpha: 0.10),
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
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
  final String label;
  const _NavItem({required this.icon, required this.label});
}