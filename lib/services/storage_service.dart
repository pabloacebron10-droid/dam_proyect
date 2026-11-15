import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Servicio de almacenamiento de archivos multimedia en Firebase Storage.
///
/// **Por qué:** Permite subir imágenes de perfil comprimidas en binario (`Uint8List`)
/// a Firebase Storage y obtener su URL pública de descarga HTTPS. Si la subida a Storage
/// no estuviera disponible (por ejemplo sin conexión o reglas cerradas), el sistema cuenta
/// con un mecanismo de respaldo automático a almacenamiento Base64 dentro del documento de Firestore.
class StorageService {
  /// Sube la imagen de perfil de un usuario a la ruta `profile_photos/{uId}/profile.jpg`.
  ///
  /// Escucha los eventos de transferencia para mostrar progreso por consola y retorna la
  /// URL pública asignada por Firebase Storage.
  Future<String> uploadProfilePhoto(
    String uId,
    Uint8List imageBytes,
  ) async {
    final storage = FirebaseStorage.instance;

    debugPrint('StorageService: bucket=${storage.bucket}');
    debugPrint('StorageService: UID=$uId, bytes=${imageBytes.length}');

    try {
      final ref = storage.ref().child('profile_photos/$uId/profile.jpg');

      final task = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      task.snapshotEvents.listen((snapshot) {
        debugPrint(
          'StorageService: estado=${snapshot.state}, '
          'transferidos=${snapshot.bytesTransferred}/'
          '${snapshot.totalBytes}',
        );
      });

      final snapshot = await task;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('StorageService: subida completada.');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint(
        'StorageService: Firebase error code=${e.code}, message=${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('StorageService: error inesperado: $e');
      rethrow;
    }
  }
}
