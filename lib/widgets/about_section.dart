import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import 'glowing_button.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 80),
      padding: EdgeInsets.all(isMobile ? 32 : 64),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.surface,
            AppColors.primary.withOpacity(0.06),
          ],
        ),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: isMobile
          ? _buildMobileLayout(context)
          : _buildDesktopLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 55, child: _buildContent()),
        const SizedBox(width: 64),
        Expanded(flex: 45, child: _buildVisual()),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildVisual(),
        const SizedBox(height: 48),
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESPRE ASTROLAB',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 4,
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Facem astrofizica accesibilă pentru toți',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: 20),
        const Text(
          'AstroLab a fost creat pentru elevi, studenți și pasionați care vor să înțeleagă universul fără a se pierde în formule complicate. Transformăm concepte complexe de astrofizică în experiențe vizuale intuitive și captivante.',
          style: AppTextStyles.sectionSubtitle,
        ),
        const SizedBox(height: 16),
        const Text(
          'Construită cu Flutter pentru o experiență nativă pe iOS, Android și Web — AstroLab aduce aceleași instrumente de calitate pe orice dispozitiv.',
          style: AppTextStyles.sectionSubtitle,
        ),
        const SizedBox(height: 40),
        _buildTechStack(),
        const SizedBox(height: 40),
        GlowingButton(
          label: 'Descoperă mai mult',
          onPressed: () {},
          icon: Icons.arrow_forward_rounded,
        ),
      ],
    );
  }

  Widget _buildTechStack() {
    final techs = ['Flutter', 'Dart', 'AR/VR', 'Cross-platform', 'Offline'];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: techs
          .map(
            (t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.25),
              width: 0.5,
            ),
          ),
          child: Text(
            t,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  Widget _buildVisual() {
    return Column(
      children: [
        _buildInfoCard(
          Icons.school_rounded,
          'Audiență țintă',
          'Elevi (12+), studenți și pasionați de astronomie de toate vârstele.',
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          Icons.devices_rounded,
          'Cross-platform',
          'Disponibil pe iOS, Android și Web cu sincronizare completă a progresului.',
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          Icons.translate_rounded,
          'Conținut în română',
          'Toate lecțiile, testele și simulările sunt disponibile integral în limba română.',
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc, style: AppTextStyles.cardBody),
              ],
            ),
          ),
        ],
      ),
    );
  }
}