import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<UserCredential?> register(
      String email,
      String password,
      ) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Este correo ya está registrado');
      }

      if (e.code == 'weak-password') {
        throw Exception('La contraseña es demasiado débil');
      }

      if (e.code == 'invalid-email') {
        throw Exception('El correo electrónico no es válido');
      }

      throw Exception('No se ha podido crear la cuenta');
    }
  }

  Future<UserCredential> login(
      String email,
      String password,
      ) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
  Future<void> logout() {
    return _firebaseAuth.signOut();
  }
}