import 'package:latlong2/latlong.dart';

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
