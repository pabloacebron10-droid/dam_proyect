import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_proyect/models/perfil.dart';
import 'package:dam_proyect/models/mensaje.dart';
import 'package:dam_proyect/models/destino.dart';

/// Resultado tipado para la consulta paginada con `startAfterDocument`.
class PaginatedDestinationsResult {
  final List<Destino> items;
  final DocumentSnapshot<Destino>? lastDocument;
  final bool hasMore;

  const PaginatedDestinationsResult({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });
}

/// Servicio de persistencia y consultas avanzadas en Cloud Firestore.
///
/// **Por qué:** Centraliza el acceso a la base de datos NoSQL de Firebase utilizando
/// `withConverter` para lograr tipado fuerte en `Perfil`, `Mensaje` y `Destino`.
/// Incluye el sembrado inicial de 20 documentos con `GeoPoint` y `Timestamp`, las 4 consultas
/// avanzadas exigidas por la rúbrica y las operaciones de edición (`update`) y borrado (`delete`)
/// de documentos propios.
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Referencia tipada a la colección `profiles`.
  CollectionReference<Perfil> get _profilesRef =>
      _firestore.collection('profiles').withConverter<Perfil>(
            fromFirestore: (snapshot, _) {
              final data = snapshot.data();
              final rawGeo = data?['ubicacion'];
              final rawFecha = data?['ultimaActualizacionUbicacion'];
              return Perfil(
                uId: data?['uId'] ?? snapshot.id,
                nombre: data?['nombre'] ?? '',
                email: data?['email'] ?? '',
                fotoUrl: data?['fotoUrl'],
                ubicacion: rawGeo is GeoPoint ? rawGeo : null,
                ultimaActualizacionUbicacion:
                    rawFecha is Timestamp ? rawFecha.toDate() : null,
              );
            },
            toFirestore: (perfil, _) => {
              'uId': perfil.uId,
              'nombre': perfil.nombre,
              'email': perfil.email,
              if (perfil.fotoUrl != null) 'fotoUrl': perfil.fotoUrl,
              if (perfil.ubicacion != null) 'ubicacion': perfil.ubicacion,
              if (perfil.ultimaActualizacionUbicacion != null)
                'ultimaActualizacionUbicacion': Timestamp.fromDate(
                  perfil.ultimaActualizacionUbicacion!,
                ),
            },
          );

  /// Referencia tipada a la colección `destinations`.
  CollectionReference<Destino> get _destinationsRef =>
      _firestore.collection('destinations').withConverter<Destino>(
            fromFirestore: Destino.fromFirestore,
            toFirestore: (destino, _) => destino.toFirestore(),
          );

  /// Guarda o actualiza un perfil de usuario en la colección `profiles`.
  ///
  /// Utiliza `SetOptions(merge: true)` para evitar sobreescribir campos existentes.
  Future<void> saveProfile(Perfil perfil) async {
    await _profilesRef.doc(perfil.uId).set(perfil, SetOptions(merge: true));
  }

  /// Vincula o sincroniza el perfil del usuario tras iniciar sesión con Google Sign-In.
  ///
  /// Si el perfil no existe, lo crea con el nombre, correo y foto de Google.
  /// Si ya existe, conserva su foto o nombre personalizado y completa los campos vacíos.
  Future<Perfil> syncGoogleUserProfile({
    required String uId,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final existing = await getProfileByUid(uId);
    final perfil = Perfil(
      uId: uId,
      nombre: (existing != null && existing.nombre.trim().isNotEmpty)
          ? existing.nombre
          : (displayName != null && displayName.trim().isNotEmpty
              ? displayName
              : email.split('@').first),
      email: email,
      fotoUrl: (existing?.fotoUrl != null && existing!.fotoUrl!.isNotEmpty)
          ? existing.fotoUrl
          : photoUrl,
      ubicacion: existing?.ubicacion,
      ultimaActualizacionUbicacion: existing?.ultimaActualizacionUbicacion,
    );
    await saveProfile(perfil);
    return perfil;
  }

  /// Guarda la posición GPS real del usuario como `GeoPoint` junto con un `Timestamp` en Firestore.
  ///
  /// Cumple con el Bloque 5 de la rúbrica (`GeoPoint` + `Timestamp`).
  Future<void> updateUserLocation(String uId, GeoPoint coordenadas) async {
    await _firestore.collection('profiles').doc(uId).set(
      {
        'uId': uId,
        'ubicacion': coordenadas,
        'ultimaActualizacionUbicacion': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );
  }

  /// Guarda un nuevo mensaje en la colección `messages`.
  Future<void> saveMessage(Mensaje mensaje) async {
    await _firestore
        .collection('messages')
        .doc(mensaje.id)
        .withConverter<Mensaje>(
          fromFirestore: (snapshot, _) {
            final data = snapshot.data();
            return Mensaje(
              id: snapshot.id,
              remitenteId: data?['remitenteId'] ?? '',
              destinatarioId: data?['destinatarioId'] ?? '',
              texto: data?['texto'] ?? '',
              fecha: (data?['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
              leido: data?['leido'] ?? false,
            );
          },
          toFirestore: (mensaje, _) => {
            'remitenteId': mensaje.remitenteId,
            'destinatarioId': mensaje.destinatarioId,
            'texto': mensaje.texto,
            'fecha': Timestamp.fromDate(mensaje.fecha),
            'leido': mensaje.leido,
          },
        )
        .set(mensaje);
  }

  /// Busca un perfil de usuario por su correo electrónico (Lectura puntual `get()`).
  Future<Perfil?> getProfileByEmail(String email) async {
    final querySnapshot =
        await _profilesRef.where('email', isEqualTo: email).limit(1).get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return querySnapshot.docs.first.data();
  }

  /// Obtiene el perfil de un usuario por su UID (Lectura puntual `get()`).
  Future<Perfil?> getProfileByUid(String uId) async {
    final docSnapshot = await _profilesRef.doc(uId).get();
    if (!docSnapshot.exists) {
      return null;
    }
    return docSnapshot.data();
  }

  /// Recupera todos los perfiles de la colección `profiles`.
  Future<List<Perfil>> getAllProfiles() async {
    final querySnapshot = await _profilesRef.get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Escucha en tiempo real (`snapshots()`) los mensajes recibidos por un usuario.
  Stream<List<Mensaje>> getReceivedMessages(String userId) {
    return _firestore
        .collection('messages')
        .withConverter<Mensaje>(
          fromFirestore: (snapshot, _) {
            final data = snapshot.data();
            return Mensaje(
              id: snapshot.id,
              remitenteId: data?['remitenteId'] ?? '',
              destinatarioId: data?['destinatarioId'] ?? '',
              texto: data?['texto'] ?? '',
              fecha: (data?['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
              leido: data?['leido'] ?? false,
            );
          },
          toFirestore: (mensaje, _) => {
            'remitenteId': mensaje.remitenteId,
            'destinatarioId': mensaje.destinatarioId,
            'texto': mensaje.texto,
            'fecha': Timestamp.fromDate(mensaje.fecha),
            'leido': mensaje.leido,
          },
        )
        .where('destinatarioId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final mensajes =
          snapshot.docs.map((document) => document.data()).toList();
      mensajes.sort((a, b) => b.fecha.compareTo(a.fecha));
      return mensajes;
    });
  }

  /// Escucha en tiempo real (`snapshots()`) los mensajes enviados por un usuario.
  Stream<List<Mensaje>> getSentMessages(String userId) {
    return _firestore
        .collection('messages')
        .withConverter<Mensaje>(
          fromFirestore: (snapshot, _) {
            final data = snapshot.data();
            return Mensaje(
              id: snapshot.id,
              remitenteId: data?['remitenteId'] ?? '',
              destinatarioId: data?['destinatarioId'] ?? '',
              texto: data?['texto'] ?? '',
              fecha: (data?['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
              leido: data?['leido'] ?? false,
            );
          },
          toFirestore: (mensaje, _) => {
            'remitenteId': mensaje.remitenteId,
            'destinatarioId': mensaje.destinatarioId,
            'texto': mensaje.texto,
            'fecha': Timestamp.fromDate(mensaje.fecha),
            'leido': mensaje.leido,
          },
        )
        .where('remitenteId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final mensajes =
          snapshot.docs.map((document) => document.data()).toList();
      mensajes.sort((a, b) => b.fecha.compareTo(a.fecha));
      return mensajes;
    });
  }

  /// Marca un mensaje como leído cambiando el campo `leido` a `true` en Firestore.
  Future<void> markMessageAsRead(String messageId) async {
    await _firestore.collection('messages').doc(messageId).update({
      'leido': true,
    });
  }

  /// Edita el texto de un mensaje propio mediante `update`.
  Future<void> updateMessageText(String messageId, String nuevoTexto) async {
    await _firestore.collection('messages').doc(messageId).update({
      'texto': nuevoTexto,
    });
  }

  /// Elimina un mensaje propio de la colección `messages` mediante `delete`.
  Future<void> deleteMessage(String messageId) async {
    await _firestore.collection('messages').doc(messageId).delete();
  }

  // ===========================================================================
  // BLOQUES 2, 3 Y 6: COLECCIÓN DE 20 DOCUMENTOS, 4 CONSULTAS AVANZADAS Y CRUD
  // ===========================================================================

  /// Asegura que la colección `destinations` tenga al menos 20 documentos con `GeoPoint` y `Timestamp`.
  ///
  /// Si hay menos de 20 documentos en Firestore, inserta mediante un `WriteBatch` los destinos
  /// iniciales para poder probar las 4 consultas avanzadas, el mapa interactivo y el cálculo de distancias.
  Future<void> seedDestinationsIfEmpty({String? currentUserId}) async {
    final existingSnap = await _destinationsRef.limit(20).get();
    if (existingSnap.docs.length >= 20) {
      return;
    }

    final existingIds = existingSnap.docs.map((d) => d.id).toSet();
    final now = DateTime.now();
    final ownerId = currentUserId ?? 'demo_user_1';
    const foreignUserId = 'otro_usuario_ajeno';

    final List<Destino> seedItems = [
      Destino(
        id: 'dest_01_madrid',
        titulo: 'Madrid Centro Histórico',
        pais: 'España',
        categoria: 'España',
        descripcion: ' Museo del Prado, Parque del Retiro y Palacio Real.',
        imagenUrl: 'https://images.unsplash.com/photo-1539037116277-4db20889f2d4?w=500',
        rating: 4.9,
        coordenadas: const GeoPoint(40.4168, -3.7038),
        fechaCreacion: now.subtract(const Duration(days: 1)),
        creadorId: ownerId,
      ),
      Destino(
        id: 'dest_02_barcelona',
        titulo: 'Barcelona Modernista',
        pais: 'España',
        categoria: 'España',
        descripcion: 'Sagrada Familia, Park Güell y Barrio Gótico junto al mar.',
        imagenUrl: 'https://images.unsplash.com/photo-1583422409516-2895a77efded?w=500',
        rating: 4.85,
        coordenadas: const GeoPoint(41.3851, 2.1734),
        fechaCreacion: now.subtract(const Duration(days: 2)),
        creadorId: ownerId,
      ),
      Destino(
        id: 'dest_03_sevilla',
        titulo: 'Sevilla Monumental',
        pais: 'España',
        categoria: 'España',
        descripcion: 'Plaza de España, Real Alcázar, Giralda y barrio de Triana.',
        imagenUrl: 'https://images.unsplash.com/photo-1558642084-fd07fae5282e?w=500',
        rating: 4.92,
        coordenadas: const GeoPoint(37.3891, -5.9845),
        fechaCreacion: now.subtract(const Duration(days: 3)),
        creadorId: ownerId,
      ),
      Destino(
        id: 'dest_04_granada',
        titulo: 'Granada y La Alhambra',
        pais: 'España',
        categoria: 'España',
        descripcion: 'Palacios Nazaríes, Generalife y miradores del Albaicín.',
        imagenUrl: 'https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=500',
        rating: 4.95,
        coordenadas: const GeoPoint(37.1773, -3.5986),
        fechaCreacion: now.subtract(const Duration(days: 4)),
        creadorId: ownerId,
      ),
      Destino(
        id: 'dest_05_valencia',
        titulo: 'Valencia Ciudad de las Artes',
        pais: 'España',
        categoria: 'España',
        descripcion: 'Arquitectura vanguardista, playa de la Malvarrosa y la Albufera.',
        imagenUrl: 'https://images.unsplash.com/photo-1559564484-e48b3e040ff4?w=500',
        rating: 4.78,
        coordenadas: const GeoPoint(39.4699, -0.3763),
        fechaCreacion: now.subtract(const Duration(days: 5)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_06_bilbao',
        titulo: 'Bilbao y Ría del Nervión',
        pais: 'España',
        categoria: 'España',
        descripcion: 'Museo Guggenheim, Casco Viejo y gastronomía de pintxos.',
        imagenUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=500',
        rating: 4.82,
        coordenadas: const GeoPoint(43.2630, -2.9350),
        fechaCreacion: now.subtract(const Duration(days: 6)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_07_paris',
        titulo: 'París Ciudad de la Luz',
        pais: 'Francia',
        categoria: 'Europa',
        descripcion: 'Torre Eiffel, Museo del Louvre y paseo por el río Sena.',
        imagenUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=500',
        rating: 4.9,
        coordenadas: const GeoPoint(48.8566, 2.3522),
        fechaCreacion: now.subtract(const Duration(days: 8)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_08_roma',
        titulo: 'Roma Imperial',
        pais: 'Italia',
        categoria: 'Europa',
        descripcion: 'Coliseo Romano, Foro, Fontana di Trevi y Ciudad del Vaticano.',
        imagenUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=500',
        rating: 4.88,
        coordenadas: const GeoPoint(41.9028, 12.4964),
        fechaCreacion: now.subtract(const Duration(days: 10)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_09_lisboa',
        titulo: 'Lisboa y Barrio de Belém',
        pais: 'Portugal',
        categoria: 'Europa',
        descripcion: 'Tranvía 28, Torre de Belém y miradores de Alfama.',
        imagenUrl: 'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=500',
        rating: 4.84,
        coordenadas: const GeoPoint(38.7223, -9.1393),
        fechaCreacion: now.subtract(const Duration(days: 12)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_10_amsterdam',
        titulo: 'Ámsterdam de los Canales',
        pais: 'Países Bajos',
        categoria: 'Europa',
        descripcion: 'Anillo de canales históricos, Rijksmuseum y Museo Van Gogh.',
        imagenUrl: 'https://images.unsplash.com/photo-1534351590666-13e3e96b5017?w=500',
        rating: 4.76,
        coordenadas: const GeoPoint(52.3676, 4.9041),
        fechaCreacion: now.subtract(const Duration(days: 14)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_11_praga',
        titulo: 'Praga Ciudad de las Cien Torres',
        pais: 'República Checa',
        categoria: 'Europa',
        descripcion: 'Puente de Carlos, Reloj Astronómico y Castillo de Praga.',
        imagenUrl: 'https://images.unsplash.com/photo-1519677100203-a0e668c92439?w=500',
        rating: 4.89,
        coordenadas: const GeoPoint(50.0755, 14.4378),
        fechaCreacion: now.subtract(const Duration(days: 16)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_12_viena',
        titulo: 'Viena Imperial y Musical',
        pais: 'Austria',
        categoria: 'Europa',
        descripcion: 'Palacio de Schönbrunn, Ópera Estatal y cafés históricos.',
        imagenUrl: 'https://images.unsplash.com/photo-1516550893923-42d28e5677af?w=500',
        rating: 4.81,
        coordenadas: const GeoPoint(48.2082, 16.3738),
        fechaCreacion: now.subtract(const Duration(days: 18)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_13_atenas',
        titulo: 'Atenas y la Acrópolis',
        pais: 'Grecia',
        categoria: 'Europa',
        descripcion: 'Partenón, barrio de Plaka y cuna de la civilización clásica.',
        imagenUrl: 'https://images.unsplash.com/photo-1555993539-1732b0258235?w=500',
        rating: 4.74,
        coordenadas: const GeoPoint(37.9838, 23.7275),
        fechaCreacion: now.subtract(const Duration(days: 20)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_14_tokio',
        titulo: 'Tokio Metrópolis Futurista',
        pais: 'Japón',
        categoria: 'Asia',
        descripcion: 'Shibuya, templo Senso-ji en Asakusa y mirador de Shinjuku.',
        imagenUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=500',
        rating: 4.97,
        coordenadas: const GeoPoint(35.6762, 139.6503),
        fechaCreacion: now.subtract(const Duration(days: 22)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_15_kioto',
        titulo: 'Kioto Tradicional',
        pais: 'Japón',
        categoria: 'Asia',
        descripcion: 'Santuario Fushimi Inari, bosque de bambú de Arashiyama y Gion.',
        imagenUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=500',
        rating: 4.94,
        coordenadas: const GeoPoint(35.0116, 135.7681),
        fechaCreacion: now.subtract(const Duration(days: 25)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_16_seul',
        titulo: 'Seúl Palacios y K-Culture',
        pais: 'Corea del Sur',
        categoria: 'Asia',
        descripcion: 'Palacio Gyeongbokgung, aldea Bukchon Hanok y torre N Seoul.',
        imagenUrl: 'https://images.unsplash.com/photo-1538485399081-7191377e8241?w=500',
        rating: 4.86,
        coordenadas: const GeoPoint(37.5665, 126.9780),
        fechaCreacion: now.subtract(const Duration(days: 28)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_17_bangkok',
        titulo: 'Bangkok y Templos Reales',
        pais: 'Tailandia',
        categoria: 'Asia',
        descripcion: 'Gran Palacio, Wat Arun y mercados flotantes tradicionales.',
        imagenUrl: 'https://images.unsplash.com/photo-1508009603885-50cf7c579365?w=500',
        rating: 4.72,
        coordenadas: const GeoPoint(13.7563, 100.5018),
        fechaCreacion: now.subtract(const Duration(days: 32)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_18_nuevayork',
        titulo: 'Nueva York Manhattan',
        pais: 'EE.UU.',
        categoria: 'América',
        descripcion: 'Central Park, Times Square, Estatua de la Libertad y Broadway.',
        imagenUrl: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=500',
        rating: 4.83,
        coordenadas: const GeoPoint(40.7128, -74.0060),
        fechaCreacion: now.subtract(const Duration(days: 36)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_19_cusco',
        titulo: 'Cusco y Valle Sagrado',
        pais: 'Perú',
        categoria: 'América',
        descripcion: 'Capital histórica inca y puerta de entrada a Machu Picchu.',
        imagenUrl: 'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=500',
        rating: 4.93,
        coordenadas: const GeoPoint(-13.5320, -71.9675),
        fechaCreacion: now.subtract(const Duration(days: 40)),
        creadorId: foreignUserId,
      ),
      Destino(
        id: 'dest_20_buenosaires',
        titulo: 'Buenos Aires Capital del Tango',
        pais: 'Argentina',
        categoria: 'América',
        descripcion: ' Caminito en La Boca, Palermo, Recoleta y Teatro Colón.',
        imagenUrl: 'https://images.unsplash.com/photo-1589909202802-8f4aadce1849?w=500',
        rating: 4.79,
        coordenadas: const GeoPoint(-34.6037, -58.3816),
        fechaCreacion: now.subtract(const Duration(days: 45)),
        creadorId: foreignUserId,
      ),
    ];

    final WriteBatch batch = _firestore.batch();
    for (final item in seedItems) {
      if (!existingIds.contains(item.id)) {
        final docRef = _destinationsRef.doc(item.id);
        batch.set(docRef, item);
      }
    }
    await batch.commit();
  }

  /// Obtiene todos los destinos de la colección `destinations` (para pintar marcadores en el mapa).
  Future<List<Destino>> getAllDestinations() async {
    final snap =
        await _destinationsRef.orderBy('fechaCreacion', descending: true).get();
    return snap.docs.map((d) => d.data()).toList();
  }

  /// **CONSULTA AVANZADA 1 (`where` con 2 condiciones):**
  /// Filtra los destinos por una `categoria` exacta y un `rating` mínimo (`>= minRating`).
  ///
  /// Utiliza el índice compuesto (`categoria` ASC + `rating` DESC) definido en `firestore.indexes.json`.
  Future<List<Destino>> queryDestinationsByCategoryAndMinRating(
    String categoria,
    double minRating,
  ) async {
    try {
      Query<Destino> query = _destinationsRef
          .where('categoria', isEqualTo: categoria)
          .where('rating', isGreaterThanOrEqualTo: minRating)
          .orderBy('rating', descending: true);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } on FirebaseException catch (_) {
      // Fallback seguro si el índice compuesto aún se está construyendo en Firebase Console
      final snapshot =
          await _destinationsRef.where('categoria', isEqualTo: categoria).get();
      final filtered = snapshot.docs
          .map((doc) => doc.data())
          .where((d) => d.rating >= minRating)
          .toList();
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
      return filtered;
    }
  }

  /// **CONSULTA AVANZADA 2 (`orderBy` + `limit`):**
  /// Obtiene los `N` destinos mejor valorados ordenados por `rating` descendente.
  Future<List<Destino>> queryTopRatedDestinations({int limit = 5}) async {
    final snapshot = await _destinationsRef
        .orderBy('rating', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// **CONSULTA AVANZADA 3 (Rango de fechas `Timestamp`):**
  /// Filtra los documentos cuya `fechaCreacion` esté comprendida entre `start` y `end`.
  Future<List<Destino>> queryDestinationsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _destinationsRef
        .where(
          'fechaCreacion',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
        )
        .where(
          'fechaCreacion',
          isLessThanOrEqualTo: Timestamp.fromDate(end),
        )
        .orderBy('fechaCreacion', descending: true)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// **CONSULTA AVANZADA 4 (Paginación con cursor `startAfterDocument`):**
  /// Recupera una página de destinos ordenados alfabéticamente por `titulo`,
  /// comenzando después de `lastDocument` si se proporciona.
  Future<PaginatedDestinationsResult> queryDestinationsPaginated({
    DocumentSnapshot<Destino>? lastDocument,
    int pageSize = 6,
  }) async {
    Query<Destino> query = _destinationsRef.orderBy('titulo').limit(pageSize);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    final items = snapshot.docs.map((doc) => doc.data()).toList();
    final newLastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    return PaginatedDestinationsResult(
      items: items,
      lastDocument: newLastDoc,
      hasMore: snapshot.docs.length == pageSize,
    );
  }

  /// Crea un nuevo destino en la colección `destinations`.
  Future<void> createDestination(Destino destino) async {
    await _destinationsRef.doc(destino.id).set(destino);
  }

  /// Modifica (`update`) los campos de un documento de destino propio en Firestore.
  ///
  /// Cumple con el Bloque 3 de la rúbrica (`0486 RA4.f`).
  Future<void> updateDestination(
    String id, {
    required String titulo,
    required String pais,
    required String categoria,
    required String descripcion,
    required double rating,
    String? imagenUrl,
  }) async {
    final Map<String, dynamic> data = {
      'titulo': titulo,
      'pais': pais,
      'categoria': categoria,
      'descripcion': descripcion,
      'rating': rating,
    };
    if (imagenUrl != null) {
      data['imagenUrl'] = imagenUrl;
    }
    await _firestore.collection('destinations').doc(id).update(data);
  }

  /// Elimina (`delete`) un documento de destino propio en Firestore.
  ///
  /// Cumple con el Bloque 3 de la rúbrica (`0486 RA4.f`).
  Future<void> deleteDestination(String id) async {
    await _firestore.collection('destinations').doc(id).delete();
  }
}
