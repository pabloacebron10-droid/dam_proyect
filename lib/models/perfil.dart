/// Modelo de datos que representa el perfil público de un usuario.
///
/// **Por qué:** Almacena la información de identificación del usuario en Firestore (`profiles`).
/// El campo `fotoUrl` soporta tanto URLs HTTPS públicas de Firebase Storage como datos codificados
/// en Base64 (`data:image/jpeg;base64,...`) para asegurar compatibilidad sin conexión o sin Storage.
class Perfil {
  /// Identificador único Firebase Authentication (UID).
  final String uId;

  /// Nombre visible del usuario.
  final String nombre;

  /// Correo electrónico asociado a la cuenta.
  final String email;

  /// URL de la imagen de perfil (URL remota HTTPS o cadena Base64).
  final String? fotoUrl;

  Perfil({
    required this.uId,
    required this.nombre,
    required this.email,
    this.fotoUrl,
  });
}
