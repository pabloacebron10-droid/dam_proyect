import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<String?> register(
      String email,
      String password,
      ) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Este correo ya está registrado';
      }

      if (e.code == 'weak-password') {
        return 'La contraseña es demasiado débil';
      }

      if (e.code == 'invalid-email') {
        return 'El correo electrónico no es válido';
      }

      return 'No se ha podido crear la cuenta';
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