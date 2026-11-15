import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos que representa un destino turístico almacenado en Cloud Firestore (`destinations`).
///
/// Incluye coordenadas geográficas nativas (`GeoPoint`), marca temporal de creación (`Timestamp` -> `DateTime`)
/// y el UID del creador (`creadorId`) para controlar la edición y borrado de documentos propios.
class Destino {
  /// Identificador único del documento en Firestore.
  final String id;

  /// Nombre o título del destino.
  final String titulo;

  /// País en el que se ubica el destino.
  final String pais;

  /// Categoría geográfica o temática ('Europa', 'Asia', 'América', 'España').
  final String categoria;

  /// Descripción resumida del destino turístico.
  final String descripcion;

  /// URL de la imagen representativa (HTTPS o Base64).
  final String imagenUrl;

  /// Valoración media del destino (de 0.0 a 5.0).
  final double rating;

  /// Coordenadas geográficas nativas de Firestore (`GeoPoint`).
  final GeoPoint coordenadas;

  /// Fecha de creación o registro del documento (almacenada como `Timestamp` en Firestore).
  final DateTime fechaCreacion;

  /// UID del usuario creador del documento (o `'system_seed'` para los 20 documentos iniciales).
  final String creadorId;

  const Destino({
    required this.id,
    required this.titulo,
    required this.pais,
    required this.categoria,
    required this.descripcion,
    required this.imagenUrl,
    required this.rating,
    required this.coordenadas,
    required this.fechaCreacion,
    required this.creadorId,
  });

  /// Crea una instancia de [Destino] a partir de un mapa JSON/Firestore.
  factory Destino.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data() ?? {};
    final rawGeo = data['coordenadas'];
    final GeoPoint geoPoint = rawGeo is GeoPoint
        ? rawGeo
        : const GeoPoint(40.416775, -3.703790);

    final rawFecha = data['fechaCreacion'];
    final DateTime fecha = rawFecha is Timestamp
        ? rawFecha.toDate()
        : DateTime.now();

    return Destino(
      id: snapshot.id,
      titulo: (data['titulo'] ?? '').toString(),
      pais: (data['pais'] ?? '').toString(),
      categoria: (data['categoria'] ?? 'Europa').toString(),
      descripcion: (data['descripcion'] ?? '').toString(),
      imagenUrl: (data['imagenUrl'] ?? '').toString(),
      rating: (data['rating'] as num?)?.toDouble() ?? 4.5,
      coordenadas: geoPoint,
      fechaCreacion: fecha,
      creadorId: (data['creadorId'] ?? 'system_seed').toString(),
    );
  }

  /// Convierte el objeto [Destino] a un mapa compatible con Cloud Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'pais': pais,
      'categoria': categoria,
      'descripcion': descripcion,
      'imagenUrl': imagenUrl,
      'rating': rating,
      'coordenadas': coordenadas,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'creadorId': creadorId,
    };
  }

  /// Crea una copia modificada de este [Destino].
  Destino copyWith({
    String? id,
    String? titulo,
    String? pais,
    String? categoria,
    String? descripcion,
    String? imagenUrl,
    double? rating,
    GeoPoint? coordenadas,
    DateTime? fechaCreacion,
    String? creadorId,
  }) {
    return Destino(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      pais: pais ?? this.pais,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      rating: rating ?? this.rating,
      coordenadas: coordenadas ?? this.coordenadas,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      creadorId: creadorId ?? this.creadorId,
    );
  }
}
