import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:astrolab/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AstroLabApp());
}

class AstroLabApp extends StatelessWidget {
  const AstroLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AstroLab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            overlayColor: AppColors.primary.withOpacity(0.08),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}