import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';

class FeaturesSection extends StatelessWidget {
  final void Function(String) onNavigate;
  const FeaturesSection({super.key, required this.onNavigate});

  static const List<Map<String, dynamic>> _features = [
    {'icon': Icons.play_lesson_rounded,  'title': 'Lecții Interactive',  'desc': 'Conținut vizual cu animații și explicații pas cu pas pentru fiecare concept cosmic.'},
    {'icon': Icons.public_rounded,       'title': 'Simulări Spațiale',   'desc': 'Explorează sistemul solar în 3D, vizualizează găuri negre și simulează fenomene astronomice.'},
    {'icon': Icons.emoji_events_rounded, 'title': 'Provocări și Teste',  'desc': 'Quizuri adaptive și provocări cu niveluri de dificultate personalizate.'},
    {'icon': Icons.nights_stay_rounded,  'title': 'Cerul în Timp Real',  'desc': 'Identifică constelații și planete direct din locația ta cu tehnologie AR.'},
    {'icon': Icons.trending_up_rounded,  'title': 'Progres Gamificat',   'desc': 'Sistem de puncte, insigne și clasamente — avansezi ca într-un joc, înveți ca un astronom.'},
    {'icon': Icons.hub_rounded,          'title': 'Comunitate',          'desc': 'Conectează-te cu alți pasionați și participă la misiuni comune de explorare.'},
  ];

  @override
  Widget build(BuildContext context) {
    final w        = MediaQuery.sizeOf(context).width;
    final isMobile = w < 600;
    final hPad     = isMobile ? 20.0 : (w < 1024 ? 48.0 : 80.0);

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 96),
      child: Column(
        children: [
          _header(isMobile),
          const SizedBox(height: 56),
          _cards(w, isMobile),
        ],
      ),
    );
  }

  Widget _header(bool isMobile) => Column(
    children: [
      const Text('FUNCȚIONALITĂȚI',
          style: TextStyle(
              fontSize: 10, letterSpacing: 4,
              color: AppColors.primary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      Text(
        'Tot ce ai nevoie\npentru a explora cosmosul',
        style: AppTextStyles.sectionTitle.copyWith(
            fontSize: isMobile ? 26 : 34),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 14),
      Text(
        'Instrumente puternice, conținut riguros și o experiență\nde învățare care te face să vrei mai mult.',
        style: AppTextStyles.sectionSubtitle.copyWith(
            fontSize: isMobile ? 14 : 16),
        textAlign: TextAlign.center,
      ),
    ],
  );

  // ── Layout adaptat la lățime, fără aspect ratio fix ──────────────────────
  Widget _cards(double w, bool isMobile) {
    if (isMobile) {
      // Mobile: o coloană, carduri cu înălțime automată (nu grid)
      return Column(
        children: _features
            .map((d) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _FeatureCard(data: d),
        ))
            .toList(),
      );
    }

    // Tabletă și desktop: 2 sau 3 coloane cu IntrinsicHeight
    final cols = w < 1000 ? 2 : 3;
    final rows = <Widget>[];
    for (int i = 0; i < _features.length; i += cols) {
      final rowItems = _features.sublist(i, (i + cols).clamp(0, _features.length));
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rowItems.asMap().entries.map((e) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: e.key == 0 ? 0 : 9, right: e.key == rowItems.length - 1 ? 0 : 9),
                    child: _FeatureCard(data: e.value),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _FeatureCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _FeatureCard({required this.data});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? AppColors.primary.withOpacity(0.45)
                : AppColors.primary.withOpacity(0.1),
            width: _hovered ? 1.5 : 0.5,
          ),
          boxShadow: _hovered
              ? [BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              blurRadius: 28)]
              : [],
        ),
        // Niciun onTap — cardurile sunt doar informative
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(_hovered ? 0.22 : 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(widget.data['icon'] as IconData,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 16),
            Text(widget.data['title'] as String,
                style: AppTextStyles.cardTitle),
            const SizedBox(height: 8),
            Text(widget.data['desc'] as String,
                style: AppTextStyles.cardBody),
          ],
        ),
      ),
    );
  }
}