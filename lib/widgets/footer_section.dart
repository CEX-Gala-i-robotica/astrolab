import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import 'glowing_button.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      margin: const EdgeInsets.only(top: 80),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: 80,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.primary.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildCTABlock(isMobile),
          const SizedBox(height: 80),
          _buildBottom(isMobile),
        ],
      ),
    );
  }

  Widget _buildCTABlock(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 32 : 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          const Text(
            'Pregătit să explorezi cosmosul?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Alătură-te a mii de elevi care au descoperit deja\nfrumosul univers prin AstroLab.',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              GlowingButton(label: 'Creează cont gratuit', onPressed: () {}, icon: Icons.rocket_launch_rounded),
              GlowingButton(label: 'Autentificare', onPressed: () {}, outlined: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottom(bool isMobile) {
    return isMobile
        ? Column(children: [_buildLogo(), const SizedBox(height: 24), _buildLinks(), const SizedBox(height: 24), _buildCopyright()])
        : Row(children: [_buildLogo(), const Spacer(), _buildLinks(), const Spacer(), _buildCopyright()]);
  }

  Widget _buildLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
          child: const Icon(Icons.public, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        RichText(
          text: const TextSpan(children: [
            TextSpan(text: 'ASTRO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            TextSpan(text: 'LAB', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.primary)),
          ]),
        ),
      ],
    );
  }

  Widget _buildLinks() {
    final links = ['Acasă', 'Funcții', 'Despre', 'Contact', 'Politică'];
    return Wrap(
      spacing: 24, runSpacing: 8, alignment: WrapAlignment.center,
      children: links.map((l) => TextButton(
        onPressed: () {},
        child: Text(l, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w400)),
      )).toList(),
    );
  }

  Widget _buildCopyright() {
    return const Text('© 2026 AstroLab. Toate drepturile rezervate.',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center);
  }
}