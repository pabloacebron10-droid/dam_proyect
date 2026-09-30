import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_proyect/models/perfil.dart';

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
}