import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import 'app_planet_logo.dart';
import 'glowing_button.dart';

class Navbar extends StatefulWidget {
  final ScrollController scrollController;
  final void Function(String section) onNavigate;

  const Navbar({
    super.key,
    required this.scrollController,
    required this.onNavigate,
  });

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  bool _isScrolled = false;
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = widget.scrollController.offset > 40;
    if (scrolled != _isScrolled) {
      setState(() {
        _isScrolled = scrolled;
        if (scrolled) _menuOpen = false;
      });
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 900;
    final blur = _isScrolled ? 26.0 : 18.0;
    final bgAlpha = _isScrolled ? 0.13 : 0.07;
    final bdAlpha = _isScrolled ? 0.26 : 0.14;
    final bottomR = (isMobile && _menuOpen) ? 18.0 : 34.0;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(34),
        bottom: Radius.circular(bottomR),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(bgAlpha),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(34),
              bottom: Radius.circular(bottomR),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(bdAlpha),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isScrolled ? 0.42 : 0.20),
                blurRadius: _isScrolled ? 32 : 18,
                offset: const Offset(0, 12),
                spreadRadius: -8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: isMobile ? 56 : 62,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 22),
                  child: Row(
                    children: [
                      _logo(isMobile),
                      if (isMobile) ...[
                        const Spacer(),
                        _hamburger(),
                      ] else
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _link('Acasă', 'hero'),
                              _link('Funcții', 'features'),
                              _link('Despre', 'about'),
                              const SizedBox(width: 14),
                              GlowingButton(
                                label: 'Intră în platformă',
                                onPressed: () => widget.onNavigate('login'),
                                icon: Icons.rocket_launch_rounded,
                                compact: true,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (isMobile && _menuOpen) _mobileMenu(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────────────
  Widget _logo(bool compact) {
    final sz = compact ? 32.0 : 36.0;
    return GestureDetector(
      onTap: () => widget.onNavigate('hero'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Planet logo — usa asset sau fallback vectorial
          ClipOval(child: AppPlanetLogo(size: sz)),
          const SizedBox(width: 10),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'ASTRO',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
                TextSpan(
                  text: 'LAB',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _link(String label, String section) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: TextButton(
      onPressed: () => widget.onNavigate(section),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        overlayColor: AppColors.primary.withOpacity(0.08),
      ),
      child: Text(label, style: AppTextStyles.navLabel),
    ),
  );

  Widget _hamburger() => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => setState(() => _menuOpen = !_menuOpen),
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _menuOpen ? Icons.close_rounded : Icons.menu_rounded,
              key: ValueKey(_menuOpen),
              color: AppColors.textPrimary,
              size: 26,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _mobileMenu() => Padding(
    padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: AppColors.primary.withOpacity(0.15)),
        const SizedBox(height: 4),
        _mobileLink('Acasă', 'hero'),
        _mobileLink('Funcții', 'features'),
        _mobileLink('Despre', 'about'),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GlowingButton(
            label: 'Intră în platformă',
            onPressed: () {
              setState(() => _menuOpen = false);
              widget.onNavigate('login');
            },
            icon: Icons.rocket_launch_rounded,
          ),
        ),
      ],
    ),
  );

  Widget _mobileLink(String label, String section) => TextButton(
    style: TextButton.styleFrom(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      foregroundColor: AppColors.textSecondary,
    ),
    onPressed: () {
      setState(() => _menuOpen = false);
      widget.onNavigate(section);
    },
    child: Text(label, style: AppTextStyles.navLabel),
  );
}
