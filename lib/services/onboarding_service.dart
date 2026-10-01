import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  Future<bool> hasSeenOnboarding() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getBool('onboarding_visto') ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool('onboarding_visto', true);
  }
}