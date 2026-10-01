import 'package:flutter/material.dart';
import 'package:dam_proyect/services/onboarding_service.dart';
import 'package:dam_proyect/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(seconds: 2),
          () async {
        final hasSeenOnboarding =
        await _onboardingService.hasSeenOnboarding();

        if (!mounted) return;

        if (!hasSeenOnboarding) {
          Navigator.pushReplacementNamed(
            context,
            '/onboarding',
          );
          return;
        }

        final user = _authService.getCurrentUser();

        if (user != null) {
          Navigator.pushReplacementNamed(
            context,
            '/homescreen',
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/login',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text('Cargando...'),
      ),
    );
  }
}