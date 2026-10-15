import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dam_proyect/models/perfil.dart';
import 'package:dam_proyect/services/auth_service.dart';
import 'package:dam_proyect/services/firestore_service.dart';
import 'package:dam_proyect/services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoadingData = true;
  bool _isSaving = false;
  Uint8List? _selectedImageBytes;
  String? _fotoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

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
      } else {
        _emailController.text = user.email ?? '';
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 60,
        maxWidth: 600,
        maxHeight: 600,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar la imagen: ${e.toString()}'),
          ),
        );
      }
    }
  }

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
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galería de fotos'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Cámara'),
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
        try {
          debugPrint('Intentando subir foto a Firebase Storage...');
          nuevaFotoUrl = await _storageService.uploadProfilePhoto(
            user.uid,
            _selectedImageBytes!,
          );
          debugPrint('Foto subida con éxito a Storage: $nuevaFotoUrl');
        } catch (storageError) {
          debugPrint('Storage fallo: $storageError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Aviso Storage: ${storageError.toString().replaceFirst('Exception: ', '')}'),
                backgroundColor: Colors.orange.shade800,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          final base64String = base64Encode(_selectedImageBytes!);
          nuevaFotoUrl = 'data:image/jpeg;base64,$base64String';
        }
      }

      final perfilActualizado = Perfil(
        uId: user.uid,
        nombre: nombre,
        email: user.email ?? _emailController.text,
        fotoUrl: nuevaFotoUrl,
      );

      debugPrint('Guardando perfil en Cloud Firestore...');
      await _firestoreService.saveProfile(perfilActualizado);
      debugPrint('Perfil guardado correctamente en Firestore.');

      if (!mounted) return;

      setState(() {
        _fotoUrl = nuevaFotoUrl;
        _selectedImageBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error al guardar perfil: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${e.toString().replaceFirst('Exception: ', '')}'),
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
      } else if (_fotoUrl!.startsWith('http://') || _fotoUrl!.startsWith('https://')) {
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
                      onTap: _isSaving ? null : _showImageSourceModal,
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

          Text(
            _selectedImageBytes != null
                ? 'Foto seleccionada (sin guardar)'
                : 'Toca la cámara para cambiar de foto',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _selectedImageBytes != null
                  ? Colors.deepPurple
                  : Colors.grey.shade600,
              fontWeight: _selectedImageBytes != null
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),

          const SizedBox(height: 35),

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

          const SizedBox(height: 35),

          SizedBox(
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
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
