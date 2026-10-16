import 'package:flutter/material.dart';
import 'package:dam_proyect/models/trip_preferences.dart';

class TripDetailScreen extends StatefulWidget {
  final TripPreferences preferences;

  const TripDetailScreen({
    super.key,
    required this.preferences,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  String _activeCategory = 'restaurantes';

  List<Map<String, String>> _getCategoryResults() {
    final prefs = widget.preferences;
    final cityName = prefs.city.split(',').first.trim();

    if (_activeCategory == 'restaurantes') {
      final totalCount = 3 + prefs.tripDays;
      final styleName = prefs.diningStyle.toUpperCase();
      final priceSymbol = prefs.diningPrice == 'economico'
          ? '€'
          : prefs.diningPrice == 'lujo'
              ? '€€€'
              : '€€';

      return List.generate(totalCount, (index) {
        if (index < 3) {
          return {
            'title': 'Restaurante $styleName Top #${index + 1} en $cityName',
            'subtitle': 'Selección de estilo $styleName acorde a tus preferencias',
            'tag': 'Top 3 $styleName',
            'rating': '4.${9 - index}',
            'price': priceSymbol,
          };
        } else {
          final dayNum = index - 2;
          return {
            'title': 'Restaurante $styleName - Día $dayNum',
            'subtitle': 'Sugerencia gastronómica $styleName para la comida del Día $dayNum',
            'tag': 'Sugerencia Día $dayNum',
            'rating': '4.7',
            'price': priceSymbol,
          };
        }
      });
    } else if (_activeCategory == 'hotel') {
      final priceSymbol = prefs.lodgingPrice == 'economico'
          ? '€'
          : prefs.lodgingPrice == 'lujo'
              ? '€€€€'
              : '€€€';
      final vibesText = prefs.lodgingVibes.join(', ').toUpperCase();

      return [
        {
          'title': 'Grand Hotel $cityName',
          'subtitle': 'Alojamiento seleccionado con ambiente [$vibesText]',
          'tag': 'Recomendación Hotel',
          'rating': '4.9',
          'price': priceSymbol,
        },
      ];
    } else if (_activeCategory == 'apartamento') {
      final priceSymbol = prefs.lodgingPrice == 'economico'
          ? '€'
          : prefs.lodgingPrice == 'lujo'
              ? '€€€'
              : '€€';

      return [
        {
          'title': 'Apartamento Turístico $cityName',
          'subtitle': 'Apartamento completo para ${prefs.tripDays} días de estancia con ambiente ideal',
          'tag': 'Recomendación Apartamento',
          'rating': '4.8',
          'price': priceSymbol,
        },
      ];
    } else {
      final paceText = prefs.pace.toUpperCase();
      final actText = prefs.activityTypes.join(', ').toUpperCase();

      return [
        {
          'title': 'Ruta de Ocio ($actText) en $cityName',
          'subtitle': 'Planificación a ritmo $paceText adaptado a ${prefs.tripDays} días de viaje',
          'tag': 'Ritmo $paceText',
          'rating': '4.9',
          'price': 'Gratis',
        },
        {
          'title': 'Experiencia Cultural y Destacados de $cityName',
          'subtitle': 'Cultura y principales puntos de interés dentro del radio de ${prefs.radiusKm.toStringAsFixed(1)} km',
          'tag': 'Puntos de Interés',
          'rating': '4.8',
          'price': '€15',
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = widget.preferences;
    final results = _getCategoryResults();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Text(
          prefs.city.split(',').first,
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
                        prefs.city,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.calendar_today, size: 16, color: Colors.deepPurple),
                      label: Text('${prefs.tripDays} ${prefs.tripDays == 1 ? "día" : "días"}'),
                      backgroundColor: Colors.deepPurple.shade50,
                      side: BorderSide.none,
                    ),
                    Chip(
                      avatar: const Icon(Icons.radar, size: 16, color: Colors.deepPurple),
                      label: Text('Radio ${prefs.radiusKm.toStringAsFixed(1)} km'),
                      backgroundColor: Colors.deepPurple.shade50,
                      side: BorderSide.none,
                    ),
                    Chip(
                      avatar: const Icon(Icons.restaurant, size: 16, color: Colors.deepPurple),
                      label: Text(prefs.diningStyle.toUpperCase()),
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
                    label: '🍽️ Restaurantes (${3 + prefs.tripDays})',
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
