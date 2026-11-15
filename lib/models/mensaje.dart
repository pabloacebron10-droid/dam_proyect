/// Modelo de datos que representa un mensaje de chat entre dos usuarios.
///
/// **Por qué:** Permite estructurar la información enviada/recibida en Cloud Firestore,
/// incluyendo la marca temporal `fecha` para ordenación cronológica y el estado
/// de lectura `leido` para indicar mensajes no leídos al usuario destinatario.
class Mensaje {
  /// Identificador único del mensaje en la colección de Firestore.
  final String id;

  /// UID del usuario que envía el mensaje.
  final String remitenteId;

  /// UID del usuario que recibe el mensaje.
  final String destinatarioId;

  /// Contenido textual del mensaje.
  final String texto;

  /// Fecha y hora en la que fue enviado el mensaje (convertido desde Timestamp).
  final DateTime fecha;

  /// Indicador de si el mensaje ha sido leído por el destinatario.
  final bool leido;

  Mensaje({
    required this.id,
    required this.remitenteId,
    required this.destinatarioId,
    required this.texto,
    required this.fecha,
    required this.leido,
  });
}
