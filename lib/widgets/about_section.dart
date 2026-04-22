import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import 'glowing_button.dart';

class AboutSection extends StatelessWidget {
  final void Function(String) onNavigate;
  const AboutSection({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 600;
    final hPad = isMobile ? 16.0 : (w < 1024 ? 40.0 : 80.0);

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(vertical: 80, horizontal: hPad),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.11),
              AppColors.surface,
              AppColors.primary.withOpacity(0.05),
            ],
          ),
          border:
          Border.all(color: AppColors.primary.withOpacity(0.18), width: 1),
        ),
        padding: EdgeInsets.all(isMobile ? 28 : 56),
        child: isMobile
            ? _mobile()
            : _desktop(),
      ),
    );
  }

  Widget _desktop() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(flex: 55, child: _content()),
      const SizedBox(width: 56),
      Expanded(flex: 45, child: _cards()),
    ],
  );

  Widget _mobile() => Column(
    children: [_cards(), const SizedBox(height: 40), _content()],
  );

  Widget _content() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('DESPRE ASTROLAB',
          style: TextStyle(
              fontSize: 10, letterSpacing: 4,
              color: AppColors.primary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 18),
      const Text('Facem astrofizica accesibilă pentru toți',
          style: AppTextStyles.sectionTitle),
      const SizedBox(height: 18),
      const Text(
        'AstroLab a fost creat pentru elevi, studenți și pasionați care vor să înțeleagă universul fără a se pierde în formule complicate. Transformăm concepte complexe de astrofizică în experiențe vizuale intuitive și captivante.',
        style: AppTextStyles.sectionSubtitle,
      ),
      const SizedBox(height: 12),
      const Text(
        'Construită cu Flutter pentru o experiență nativă pe iOS, Android și Web — AstroLab aduce aceleași instrumente de calitate pe orice dispozitiv.',
        style: AppTextStyles.sectionSubtitle,
      ),
      const SizedBox(height: 32),
      _techStack(),
      const SizedBox(height: 32),
      GlowingButton(
        label: 'Intră în platformă',
        onPressed: () => onNavigate('login'),
        icon: Icons.rocket_launch_rounded,
      ),
    ],
  );

  Widget _techStack() {
    final techs = ['Flutter', 'Dart', 'AR/VR', 'Cross-platform', 'Offline'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: techs
          .map((t) => Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.22), width: 0.5),
        ),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondary,
                fontWeight: FontWeight.w500)),
      ))
          .toList(),
    );
  }

  Widget _cards() => Column(
    children: [
      _infoCard(Icons.school_rounded, 'Audiență țintă',
          'Elevi (12+), studenți și pasionați de astronomie de toate vârstele.'),
      const SizedBox(height: 14),
      _infoCard(Icons.devices_rounded, 'Cross-platform',
          'Disponibil pe iOS, Android și Web cu sincronizare completă a progresului.'),
      const SizedBox(height: 14),
      _infoCard(Icons.translate_rounded, 'Conținut în română',
          'Toate lecțiile, testele și simulările sunt disponibile integral în limba română.'),
    ],
  );

  Widget _infoCard(IconData icon, String title, String desc) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.background.withOpacity(0.55),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
          color: AppColors.primary.withOpacity(0.13), width: 0.5),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.cardTitle
                      .copyWith(fontSize: 14)),
              const SizedBox(height: 4),
              Text(desc, style: AppTextStyles.cardBody),
            ],
          ),
        ),
      ],
    ),
  );
}