import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_proyect/models/perfil.dart';
import 'package:dam_proyect/models/mensaje.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          final mensajes = snapshot.docs.map((document) => document.data()).toList();
          mensajes.sort((a, b) => b.fecha.compareTo(a.fecha));
          return mensajes;
        });
  }

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
          final mensajes = snapshot.docs.map((document) => document.data()).toList();
          mensajes.sort((a, b) => b.fecha.compareTo(a.fecha));
          return mensajes;
        });
  }

  Future<void> markMessageAsRead(String messageId) async {
    await _firestore
        .collection('messages')
        .doc(messageId)
        .update({
      'leido': true,
    });
  }
}
