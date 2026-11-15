import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:dam_proyect/models/destino.dart';
import 'package:dam_proyect/services/distance_isolate_service.dart';
import 'package:dam_proyect/services/image_isolate_service.dart';

void main() {
  group('Pruebas de Isolates y Modelos Fase 1b', () {
    test(
      'DistanceIsolateService calcula distancias Haversine en Isolate y ordena de menor a mayor reportando progreso',
      () async {
        final destinos = [
          Destino(
            id: 'tokio',
            titulo: 'Tokio',
            pais: 'Japón',
            categoria: 'Asia',
            descripcion: 'Capital de Japón',
            imagenUrl: 'https://example.com/tokio.jpg',
            rating: 4.9,
            coordenadas: const GeoPoint(35.6762, 139.6503),
            fechaCreacion: DateTime(2026, 11, 1),
            creadorId: 'user_1',
          ),
          Destino(
            id: 'madrid',
            titulo: 'Madrid',
            pais: 'España',
            categoria: 'España',
            descripcion: 'Capital de España',
            imagenUrl: 'https://example.com/madrid.jpg',
            rating: 4.9,
            coordenadas: const GeoPoint(40.4168, -3.7038),
            fechaCreacion: DateTime(2026, 11, 2),
            creadorId: 'user_1',
          ),
          Destino(
            id: 'paris',
            titulo: 'París',
            pais: 'Francia',
            categoria: 'Europa',
            descripcion: 'Capital de Francia',
            imagenUrl: 'https://example.com/paris.jpg',
            rating: 4.8,
            coordenadas: const GeoPoint(48.8566, 2.3522),
            fechaCreacion: DateTime(2026, 11, 3),
            creadorId: 'user_1',
          ),
        ];

        final List<double> progressUpdates = [];
        final sorted = await DistanceIsolateService.calculateNearbyInIsolate(
          userLat: 40.4168,
          userLon: -3.7038,
          destinos: destinos,
          onProgress: (p) => progressUpdates.add(p),
        );

        expect(sorted.length, 3);
        expect(sorted.first.destino.id, 'madrid');
        expect(sorted.first.distanciaKm, closeTo(0.0, 0.5));
        expect(sorted[1].destino.id, 'paris');
        expect(sorted.last.destino.id, 'tokio');
        expect(progressUpdates.isNotEmpty, isTrue);
        expect(progressUpdates.last, 1.0);
      },
    );

    test(
      'ImageIsolateService comprime una imagen en un Isolate por debajo de 300 KB y emite progreso',
      () async {
        // Crear una imagen sintética de 800x800 en memoria
        final rawImage = img.Image(width: 800, height: 800);
        img.fill(rawImage, color: img.ColorRgb8(103, 58, 183));
        final rawPngBytes = Uint8List.fromList(img.encodePng(rawImage));

        final List<double> progressValues = [];
        final result = await ImageIsolateService.compressImageWithProgress(
          rawPngBytes,
          maxDimension: 480,
          onProgress: (progress, stage) {
            progressValues.add(progress);
          },
        );

        expect(result.sizeKb, lessThan(300.0));
        expect(result.width, lessThanOrEqualTo(480));
        expect(result.height, lessThanOrEqualTo(480));
        expect(result.base64DataUri.startsWith('data:image/jpeg;base64,'), isTrue);
        expect(progressValues.last, 1.0);
      },
    );
  });
}
