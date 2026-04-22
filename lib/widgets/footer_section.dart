import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import 'app_planet_logo.dart';
import 'glowing_button.dart';

class FooterSection extends StatelessWidget {
  final void Function(String) onNavigate;
  const FooterSection({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final w        = MediaQuery.sizeOf(context).width;
    final isMobile = w < 600;
    final hPad     = isMobile ? 20.0 : (w < 1024 ? 48.0 : 80.0);

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(hPad, 80, hPad, 48),
      child: Column(
        children: [
          _cta(isMobile),
          const SizedBox(height: 72),
          _bottom(context, isMobile),
        ],
      ),
    );
  }

  Widget _cta(bool isMobile) => Container(
    padding: EdgeInsets.all(isMobile ? 28 : 56),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withOpacity(0.14),
          AppColors.primary.withOpacity(0.04),
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
    ),
    child: Column(
      children: [
        Text(
          'Pregătit să explorezi cosmosul?',
          style: TextStyle(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        const Text(
          'Alătură-te a mii de elevi care au descoperit deja\nfrumosul univers prin AstroLab.',
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        GlowingButton(
          label: 'Intră în platformă',
          onPressed: () => onNavigate('login'),
          icon: Icons.rocket_launch_rounded,
        ),
      ],
    ),
  );

  Widget _bottom(BuildContext context, bool isMobile) {
    final logo   = _logo();
    // Exact aceleași linkuri ca în navbar, cu aceleași acțiuni
    final links  = _navLinks();
    final copy   = const Text(
      '© 2025 AstroLab. Toate drepturile rezervate.',
      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
      textAlign: TextAlign.center,
    );

    if (isMobile) {
      return Column(
        children: [
          logo,
          const SizedBox(height: 24),
          links,
          const SizedBox(height: 20),
          copy,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logo,
        const Spacer(),
        links,
        const Spacer(),
        copy,
      ],
    );
  }

  Widget _logo() => GestureDetector(
    onTap: () => onNavigate('hero'),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(child: AppPlanetLogo(size: 34)),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(children: [
            TextSpan(
              text: 'ASTRO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 0.8,
              ),
            ),
            TextSpan(
              text: 'LAB',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
          ]),
        ),
      ],
    ),
  );

  // Exact aceleași linkuri + acțiuni ca navbar
  Widget _navLinks() => Wrap(
    spacing: 8,
    runSpacing: 4,
    alignment: WrapAlignment.center,
    children: [
      _link('Acasă',   'hero'),
      _link('Funcții', 'features'),
      _link('Despre',  'about'),
    ],
  );

  Widget _link(String label, String section) => TextButton(
    onPressed: () => onNavigate(section),
    style: TextButton.styleFrom(
      foregroundColor: AppColors.textMuted,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
    ),
  );
}