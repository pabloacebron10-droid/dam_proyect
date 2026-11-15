import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dam_proyect/models/perfil.dart';
import 'package:dam_proyect/services/auth_service.dart';
import 'package:dam_proyect/services/firestore_service.dart';
import 'package:dam_proyect/services/image_isolate_service.dart';
import 'package:dam_proyect/services/location_service.dart';

/// Pantalla de Gestión de Perfil de Usuario (`ProfileScreen`).
///
/// **Por qué:** Permite consultar y editar los datos del perfil (nombre y fotografía).
/// Cumple con el **Bloque 4 de la rúbrica (`0489 RA2.n, 2.d`, `0490 RA2.c`, `0486 RA4.d`)**:
/// - Selección desde Cámara y Galería con tratamiento explícito de denegación de permisos.
/// - Compresión y redimensionado de la imagen dentro de un `Isolate` secundario (`ImageIsolateService`)
///   comunicando el progreso en tiempo real (`LinearProgressIndicator`) sin congelar la interfaz.
/// - Garantiza miniaturas inferiores a `300 KB` tanto en binario como en cadena Base64.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoadingData = true;
  bool _isSaving = false;
  bool _isUpdatingGps = false;

  // Estado de compresión en Isolate
  bool _isCompressingInIsolate = false;
  double _compressionProgress = 0.0;
  String _compressionStage = '';
  double? _compressedSizeKb;
  String? _compressedBase64DataUri;

  Uint8List? _selectedImageBytes;
  String? _fotoUrl;
  GeoPoint? _ultimaUbicacion;
  DateTime? _ultimaFechaUbicacion;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Carga los datos del perfil del usuario actualmente autenticado desde Cloud Firestore.
  Future<void> _loadProfile() async {
    final user = _authService.getCurrentUser();
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
      return;
    }

    try {
      final perfil = await _firestoreService.getProfileByUid(user.uid);
      if (!mounted) return;

      if (perfil != null) {
        _nameController.text = perfil.nombre;
        _emailController.text = perfil.email;
        _fotoUrl = perfil.fotoUrl;
        _ultimaUbicacion = perfil.ubicacion;
        _ultimaFechaUbicacion = perfil.ultimaActualizacionUbicacion;
      } else {
        _nameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
        _fotoUrl = user.photoURL;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el perfil: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  /// Muestra un cuadro de diálogo explicativo cuando el usuario deniega el permiso de cámara o galería.
  void _showPermissionDeniedDialog(ImageSource source, String detail) {
    final origen = source == ImageSource.camera ? 'la Cámara' : 'la Galería';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.privacy_tip_outlined, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text('Permiso denegado para $origen')),
          ],
        ),
        content: Text(
          'No se ha concedido acceso a $origen del dispositivo.\n\n'
          'Para actualizar tu foto de perfil, concede el permiso en los Ajustes del sistema.\n'
          'Detalle: $detail',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /// Permite seleccionar una foto utilizando la cámara o la galería y la comprime en un `Isolate`.
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) {
        return;
      }

      final rawBytes = await pickedFile.readAsBytes();
      if (!mounted) return;

      setState(() {
        _isCompressingInIsolate = true;
        _compressionProgress = 0.05;
        _compressionStage = 'Preparando Isolate...';
      });

      final CompressedImageResult compressed =
          await ImageIsolateService.compressImageWithProgress(
        rawBytes,
        maxDimension: 480,
        onProgress: (progress, stage) {
          if (mounted) {
            setState(() {
              _compressionProgress = progress;
              _compressionStage = stage;
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _selectedImageBytes = compressed.bytes;
        _compressedBase64DataUri = compressed.base64DataUri;
        _compressedSizeKb = compressed.sizeKb;
        _isCompressingInIsolate = false;
      });
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _isCompressingInIsolate = false;
        });
        _showPermissionDeniedDialog(
          source,
          e.message ?? e.code,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCompressingInIsolate = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la imagen: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Despliega el menú modal inferior para elegir el origen de la fotografía (cámara o galería).
  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.deepPurple,
                ),
                title: const Text('Galería de fotos'),
                subtitle: const Text(
                  'Seleccionar imagen y comprimir en Isolate (< 300 KB)',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: Colors.deepPurple,
                ),
                title: const Text('Cámara'),
                subtitle: const Text(
                  'Capturar fotografía y comprimir en Isolate (< 300 KB)',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Lee la posición GPS actual con `geolocator`, la guarda como `GeoPoint` + `Timestamp`
  /// en el documento de perfil de Firestore y la lee de vuelta tipada (Bloque 5).
  Future<void> _updateMyGpsInProfile() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    setState(() {
      _isUpdatingGps = true;
    });

    try {
      final pos = await _locationService.getCurrentRealPosition();
      final nuevoGeoPoint = GeoPoint(pos.latitude, pos.longitude);
      await _firestoreService.updateUserLocation(user.uid, nuevoGeoPoint);

      // Leer de vuelta tipada desde Firestore
      final perfilLeido = await _firestoreService.getProfileByUid(user.uid);
      if (!mounted) return;

      setState(() {
        _ultimaUbicacion = perfilLeido?.ubicacion ?? nuevoGeoPoint;
        _ultimaFechaUbicacion =
            perfilLeido?.ultimaActualizacionUbicacion ?? DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Posición guardada y leída de Firestore: GeoPoint(${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on LocationFailureException catch (e) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_off_outlined, color: Colors.redAccent),
              SizedBox(width: 8),
              Expanded(child: Text('Aviso de Localización GPS')),
            ],
          ),
          content: Text(e.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar posición GPS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingGps = false;
        });
      }
    }
  }

  /// Guarda los cambios introducidos en el perfil en Firebase Storage y Cloud Firestore.
  Future<void> _saveProfile() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    final nombre = _nameController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre no puede estar vacío'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? nuevaFotoUrl = _fotoUrl;

      if (_selectedImageBytes != null) {
        // Guardar la miniatura resultante (< 300 KB) como texto Base64 directamente
        // dentro del documento de Firestore (Bloque 4 de la rúbrica).
        nuevaFotoUrl = _compressedBase64DataUri ??
            'data:image/jpeg;base64,${base64Encode(_selectedImageBytes!)}';
      }

      final perfilActualizado = Perfil(
        uId: user.uid,
        nombre: nombre,
        email: user.email ?? _emailController.text,
        fotoUrl: nuevaFotoUrl,
        ubicacion: _ultimaUbicacion,
        ultimaActualizacionUbicacion: _ultimaFechaUbicacion,
      );

      await _firestoreService.saveProfile(perfilActualizado);

      if (!mounted) return;

      setState(() {
        _fotoUrl = nuevaFotoUrl;
        _selectedImageBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente en Firestore'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error al guardar perfil: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Renderea el widget de imagen soportando selección en memoria, Base64 o URL remota HTTPS.
  Widget _buildAvatarWidget() {
    if (_selectedImageBytes != null) {
      return Image.memory(
        _selectedImageBytes!,
        fit: BoxFit.cover,
        width: 130,
        height: 130,
      );
    }

    if (_fotoUrl != null && _fotoUrl!.isNotEmpty) {
      if (_fotoUrl!.startsWith('data:image/')) {
        try {
          final base64String = _fotoUrl!.split(',').last;
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: 130,
            height: 130,
          );
        } catch (e) {
          debugPrint('Error decodificando Base64: $e');
        }
      } else if (_fotoUrl!.startsWith('http://') ||
          _fotoUrl!.startsWith('https://')) {
        return Image.network(
          _fotoUrl!,
          fit: BoxFit.cover,
          width: 130,
          height: 130,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.person_rounded,
              size: 70,
              color: Colors.deepPurple,
            );
          },
        );
      }
    }

    return const Icon(
      Icons.person_rounded,
      size: 70,
      color: Colors.deepPurple,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: _buildAvatarWidget(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: Colors.deepPurple,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: (_isSaving || _isCompressingInIsolate)
                          ? null
                          : _showImageSourceModal,
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Barra de progreso de compresión en Isolate (Bloque 4 - PSP 0490)
          if (_isCompressingInIsolate) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _compressionStage,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      Text(
                        '${(_compressionProgress * 100).toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _compressionProgress,
                    backgroundColor: Colors.white,
                    color: Colors.deepPurple,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Text(
            _selectedImageBytes != null
                ? 'Miniatura procesada en Isolate (${_compressedSizeKb?.toStringAsFixed(1) ?? "?"} KB < 300 KB)'
                : 'Toca la cámara para elegir foto de Cámara o Galería',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _selectedImageBytes != null
                  ? Colors.green.shade800
                  : Colors.grey.shade600,
              fontWeight: _selectedImageBytes != null
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),

          const SizedBox(height: 16),
          // Tarjeta Bloque 5: Dónde estoy (GeoPoint + Timestamp guardados y leídos de Firestore)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.gps_fixed, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mi Posición GPS en Firestore (GeoPoint + Timestamp)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _ultimaUbicacion != null
                      ? 'GeoPoint: (${_ultimaUbicacion!.latitude.toStringAsFixed(5)}, ${_ultimaUbicacion!.longitude.toStringAsFixed(5)})\n'
                          'Timestamp: ${_ultimaFechaUbicacion != null ? "${_ultimaFechaUbicacion!.day.toString().padLeft(2, "0")}/${_ultimaFechaUbicacion!.month.toString().padLeft(2, "0")}/${_ultimaFechaUbicacion!.year} ${_ultimaFechaUbicacion!.hour.toString().padLeft(2, "0")}:${_ultimaFechaUbicacion!.minute.toString().padLeft(2, "0")}:${_ultimaFechaUbicacion!.second.toString().padLeft(2, "0")}" : "Recién actualizado"}'
                      : 'Aún no has guardado tu posición GPS en este perfil.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isUpdatingGps ? null : _updateMyGpsInProfile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade800,
                    side: BorderSide(color: Colors.blue.shade400),
                    backgroundColor: Colors.white,
                  ),
                  icon: _isUpdatingGps
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 17),
                  label: Text(
                    _isUpdatingGps
                        ? 'Leyendo GPS con geolocator...'
                        : 'Dónde estoy: Leer y guardar mi GPS ahora',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Nombre de usuario',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _nameController,
            enabled: !_isSaving,
            decoration: InputDecoration(
              hintText: 'Introduce tu nombre',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Correo electrónico',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _emailController,
            enabled: false,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              filled: true,
              fillColor: Colors.grey.shade200,
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed:
                  (_isSaving || _isCompressingInIsolate) ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSaving ? 'Guardando...' : 'Guardar cambios',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
