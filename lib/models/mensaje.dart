class Mensaje {
  final String id;
  final String remitenteId;
  final String destinatarioId;
  final String texto;
  final DateTime fecha;
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