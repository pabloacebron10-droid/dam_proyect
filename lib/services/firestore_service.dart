import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_proyect/models/perfil.dart';
import 'package:dam_proyect/models/mensaje.dart';

/// Servicio de persistencia y consultas en Cloud Firestore.
///
/// **Por qué:** Centraliza el acceso a la base de datos NoSQL de Firebase utilizando
/// `withConverter` para lograr tipado fuerte en los objetos `Perfil` y `Mensaje`.
/// Separa de forma explícita la diferencia entre lecturas puntuales (`get()`) y lecturas
/// en tiempo real mediante streams (`snapshots()`).
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guarda o actualiza un perfil de usuario en la colección `profiles`.
  ///
  /// Utiliza `SetOptions(merge: true)` para evitar sobreescribir campos existentes
  /// si solo se están actualizando ciertos atributos del documento.
  Future<void> saveProfile(Perfil perfil) async {
    await _firestore
        .collection('profiles')
        .doc(perfil.uId)
        .withConverter<Perfil>(
          fromFirestore: (snapshot, _) {
            final data = snapshot.data();
            return Perfil(
              uId: data?['uId'] ?? snapshot.id,
              nombre: data?['nombre'] ?? '',
              email: data?['email'] ?? '',
              fotoUrl: data?['fotoUrl'],
            );
          },
          toFirestore: (perfil, _) => {
            'uId': perfil.uId,
            'nombre': perfil.nombre,
            'email': perfil.email,
            if (perfil.fotoUrl != null) 'fotoUrl': perfil.fotoUrl,
          },
        )
        .set(perfil, SetOptions(merge: true));
  }

  /// Guarda un nuevo mensaje en la colección `messages`.
  ///
  /// Convierte el objeto `DateTime` en un `Timestamp` nativo de Firestore.
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
  ///
  /// **Por qué `get()`:** Se requiere una lectura única al enviar un nuevo mensaje para
  /// verificar que el destinatario existe en la base de datos.
  Future<Perfil?> getProfileByEmail(String email) async {
    final querySnapshot = await _firestore
        .collection('profiles')
        .withConverter<Perfil>(
          fromFirestore: (snapshot, _) {
            final data = snapshot.data();
            return Perfil(
              uId: data?['uId'] ?? snapshot.id,
              nombre: data?['nombre'] ?? '',
              email: data?['email'] ?? '',
              fotoUrl: data?['fotoUrl'],
            );
          },
          toFirestore: (perfil, _) => {
            'uId': perfil.uId,
            'nombre': perfil.nombre,
            'email': perfil.email,
            if (perfil.fotoUrl != null) 'fotoUrl': perfil.fotoUrl,
          },
        )
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return querySnapshot.docs.first.data();
  }

  /// Obtiene el perfil de un usuario por su UID (Lectura puntual `get()`).
  Future<Perfil?> getProfileByUid(String uId) async {
    final docSnapshot = await _firestore
        .collection('profiles')
        .doc(uId)
        .withConverter<Perfil>(
          fromFirestore: (snapshot, _) {
            final data = snapshot.data();
            return Perfil(
              uId: data?['uId'] ?? snapshot.id,
              nombre: data?['nombre'] ?? '',
              email: data?['email'] ?? '',
              fotoUrl: data?['fotoUrl'],
            );
          },
          toFirestore: (perfil, _) => {
            'uId': perfil.uId,
            'nombre': perfil.nombre,
            'email': perfil.email,
            if (perfil.fotoUrl != null) 'fotoUrl': perfil.fotoUrl,
          },
        )
        .get();

    if (!docSnapshot.exists) {
      return null;
    }

    return docSnapshot.data();
  }

  /// Recupera todos los perfiles de la colección `profiles`.
  Future<List<Perfil>> getAllProfiles() async {
    final querySnapshot = await _firestore
        .collection('profiles')
        .withConverter<Perfil>(
          fromFirestore: (snapshot, _) {
            final data = snapshot.data();
            return Perfil(
              uId: data?['uId'] ?? snapshot.id,
              nombre: data?['nombre'] ?? '',
              email: data?['email'] ?? '',
              fotoUrl: data?['fotoUrl'],
            );
          },
          toFirestore: (perfil, _) => {
            'uId': perfil.uId,
            'nombre': perfil.nombre,
            'email': perfil.email,
            if (perfil.fotoUrl != null) 'fotoUrl': perfil.fotoUrl,
          },
        )
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Escucha en tiempo real (`snapshots()`) los mensajes recibidos por un usuario.
  ///
  /// **Por qué `snapshots()`:** Al ser una aplicación de mensajería instantánea, se
  /// requiere actualizar la pantalla automáticamente al recibir un mensaje sin refrescar a mano.
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
}
