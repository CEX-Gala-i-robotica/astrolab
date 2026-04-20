import 'dart:math';
import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import 'glowing_button.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _planetController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _planetRotation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _planetController = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _planetRotation = Tween<double>(begin: 0, end: 2 * pi).animate(CurvedAnimation(parent: _planetController, curve: Curves.linear));

    Future.delayed(const Duration(milliseconds: 200), () { if (mounted) _fadeController.forward(); });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _planetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;
    final isTablet = size.width < 1024 && size.width >= 768;

    return Container(
      width: double.infinity,
      height: isMobile ? null : size.height,
      constraints: isMobile ? const BoxConstraints(minHeight: 600) : BoxConstraints(minHeight: size.height),
      decoration: const BoxDecoration(color: Color(0xFF020A12)),
      child: Stack(
        children: [
          _buildStarfield(size),
          _buildNebulaGlow(),
          _buildOrbitingPlanet(size, isMobile),
          Padding(
            padding: EdgeInsets.only(
              top: isMobile ? 100 : 0,
              bottom: isMobile ? 60 : 0,
              left: isMobile ? 24 : (isTablet ? 48 : 80),
              right: isMobile ? 24 : (isTablet ? 48 : 80),
            ),
            child: isMobile ? _buildMobileContent() : Center(child: _buildDesktopContent(size)),
          ),
          _buildScrollIndicator(),
        ],
      ),
    );
  }

  Widget _buildStarfield(Size size) {
    return Positioned.fill(child: CustomPaint(painter: _StarfieldPainter()));
  }

  Widget _buildNebulaGlow() {
    return Positioned(
      right: -100, top: -50,
      child: Container(
        width: 600, height: 600,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primary.withOpacity(0.03),
            Colors.transparent,
          ]),
        ),
      ),
    );
  }

  Widget _buildOrbitingPlanet(Size size, bool isMobile) {
    if (isMobile) return const SizedBox.shrink();
    return Positioned(
      right: size.width * 0.05,
      top: size.height * 0.1,
      child: AnimatedBuilder(
        animation: _planetController,
        builder: (context, child) => Transform.rotate(angle: _planetRotation.value * 0.1, child: child),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size.width * 0.38, height: size.width * 0.38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.primary.withOpacity(0.05), Colors.transparent]),
              ),
            ),
            _buildPlanetRing(size.width * 0.32),
            Container(
              width: size.width * 0.28, height: size.width * 0.28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.3, -0.3),
                  colors: [Color(0xFF1A6B8A), Color(0xFF00B4D8), Color(0xFF023E58), Color(0xFF011828)],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 60, spreadRadius: 10)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanetRing(double diameter) {
    return Container(
      width: diameter * 1.5, height: diameter * 0.3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(diameter),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2), width: 2),
        gradient: LinearGradient(colors: [
          AppColors.primary.withOpacity(0.1),
          Colors.transparent,
          AppColors.secondary.withOpacity(0.1),
        ]),
      ),
    );
  }

  Widget _buildDesktopContent(Size size) {
    return Row(
      children: [
        Expanded(
          flex: 55,
          child: AnimatedBuilder(
            animation: _fadeAnim,
            builder: (context, child) => Opacity(
              opacity: _fadeAnim.value,
              child: Transform.translate(offset: Offset(0, _slideAnim.value), child: child),
            ),
            child: _buildTextContent(false),
          ),
        ),
        const Spacer(flex: 45),
      ],
    );
  }

  Widget _buildMobileContent() {
    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, child) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.translate(offset: Offset(0, _slideAnim.value), child: child),
      ),
      child: _buildTextContent(true),
    );
  }

  Widget _buildTextContent(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // FIX: color mutat în BoxDecoration, nu separat
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text(
                'Platformă educațională interactivă',
                style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w500, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: 'Explorează\nUniversul\n', style: AppTextStyles.heroTitle.copyWith(fontSize: isMobile ? 38 : 56)),
              TextSpan(text: 'ca Niciodată\nÎnainte', style: AppTextStyles.heroTitleAccent.copyWith(fontSize: isMobile ? 38 : 56)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'O platformă de învățare interactivă pentru astronomie\nși astrofizică — lecții imersive, simulări spațiale\nși provocări gamificate pentru toți curioșii cosmosului.',
          style: AppTextStyles.heroSubtitle.copyWith(fontSize: isMobile ? 15 : 18),
        ),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16, runSpacing: 16,
          children: [
            GlowingButton(label: 'Începe Acum', onPressed: () {}, icon: Icons.rocket_launch_rounded),
            GlowingButton(label: 'Află Mai Mult', onPressed: () {}, outlined: true),
          ],
        ),
        const SizedBox(height: 56),
        _buildStats(),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _buildStat('10K+', 'Elevi activi'),
        _buildStatDivider(),
        _buildStat('200+', 'Lecții'),
        _buildStatDivider(),
        _buildStat('50+', 'Simulări'),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w400)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1, height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: AppColors.primary.withOpacity(0.2),
    );
  }

  Widget _buildScrollIndicator() {
    return Positioned(
      bottom: 32, left: 0, right: 0,
      child: Center(
        child: Column(
          children: [
            const Text('Derulează', style: TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 2)),
            const SizedBox(height: 8),
            Container(
              width: 1, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary.withOpacity(0.6), Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(42);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 150; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 1.5 + 0.3;
      final opacity = rnd.nextDouble() * 0.7 + 0.1;
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}