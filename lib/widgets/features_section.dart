import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';

class FeaturesSection extends StatelessWidget {
  final void Function(String) onNavigate;
  const FeaturesSection({super.key, required this.onNavigate});

  static const List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.play_lesson_rounded,
      'title': 'Lecții structurate',
      'desc':
      '69 de lecții organizate pe module și capitole, cu progres salvat automat.',
    },
    {
      'icon': Icons.science_rounded,
      'title': 'Exerciții aplicative',
      'desc':
      'Probleme evaluate pe o scară de la 0 la 100, cu analiză a răspunsurilor și feedback după rezolvare.',
    },
    {
      'icon': Icons.quiz_rounded,
      'title': 'Quiz-uri și teste finale',
      'desc':
      'Quiz-uri de capitol, teste finale de modul și un test inițial pentru stabilirea nivelului de pornire.',
    },
    {
      'icon': Icons.leaderboard_rounded,
      'title': 'Clasamente și prieteni',
      'desc':
      'Puncte pentru lecții, quiz-uri și exerciții, plus clasament global și clasament între prieteni.',
    },
    {
      'icon': Icons.workspace_premium_rounded,
      'title': 'Diplome AstroLab',
      'desc':
      'Certificate PDF pentru capitolele și modulele finalizate, gata de salvat sau de tipărit.',
    },
    {
      'icon': Icons.auto_awesome_rounded,
      'title': 'Colțul curioșilor',
      'desc':
      'Poziții pe cer, eclipse, căutare de stele, fazele Lunii și hărți stelare',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 600;
    final hPad = isMobile ? 20.0 : (w < 1024 ? 48.0 : 80.0);

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
      const Text(
        'FUNCȚIONALITĂȚI',
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 4,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        'Ce poți face\nîn AstroLab',
        style: AppTextStyles.sectionTitle.copyWith(
          fontSize: isMobile ? 26 : 34,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 14),
      Text(
        'Curriculum, evaluări, progres, diplome și instrumente astronomice\nreunite într-o experiență de învățare coerentă și plăcută.',
        style: AppTextStyles.sectionSubtitle.copyWith(
          fontSize: isMobile ? 14 : 16,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _cards(double w, bool isMobile) {
    if (isMobile) {
      return Column(
        children: _features
            .map(
              (data) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _FeatureCard(data: data),
          ),
        )
            .toList(),
      );
    }

    final cols = w < 1000 ? 2 : 3;
    final rows = <Widget>[];
    for (int i = 0; i < _features.length; i += cols) {
      final rowItems = _features.sublist(
        i,
        (i + cols).clamp(0, _features.length),
      );
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rowItems.asMap().entries.map((entry) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: entry.key == 0 ? 0 : 9,
                      right: entry.key == rowItems.length - 1 ? 0 : 9,
                    ),
                    child: _FeatureCard(data: entry.value),
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
      onExit: (_) => setState(() => _hovered = false),
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
              ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              blurRadius: 28,
            ),
          ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(_hovered ? 0.22 : 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                widget.data['icon'] as IconData,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.data['title'] as String,
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: 8),
            Text(widget.data['desc'] as String, style: AppTextStyles.cardBody),
          ],
        ),
      ),
    );
  }
}