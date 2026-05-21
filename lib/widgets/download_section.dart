import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class DownloadSection extends StatelessWidget {
  const DownloadSection({super.key});

  static final Uri _androidUri = Uri.parse(
    'https://github.com/CEX-Gala-i-robotica/astrolab/releases/download/v1.0/astrolab.apk',
  );
  static final Uri _windowsUri = Uri.parse(
    'https://github.com/CEX-Gala-i-robotica/astrolab/releases/download/v1.0/astrolab.exe',
  );

  Future<void> _download(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 700;
    final hPad = width < 600 ? 20.0 : (width < 1024 ? 48.0 : 80.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 78),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 24 : 34),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withOpacity(0.22)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 34,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: isMobile ? _mobileContent() : _desktopContent(),
          ),
        ),
      ),
    );
  }

  Widget _desktopContent() => Row(
    children: [
      Expanded(child: _copy()),
      const SizedBox(width: 28),
      _downloadCard(
        icon: Icons.android_rounded,
        title: 'Android',
        subtitle: '.apk installer',
        onTap: () => _download(_androidUri),
      ),
      const SizedBox(width: 14),
      _downloadCard(
        icon: Icons.desktop_windows_rounded,
        title: 'Windows',
        subtitle: '.exe installer',
        onTap: () => _download(_windowsUri),
      ),
    ],
  );

  Widget _mobileContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _copy(),
      const SizedBox(height: 20),
      _downloadCard(
        icon: Icons.android_rounded,
        title: 'Android',
        subtitle: '.apk installer',
        onTap: () => _download(_androidUri),
      ),
      const SizedBox(height: 12),
      _downloadCard(
        icon: Icons.desktop_windows_rounded,
        title: 'Windows',
        subtitle: '.exe installer',
        onTap: () => _download(_windowsUri),
      ),
    ],
  );

  Widget _copy() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'DESCARCĂ APLICAȚIA',
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 4,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 12),
      Text(
        'Instalează AstroLab pe dispozitivul tău',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          height: 1.15,
        ),
      ),
      SizedBox(height: 10),
      Text(
        'Descarcă installerul pentru dispozitivul tău Android sau Windows chiar acum!',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.45,
        ),
      ),
    ],
  );

  Widget _downloadCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 190,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.50),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.download_rounded,
                color: AppColors.secondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
