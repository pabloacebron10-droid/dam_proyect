import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:dam_proyect/models/destino.dart';

/// Elemento que asocia un [Destino] con su distancia física en kilómetros respecto al usuario.
class DestinoConDistancia {
  final Destino destino;
  final double distanciaKm;

  const DestinoConDistancia({
    required this.destino,
    required this.distanciaKm,
  });
}

/// Estructura ligera serializable para enviar coordenadas de cada destino al `Isolate`.
class _RawDestinationCoord {
  final int index;
  final double lat;
  final double lon;

  const _RawDestinationCoord({
    required this.index,
    required this.lat,
    required this.lon,
  });
}

/// Argumentos enviados al `Isolate` de cálculo de distancias.
class _DistanceIsolateArgs {
  final SendPort sendPort;
  final double userLat;
  final double userLon;
  final List<_RawDestinationCoord> destinations;

  const _DistanceIsolateArgs({
    required this.sendPort,
    required this.userLat,
    required this.userLon,
    required this.destinations,
  });
}

/// Mensaje enviado desde el `Isolate` al hilo principal (progreso parcial o resultado final).
class _DistanceIsolateMessage {
  final double progress;
  final List<Map<String, num>>? sortedResults;

  const _DistanceIsolateMessage({
    required this.progress,
    this.sortedResults,
  });
}

/// Servicio que calcula y ordena la lista «Cerca de mí» en un `Isolate` secundario (`0490 PSP RA2.e, 2.a`).
///
/// **Por qué un `Isolate`:** Calcular la distancia geodésica (fórmula de Haversine con funciones
/// trigonométricas `sin`, `cos`, `atan2`, `sqrt`) sobre colecciones de documentos y ordenarlas
/// se ejecuta de forma concurrente en un `Isolate` independiente, comunicando el porcentaje
/// de progreso (`0%` a `100%`) mediante `SendPort` / `ReceivePort` sin bloquear el hilo de UI.
class DistanceIsolateService {
  /// Calcula la distancia desde `(userLat, userLon)` a todos los `destinos` en un `Isolate`
  /// y devuelve la lista ordenada de menor a mayor distancia en kilómetros.
  static Future<List<DestinoConDistancia>> calculateNearbyInIsolate({
    required double userLat,
    required double userLon,
    required List<Destino> destinos,
    required void Function(double progress) onProgress,
  }) async {
    if (destinos.isEmpty) {
      onProgress(1.0);
      return const [];
    }

    onProgress(0.05);

    if (kIsWeb) {
      return _calculateOnWebWithProgress(
        userLat: userLat,
        userLon: userLon,
        destinos: destinos,
        onProgress: onProgress,
      );
    }

    final ReceivePort receivePort = ReceivePort();
    final Completer<List<DestinoConDistancia>> completer =
        Completer<List<DestinoConDistancia>>();

    final rawList = <_RawDestinationCoord>[
      for (int i = 0; i < destinos.length; i++)
        _RawDestinationCoord(
          index: i,
          lat: destinos[i].coordenadas.latitude,
          lon: destinos[i].coordenadas.longitude,
        ),
    ];

    Isolate? isolate;
    try {
      isolate = await Isolate.spawn<_DistanceIsolateArgs>(
        _distanceIsolateEntry,
        _DistanceIsolateArgs(
          sendPort: receivePort.sendPort,
          userLat: userLat,
          userLon: userLon,
          destinations: rawList,
        ),
      );

      receivePort.listen((dynamic message) {
        if (message is _DistanceIsolateMessage) {
          onProgress(message.progress);
          if (message.sortedResults != null) {
            final result = message.sortedResults!.map((entry) {
              final int idx = entry['index']!.toInt();
              final double dist = entry['distanceKm']!.toDouble();
              return DestinoConDistancia(
                destino: destinos[idx],
                distanciaKm: dist,
              );
            }).toList();

            if (!completer.isCompleted) {
              completer.complete(result);
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

  /// Punto de entrada estático ejecutado en el `Isolate` secundario.
  static void _distanceIsolateEntry(_DistanceIsolateArgs args) {
    final int total = args.destinations.length;
    final List<Map<String, num>> computed = [];

    for (int i = 0; i < total; i++) {
      final item = args.destinations[i];
      final double distKm = haversineKm(
        args.userLat,
        args.userLon,
        item.lat,
        item.lon,
      );

      computed.add({
        'index': item.index,
        'distanceKm': distKm,
      });

      // Comunicar progreso cada 25% de los elementos procesados
      if (i % math.max(1, total ~/ 4) == 0 || i == total - 1) {
        final double progress = ((i + 1) / total) * 0.85;
        args.sendPort.send(_DistanceIsolateMessage(progress: progress));
      }
    }

    // Ordenar de menor a mayor distancia física
    computed.sort(
      (a, b) => a['distanceKm']!.compareTo(b['distanceKm']!),
    );

    args.sendPort.send(
      _DistanceIsolateMessage(
        progress: 1.0,
        sortedResults: computed,
      ),
    );
  }

  /// Fórmula de Haversine para calcular la distancia esférica en kilómetros entre dos coordenadas.
  static double haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Fallback asíncrono con reporte de progreso para navegador Web.
  static Future<List<DestinoConDistancia>> _calculateOnWebWithProgress({
    required double userLat,
    required double userLon,
    required List<Destino> destinos,
    required void Function(double progress) onProgress,
  }) async {
    final List<DestinoConDistancia> results = [];
    final int total = destinos.length;

    for (int i = 0; i < total; i++) {
      final d = destinos[i];
      final dist = haversineKm(
        userLat,
        userLon,
        d.coordenadas.latitude,
        d.coordenadas.longitude,
      );
      results.add(DestinoConDistancia(destino: d, distanciaKm: dist));

      if (i % math.max(1, total ~/ 4) == 0) {
        onProgress(((i + 1) / total) * 0.85);
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    }

    results.sort((a, b) => a.distanciaKm.compareTo(b.distanciaKm));
    onProgress(1.0);
    return results;
  }
}
