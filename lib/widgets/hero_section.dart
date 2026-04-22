import 'dart:math';
import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import 'glowing_button.dart';

class HeroSection extends StatefulWidget {
  final void Function(String) onNavigate;
  const HeroSection({super.key, required this.onNavigate});

  @override
  State<HeroSection> createState() => HeroSectionState();
}

class HeroSectionState extends State<HeroSection>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _planetCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _orbitCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;

  bool _showScrollHint = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _planetCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 50))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<double>(begin: 36, end: 0).animate(
        CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 150),
            () { if (mounted) _fadeCtrl.forward(); });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _planetCtrl.dispose();
    _pulseCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  void onScroll(double offset) {
    if (offset > 40 && _showScrollHint) {
      setState(() => _showScrollHint = false);
    } else if (offset <= 40 && !_showScrollHint) {
      setState(() => _showScrollHint = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      height: isMobile ? null : size.height,
      constraints: isMobile ? BoxConstraints(minHeight: size.height) : null,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (!isMobile) _planet(size, isTablet),
          _content(size, isMobile, isTablet),
          if (!isMobile)
            AnimatedOpacity(
              opacity: _showScrollHint ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Align(
                alignment: Alignment(0, 0.85),
                child: _scrollHint(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _planet(Size screen, bool isTablet) {
    final pR = (screen.width * (isTablet ? 0.16 : 0.18))
        .clamp(80.0, screen.height * 0.42);
    final cx = screen.width * 0.74;
    final cy = screen.height * 0.50;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([_planetCtrl, _pulseCtrl, _orbitCtrl]),
        builder: (_, __) {
          final pulse = 0.93 + 0.07 * sin(_pulseCtrl.value * pi);
          final orbitAngle = _orbitCtrl.value * 2 * pi;
          final surfAngle = _planetCtrl.value * 2 * pi;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: cx - pR * 1.5,
                top: cy - pR * 1.5,
                child: Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: pR * 3.0,
                    height: pR * 3.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppColors.primary.withOpacity(0.0),
                        AppColors.primary.withOpacity(0.05 * pulse),
                        Colors.transparent,
                      ], stops: const [0.4, 0.65, 1.0]),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: cx - pR * 1.38,
                top: cy - pR * 0.26,
                child: Transform.rotate(
                  angle: -0.22,
                  child: Container(
                    width: pR * 2.76,
                    height: pR * 0.52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(pR),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.22), width: 1.2),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: cx - pR * 1.10,
                top: cy - pR * 0.20,
                child: Transform.rotate(
                  angle: -0.22,
                  child: Container(
                    width: pR * 2.20,
                    height: pR * 0.40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(pR),
                      border: Border.all(color: AppColors.primary.withOpacity(0.13), width: 0.8),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: cx - pR * 1.38,
                top: cy - pR * 1.38,
                child: SizedBox(
                  width: pR * 2.76,
                  height: pR * 2.76,
                  child: CustomPaint(painter: _MoonPainter(
                    angle: orbitAngle,
                    moonR: pR * 0.105,
                    orbitRx: pR * 1.35,
                    orbitRy: pR * 0.32,
                    tilt: -0.22,
                    color: AppColors.light,
                    glowColor: AppColors.secondary,
                  )),
                ),
              ),
              Positioned(
                left: cx - pR * 1.10,
                top: cy - pR * 1.10,
                child: SizedBox(
                  width: pR * 2.20,
                  height: pR * 2.20,
                  child: CustomPaint(painter: _MoonPainter(
                    angle: -orbitAngle * 0.65 + pi * 0.7,
                    moonR: pR * 0.072,
                    orbitRx: pR * 1.07,
                    orbitRy: pR * 0.25,
                    tilt: -0.22,
                    color: AppColors.secondary,
                    glowColor: AppColors.primary,
                  )),
                ),
              ),
              Positioned(
                left: cx - pR,
                top: cy - pR,
                child: Container(
                  width: pR * 2,
                  height: pR * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.35, -0.35),
                      radius: 1.0,
                      colors: [
                        Color(0xFF52D4F0),
                        Color(0xFF00B4D8),
                        Color(0xFF006E8A),
                        Color(0xFF013850),
                        Color(0xFF010F1A),
                      ],
                      stops: [0.0, 0.25, 0.55, 0.80, 1.0],
                    ),
                    boxShadow: [BoxShadow(
                      color: AppColors.primary.withOpacity(0.28 + 0.10 * sin(_pulseCtrl.value * pi)),
                      blurRadius: pR * 0.5,
                      spreadRadius: pR * 0.03,
                    )],
                  ),
                  child: ClipOval(child: CustomPaint(painter: _SwirlPainter(progress: surfAngle))),
                ),
              ),
              Positioned(
                left: cx - pR,
                top: cy - pR,
                child: Container(
                  width: pR * 2,
                  height: pR * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(0.65, 0.65),
                      radius: 0.85,
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withOpacity(0.06),
                        AppColors.primary.withOpacity(0.13),
                      ],
                      stops: const [0.45, 0.78, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _content(Size size, bool isMobile, bool isTablet) {
    final hPad = isMobile ? 24.0 : (isTablet ? 48.0 : 80.0);
    final rPad = isMobile ? hPad : isTablet ? hPad : size.width * 0.40;

    if (isMobile) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(hPad, 120, rPad, 120),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              _animContent(isMobile, includeScrollHint: true),
            ],
          ),
        ),
      );
    }

    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, 80, rPad, 80),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _animContent(isMobile, includeScrollHint: false),
        ),
      ),
    );
  }

  Widget _animContent(bool isMobile, {required bool includeScrollHint}) => AnimatedBuilder(
    animation: _fadeAnim,
    builder: (_, child) => Opacity(
      opacity: _fadeAnim.value,
      child: Transform.translate(offset: Offset(0, _slideAnim.value), child: child),
    ),
    child: _textBody(isMobile, includeScrollHint: includeScrollHint),
  );

  Widget _textBody(bool isMobile, {required bool includeScrollHint}) {
    final ts = isMobile ? 34.0 : 52.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.09),
            border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.6 + 0.4 * sin(_pulseCtrl.value * pi)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Platformă educațională interactivă',
                style: TextStyle(fontSize: 12, color: AppColors.secondary)),
          ]),
        ),
        const SizedBox(height: 24),
        RichText(text: TextSpan(children: [
          TextSpan(text: 'Explorează\nUniversul\n',
              style: AppTextStyles.heroTitle.copyWith(fontSize: ts)),
          TextSpan(text: 'ca Niciodată\nÎnainte',
              style: AppTextStyles.heroTitleAccent.copyWith(fontSize: ts)),
        ])),
        const SizedBox(height: 20),
        Text(
          'Lecții imersive, simulări spațiale 3D și provocări\ngamificate pentru toți curioșii cosmosului.',
          style: AppTextStyles.heroSubtitle.copyWith(fontSize: isMobile ? 14 : 16),
        ),
        const SizedBox(height: 32),
        Wrap(spacing: 12, runSpacing: 12, children: [
          GlowingButton(
            label: 'Intră în platformă',
            onPressed: () => widget.onNavigate('login'),
            icon: Icons.rocket_launch_rounded,
          ),
          GlowingButton(
            label: 'Descoperă',
            onPressed: () => widget.onNavigate('features'),
            outlined: true,
            icon: Icons.explore_rounded,
          ),
        ]),
        const SizedBox(height: 44),
        _stats(),
        if (includeScrollHint) ...[
          const SizedBox(height: 40),
          AnimatedOpacity(
            opacity: _showScrollHint ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: Center(child: _scrollHint()),
          ),
        ],
      ],
    );
  }

  Widget _stats() => Wrap(
    spacing: 0,
    runSpacing: 16,
    children: [
      _stat('10K+', 'Elevi activi'),
      _div(),
      _stat('200+', 'Lecții'),
      _div(),
      _stat('50+', 'Simulări'),
    ],
  );

  Widget _stat(String v, String l) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
      Text(l, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
    ],
  );

  Widget _div() => Container(
    width: 1,
    height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 20),
    color: AppColors.primary.withOpacity(0.2),
  );

  Widget _scrollHint() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Derulează',
          style: TextStyle(fontSize: 10, color: AppColors.textMuted, letterSpacing: 2)),
      const SizedBox(height: 6),
      Container(
        width: 1,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withOpacity(0.6), Colors.transparent],
          ),
        ),
      ),
    ],
  );
}

class _MoonPainter extends CustomPainter {
  final double angle, moonR, orbitRx, orbitRy, tilt;
  final Color color, glowColor;
  _MoonPainter({
    required this.angle,
    required this.moonR,
    required this.orbitRx,
    required this.orbitRy,
    required this.tilt,
    required this.color,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final rawX = orbitRx * cos(angle), rawY = orbitRy * sin(angle);
    final mx = cx + rawX * cos(tilt) - rawY * sin(tilt);
    final my = cy + rawX * sin(tilt) + rawY * cos(tilt);
    canvas.drawCircle(Offset(mx, my), moonR * 2.0,
        Paint()..color = glowColor.withOpacity(0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(Offset(mx, my), moonR,
        Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _MoonPainter old) => old.angle != angle;
}

class _SwirlPainter extends CustomPainter {
  final double progress;
  _SwirlPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final p = Paint()..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.016..strokeCap = StrokeCap.round;
    for (int i = 0; i < 6; i++) {
      p.color = Colors.white.withOpacity(0.05 + 0.04 * sin(progress * 2 + i));
      final path = Path();
      bool first = true;
      for (double t = 0; t <= 1.0; t += 0.025) {
        final a = progress + i * pi / 3 + t * pi * 1.4;
        final r = size.width * 0.08 + t * size.width * 0.40;
        final x = cx + cos(a) * r;
        final y = cy + sin(a) * r * 0.62;
        if (first) {
          path.moveTo(x, y);
          first = false;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _SwirlPainter old) => old.progress != progress;
}