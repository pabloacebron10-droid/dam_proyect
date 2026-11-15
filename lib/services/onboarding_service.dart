import 'package:shared_preferences/shared_preferences.dart';

/// Servicio encargado de almacenar y consultar si el usuario ya ha completado la guía inicial (`OnboardingScreen`).
///
/// **Por qué:** Utiliza `SharedPreferences` para persistir un booleano local en el dispositivo
/// evitando mostrar las pantallas de introducción en posteriores inicios de la aplicación.
class OnboardingService {
  /// Comprueba si el usuario ya ha visto el onboarding previamente.
  Future<bool> hasSeenOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool('onboarding_visto') ?? false;
  }

  /// Guarda en preferencias locales que el onboarding ha sido completado.
  Future<void> setOnboardingSeen() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_visto', true);
  }
}
