import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sys/screens/login_screen.dart';
import 'package:sys/screens/onboarding_screen.dart';
import 'package:sys/utils/app_theme.dart';
import 'package:sys/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Always show onboarding screen on each run
  // Clear the onboarding_complete flag
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_complete', false);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BarberBook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const OnboardingScreen(),
    );
  }
}
