import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  Future<String> uploadProfilePhoto(
      String uId,
      Uint8List imageBytes,
      ) async {
    final storage = FirebaseStorage.instance;

    debugPrint(
      'StorageService: bucket=${storage.bucket}',
    );
    debugPrint(
      'StorageService: UID=$uId, bytes=${imageBytes.length}',
    );

    try {
      final ref = storage
          .ref()
          .child('profile_photos/$uId/profile.jpg');

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
        'StorageService: Firebase error '
            'code=${e.code}, message=${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('StorageService: error inesperado: $e');
      rethrow;
    }
  }
}
