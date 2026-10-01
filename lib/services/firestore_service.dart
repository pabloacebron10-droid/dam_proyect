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
      fromFirestore: (snapshot, _) => Perfil(
        uId: snapshot['uId'],
        nombre: snapshot['nombre'],
        email: snapshot['email'],
      ),
      toFirestore: (perfil, _) => {
        'uId': perfil.uId,
        'nombre': perfil.nombre,
        'email': perfil.email,
      },
    )
        .set(perfil);
  }
  Future<void> saveMessage(Mensaje mensaje) async {
    await _firestore
        .collection('messages')
        .doc(mensaje.id)
        .withConverter<Mensaje>(
      fromFirestore: (snapshot, _) => Mensaje(
        id: snapshot.id,
        remitenteId: snapshot['remitenteId'],
        destinatarioId: snapshot['destinatarioId'],
        texto: snapshot['texto'],
        fecha: (snapshot['fecha'] as Timestamp).toDate(),
        leido: snapshot['leido'] ?? false,
      ),
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
      fromFirestore: (snapshot, _) => Perfil(
        uId: snapshot['uId'],
        nombre: snapshot['nombre'],
        email: snapshot['email'],
      ),
      toFirestore: (perfil, _) => {
        'uId': perfil.uId,
        'nombre': perfil.nombre,
        'email': perfil.email,
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
  Stream<List<Mensaje>> getReceivedMessages(String userId) {
    return _firestore
        .collection('messages')
        .withConverter<Mensaje>(
      fromFirestore: (snapshot, _) => Mensaje(
        id: snapshot.id,
        remitenteId: snapshot['remitenteId'],
        destinatarioId: snapshot['destinatarioId'],
        texto: snapshot['texto'],
        fecha: (snapshot['fecha'] as Timestamp).toDate(),
        leido: snapshot['leido'] ?? false,
      ),
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
        .map(
          (snapshot) => snapshot.docs
          .map((document) => document.data())
          .toList(),
    );
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