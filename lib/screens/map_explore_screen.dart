import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dam_proyect/models/destino.dart';
import 'package:dam_proyect/models/trip_preferences.dart';
import 'package:dam_proyect/services/auth_service.dart';
import 'package:dam_proyect/services/firestore_service.dart';
import 'package:dam_proyect/services/location_service.dart';
import 'package:dam_proyect/services/distance_isolate_service.dart';

/// Pantalla de Exploración en Mapa (OpenStreetMap), GPS Real y «Cerca de mí» - Sección 2.
///
/// Cumple con los **Bloques 5 y 6 de la rúbrica (`0489 RA2.k, 2.l, 2.j, 2.n`, `0490 RA2.e, 2.a`, `0486 RA4.d`)**:
/// 1. Obtiene la posición GPS real del dispositivo con `geolocator` (`LocationService`), controlando
///    GPS apagado, permisos denegados, denegación permanente y `TimeoutException`.
/// 2. Guarda `GeoPoint` + `Timestamp` en Cloud Firestore (`profiles/{uId}`).
/// 3. Lee los documentos con `GeoPoint` de la colección `destinations` y pinta un `Marker` interactivo
///    por cada documento en el mapa.
/// 4. Calcula y ordena la lista **«Cerca de mí»** en un `Isolate` secundario (`DistanceIsolateService`)
///    mostrando el porcentaje de progreso en tiempo real sin bloquear la interfaz.
class MapExploreScreen extends StatefulWidget {
  const MapExploreScreen({super.key});

  @override
  State<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends State<MapExploreScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  LatLng _selectedLocation = const LatLng(40.416775, -3.703790);
  String _selectedCity = 'Madrid, España';
  double _actionRadiusKm = 5.0;
  int _tripDays = 3;

  // Estado GPS real y persistencia GeoPoint + Timestamp
  bool _isGettingGps = false;
  DateTime? _lastGpsTimestamp;
  bool _hasRealGpsFix = false;

  // Marcadores dinámicos de Firestore y cálculo Cerca de mí en Isolate
  List<Destino> _firestoreDestinations = [];
  List<DestinoConDistancia> _nearbyDestinations = [];
  bool _isCalculatingIsolate = false;
  double _isolateProgress = 0.0;
  bool _showNearbyPanel = false;

  bool _isSearching = false;
  String? _searchErrorMessage;
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadFirestoreMarkersAndCalculateNearby();
  }

  /// Carga los 20 documentos con `GeoPoint` de Firestore y lanza el cálculo inicial de distancias en `Isolate`.
  Future<void> _loadFirestoreMarkersAndCalculateNearby() async {
    try {
      final user = _authService.getCurrentUser();
      await _firestoreService.seedDestinationsIfEmpty(
        currentUserId: user?.uid,
      );
      final destinos = await _firestoreService.getAllDestinations();
      if (!mounted) return;

      setState(() {
        _firestoreDestinations = destinos;
      });

      await _runNearbyIsolateCalculation();
    } catch (e) {
      debugPrint('Error cargando marcadores de Firestore: $e');
    }
  }

  /// Ejecuta el cálculo de distancias Haversine dentro de un `Isolate` secundario comunicando el progreso.
  Future<void> _runNearbyIsolateCalculation() async {
    if (_firestoreDestinations.isEmpty) return;

    setState(() {
      _isCalculatingIsolate = true;
      _isolateProgress = 0.0;
    });

    try {
      final sorted = await DistanceIsolateService.calculateNearbyInIsolate(
        userLat: _selectedLocation.latitude,
        userLon: _selectedLocation.longitude,
        destinos: _firestoreDestinations,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _isolateProgress = progress;
            });
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _nearbyDestinations = sorted;
        _isCalculatingIsolate = false;
      });
    } catch (e) {
      debugPrint('Error en Isolate de distancias: $e');
      if (mounted) {
        setState(() {
          _isCalculatingIsolate = false;
        });
      }
    }
  }

  /// Obtiene la posición GPS real del dispositivo con `geolocator`, guarda `GeoPoint` + `Timestamp`
  /// en Firestore y recalcula la lista «Cerca de mí» en el `Isolate`.
  Future<void> _obtainRealGpsPosition() async {
    setState(() {
      _isGettingGps = true;
    });

    try {
      final position = await _locationService.getCurrentRealPosition();
      final newPoint = LatLng(position.latitude, position.longitude);
      final now = DateTime.now();

      // Guardar GeoPoint + Timestamp en Firestore si hay usuario autenticado
      final user = _authService.getCurrentUser();
      if (user != null) {
        await _firestoreService.updateUserLocation(
          user.uid,
          GeoPoint(position.latitude, position.longitude),
        );
      }

      if (!mounted) return;

      setState(() {
        _selectedLocation = newPoint;
        _lastGpsTimestamp = now;
        _hasRealGpsFix = true;
        _selectedCity =
            'GPS (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
      });

      _mapController.move(newPoint, 13.0);
      _reverseGeocode(newPoint);
      await _runNearbyIsolateCalculation();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Posición GPS guardada en Firestore: GeoPoint(${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on LocationFailureException catch (e) {
      if (!mounted) return;
      _showLocationFailureDialog(e);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener GPS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingGps = false;
        });
      }
    }
  }

  /// Muestra un diálogo modal adaptado al tipo de fallo GPS (apagado, permiso denegado, bloqueado o timeout).
  void _showLocationFailureDialog(LocationFailureException error) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              error.type == LocationFailureType.serviceDisabled
                  ? Icons.location_disabled
                  : error.type == LocationFailureType.timeout
                      ? Icons.timer_off_outlined
                      : Icons.location_off_outlined,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Aviso de Localización GPS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(error.message),
        actions: [
          if (error.type == LocationFailureType.serviceDisabled)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _locationService.openLocationSettings();
              },
              child: const Text('Abrir Ajustes de Ubicación'),
            ),
          if (error.type == LocationFailureType.permissionDeniedForever)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _locationService.openAppSettings();
              },
              child: const Text('Abrir Permisos de la App'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _obtainRealGpsPosition();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar GPS'),
          ),
        ],
      ),
    );
  }

  /// Renderiza la imagen de un destino soportando tanto miniatura Base64 (`data:image/...`) como URL HTTPS.
  Widget _buildDestinoThumbnail(String imagenUrl, {double size = 80}) {
    if (imagenUrl.startsWith('data:image/')) {
      try {
        final base64Str = imagenUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      } catch (_) {}
    }
    return Image.network(
      imagenUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: size,
        height: size,
        color: Colors.deepPurple.shade100,
        child: const Icon(
          Icons.place,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  /// Muestra la tarjeta inferior con los detalles de un marcador de Firestore al tocarlo en el mapa.
  void _showDestinationMarkerModal(Destino destino) {
    final double distKm = DistanceIsolateService.haversineKm(
      _selectedLocation.latitude,
      _selectedLocation.longitude,
      destino.coordenadas.latitude,
      destino.coordenadas.longitude,
    );
    final fechaStr =
        '${destino.fechaCreacion.day.toString().padLeft(2, "0")}/${destino.fechaCreacion.month.toString().padLeft(2, "0")}/${destino.fechaCreacion.year}';

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildDestinoThumbnail(destino.imagenUrl, size: 80),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destino.titulo,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${destino.pais} • ${destino.categoria}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${destino.rating}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.straighten,
                                size: 15,
                                color: Colors.deepPurple.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${distKm.toStringAsFixed(1)} km de ti',
                                style: TextStyle(
                                  color: Colors.deepPurple.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  destino.descripcion,
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'GeoPoint: (${destino.coordenadas.latitude.toStringAsFixed(4)}, ${destino.coordenadas.longitude.toStringAsFixed(4)}) • Timestamp: $fechaStr',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(
                      context,
                      '/trip_wizard',
                      arguments: TripWizardArgs(
                        city: '${destino.titulo}, ${destino.pais}',
                        location: LatLng(
                          destino.coordenadas.latitude,
                          destino.coordenadas.longitude,
                        ),
                        radiusKm: _actionRadiusKm,
                        tripDays: _tripDays,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.explore_rounded),
                  label: const Text('Planificar Viaje a este Destino'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _searchCity(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _searchErrorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchErrorMessage = null;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'dam_proyect_flutter_app'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        if (mounted) {
          setState(() {
            _searchResults = data;
            if (data.isEmpty) {
              _searchErrorMessage = 'No se encontraron resultados para "$query".';
            }
          });
        }
      } else {
        throw Exception(
          'Servidor OpenStreetMap no disponible (Código ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Error en la búsqueda de ciudad: $e');
      if (mounted) {
        setState(() {
          _searchErrorMessage =
              'Error de red al buscar ubicación. Revisa tu conexión.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectSearchResult(dynamic place) {
    final lat = double.parse(place['lat'].toString());
    final lon = double.parse(place['lon'].toString());
    final displayName = place['display_name'].toString();

    final newLocation = LatLng(lat, lon);

    setState(() {
      _selectedLocation = newLocation;
      _selectedCity = displayName.split(',').take(2).join(', ');
      _searchResults = [];
      _searchErrorMessage = null;
      _searchController.text = _selectedCity;
    });

    _mapController.move(newLocation, 13.0);
    _runNearbyIsolateCalculation();
  }

  Future<void> _reverseGeocode(LatLng location) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'dam_proyect_flutter_app'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName =
            data['display_name']?.toString() ?? 'Ubicación seleccionada';
        if (mounted) {
          setState(() {
            _selectedCity = displayName.split(',').take(2).join(', ');
            _searchController.text = _selectedCity;
          });
        }
      }
    } catch (e) {
      debugPrint('Error en geocodificación inversa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Cabecera de búsqueda y barra de estado GPS / Cerca de mí
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar ciudad o pulsar GPS...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.deepPurple,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                        _searchErrorMessage = null;
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          onChanged: _searchCity,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botón explícito "Dónde estoy (GPS Real)" - Bloque 5
                      Tooltip(
                        message:
                            'Obtener posición GPS real y guardar GeoPoint en Firestore',
                        child: ElevatedButton.icon(
                          onPressed:
                              _isGettingGps ? null : _obtainRealGpsPosition,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasRealGpsFix
                                ? Colors.green.shade700
                                : Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: _isGettingGps
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location, size: 18),
                          label: const Text(
                            'GPS',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Barra de estado de Marcadores de Firestore y botón "Cerca de mí (Isolate)"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _lastGpsTimestamp != null
                              ? 'GeoPoint guardado (${_lastGpsTimestamp!.hour.toString().padLeft(2, "0")}:${_lastGpsTimestamp!.minute.toString().padLeft(2, "0")}) • ${_firestoreDestinations.length} marcadores'
                              : '${_firestoreDestinations.length} marcadores Firestore en el mapa',
                          style: TextStyle(
                            fontSize: 12,
                            color: _hasRealGpsFix
                                ? Colors.green.shade800
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showNearbyPanel = !_showNearbyPanel;
                          });
                          if (_showNearbyPanel) {
                            _runNearbyIsolateCalculation();
                          }
                        },
                        icon: Icon(
                          _showNearbyPanel
                              ? Icons.expand_less
                              : Icons.near_me_outlined,
                          size: 18,
                          color: Colors.deepPurple,
                        ),
                        label: Text(
                          _showNearbyPanel
                              ? 'Ocultar Cerca de mí'
                              : 'Cerca de mí (${_nearbyDestinations.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Progreso del Isolate de cálculo de distancias (Bloque 6 - PSP 0490)
                  if (_isCalculatingIsolate)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Calculando distancias Haversine en Isolate...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.deepPurple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(_isolateProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: _isolateProgress,
                            color: Colors.deepPurple,
                            backgroundColor: Colors.deepPurple.shade50,
                          ),
                        ],
                      ),
                    ),

                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: LinearProgressIndicator(color: Colors.deepPurple),
                    ),

                  if (_searchErrorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _searchErrorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                _searchCity(_searchController.text),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),

                  if (_searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final place = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.location_on,
                              color: Colors.deepPurple,
                            ),
                            title: Text(
                              place['display_name'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () => _selectSearchResult(place),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // Panel desplegable «Cerca de mí» ordenado por distancia en Isolate (Bloque 6)
            if (_showNearbyPanel && _nearbyDestinations.isNotEmpty)
              Container(
                height: 125,
                color: Colors.deepPurple.shade50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _nearbyDestinations.length,
                  itemBuilder: (context, index) {
                    final item = _nearbyDestinations[index];
                    final d = item.destino;
                    return GestureDetector(
                      onTap: () {
                        final target = LatLng(
                          d.coordenadas.latitude,
                          d.coordenadas.longitude,
                        );
                        _mapController.move(target, 11.0);
                        _showDestinationMarkerModal(d);
                      },
                      child: Container(
                        width: 210,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: index == 0
                                ? Colors.deepPurple
                                : Colors.grey.shade300,
                            width: index == 0 ? 1.6 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '#${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    d.titulo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${d.pais} (${d.categoria})',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item.distanciaKm.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 13,
                                      color: Colors.amber,
                                    ),
                                    Text(
                                      '${d.rating}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Mapa interactivo con marcadores de Firestore
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _selectedLocation,
                      initialZoom: 5.5,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _selectedLocation = point;
                        });
                        _reverseGeocode(point);
                        _runNearbyIsolateCalculation();
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.damProyect',
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _selectedLocation,
                            radius: _actionRadiusKm * 300,
                            useRadiusInMeter: true,
                            color: Colors.deepPurple.withValues(alpha: 0.15),
                            borderColor: Colors.deepPurple,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                      // Capa de marcadores dinámicos leídos de Cloud Firestore + marcador del usuario
                      MarkerLayer(
                        markers: [
                          // 1. Un marcador por cada documento con GeoPoint en Firestore
                          ..._firestoreDestinations.map(
                            (destino) => Marker(
                              point: LatLng(
                                destino.coordenadas.latitude,
                                destino.coordenadas.longitude,
                              ),
                              width: 44,
                              height: 44,
                              child: GestureDetector(
                                onTap: () =>
                                    _showDestinationMarkerModal(destino),
                                child: Tooltip(
                                  message: '${destino.titulo} (${destino.pais})',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.25),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.place,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 2. Marcador de la posición actual del usuario
                          Marker(
                            point: _selectedLocation,
                            width: 52,
                            height: 52,
                            child: const Icon(
                              Icons.person_pin_circle,
                              size: 48,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      // Atribución obligatoria a OpenStreetMap visible (Bloque 6 de la rúbrica)
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            'OpenStreetMap contributors',
                          ),
                        ],
                      ),
                    ],
                  ),

                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'gps_btn',
                          tooltip: 'Centrar en mi posición GPS real',
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                          onPressed: _obtainRealGpsPosition,
                          child: const Icon(Icons.my_location),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'world_btn',
                          tooltip: 'Ver todos los marcadores',
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                          onPressed: () {
                            _mapController.move(_selectedLocation, 4.5);
                          },
                          child: const Icon(Icons.public),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Controles inferiores de radio y duración del viaje
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Radio de acción: ${_actionRadiusKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            'Días: ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 20,
                            ),
                            onPressed: _tripDays > 1
                                ? () => setState(() => _tripDays--)
                                : null,
                          ),
                          Text(
                            '$_tripDays',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                            ),
                            onPressed: _tripDays < 14
                                ? () => setState(() => _tripDays++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Slider(
                    value: _actionRadiusKm,
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    activeColor: Colors.deepPurple,
                    label: '${_actionRadiusKm.toStringAsFixed(0)} km',
                    onChanged: (value) {
                      setState(() {
                        _actionRadiusKm = value;
                      });
                    },
                  ),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/trip_wizard',
                          arguments: TripWizardArgs(
                            city: _selectedCity,
                            location: _selectedLocation,
                            radiusKm: _actionRadiusKm,
                            tripDays: _tripDays,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.explore_rounded, size: 20),
                      label: const Text(
                        'Ver Recomendaciones del Viaje',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }
}
