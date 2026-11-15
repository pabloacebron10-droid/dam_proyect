import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:dam_proyect/models/trip_preferences.dart';

/// Modelo para los elementos mostrados en la sección en cuadrícula.
class DestinoItem {
  final String id;
  final String titulo;
  final String pais;
  final String imagenUrl;
  final double rating;
  final String categoria;
  final LatLng location;

  const DestinoItem({
    required this.id,
    required this.titulo,
    required this.pais,
    required this.imagenUrl,
    required this.rating,
    required this.categoria,
    required this.location,
  });
}

/// Pantalla de exploración en Cuadrícula (GridView) - Sección 3 de la Barra Inferior.
///
/// Presenta los destinos recomendados en un formato de cuadrícula de 2 columnas,
/// e incluye control completo de estados de pantalla: Carga, Éxito, Vacío y Error
/// con botón de reintento en pantalla para cumplir con la rúbrica del proyecto.
class GridExploreScreen extends StatefulWidget {
  const GridExploreScreen({super.key});

  @override
  State<GridExploreScreen> createState() => _GridExploreScreenState();
}

class _GridExploreScreenState extends State<GridExploreScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'Todos';

  List<DestinoItem> _allDestinos = [];
  List<DestinoItem> _filteredDestinos = [];

  @override
  void initState() {
    super.initState();
    _loadDestinosData();
  }

  /// Carga simulada de datos de la cuadrícula con manejo explícito de errores.
  Future<void> _loadDestinosData({bool forceError = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      if (forceError) {
        throw Exception('No se pudo conectar con el servidor de destinos. Comprueba tu red.');
      }

      final items = const [
        DestinoItem(
          id: '1',
          titulo: 'París',
          pais: 'Francia',
          imagenUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=500',
          rating: 4.9,
          categoria: 'Europa',
          location: LatLng(48.8566, 2.3522),
        ),
        DestinoItem(
          id: '2',
          titulo: 'Roma',
          pais: 'Italia',
          imagenUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=500',
          rating: 4.8,
          categoria: 'Europa',
          location: LatLng(41.9028, 12.4964),
        ),
        DestinoItem(
          id: '3',
          titulo: 'Tokio',
          pais: 'Japón',
          imagenUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=500',
          rating: 4.95,
          categoria: 'Asia',
          location: LatLng(35.6762, 139.6503),
        ),
        DestinoItem(
          id: '4',
          titulo: 'Nueva York',
          pais: 'EE.UU.',
          imagenUrl: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?w=500',
          rating: 4.75,
          categoria: 'América',
          location: LatLng(40.7128, -74.0060),
        ),
        DestinoItem(
          id: '5',
          titulo: 'Barcelona',
          pais: 'España',
          imagenUrl: 'https://images.unsplash.com/photo-1583422409516-2895a77efded?w=500',
          rating: 4.85,
          categoria: 'Europa',
          location: LatLng(41.3851, 2.1734),
        ),
        DestinoItem(
          id: '6',
          titulo: 'Kyoto',
          pais: 'Japón',
          imagenUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=500',
          rating: 4.9,
          categoria: 'Asia',
          location: LatLng(35.0116, 135.7681),
        ),
      ];

      if (mounted) {
        setState(() {
          _allDestinos = items;
          _applyCategoryFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _applyCategoryFilter() {
    if (_selectedCategory == 'Todos') {
      _filteredDestinos = List.from(_allDestinos);
    } else {
      _filteredDestinos =
          _allDestinos.where((d) => d.categoria == _selectedCategory).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // Barra de herramientas de filtro y botón de simulación de error
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Todos', 'Europa', 'Asia', 'América'].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: Colors.deepPurple.shade100,
                            checkmarkColor: Colors.deepPurple,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.deepPurple
                                  : Colors.grey.shade800,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategory = cat;
                                  _applyCategoryFilter();
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Simular estado de error',
                  icon: const Icon(Icons.bug_report_outlined, color: Colors.orange),
                  onPressed: () => _loadDestinosData(forceError: true),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Cuerpo con manejo de estados (Carga, Error, Vacío, Cuadrícula)
          Expanded(
            child: _buildBodyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyState() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // ESTADO DE ERROR EN PANTALLA CON BOTÓN DE REINTENTAR
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
                onPressed: () => _loadDestinosData(forceError: false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

    // ESTADO VACÍO
    if (_filteredDestinos.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron destinos en esta categoría.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // ESTADO ÉXITO: VISTA EN CUADRÍCULA (GRIDVIEW.BUILDER)
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _filteredDestinos.length,
      itemBuilder: (context, index) {
        final item = _filteredDestinos[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/trip_wizard',
                arguments: TripWizardArgs(
                  city: '${item.titulo}, ${item.pais}',
                  location: item.location,
                  radiusKm: 5.0,
                  tripDays: 3,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        item.imagenUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: Colors.deepPurple.shade100,
                          child: const Icon(
                            Icons.landscape_rounded,
                            size: 40,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 14),
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
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.titulo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              item.pais,
                              style: TextStyle(
                                fontSize: 13,
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
    );
  }
}
