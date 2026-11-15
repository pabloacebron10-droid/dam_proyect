import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:dam_proyect/models/perfil.dart';
import 'package:dam_proyect/models/trip_preferences.dart';
import 'package:dam_proyect/screens/chat_screen.dart';
import 'package:dam_proyect/screens/home_screen.dart';
import 'package:dam_proyect/screens/login_screen.dart';
import 'package:dam_proyect/screens/newmessage_screen.dart';
import 'package:dam_proyect/screens/onboarding_screen.dart';
import 'package:dam_proyect/screens/register_screen.dart';
import 'package:dam_proyect/screens/splash_screen.dart';
import 'package:dam_proyect/screens/trip_detail_screen.dart';
import 'package:dam_proyect/screens/trip_wizard_screen.dart';

/// Punto de entrada principal de la aplicación Flutter.
///
/// Inicializa las vinculaciones de widgets de Flutter y Firebase Core con la
/// configuración de la plataforma actual, e inicia el widget raíz `MyApp`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

/// Widget principal que configura el sistema de navegación por rutas con nombre.
///
/// Utiliza `onGenerateRoute` para recibir parámetros pasados a través de
/// `Navigator.pushNamed(context, route, arguments: ...)` sin acoplar la
/// construcción directa de widgets en llamadas impersonales de `MaterialPageRoute`.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAM Proyecto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
              settings: settings,
            );
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
              settings: settings,
            );
          case '/onboarding':
            return MaterialPageRoute(
              builder: (_) => const OnboardingScreen(),
              settings: settings,
            );
          case '/homescreen':
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
              settings: settings,
            );
          case '/register':
            return MaterialPageRoute(
              builder: (_) => const RegisterScreen(),
              settings: settings,
            );
          case '/newmessage':
            return MaterialPageRoute(
              builder: (_) => const NewMessageScreen(),
              settings: settings,
            );
          case '/chat':
            final contacto = settings.arguments as Perfil;
            return MaterialPageRoute(
              builder: (_) => ChatScreen(contacto: contacto),
              settings: settings,
            );
          case '/trip_wizard':
            final args = settings.arguments as TripWizardArgs;
            return MaterialPageRoute(
              builder: (_) => TripWizardScreen(
                city: args.city,
                location: args.location,
                radiusKm: args.radiusKm,
                tripDays: args.tripDays,
              ),
              settings: settings,
            );
          case '/trip_detail':
            final preferences = settings.arguments as TripPreferences;
            return MaterialPageRoute(
              builder: (_) => TripDetailScreen(preferences: preferences),
              settings: settings,
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
              settings: settings,
            );
        }
      },
    );
  }
}
