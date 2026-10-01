import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // =========================
          // PÁGINAS DEL ONBOARDING
          // =========================
          Expanded(
            child: PageView(
              controller: _pageController,

              // Permite deslizar con pantalla táctil y ratón
              scrollBehavior: const MaterialScrollBehavior().copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),

              // Actualizamos la página actual
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },

              children: [
                // =========================
                // PÁGINA 1
                // =========================
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/onboarding1.jpg',
                        height: 250,
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        '¡Bienvenido a nuestra app!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Descubre todo lo que puedes hacer con nuestra aplicación de forma sencilla y rápida.',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // =========================
                // PÁGINA 2
                // =========================
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/onboarding2.jpg',
                        height: 250,
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'Descubre todo lo que tenemos',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Explora las diferentes funciones de la aplicación y encuentra todo lo que necesitas.',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // =========================
                // PÁGINA 3
                // =========================
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Image.asset(
                          'assets/images/onboarding3.jpg',
                          height: 220,
                        ),
                      ),

                      const SizedBox(height: 35),

                      const Text(
                        'Todo listo para comenzar',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        'Ya conoces lo básico. Ahora es tu turno de descubrir todo lo que puedes hacer.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 35),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _onboardingService.setOnboardingSeen();

                            if (!mounted) return;

                            Navigator.pushReplacementNamed(
                              context,
                              '/register',
                            );
                          },
                          child: const Text(
                            'Empezar →',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // =========================
          // INDICADORES DE PÁGINA
          // =========================
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < 3; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.deepPurple
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
            ],
          ),

          SizedBox(
            height: 68,
            child: (_currentPage == 0 || _currentPage == 1)
                ? TextButton(
              onPressed: () async {
                await _onboardingService.setOnboardingSeen();

                if (!mounted) return;
                Navigator.pushReplacementNamed(context,'/register');
              },
              child: const Text('Saltar'),
            )
                : null,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}