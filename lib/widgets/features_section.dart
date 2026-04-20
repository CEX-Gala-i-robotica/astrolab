import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static const List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.play_lesson_rounded,
      'title': 'Lecții Interactive',
      'desc':
      'Conținut vizual captivant cu animații și explicații pas cu pas pentru fiecare concept cosmic.',
    },
    {
      'icon': Icons.public_rounded,
      'title': 'Simulări Spațiale',
      'desc':
      'Explorează sistemul solar în 3D, vizualizează găuri negre și simulează fenomene astronomice.',
    },
    {
      'icon': Icons.emoji_events_rounded,
      'title': 'Provocări și Teste',
      'desc':
      'Evaluează-ți cunoștințele prin quizuri adaptive și provocări cu niveluri de dificultate.',
    },
    {
      'icon': Icons.nights_stay_rounded,
      'title': 'Cerul în Timp Real',
      'desc':
      'Identifică constelații, planete și obiecte cerești direct din locația ta cu AR.',
    },
    {
      'icon': Icons.trending_up_rounded,
      'title': 'Progres Gamificat',
      'desc':
      'Sistem de puncte, insigne și clasamente — avansezi ca într-un joc, înveți ca un astronom.',
    },
    {
      'icon': Icons.hub_rounded,
      'title': 'Comunitate',
      'desc':
      'Conectează-te cu alți pasionați, participă la misiuni comune și schimbă idei.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: 100,
      ),
      child: Column(
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 64),
          _buildGrid(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Column(
      children: [
        Text(
          'FUNCȚIONALITĂȚI',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 4,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tot ce ai nevoie\npentru a explora cosmosul',
          style: AppTextStyles.sectionTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Instrumente puternice, conținut riguros și o experiență\nde învățare care te face să vrei mai mult.',
          style: AppTextStyles.sectionSubtitle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, bool isMobile) {
    final crossCount = isMobile ? 1 : (MediaQuery.of(context).size.width < 1100 ? 2 : 3);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isMobile ? 3.5 : 1.4,
      ),
      itemCount: _features.length,
      itemBuilder: (context, i) => _FeatureCard(data: _features[i]),
    );
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
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.primary.withOpacity(0.1),
            width: _hovered ? 1.5 : 0.5,
          ),
          boxShadow: _hovered
              ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: 0,
            ),
          ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _hovered
                    ? AppColors.primary.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                widget.data['icon'] as IconData,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 20),
            Text(widget.data['title'] as String,
                style: AppTextStyles.cardTitle),
            const SizedBox(height: 10),
            Text(widget.data['desc'] as String, style: AppTextStyles.cardBody),
          ],
        ),
      ),
    );
  }
}