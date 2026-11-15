import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Categorías de error posibles al obtener la posición GPS del dispositivo.
enum LocationFailureType {
  /// El interruptor general de Ubicación / GPS del dispositivo está apagado.
  serviceDisabled,

  /// El usuario ha rechazado el permiso de ubicación en el diálogo del sistema.
  permissionDenied,

  /// El usuario ha rechazado permanentemente el permiso ("No volver a preguntar" o bloqueado en navegador).
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
/// Gestiona de forma explícita los escenarios exigidos por el Bloque 5 de la rúbrica:
/// 1. Comprobación de si el GPS del sistema está encendido (`isLocationServiceEnabled`).
/// 2. Solicitud de permisos en el momento adecuado (`checkPermission` / `requestPermission`).
/// 3. Tratamiento diferenciado de permiso denegado, denegación permanente y GPS apagado.
/// 4. Límite de tiempo (`timeLimit`) para controlar bloqueos en interiores o sin señal (`TimeoutException`).
/// Ninguno de los fallos deja la pantalla colgada.
class LocationService {
  /// Obtiene la posición GPS actual real del dispositivo con control de permisos y timeout.
  Future<Position> getCurrentRealPosition({
    Duration timeLimit = const Duration(seconds: 12),
  }) async {
    // 1. Verificar si el servicio de ubicación (GPS) está activo en el dispositivo
    bool serviceEnabled = false;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      serviceEnabled = !kIsWeb;
    }

    if (!serviceEnabled) {
      throw const LocationFailureException(
        type: LocationFailureType.serviceDisabled,
        message:
            'El GPS o servicio de ubicación del dispositivo está apagado. Actívalo en los ajustes del sistema y vuelve a intentarlo.',
      );
    }

    // 2. Comprobar y solicitar permisos de ubicación al usuario en el momento adecuado
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationFailureException(
          type: LocationFailureType.permissionDenied,
          message: kIsWeb
              ? 'Has denegado el permiso de ubicación en el navegador. Pulsa el icono de candado/ajustes junto a la barra de direcciones URL para permitir el acceso a la ubicación.'
              : 'Has denegado el permiso de localización. La aplicación necesita este permiso para leer tu posición GPS y ordenar los destinos cercanos.',
        );
      }
    }

    // 3. Controlar denegación permanente ("No volver a preguntar" o bloqueado en navegador)
    if (permission == LocationPermission.deniedForever) {
      throw LocationFailureException(
        type: LocationFailureType.permissionDeniedForever,
        message: kIsWeb
            ? 'El permiso de ubicación está bloqueado en este sitio web. Haz clic en el icono de configuración junto a la URL del navegador y cambia "Ubicación" a "Permitir".'
            : 'Los permisos de ubicación están bloqueados permanentemente. Debes habilitarlos desde los Ajustes de la aplicación en tu dispositivo.',
      );
    }

    // 4. Obtener posición real con límite de tiempo (Timeout) y captura de excepciones nativas
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
            'Tiempo de espera agotado (Timeout) al buscar señal GPS. Comprueba que tienes cobertura o sal a un espacio abierto e inténtalo de nuevo.',
      );
    } on LocationServiceDisabledException {
      throw const LocationFailureException(
        type: LocationFailureType.serviceDisabled,
        message:
            'El servicio de ubicación GPS se ha desactivado. Enciende el GPS del dispositivo para continuar.',
      );
    } on PermissionDeniedException {
      throw LocationFailureException(
        type: LocationFailureType.permissionDenied,
        message: kIsWeb
            ? 'El navegador denegó el acceso a la ubicación. Actívalo en el icono junto a la URL.'
            : 'Permiso de localización denegado por el usuario.',
      );
    } catch (e) {
      throw LocationFailureException(
        type: LocationFailureType.unknown,
        message: 'No se pudo obtener la ubicación actual: $e',
      );
    }
  }

  /// Abre los ajustes de ubicación del sistema operativo (en plataformas móviles).
  Future<bool> openLocationSettings() async {
    if (kIsWeb) return false;
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Abre la pantalla de permisos de la aplicación en los Ajustes del sistema (en plataformas móviles).
  Future<bool> openAppSettings() async {
    if (kIsWeb) return false;
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
