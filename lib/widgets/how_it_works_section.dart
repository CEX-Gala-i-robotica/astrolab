import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  static const List<Map<String, String>> _steps = [
    {
      'number': '01',
      'title': 'Creează cont',
      'desc': 'Înregistrare rapidă — email, Google sau Apple. Fără abonamente ascunse.',
    },
    {
      'number': '02',
      'title': 'Alege traseul tău',
      'desc': 'Sistem solar, stele, cosmologie sau astrofizică avansată. Tu decizi.',
    },
    {
      'number': '03',
      'title': 'Completează lecții',
      'desc': 'Lecții scurte, simulări interactive și provocări după fiecare capitol.',
    },
    {
      'number': '04',
      'title': 'Urmărește progresul',
      'desc': 'Dashboard personal cu statistici detaliate, insigne câștigate și obiective.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 80,
        vertical: 100,
      ),
      color: AppColors.background,
      child: Column(
        children: [
          Text(
            'CUM FUNCȚIONEAZĂ',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 4,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '4 pași simpli spre\nstele',
            style: AppTextStyles.sectionTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),
          isMobile
              ? _buildVertical()
              : _buildHorizontal(),
        ],
      ),
    );
  }

  Widget _buildHorizontal() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 28),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.4),
                      AppColors.primary.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return Expanded(
          flex: 3,
          child: _StepCard(data: _steps[i ~/ 2]),
        );
      }),
    );
  }

  Widget _buildVertical() {
    return Column(
      children: _steps.map((step) {
        final isLast = step == _steps.last;
        return Column(
          children: [
            _StepCard(data: step, horizontal: true),
            if (!isLast) ...[
              const SizedBox(height: 0),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.only(left: 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.5),
                      AppColors.primary.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      }).toList(),
    );
  }
}

class _StepCard extends StatelessWidget {
  final Map<String, String> data;
  final bool horizontal;

  const _StepCard({required this.data, this.horizontal = false});

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNumber(),
          const SizedBox(width: 20),
          Expanded(child: _buildText()),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNumber(),
        const SizedBox(height: 20),
        _buildText(),
      ],
    );
  }

  Widget _buildNumber() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.2),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          data['number']!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data['title']!, style: AppTextStyles.cardTitle),
        const SizedBox(height: 8),
        Text(data['desc']!, style: AppTextStyles.cardBody),
      ],
    );
  }
}