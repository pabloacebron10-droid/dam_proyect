import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Servicio encargado de la autenticación de usuarios mediante Firebase Auth y Google Sign-In.
///
/// **Por qué:** Aislar las llamadas directas al SDK de Firebase Auth y Google Sign-In permite transformar
/// los códigos de error técnicos y la cancelación del flujo OAuth en estados y mensajes descriptivos
/// en español comprensibles para el usuario final.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Instancia perezosa de `GoogleSignIn` para plataformas nativas (Android/iOS).
  GoogleSignIn get _googleSignIn => GoogleSignIn(
        scopes: <String>['email', 'profile'],
      );

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

  /// Inicia sesión con una cuenta de Google tanto en Android/iOS como en Web.
  ///
  /// Retorna `null` si el usuario cancela voluntariamente el selector de cuentas
  /// (para que la UI pueda informar de la cancelación sin tratarlo como fallo crítico).
  /// Lanza una [Exception] descriptiva en español si ocurre un error de red o configuración OAuth.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        return await _firebaseAuth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        // Si el usuario cierra el selector sin elegir cuenta (cancelación):
        if (googleUser == null) {
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _firebaseAuth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'canceled' ||
          e.code == 'cancelled-popup-request') {
        return null;
      }
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception(
          'Ya existe una cuenta con este correo usando otro método de acceso.',
        );
      }
      if (e.code == 'network-request-failed') {
        throw Exception(
          'Error de red al conectar con Google. Revisa tu conexión a internet.',
        );
      }
      throw Exception(
        'Error al autenticar con Google (${e.code}): ${e.message ?? "Inténtalo de nuevo"}',
      );
    } on PlatformException catch (e) {
      if (e.code == GoogleSignIn.kSignInCanceledError ||
          e.code == 'sign_in_canceled' ||
          e.code == 'canceled') {
        return null;
      }
      if (e.code == GoogleSignIn.kNetworkError || e.code == 'network_error') {
        throw Exception(
          'Sin conexión de red para iniciar sesión con Google.',
        );
      }
      throw Exception(
        'No se pudo completar el acceso con Google. Verifica la huella SHA-1 en Firebase (${e.code}).',
      );
    } catch (e) {
      throw Exception('Error inesperado en Google Sign-In: $e');
    }
  }

  /// Cierra la sesión activa actual del usuario en Firebase Auth y Google Sign-In.
  Future<void> logout() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    await _firebaseAuth.signOut();
  }

  /// Retorna el usuario actualmente autenticado en el dispositivo o `null` si no hay sesión.
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
}
