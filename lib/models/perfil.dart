import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos que representa el perfil público de un usuario.
///
/// **Por qué:** Almacena la información de identificación del usuario en Firestore (`profiles`).
/// El campo `fotoUrl` soporta tanto URLs HTTPS públicas de Firebase Storage como datos codificados
/// en Base64 (`data:image/jpeg;base64,...`) para asegurar compatibilidad sin conexión o sin Storage.
/// También almacena la última ubicación GPS real (`GeoPoint`) junto con su marca temporal (`Timestamp`).
class Perfil {
  /// Identificador único Firebase Authentication (UID).
  final String uId;

  /// Nombre visible del usuario.
  final String nombre;

  /// Correo electrónico asociado a la cuenta.
  final String email;

  /// URL de la imagen de perfil (URL remota HTTPS o cadena Base64).
  final String? fotoUrl;

  /// Última coordenada GPS registrada por el usuario en Firestore (`GeoPoint`).
  final GeoPoint? ubicacion;

  /// Fecha y hora de la última captura GPS (almacenada como `Timestamp` en Firestore).
  final DateTime? ultimaActualizacionUbicacion;

  Perfil({
    required this.uId,
    required this.nombre,
    required this.email,
    this.fotoUrl,
    this.ubicacion,
    this.ultimaActualizacionUbicacion,
  });
}
