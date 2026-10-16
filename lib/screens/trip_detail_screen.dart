import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class TripDetailScreen extends StatefulWidget {
  final String city;
  final LatLng location;
  final double radiusKm;
  final int tripDays;

  const TripDetailScreen({
    super.key,
    required this.city,
    required this.location,
    required this.radiusKm,
    required this.tripDays,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  String _activeCategory = 'restaurantes'; // 'restaurantes', 'hotel', 'apartamento', 'ocio'

  List<Map<String, String>> _getCategoryResults() {
    final cityName = widget.city.split(',').first.trim();

    if (_activeCategory == 'restaurantes') {
      final totalCount = 3 + widget.tripDays;
      return List.generate(totalCount, (index) {
        if (index < 3) {
          return {
            'title': 'Restaurante Top #${index + 1} en $cityName',
            'subtitle': 'Gastronomía de alta calidad • Top Recomendación',
            'tag': 'Top 3 General',
            'rating': '4.${9 - index}',
            'price': '€€€',
          };
        } else {
          final dayNum = index - 2;
          return {
            'title': 'Restaurante Recomendado - Día $dayNum',
            'subtitle': 'Plato especial y menú degustación para el día $dayNum',
            'tag': 'Sugerencia Día $dayNum',
            'rating': '4.7',
            'price': '€€',
          };
        }
      });
    } else if (_activeCategory == 'hotel') {
      return [
        {
          'title': 'Grand Hotel $cityName & Spa',
          'subtitle': 'La mejor opción hotelera recomendada en el centro de $cityName',
          'tag': 'Mejor Opción Hotel',
          'rating': '4.9',
          'price': '€€€€',
        },
      ];
    } else if (_activeCategory == 'apartamento') {
      return [
        {
          'title': 'Apartamento Turístico Premium $cityName',
          'subtitle': 'Apartamento completo totalmente equipado para ${widget.tripDays} días de estancia',
          'tag': 'Mejor Apartamento',
          'rating': '4.8',
          'price': '€€',
        },
      ];
    } else {
      return [
        {
          'title': 'Ruta Imprescindible por $cityName',
          'subtitle': 'Recorrido por las atracciones principales adaptado a ${widget.tripDays} días',
          'tag': 'Imperdible',
          'rating': '4.9',
          'price': 'Gratis',
        },
        {
          'title': 'Museo y Centro Cultural de $cityName',
          'subtitle': 'Exposiciones y patrimonio histórico',
          'tag': 'Cultura',
          'rating': '4.8',
          'price': '€15',
        },
        {
          'title': 'Paseo Guiado y Mirador Panorámico',
          'subtitle': 'Las mejores vistas de la ciudad al atardecer',
          'tag': 'Actividad',
          'rating': '4.7',
          'price': '€10',
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _getCategoryResults();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Text(
          widget.city.split(',').first,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.city,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Chip(
                      avatar: const Icon(Icons.calendar_today, size: 16, color: Colors.deepPurple),
                      label: Text('${widget.tripDays} ${widget.tripDays == 1 ? "día" : "días"} de viaje'),
                      backgroundColor: Colors.deepPurple.shade50,
                      side: BorderSide.none,
                    ),
                    const SizedBox(width: 10),
                    Chip(
                      avatar: const Icon(Icons.radar, size: 16, color: Colors.deepPurple),
                      label: Text('Radio ${widget.radiusKm.toStringAsFixed(1)} km'),
                      backgroundColor: Colors.deepPurple.shade50,
                      side: BorderSide.none,
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryButton(
                    id: 'restaurantes',
                    label: '🍽️ Restaurantes (${3 + widget.tripDays})',
                  ),
                  _buildCategoryButton(
                    id: 'hotel',
                    label: '🏨 Hotel',
                  ),
                  _buildCategoryButton(
                    id: 'apartamento',
                    label: '🏢 Apartamento',
                  ),
                  _buildCategoryButton(
                    id: 'ocio',
                    label: '🎭 Ocio y Actividades',
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final item = results[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item['tag'] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  item['rating'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  item['price'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['subtitle'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton({required String id, required String label}) {
    final isSelected = _activeCategory == id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _activeCategory = id;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.deepPurple : Colors.grey.shade200,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
