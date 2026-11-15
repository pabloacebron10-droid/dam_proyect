import 'package:firebase_auth/firebase_auth.dart';

/// Servicio encargado de la autenticación de usuarios mediante Firebase Auth.
///
/// **Por qué:** Aislar las llamadas directas al SDK de Firebase Auth permite transformar
/// los códigos de error técnicos de `FirebaseAuthException` en mensajes descriptivos en español
/// comprensibles para el usuario final.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Registra una nueva cuenta de usuario con email y contraseña.
  ///
  /// Mapea los códigos de error comunes como `email-already-in-use`, `weak-password`
  /// o `invalid-email` a excepciones legibles en la interfaz de usuario.
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

  /// Inicia sesión con credenciales existentes (email y contraseña).
  ///
  /// Transforma los errores de autenticación (`invalid-credential`, `user-disabled`, etc.)
  /// para ofrecer mensajes limpios en la pantalla de Login.
  Future<UserCredential> login(
    String email,
    String password,
  ) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        throw Exception('El correo o la contraseña no son correctos');
      }
      if (e.code == 'invalid-email') {
        throw Exception('El correo electrónico no es válido');
      }
      if (e.code == 'user-disabled') {
        throw Exception('Esta cuenta está deshabilitada');
      }
      throw Exception('No se ha podido iniciar sesión');
    }
  }

  /// Cierra la sesión activa actual del usuario.
  Future<void> logout() {
    return _firebaseAuth.signOut();
  }

  /// Retorna el usuario actualmente autenticado en el dispositivo o `null` si no hay sesión.
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}
