import 'package:latlong2/latlong.dart';

/// Argumentos para la navegación hacia el asistente de viajes `TripWizardScreen`.
///
/// Encapsula la ciudad elegida, las coordenadas de mapa, el radio de acción en km
/// y la duración prevista del viaje en días para transferirlos como `arguments` en rutas con nombre.
class TripWizardArgs {
  final String city;
  final LatLng location;
  final double radiusKm;
  final int tripDays;

  const TripWizardArgs({
    required this.city,
    required this.location,
    required this.radiusKm,
    required this.tripDays,
  });
}

/// Modelo de datos que representa las preferencias completas de un viaje.
///
/// Acumula las selecciones del usuario a través de los distintos pasos del
/// asistente (alojamiento, gastronomía y ocio) para calcular recomendaciones.
class TripPreferences {
  String city;
  LatLng location;
  double radiusKm;
  int tripDays;

  // Paso 1: Alojamiento
  String lodgingType; // 'hotel', 'apartamento', 'ambos'
  String lodgingPrice; // 'economico', 'moderado', 'lujo'
  List<String> lodgingVibes; // ['urbano', 'centrico', 'rustico', 'tranquilo', 'con_vida']

  // Paso 2: Gastronomía / Restaurantes
  String diningStyle; // 'tradicional', 'tapas', 'internacional', 'alta_cocina'
  String diningPrice; // 'economico', 'moderado', 'lujo'

  // Paso 3: Ocio y Actividades
  List<String> activityTypes; // ['cultura', 'naturaleza', 'compras', 'fiesta', 'familiar']
  String pace; // 'tranquilo', 'equilibrado', 'intenso'

  TripPreferences({
    required this.city,
    required this.location,
    required this.radiusKm,
    required this.tripDays,
    this.lodgingType = 'ambos',
    this.lodgingPrice = 'moderado',
    List<String>? lodgingVibes,
    this.diningStyle = 'tradicional',
    this.diningPrice = 'moderado',
    List<String>? activityTypes,
    this.pace = 'equilibrado',
  })  : lodgingVibes = lodgingVibes ?? ['centrico'],
        activityTypes = activityTypes ?? ['cultura'];
}
