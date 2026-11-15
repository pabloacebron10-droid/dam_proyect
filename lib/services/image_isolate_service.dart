import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Resultado del procesamiento y compresión de una imagen en `Isolate`.
class CompressedImageResult {
  /// Bytes binarios JPEG ya redimensionados y comprimidos (< 300 KB).
  final Uint8List bytes;

  /// Cadena Data URI Base64 lista para almacenar en Firestore (`data:image/jpeg;base64,...`).
  final String base64DataUri;

  /// Tamaño final en kilobytes (KB).
  final double sizeKb;

  /// Ancho final de la miniatura en píxeles.
  final int width;

  /// Alto final de la miniatura en píxeles.
  final int height;

  const CompressedImageResult({
    required this.bytes,
    required this.base64DataUri,
    required this.sizeKb,
    required this.width,
    required this.height,
  });
}

/// Mensaje interno enviado desde el `Isolate` de compresión al hilo principal.
class _IsolateProgressMessage {
  final double progress;
  final String stage;
  final CompressedImageResult? result;
  final String? error;

  const _IsolateProgressMessage({
    required this.progress,
    required this.stage,
    this.result,
    this.error,
  });
}

/// Argumentos de entrada para la función ejecutada en el `Isolate`.
class _IsolateCompressArgs {
  final SendPort sendPort;
  final Uint8List rawBytes;
  final int maxDimension;
  final int maxBytes;

  const _IsolateCompressArgs({
    required this.sendPort,
    required this.rawBytes,
    required this.maxDimension,
    required this.maxBytes,
  });
}

/// Servicio encargado de comprimir fotografías en segundo plano mediante un `Isolate` (`0490 PSP RA2.c`).
///
/// **Por qué un `Isolate`:** La decodificación de mapas de bits, el reescalado bilineal y la
/// compresión JPEG son operaciones intensivas en CPU. Ejecutarlas en el hilo principal de Flutter
/// congelaría los fotogramas de la interfaz (UI jank). Al delegar el trabajo a un `Isolate` con
/// `ReceivePort`/`SendPort`, la barra de progreso se actualiza con fluidez a 60 fps.
class ImageIsolateService {
  /// Límite máximo permitido por la rúbrica: 300 KB (se fija el binario objetivo en 200 KB
  /// para que incluso la cadena Base64 resultante sea siempre inferior a 300 KB).
  static const int maxTargetBytes = 200 * 1024;

  /// Comprime `rawBytes` en un `Isolate` reportando el progreso (`0.0` a `1.0`) y la etapa actual.
  static Future<CompressedImageResult> compressImageWithProgress(
    Uint8List rawBytes, {
    int maxDimension = 480,
    required void Function(double progress, String stage) onProgress,
  }) async {
    onProgress(0.10, 'Iniciando Isolate de compresión...');

    if (kIsWeb) {
      // En entorno Web (donde dart:isolate no soporta Isolate.spawn nativo),
      // dividimos por etapas asíncronas para refrescar la barra de progreso sin bloquear la UI.
      return _compressOnWebWithProgress(
        rawBytes,
        maxDimension: maxDimension,
        onProgress: onProgress,
      );
    }

    final ReceivePort receivePort = ReceivePort();
    final Completer<CompressedImageResult> completer =
        Completer<CompressedImageResult>();

    Isolate? isolate;
    try {
      isolate = await Isolate.spawn<_IsolateCompressArgs>(
        _compressImageEntryPoint,
        _IsolateCompressArgs(
          sendPort: receivePort.sendPort,
          rawBytes: rawBytes,
          maxDimension: maxDimension,
          maxBytes: maxTargetBytes,
        ),
      );

      receivePort.listen((dynamic message) {
        if (message is _IsolateProgressMessage) {
          onProgress(message.progress, message.stage);
          if (message.error != null) {
            if (!completer.isCompleted) {
              completer.completeError(Exception(message.error));
            }
            receivePort.close();
            isolate?.kill(priority: Isolate.immediate);
          } else if (message.result != null) {
            if (!completer.isCompleted) {
              completer.complete(message.result!);
            }
            receivePort.close();
            isolate?.kill(priority: Isolate.immediate);
          }
        }
      });

      return await completer.future;
    } catch (e) {
      receivePort.close();
      isolate?.kill(priority: Isolate.immediate);
      rethrow;
    }
  }

  /// Punto de entrada estático ejecutado dentro del `Isolate` secundario.
  static void _compressImageEntryPoint(_IsolateCompressArgs args) {
    try {
      args.sendPort.send(
        const _IsolateProgressMessage(
          progress: 0.25,
          stage: 'Decodificando imagen en Isolate...',
        ),
      );

      final img.Image? decoded = img.decodeImage(args.rawBytes);
      if (decoded == null) {
        args.sendPort.send(
          const _IsolateProgressMessage(
            progress: 1.0,
            stage: 'Error',
            error: 'No se pudo decodificar el formato de la imagen seleccionada.',
          ),
        );
        return;
      }

      args.sendPort.send(
        const _IsolateProgressMessage(
          progress: 0.55,
          stage: 'Redimensionando miniatura...',
        ),
      );

      img.Image resized = decoded;
      if (decoded.width > args.maxDimension ||
          decoded.height > args.maxDimension) {
        resized = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? args.maxDimension : null,
          height: decoded.height > decoded.width ? args.maxDimension : null,
          interpolation: img.Interpolation.average,
        );
      }

      args.sendPort.send(
        const _IsolateProgressMessage(
          progress: 0.80,
          stage: 'Ajustando calidad JPEG (< 300 KB)...',
        ),
      );

      int quality = 75;
      Uint8List encodedBytes =
          Uint8List.fromList(img.encodeJpg(resized, quality: quality));

      while (encodedBytes.lengthInBytes > args.maxBytes && quality > 20) {
        quality -= 15;
        encodedBytes =
            Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      }

      final String base64Str = base64Encode(encodedBytes);
      final String dataUri = 'data:image/jpeg;base64,$base64Str';
      final double sizeKb = encodedBytes.lengthInBytes / 1024.0;

      args.sendPort.send(
        _IsolateProgressMessage(
          progress: 1.0,
          stage: 'Compresión completada (${sizeKb.toStringAsFixed(1)} KB)',
          result: CompressedImageResult(
            bytes: encodedBytes,
            base64DataUri: dataUri,
            sizeKb: sizeKb,
            width: resized.width,
            height: resized.height,
          ),
        ),
      );
    } catch (e) {
      args.sendPort.send(
        _IsolateProgressMessage(
          progress: 1.0,
          stage: 'Error en Isolate',
          error: e.toString(),
        ),
      );
    }
  }

  /// Fallback escalonado para compilación Web (mantiene el mismo contrato de progreso y límite < 300 KB).
  static Future<CompressedImageResult> _compressOnWebWithProgress(
    Uint8List rawBytes, {
    required int maxDimension,
    required void Function(double progress, String stage) onProgress,
  }) async {
    onProgress(0.25, 'Decodificando imagen...');
    await Future<void>.delayed(const Duration(milliseconds: 80));

    final img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      throw Exception('No se pudo decodificar la imagen seleccionada.');
    }

    onProgress(0.55, 'Redimensionando miniatura...');
    await Future<void>.delayed(const Duration(milliseconds: 80));

    img.Image resized = decoded;
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxDimension : null,
        height: decoded.height > decoded.width ? maxDimension : null,
      );
    }

    onProgress(0.80, 'Comprimiendo JPEG (< 300 KB)...');
    await Future<void>.delayed(const Duration(milliseconds: 80));

    int quality = 75;
    Uint8List encodedBytes =
        Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    while (encodedBytes.lengthInBytes > maxTargetBytes && quality > 20) {
      quality -= 15;
      encodedBytes =
          Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    }

    final String base64Str = base64Encode(encodedBytes);
    final double sizeKb = encodedBytes.lengthInBytes / 1024.0;
    onProgress(1.0, 'Compresión completada (${sizeKb.toStringAsFixed(1)} KB)');

    return CompressedImageResult(
      bytes: encodedBytes,
      base64DataUri: 'data:image/jpeg;base64,$base64Str',
      sizeKb: sizeKb,
      width: resized.width,
      height: resized.height,
    );
  }
}
