import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Categorías de error posibles al obtener la posición GPS del dispositivo.
enum LocationFailureType {
  /// El interruptor general de Ubicación / GPS del dispositivo está apagado.
  serviceDisabled,

  /// El usuario ha rechazado el permiso de ubicación en el diálogo del sistema.
  permissionDenied,

  /// El usuario ha rechazado permanentemente el permiso ("No volver a preguntar").
  permissionDeniedForever,

  /// Se ha agotado el tiempo máximo de espera buscando satélites GPS.
  timeout,

  /// Otro error de hardware o plataforma.
  unknown,
}

/// Excepción tipada que describe con exactitud por qué no se pudo obtener la posición GPS.
class LocationFailureException implements Exception {
  final LocationFailureType type;
  final String message;

  const LocationFailureException({
    required this.type,
    required this.message,
  });

  @override
  String toString() => message;
}

/// Servicio de Geolocalización Real mediante el paquete `geolocator` (`0489 PMDM RA2.l, 2.j, 2.n`).
///
/// Gestiona de forma explícita los 4 escenarios exigidos por la rúbrica:
/// 1. Comprobación de si el GPS del sistema está encendido (`isLocationServiceEnabled`).
/// 2. Solicitud de permisos (`checkPermission` / `requestPermission`).
/// 3. Tratamiento diferenciado de denegación temporal y denegación permanente.
/// 4. Límite de tiempo (`timeLimit`) para controlar bloqueos en interiores o sin señal.
class LocationService {
  /// Obtiene la posición GPS actual real del dispositivo con control de permisos y timeout.
  Future<Position> getCurrentRealPosition({
    Duration timeLimit = const Duration(seconds: 12),
  }) async {
    // 1. Verificar si el servicio de ubicación (GPS) está activo en el dispositivo
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailureException(
        type: LocationFailureType.serviceDisabled,
        message:
            'El GPS del dispositivo está desactivado. Por favor, actívalo en los ajustes de ubicación.',
      );
    }

    // 2. Comprobar y solicitar permisos de ubicación al usuario
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationFailureException(
          type: LocationFailureType.permissionDenied,
          message:
              'Permiso de ubicación denegado. La aplicación necesita acceso al GPS para centrar el mapa en tu posición.',
        );
      }
    }

    // 3. Controlar denegación permanente ("No volver a preguntar")
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailureException(
        type: LocationFailureType.permissionDeniedForever,
        message:
            'Los permisos de ubicación están bloqueados permanentemente. Debes habilitarlos desde los Ajustes de la aplicación.',
      );
    }

    // 4. Obtener posición real con límite de tiempo (Timeout)
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
    } on TimeoutException {
      throw const LocationFailureException(
        type: LocationFailureType.timeout,
        message:
            'Tiempo de espera agotado al buscar señal GPS. Comprueba que tienes cobertura o sal a un espacio abierto.',
      );
    } catch (e) {
      throw LocationFailureException(
        type: LocationFailureType.unknown,
        message: 'No se pudo obtener la ubicación actual: $e',
      );
    }
  }

  /// Abre los ajustes de ubicación del sistema operativo (solo plataformas móviles).
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Abre la pantalla de permisos de la aplicación en los Ajustes del sistema.
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
