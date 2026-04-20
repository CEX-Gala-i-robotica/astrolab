import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import '../widgets/navbar.dart';
import '../widgets/hero_section.dart';
import '../widgets/features_section.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/about_section.dart';
import '../widgets/footer_section.dart';
import '../widgets/floating_particles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _navHorizontalPadding(double width) {
    if (width < 768) return 20;
    if (width < 1024) return 48;
    return 80;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = _navHorizontalPadding(width);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          const FloatingParticles(),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: const [
                    HeroSection(),
                    FeaturesSection(),
                    HowItWorksSection(),
                    AboutSection(),
                    FooterSection(),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
                child: Navbar(scrollController: _scrollController),
              ),
            ),
          ),
        ],
      ),
    );
  }
}