import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:astrolab/theme/app_theme.dart';
import '../widgets/navbar.dart';
import '../widgets/hero_section.dart';
import '../widgets/features_section.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/about_section.dart';
import '../widgets/download_section.dart';
import '../widgets/footer_section.dart';
import '../widgets/cosmic_background.dart';
import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../services/session_service.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scroll = ScrollController();
  final _heroKey = GlobalKey<HeroSectionState>();
  final _featuresKey = GlobalKey();
  final _aboutKey = GlobalKey();
  bool _openingPlatform = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    // Notifică HeroSection să ascundă/arate scroll hint
    _heroKey.currentState?.onScroll(_scroll.offset);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _handleNavigate(String section) {
    switch (section) {
      case 'login':
        _enterPlatform();
        break;
      case 'hero':
        _scrollTo(_heroKey);
        break;
      case 'features':
        _scrollTo(_featuresKey);
        break;
      case 'about':
        _scrollTo(_aboutKey);
        break;
    }
  }

  Future<void> _enterPlatform() async {
    if (_openingPlatform) return;
    setState(() => _openingPlatform = true);

    final session = await SessionService.load();
    if (!mounted) return;

    if (session != null &&
        session.rememberMe &&
        session.loggedIn &&
        session.uid.isNotEmpty) {
      var token = session.idToken;
      var refreshToken = session.refreshToken;
      if (refreshToken.isNotEmpty) {
        final refreshed = await AuthService.refreshSession(refreshToken);
        if (refreshed.ok) {
          token = refreshed.idToken ?? token;
          refreshToken = refreshed.refreshToken ?? refreshToken;
          await SessionService.save(
            email: session.email,
            idToken: token,
            uid: session.uid,
            rememberMe: true,
            refreshToken: refreshToken,
          );
        }
      }

      if (token.isNotEmpty) {
        await ProgressService.configureRemote(uid: session.uid, token: token);
        final needsSetup = await AuthService.needsProfileSetup(
          token,
          session.uid,
        );
        if (!mounted) return;
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => DashboardScreen(
              email: session.email,
              uid: session.uid,
              idToken: token,
              needsProfileSetup: needsSetup,
            ),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        setState(() => _openingPlatform = false);
        return;
      }
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    if (mounted) setState(() => _openingPlatform = false);
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  double _navPad(double w) {
    if (w < 600) return 16;
    if (w < 1024) return 40;
    return 72;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hPad = _navPad(w);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Fundal cosmic animat — acoperă toată pagina
          const CosmicBackground(),
          // Conținut scrollabil
          CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    HeroSection(key: _heroKey, onNavigate: _handleNavigate),
                    FeaturesSection(
                      key: _featuresKey,
                      onNavigate: _handleNavigate,
                    ),
                    HowItWorksSection(onNavigate: _handleNavigate),
                    AboutSection(key: _aboutKey, onNavigate: _handleNavigate),
                    if (kIsWeb) const DownloadSection(),
                    FooterSection(onNavigate: _handleNavigate),
                  ],
                ),
              ),
            ],
          ),
          // Navbar floating
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
                child: Navbar(
                  scrollController: _scroll,
                  onNavigate: _handleNavigate,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
