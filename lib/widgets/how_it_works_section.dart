import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import 'glowing_button.dart';

class HowItWorksSection extends StatelessWidget {
  final void Function(String) onNavigate;
  const HowItWorksSection({super.key, required this.onNavigate});

  static const List<Map<String, String>> _steps = [
    {'number': '01', 'title': 'Creează cont',       'desc': 'Înregistrare rapidă cu email, Google sau Apple. Gratuit și fără abonamente ascunse.'},
    {'number': '02', 'title': 'Alege traseul',      'desc': 'Sistem solar, stele, cosmologie sau astrofizică avansată. Tu decizi de unde începi.'},
    {'number': '03', 'title': 'Completează lecții', 'desc': 'Lecții scurte, simulări interactive și provocări după fiecare capitol.'},
    {'number': '04', 'title': 'Urmărește progresul','desc': 'Dashboard personal cu statistici detaliate, insigne câștigate și obiective viitoare.'},
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
          const Text('CUM FUNCȚIONEAZĂ',
              style: TextStyle(
                  fontSize: 10, letterSpacing: 4,
                  color: AppColors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          const Text('4 pași simpli spre stele',
              style: AppTextStyles.sectionTitle,
              textAlign: TextAlign.center),
          const SizedBox(height: 60),
          isMobile ? _vertical() : _horizontal(),
          const SizedBox(height: 56),
          GlowingButton(
            label: 'Intră în platformă',
            onPressed: () => onNavigate('login'),
            icon: Icons.rocket_launch_rounded,
          ),
        ],
      ),
    );
  }

  Widget _horizontal() {
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
                      AppColors.primary.withOpacity(0.08),
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

  Widget _vertical() {
    return Column(
      children: List.generate(_steps.length, (i) {
        final isLast = i == _steps.length - 1;
        return Column(
          children: [
            _StepCard(data: _steps[i], horizontal: true),
            if (!isLast)
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
                      AppColors.primary.withOpacity(0.08),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
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
        children: [_numBox(), const SizedBox(width: 18), Expanded(child: _text())],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_numBox(), const SizedBox(height: 18), _text()],
    );
  }

  Widget _numBox() => Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(colors: [
        AppColors.primary.withOpacity(0.2),
        AppColors.primary.withOpacity(0.05),
      ]),
      border: Border.all(
          color: AppColors.primary.withOpacity(0.3), width: 1),
    ),
    child: Center(
      child: Text(data['number']!,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.primary)),
    ),
  );

  Widget _text() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(data['title']!, style: AppTextStyles.cardTitle),
      const SizedBox(height: 6),
      Text(data['desc']!, style: AppTextStyles.cardBody),
    ],
  );
}