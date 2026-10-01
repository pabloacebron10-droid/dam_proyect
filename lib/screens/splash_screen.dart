import 'package:flutter/material.dart';
import 'package:dam_proyect/services/onboarding_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final OnboardingService _onboardingService = OnboardingService();

  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(seconds: 2),
          () async {
        final hasSeenOnboarding =
        await _onboardingService.hasSeenOnboarding();

        if (!mounted) return;

        if (hasSeenOnboarding) {
          Navigator.pushReplacementNamed(
            context,
            '/login',
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/onboarding',
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