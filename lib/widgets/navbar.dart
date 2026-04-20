import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import 'app_planet_logo.dart';
import 'glowing_button.dart';

class Navbar extends StatefulWidget {
  final ScrollController scrollController;

  const Navbar({super.key, required this.scrollController});

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> {
  static const double _scrollThreshold = 50;

  bool _isScrolled = false;
  bool _menuOpen = false;

  late final VoidCallback _onScroll;

  @override
  void initState() {
    super.initState();
    _onScroll = _handleScroll;
    widget.scrollController.addListener(_onScroll);
    _isScrolled = widget.scrollController.offset > _scrollThreshold;
  }

  void _handleScroll() {
    final next = widget.scrollController.offset > _scrollThreshold;
    if (next != _isScrolled || _menuOpen) {
      setState(() {
        _isScrolled = next;
        if (next) _menuOpen = false;
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
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 768;

    // Apple-like glass: very clear, subtle white tint + strong blur.
    final blur = _isScrolled ? 26.0 : 18.0;
    final fill = _isScrolled
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.06);
    final borderColor = _isScrolled
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.14);

    final bottomRadius = isMobile && _menuOpen ? 20.0 : 36.0;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(36),
        bottom: Radius.circular(bottomRadius),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(36),
              bottom: Radius.circular(bottomRadius),
            ),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: _isScrolled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                      spreadRadius: -8,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                      spreadRadius: -10,
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: isMobile ? 56 : 58,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
                  child: Row(
                    children: [
                      _buildLogo(isMobile),
                      if (isMobile) const Spacer(),
                      if (isMobile)
                        _buildHamburger()
                      else
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildNavLink('Acasă'),
                                  _buildNavLink('Funcții'),
                                  _buildNavLink('Despre'),
                                  const SizedBox(width: 12),
                                  _buildAuthButtons(false),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (isMobile && _menuOpen) _buildMobileMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(bool compact) {
    final logoSize = compact ? 34.0 : 38.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: AppPlanetLogo(size: logoSize),
        ),
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
    );
  }

  Widget _buildHamburger() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _menuOpen = !_menuOpen),
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
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
  }

  Widget _buildMobileMenu() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 6),
          _mobileLink('Acasă'),
          _mobileLink('Funcții'),
          _mobileLink('Despre'),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: () => setState(() => _menuOpen = false),
                child: const Text(
                  'Autentificare',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GlowingButton(
                label: 'Înregistrare',
                onPressed: () => setState(() => _menuOpen = false),
                compact: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mobileLink(String label) {
    return TextButton(
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () => setState(() => _menuOpen = false),
      child: Text(label, style: AppTextStyles.navLabel),
    );
  }

  Widget _buildNavLink(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextButton(
        onPressed: () {},
        child: Text(label, style: AppTextStyles.navLabel),
      ),
    );
  }

  Widget _buildAuthButtons(bool compact) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () {},
          child: const Text(
            'Autentificare',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: compact ? 4 : 8),
        GlowingButton(
          label: 'Înregistrare',
          onPressed: () {},
          compact: compact,
        ),
      ],
    );
  }
}
