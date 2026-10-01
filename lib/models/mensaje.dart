class Mensaje {
  final String id;
  final String remitenteId;
  final String destinatarioId;
  final String texto;
  final DateTime fecha;

  Mensaje({
    required this.id,
    required this.remitenteId,
    required this.destinatarioId,
    required this.texto,
    required this.fecha,
  });
}