import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:dam_proyect/models/destino.dart';
import 'package:dam_proyect/models/trip_preferences.dart';
import 'package:dam_proyect/services/auth_service.dart';
import 'package:dam_proyect/services/firestore_service.dart';
import 'package:dam_proyect/services/image_isolate_service.dart';
import 'package:dam_proyect/services/location_service.dart';

/// Modos de consulta de Cloud Firestore disponibles en la pantalla (Bloque 2 de la rúbrica).
enum FirestoreQueryMode {
  /// Consulta 1: `where` compuesto con 2 condiciones (`categoria` == X y `rating` >= 4.8).
  compoundWhere,

  /// Consulta 2: `orderBy('rating', descending: true)` + `limit(5)`.
  orderByLimit,

  /// Consulta 3: Rango de fechas (`fechaCreacion` entre inicio y fin con `Timestamp`).
  dateRange,

  /// Consulta 4: Paginación con cursor `startAfterDocument`.
  paginated,
}

/// Pantalla de exploración en Cuadrícula (`GridView`), 4 Consultas Firestore y CRUD - Sección 3.
///
/// Cumple con los **Bloques 2, 3, 4 y 5 de la rúbrica**:
/// - Inicializa y consulta la colección `destinations` en Cloud Firestore (con al menos 20 documentos).
/// - Permite ejecutar y demostrar en pantalla las **4 consultas avanzadas distintas**:
///   1. `where` compuesto (Categoría + Rating mínimo).
///   2. `orderBy` + `limit` (Top 5 destinos mejor valorados).
///   3. Rango de fechas (`Timestamp` últimos N días).
///   4. Paginación con `startAfterDocument` (carga progresiva por bloques).
/// - Permite **Crear, Modificar (`update`) y Borrar (`delete`)** únicamente los documentos propios
///   (`creadorId == currentUser.uid`), impidiendo tocar lo ajeno tanto en interfaz como en `firestore.rules`.
/// - Incluye captura de foto desde Cámara/Galería comprimida en `Isolate` (`< 300 KB` Base64) y lectura
///   de posición GPS real (`GeoPoint` + `Timestamp`) guardada en el propio documento y mostrada en lista y detalle.
class GridExploreScreen extends StatefulWidget {
  const GridExploreScreen({super.key});

  @override
  State<GridExploreScreen> createState() => _GridExploreScreenState();
}

class _GridExploreScreenState extends State<GridExploreScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();

  bool _isLoading = true;
  bool _isLoadingMorePage = false;
  String? _errorMessage;

  FirestoreQueryMode _queryMode = FirestoreQueryMode.compoundWhere;
  String _selectedCategory = 'España';
  double _minRating = 4.8;
  int _dateRangeDays = 20;

  List<Destino> _destinos = [];
  DocumentSnapshot<Destino>? _lastPageDoc;
  bool _hasMorePages = false;

  @override
  void initState() {
    super.initState();
    _executeActiveQuery();
  }

  /// Ejecuta en Cloud Firestore la consulta correspondiente al modo seleccionado (`get()`).
  Future<void> _executeActiveQuery({bool forceError = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (forceError) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        throw Exception(
          'No se pudo conectar con Cloud Firestore. Comprueba tu red.',
        );
      }

      final currentUser = _authService.getCurrentUser();
      await _firestoreService.seedDestinationsIfEmpty(
        currentUserId: currentUser?.uid,
      );

      List<Destino> results = [];

      switch (_queryMode) {
        case FirestoreQueryMode.compoundWhere:
          results = await _firestoreService
              .queryDestinationsByCategoryAndMinRating(
            _selectedCategory,
            _minRating,
          );
          _hasMorePages = false;
          break;

        case FirestoreQueryMode.orderByLimit:
          results =
              await _firestoreService.queryTopRatedDestinations(limit: 5);
          _hasMorePages = false;
          break;

        case FirestoreQueryMode.dateRange:
          final now = DateTime.now();
          final start = now.subtract(Duration(days: _dateRangeDays));
          results = await _firestoreService.queryDestinationsByDateRange(
            start,
            now.add(const Duration(hours: 1)),
          );
          _hasMorePages = false;
          break;

        case FirestoreQueryMode.paginated:
          final pageResult =
              await _firestoreService.queryDestinationsPaginated(
            lastDocument: null,
            pageSize: 6,
          );
          results = pageResult.items;
          _lastPageDoc = pageResult.lastDocument;
          _hasMorePages = pageResult.hasMore;
          break;
      }

      if (!mounted) return;
      setState(() {
        _destinos = results;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  /// Carga la siguiente página de documentos en Firestore usando `startAfterDocument`.
  Future<void> _loadNextPage() async {
    if (_isLoadingMorePage || !_hasMorePages || _lastPageDoc == null) return;

    setState(() {
      _isLoadingMorePage = true;
    });

    try {
      final pageResult = await _firestoreService.queryDestinationsPaginated(
        lastDocument: _lastPageDoc,
        pageSize: 6,
      );

      if (!mounted) return;
      setState(() {
        _destinos.addAll(pageResult.items);
        _lastPageDoc = pageResult.lastDocument;
        _hasMorePages = pageResult.hasMore;
        _isLoadingMorePage = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMorePage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al paginar documentos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Renderiza la imagen de un destino soportando tanto miniatura Base64 (`< 300 KB`) como URL HTTPS.
  Widget _buildDestinoImage(String imagenUrl) {
    if (imagenUrl.startsWith('data:image/')) {
      try {
        final base64String = imagenUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
        );
      } catch (_) {}
    }
    return Image.network(
      imagenUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.deepPurple.shade100,
        child: const Icon(
          Icons.landscape_rounded,
          size: 40,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  /// Muestra la tarjeta modal de Detalle del Destino con su foto Base64/URL, GeoPoint y Timestamp tipados.
  void _showDestinoDetailModal(Destino item, bool isMine) {
    final fechaFormateada =
        '${item.fechaCreacion.day.toString().padLeft(2, "0")}/${item.fechaCreacion.month.toString().padLeft(2, "0")}/${item.fechaCreacion.year} '
        '${item.fechaCreacion.hour.toString().padLeft(2, "0")}:${item.fechaCreacion.minute.toString().padLeft(2, "0")}';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 170,
                    child: _buildDestinoImage(item.imagenUrl),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.titulo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isMine
                            ? Colors.deepPurple.shade50
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isMine ? 'Documento propio' : 'Documento ajeno',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isMine
                              ? Colors.deepPurple
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.pais} • Categoría: ${item.categoria} • ⭐ ${item.rating}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.descripcion,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GeoPoint tipado: (${item.coordenadas.latitude.toStringAsFixed(4)}, ${item.coordenadas.longitude.toStringAsFixed(4)})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Timestamp (fechaCreacion): $fechaFormateada',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (isMine) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showCreateOrEditDialog(existing: item);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Editar'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmAndDeleteDestination(item);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Borrar'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pushNamed(
                            context,
                            '/trip_wizard',
                            arguments: TripWizardArgs(
                              city: '${item.titulo}, ${item.pais}',
                              location: LatLng(
                                item.coordenadas.latitude,
                                item.coordenadas.longitude,
                              ),
                              radiusKm: 5.0,
                              tripDays: 3,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.explore_rounded, size: 18),
                        label: const Text('Planificar Viaje'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Muestra un formulario modal para crear o editar (`update`) un documento propio,
  /// permitiendo adjuntar foto desde Cámara/Galería comprimida en `Isolate` (`< 300 KB` Base64)
  /// y leer la posición GPS actual con `geolocator`.
  Future<void> _showCreateOrEditDialog({Destino? existing}) async {
    final bool isEditing = existing != null;
    final tituloCtrl = TextEditingController(text: existing?.titulo ?? '');
    final paisCtrl = TextEditingController(text: existing?.pais ?? 'España');
    final descCtrl = TextEditingController(
      text: existing?.descripcion ?? 'Destino con foto Base64 y GeoPoint.',
    );
    String categoria = existing?.categoria ?? 'España';
    double rating = existing?.rating ?? 4.9;
    String? customImageUrl = existing?.imagenUrl;
    GeoPoint currentGeoPoint =
        existing?.coordenadas ?? const GeoPoint(40.4168, -3.7038);

    bool isCompressingPhoto = false;
    double photoProgress = 0.0;
    String photoStage = '';
    double? compressedKb;
    bool isReadingGps = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickAndCompress(ImageSource source) async {
              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: source);
                if (picked == null) return;

                final rawBytes = await picked.readAsBytes();
                setDialogState(() {
                  isCompressingPhoto = true;
                  photoProgress = 0.1;
                  photoStage = 'Iniciando Isolate...';
                });

                final result =
                    await ImageIsolateService.compressImageWithProgress(
                  rawBytes,
                  maxDimension: 460,
                  onProgress: (p, stage) {
                    setDialogState(() {
                      photoProgress = p;
                      photoStage = stage;
                    });
                  },
                );

                setDialogState(() {
                  customImageUrl = result.base64DataUri;
                  compressedKb = result.sizeKb;
                  isCompressingPhoto = false;
                });
              } on PlatformException catch (e) {
                setDialogState(() => isCompressingPhoto = false);
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Permiso de cámara/galería denegado (${e.code}). Habilítalo en Ajustes.',
                      ),
                      backgroundColor: Colors.orange.shade800,
                    ),
                  );
                }
              } catch (e) {
                setDialogState(() => isCompressingPhoto = false);
              }
            }

            Future<void> readGpsForDestino() async {
              setDialogState(() => isReadingGps = true);
              try {
                final pos = await _locationService.getCurrentRealPosition();
                setDialogState(() {
                  currentGeoPoint = GeoPoint(pos.latitude, pos.longitude);
                  isReadingGps = false;
                });
              } catch (e) {
                setDialogState(() => isReadingGps = false);
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('$e'),
                      backgroundColor: Colors.orange.shade800,
                    ),
                  );
                }
              }
            }

            return AlertDialog(
              title: Text(
                isEditing ? 'Editar Destino Propio' : 'Nuevo Destino Propio',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: tituloCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Título del destino',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: paisCtrl,
                      decoration: const InputDecoration(
                        labelText: 'País',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: categoria,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const ['España', 'Europa', 'Asia', 'América']
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => categoria = val);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botones de Foto Cámara/Galería con Isolate (< 300 KB Base64)
                    const Text(
                      ' Miniatura Base64 (< 300 KB en Isolate):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isCompressingPhoto
                                ? null
                                : () => pickAndCompress(ImageSource.camera),
                            icon: const Icon(
                              Icons.photo_camera_outlined,
                              size: 16,
                            ),
                            label: const Text(
                              'Cámara',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isCompressingPhoto
                                ? null
                                : () => pickAndCompress(ImageSource.gallery),
                            icon: const Icon(
                              Icons.photo_library_outlined,
                              size: 16,
                            ),
                            label: const Text(
                              'Galería',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isCompressingPhoto) ...[
                      const SizedBox(height: 8),
                      Text(
                        '$photoStage (${(photoProgress * 100).toInt()}%)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: photoProgress),
                    ],
                    if (compressedKb != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '✅ Miniatura Base64 lista: ${compressedKb!.toStringAsFixed(1)} KB (< 300 KB)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),
                    // Posición GeoPoint real del documento
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'GeoPoint: (${currentGeoPoint.latitude.toStringAsFixed(3)}, ${currentGeoPoint.longitude.toStringAsFixed(3)})',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: isReadingGps ? null : readGpsForDestino,
                          icon: const Icon(Icons.my_location, size: 15),
                          label: Text(
                            isReadingGps ? 'Leyendo...' : 'Usar mi GPS',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Valoración (Rating):'),
                        Text(
                          rating.toStringAsFixed(2),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: rating,
                      min: 4.0,
                      max: 5.0,
                      divisions: 20,
                      activeColor: Colors.deepPurple,
                      onChanged: (v) => setDialogState(() => rating = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isCompressingPhoto
                      ? null
                      : () async {
                          final titulo = tituloCtrl.text.trim();
                          final pais = paisCtrl.text.trim();
                          if (titulo.isEmpty || pais.isEmpty) return;

                          Navigator.pop(ctx);
                          try {
                            final user = _authService.getCurrentUser();
                            if (isEditing) {
                              await _firestoreService.updateDestination(
                                existing.id,
                                titulo: titulo,
                                pais: pais,
                                categoria: categoria,
                                descripcion: descCtrl.text.trim(),
                                rating: double.parse(rating.toStringAsFixed(2)),
                                imagenUrl: customImageUrl,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Documento propio actualizado en Firestore (update)',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              final nuevo = Destino(
                                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                                titulo: titulo,
                                pais: pais,
                                categoria: categoria,
                                descripcion: descCtrl.text.trim(),
                                imagenUrl: customImageUrl ??
                                    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500',
                                rating: double.parse(rating.toStringAsFixed(2)),
                                coordenadas: currentGeoPoint,
                                fechaCreacion: DateTime.now(),
                                creadorId: user?.uid ?? 'demo_user_1',
                              );
                              await _firestoreService.createDestination(nuevo);
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Nuevo destino guardado en Firestore con GeoPoint y Timestamp',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                            await _executeActiveQuery();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Error al guardar en Firestore: $e',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Guardar cambios' : 'Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Muestra un `AlertDialog` modal de confirmación antes de borrar un documento propio con `delete`.
  Future<void> _confirmAndDeleteDestination(Destino item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Confirmar eliminación')),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar tu documento "${item.titulo}" de Cloud Firestore?\n\n'
          'Esta operación ejecutará delete() y no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestoreService.deleteDestination(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Documento "${item.titulo}" eliminado de Firestore.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      await _executeActiveQuery();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar documento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.getCurrentUser()?.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_dest_fab',
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        onPressed: () => _showCreateOrEditDialog(),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Nuevo Destino'),
      ),
      body: Column(
        children: [
          // Selector de las 4 Consultas Avanzadas de Firestore (Bloque 2)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.storage_rounded,
                      size: 18,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Consultas Firestore (20+ docs):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Simular estado de error',
                      icon: const Icon(
                        Icons.bug_report_outlined,
                        color: Colors.orange,
                      ),
                      onPressed: () => _executeActiveQuery(forceError: true),
                    ),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQueryChip(
                        FirestoreQueryMode.compoundWhere,
                        '1. where (2 cond)',
                        Icons.filter_alt_outlined,
                      ),
                      _buildQueryChip(
                        FirestoreQueryMode.orderByLimit,
                        '2. orderBy + limit(5)',
                        Icons.leaderboard_outlined,
                      ),
                      _buildQueryChip(
                        FirestoreQueryMode.dateRange,
                        '3. Rango Fechas',
                        Icons.date_range_outlined,
                      ),
                      _buildQueryChip(
                        FirestoreQueryMode.paginated,
                        '4. Paginación Cursor',
                        Icons.auto_stories_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _buildSubFilterControls(),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: _buildBodyState(currentUserId),
          ),
        ],
      ),
    );
  }

  Widget _buildQueryChip(
    FirestoreQueryMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = _queryMode == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
        ),
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.deepPurple.shade100,
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.deepPurple : Colors.grey.shade800,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _queryMode = mode;
            });
            _executeActiveQuery();
          }
        },
      ),
    );
  }

  /// Controles dinámicos según cuál de las 4 consultas esté activa.
  Widget _buildSubFilterControls() {
    switch (_queryMode) {
      case FirestoreQueryMode.compoundWhere:
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...['España', 'Europa', 'Asia', 'América'].map((cat) {
                final selected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(cat, style: const TextStyle(fontSize: 11)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                      _executeActiveQuery();
                    },
                  ),
                );
              }),
              ActionChip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  'Rating >= ${_minRating.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _minRating = _minRating >= 4.85 ? 4.7 : 4.85;
                  });
                  _executeActiveQuery();
                },
              ),
            ],
          ),
        );

      case FirestoreQueryMode.orderByLimit:
        return const Text(
          'Consulta activa: .orderBy("rating", descending: true).limit(5)',
          style: TextStyle(fontSize: 11, color: Colors.deepPurple),
        );

      case FirestoreQueryMode.dateRange:
        return Row(
          children: [
            const Text(
              'Rango Timestamp:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            ...[10, 20, 60].map((days) {
              final selected = _dateRangeDays == days;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    'Últimos $days días',
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: selected,
                  onSelected: (_) {
                    setState(() => _dateRangeDays = days);
                    _executeActiveQuery();
                  },
                ),
              );
            }),
          ],
        );

      case FirestoreQueryMode.paginated:
        return Text(
          'Mostrando ${_destinos.length} docs (.orderBy("titulo").limit(6) + startAfterDocument)',
          style: const TextStyle(fontSize: 11, color: Colors.deepPurple),
        );
    }
  }

  Widget _buildBodyState(String? currentUserId) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 60,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Error al cargar la cuadrícula',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _executeActiveQuery(forceError: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_destinos.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron destinos para los criterios de esta consulta.',
          style: TextStyle(fontSize: 15, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: _destinos.length,
            itemBuilder: (context, index) {
              final item = _destinos[index];
              // Bloque 3 estricto: solo los documentos propios se pueden editar o borrar
              final bool canModify =
                  currentUserId != null && item.creadorId == currentUserId;

              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => _showDestinoDetailModal(item, canModify),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildDestinoImage(item.imagenUrl),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.rating}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (canModify)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () => _showCreateOrEditDialog(
                                          existing: item,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(5),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            size: 16,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () =>
                                            _confirmAndDeleteDestination(item),
                                        child: Padding(
                                          padding: const EdgeInsets.all(5),
                                          child: Icon(
                                            Icons.delete_outline,
                                            size: 16,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.titulo,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    '${item.pais} • ${item.categoria}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Botón de paginación con cursor startAfterDocument (Consulta 4)
        if (_queryMode == FirestoreQueryMode.paginated && _hasMorePages)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            color: Colors.white,
            child: OutlinedButton.icon(
              onPressed: _isLoadingMorePage ? null : _loadNextPage,
              icon: _isLoadingMorePage
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.read_more),
              label: Text(
                _isLoadingMorePage
                    ? 'Cargando página siguiente...'
                    : 'Cargar siguiente página (startAfterDocument)',
              ),
            ),
          ),
      ],
    );
  }
}
