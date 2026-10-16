import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:dam_proyect/models/trip_preferences.dart';
import 'package:dam_proyect/screens/trip_detail_screen.dart';

class TripWizardScreen extends StatefulWidget {
  final String city;
  final LatLng location;
  final double radiusKm;
  final int tripDays;

  const TripWizardScreen({
    super.key,
    required this.city,
    required this.location,
    required this.radiusKm,
    required this.tripDays,
  });

  @override
  State<TripWizardScreen> createState() => _TripWizardScreenState();
}

class _TripWizardScreenState extends State<TripWizardScreen> {
  late final TripPreferences _preferences;
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _preferences = TripPreferences(
      city: widget.city,
      location: widget.location,
      radiusKm: widget.radiusKm,
      tripDays: widget.tripDays,
    );
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TripDetailScreen(
            preferences: _preferences,
          ),
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cityName = widget.city.split(',').first;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Text(
          'Personaliza tu viaje a $cityName',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paso ${_currentStep + 1} de 3',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    Text(
                      _currentStep == 0
                          ? '🏨 Alojamiento'
                          : _currentStep == 1
                              ? '🍽️ Restaurantes'
                              : '🎭 Ocio & Ritmo',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 3,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.deepPurple,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildStep1Lodging(cityName),
                _buildStep2Dining(cityName),
                _buildStep3Activities(cityName),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.deepPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text('Anterior'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: Icon(
                        _currentStep == 2
                            ? Icons.auto_awesome
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        _currentStep == 2
                            ? 'Generar Recomendaciones'
                            : 'Siguiente Paso',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Lodging(String cityName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('1. ¿Qué tipo de alojamiento buscas?'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSelectionCard(
                label: 'Hotel',
                icon: Icons.hotel_rounded,
                selected: _preferences.lodgingType == 'hotel',
                onTap: () => setState(() => _preferences.lodgingType = 'hotel'),
              ),
              const SizedBox(width: 10),
              _buildSelectionCard(
                label: 'Apartamento',
                icon: Icons.apartment_rounded,
                selected: _preferences.lodgingType == 'apartamento',
                onTap: () => setState(() => _preferences.lodgingType = 'apartamento'),
              ),
              const SizedBox(width: 10),
              _buildSelectionCard(
                label: 'Ambos',
                icon: Icons.domain_add_rounded,
                selected: _preferences.lodgingType == 'ambos',
                onTap: () => setState(() => _preferences.lodgingType = 'ambos'),
              ),
            ],
          ),

          const SizedBox(height: 28),

          _buildSectionTitle('Presupuesto de alojamiento'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSelectionCard(
                label: 'Económico (€)',
                icon: Icons.euro_symbol_rounded,
                selected: _preferences.lodgingPrice == 'economico',
                onTap: () => setState(() => _preferences.lodgingPrice = 'economico'),
              ),
              const SizedBox(width: 10),
              _buildSelectionCard(
                label: 'Moderado (€€)',
                icon: Icons.payments_rounded,
                selected: _preferences.lodgingPrice == 'moderado',
                onTap: () => setState(() => _preferences.lodgingPrice = 'moderado'),
              ),
              const SizedBox(width: 10),
              _buildSelectionCard(
                label: 'Lujo (€€€)',
                icon: Icons.diamond_rounded,
                selected: _preferences.lodgingPrice == 'lujo',
                onTap: () => setState(() => _preferences.lodgingPrice = 'lujo'),
              ),
            ],
          ),

          const SizedBox(height: 28),

          _buildSectionTitle('¿Qué ambiente te gustaría? (Selección múltiple)'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMultiChip('📍 Cerca del centro', 'centrico', _preferences.lodgingVibes),
              _buildMultiChip('🏙️ Urbano y dinámico', 'urbano', _preferences.lodgingVibes),
              _buildMultiChip('🏡 Rústico y con encanto', 'rustico', _preferences.lodgingVibes),
              _buildMultiChip('🌿 Tranquilo y relajante', 'tranquilo', _preferences.lodgingVibes),
              _buildMultiChip('🌃 Con vida nocturna', 'con_vida', _preferences.lodgingVibes),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Dining(String cityName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('2. Estilo gastronómico en $cityName'),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildListOptionTile(
                title: '🥘 Tradicional / Local',
                subtitle: 'Platos típicos y comida auténtica de la zona',
                selected: _preferences.diningStyle == 'tradicional',
                onTap: () => setState(() => _preferences.diningStyle = 'tradicional'),
              ),
              const SizedBox(height: 10),
              _buildListOptionTile(
                title: '🍢 Tapas y Raciones',
                subtitle: 'Comida informal, de bar en bar',
                selected: _preferences.diningStyle == 'tapas',
                onTap: () => setState(() => _preferences.diningStyle = 'tapas'),
              ),
              const SizedBox(height: 10),
              _buildListOptionTile(
                title: '🍕 Internacional',
                subtitle: 'Comida variada e ingredientes de todo el mundo',
                selected: _preferences.diningStyle == 'internacional',
                onTap: () => setState(() => _preferences.diningStyle = 'internacional'),
              ),
              const SizedBox(height: 10),
              _buildListOptionTile(
                title: '🍷 Alta Cocina / Gourmet',
                subtitle: 'Restaurantes galardonados e innovación culinaria',
                selected: _preferences.diningStyle == 'alta_cocina',
                onTap: () => setState(() => _preferences.diningStyle = 'alta_cocina'),
              ),
            ],
          ),

          const SizedBox(height: 28),

          _buildSectionTitle('Presupuesto por comida'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSelectionCard(
                label: 'Asequible (€)',
                icon: Icons.savings_rounded,
                selected: _preferences.diningPrice == 'economico',
                onTap: () => setState(() => _preferences.diningPrice = 'economico'),
              ),
              const SizedBox(width: 10),
              _buildSelectionCard(
                label: 'Estándar (€€)',
                icon: Icons.restaurant_rounded,
                selected: _preferences.diningPrice == 'moderado',
                onTap: () => setState(() => _preferences.diningPrice = 'moderado'),
              ),
              const SizedBox(width: 10),
              _buildSelectionCard(
                label: 'Gourmet (€€€)',
                icon: Icons.wine_bar_rounded,
                selected: _preferences.diningPrice == 'lujo',
                onTap: () => setState(() => _preferences.diningPrice = 'lujo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Activities(String cityName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('3. ¿Qué tipo de actividades prefieres?'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMultiChip('🏛️ Cultura y Museos', 'cultura', _preferences.activityTypes),
              _buildMultiChip('🌲 Naturaleza y Parques', 'naturaleza', _preferences.activityTypes),
              _buildMultiChip('🛍️ Compras y Tiendas', 'compras', _preferences.activityTypes),
              _buildMultiChip('💃 Fiesta y Ocio Nocturno', 'fiesta', _preferences.activityTypes),
              _buildMultiChip('👨‍👩‍👧 Actividades Familiares', 'familiar', _preferences.activityTypes),
            ],
          ),

          const SizedBox(height: 28),

          _buildSectionTitle('Ritmo del viaje'),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSelectionCard(
                label: 'Tranquilo 🧘',
                icon: Icons.spa_rounded,
                selected: _preferences.pace == 'tranquilo',
                onTap: () => setState(() => _preferences.pace = 'tranquilo'),
              ),
              const SizedBox(width: 10),
              _buildSelectionCard(
                label: 'Equilibrado ⚖️',
                icon: Icons.directions_walk_rounded,
                selected: _preferences.pace == 'equilibrado',
                onTap: () => setState(() => _preferences.pace = 'equilibrado'),
              ),
              const SizedBox(width: 10),
              _buildSelectionCard(
                label: 'Intenso ⚡',
                icon: Icons.directions_run_rounded,
                selected: _preferences.pace == 'intenso',
                onTap: () => setState(() => _preferences.pace = 'intenso'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSelectionCard({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.deepPurple : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? Colors.deepPurple : Colors.grey.shade300,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: Colors.deepPurple.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.deepPurple,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListOptionTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? Colors.deepPurple.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.deepPurple : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? Colors.deepPurple : Colors.grey,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.deepPurple : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
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

  Widget _buildMultiChip(String label, String value, List<String> targetList) {
    final isSelected = targetList.contains(value);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.deepPurple,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        setState(() {
          if (selected) {
            targetList.add(value);
          } else {
            if (targetList.length > 1) {
              targetList.remove(value);
            }
          }
        });
      },
    );
  }
}
