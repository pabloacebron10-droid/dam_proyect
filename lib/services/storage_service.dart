import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  Future<String> uploadProfilePhoto(String uId, Uint8List imageBytes) async {
    // 1. Probar con el bucket por defecto de FirebaseStorage
    try {
      final defaultStorage = FirebaseStorage.instance;
      debugPrint('StorageService: Probando subida en bucket principal "${defaultStorage.bucket}"...');

      final ref = defaultStorage.ref().child('profile_photos/$uId/profile.jpg');
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          throw TimeoutException('Timeout en bucket principal');
        },
      );

      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('StorageService: ¡Subida completada con éxito en bucket principal! URL=$downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('StorageService: Error en bucket principal ($e). Probando bucket .appspot.com...');
    }

    // 2. Probar con el bucket tradicional proyectodam-56a61.appspot.com
    try {
      final altStorage = FirebaseStorage.instanceFor(bucket: 'proyectodam-56a61.appspot.com');
      debugPrint('StorageService: Probando subida en bucket secundario "proyectodam-56a61.appspot.com"...');

      final altRef = altStorage.ref().child('profile_photos/$uId/profile.jpg');
      final altTask = altRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final altSnapshot = await altTask.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          throw TimeoutException('Timeout en bucket secundario');
        },
      );

      final altDownloadUrl = await altSnapshot.ref.getDownloadURL();
      debugPrint('StorageService: ¡Subida completada con éxito en bucket secundario! URL=$altDownloadUrl');
      return altDownloadUrl;
    } catch (altError) {
      debugPrint('StorageService: Error en ambos buckets: $altError');
      throw Exception('No se pudo subir a Firebase Storage: $altError');
    }
  }
}
