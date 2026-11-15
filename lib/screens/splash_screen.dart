import 'package:flutter/material.dart';
import 'package:dam_proyect/services/onboarding_service.dart';
import 'package:dam_proyect/services/auth_service.dart';

/// Pantalla de Carga Inicial / Splash (`SplashScreen`).
///
/// **Por qué:** Determina el flujo de entrada de la aplicación durante el arranque:
/// 1. Si no ha visto el onboarding -> Redirige a `/onboarding`.
/// 2. Si ya lo vio y hay sesión activa en Firebase Auth -> Redirige a `/homescreen`.
/// 3. Si ya lo vio pero no hay sesión -> Redirige a `/login`.
///
/// Todo mediante rutas con nombre (`Navigator.pushReplacementNamed`).
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
      const Duration(seconds: 3),
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
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://media1.giphy.com/media/v1.Y2lkPTc5MGI3NjExcmV6MTM5cXRrbzdsNmp2bGhyamNseDRwd3k4MTNtNnE3bzRpb3kzZCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/wkPBxvetT2UUqSukUE/giphy.webp',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                return const SizedBox(
                  width: 150,
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurple,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error al cargar la animación del Splash: $error');

                return const SizedBox(
                  width: 150,
                  height: 150,
                  child: Center(
                    child: Icon(
                      Icons.travel_explore_rounded,
                      size: 80,
                      color: Colors.deepPurple,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Cargando...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
