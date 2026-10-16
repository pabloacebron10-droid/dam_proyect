import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dam_proyect/models/mensaje.dart';
import 'package:dam_proyect/models/perfil.dart';
import 'package:dam_proyect/services/auth_service.dart';
import 'package:dam_proyect/services/firestore_service.dart';
import 'package:dam_proyect/screens/chat_screen.dart';
import 'package:dam_proyect/screens/profile_screen.dart';
import 'package:dam_proyect/screens/map_explore_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _mainNavIndex = 0; // 0: Social, 1: Explorar / Mapa
  int _socialTabIndex = 0; // 0: Chats, 1: Contactos, 2: Perfil

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<List<Mensaje>>? _receivedSub;
  StreamSubscription<List<Mensaje>>? _sentSub;

  final Map<String, Perfil> _profilesCache = {};
  List<Mensaje> _allUserMessages = [];
  List<Perfil> _allContacts = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
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
      final profiles = await _firestoreService.getAllProfiles();
      if (!mounted) return;

      for (final p in profiles) {
        _profilesCache[p.uId] = p;
      }

      setState(() {
        _allContacts = profiles.where((p) => p.uId != user.uid).toList();
      });

      _startListeningMessages(user.uid);
    } catch (e) {
      debugPrint('Error cargando perfiles iniciales: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  void _startListeningMessages(String currentUserId) {
    List<Mensaje> received = [];
    List<Mensaje> sent = [];

    void updateMessages() {
      final Map<String, Mensaje> uniqueMap = {};
      for (final m in received) {
        uniqueMap[m.id] = m;
      }
      for (final m in sent) {
        uniqueMap[m.id] = m;
      }

      final combined = uniqueMap.values.toList();
      combined.sort((a, b) => b.fecha.compareTo(a.fecha));

      if (mounted) {
        setState(() {
          _allUserMessages = combined;
        });

        _checkAndFetchMissingProfiles(currentUserId, combined);
      }
    }

    _receivedSub = _firestoreService.getReceivedMessages(currentUserId).listen((list) {
      received = list;
      updateMessages();
    });

    _sentSub = _firestoreService.getSentMessages(currentUserId).listen((list) {
      sent = list;
      updateMessages();
    });
  }

  Future<void> _checkAndFetchMissingProfiles(
      String currentUserId, List<Mensaje> messages) async {
    for (final m in messages) {
      final otherId = (m.remitenteId == currentUserId) ? m.destinatarioId : m.remitenteId;
      if (!_profilesCache.containsKey(otherId)) {
        try {
          final profile = await _firestoreService.getProfileByUid(otherId);
          if (profile != null && mounted) {
            setState(() {
              _profilesCache[otherId] = profile;
            });
          }
        } catch (_) {}
      }
    }
  }

  Widget _buildAvatar(String? url, {double radius = 24}) {
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image/')) {
        try {
          final base64String = url.split(',').last;
          final bytes = base64Decode(base64String);
          return CircleAvatar(
            radius: radius,
            backgroundImage: MemoryImage(bytes),
          );
        } catch (_) {}
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.deepPurple.shade100,
          child: ClipOval(
            child: Image.network(
              url,
              fit: BoxFit.cover,
              width: radius * 2,
              height: radius * 2,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.person,
                color: Colors.deepPurple,
                size: radius,
              ),
            ),
          ),
        );
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.deepPurple.shade100,
      child: Icon(
        Icons.person,
        color: Colors.deepPurple,
        size: radius,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _mainNavIndex == 0
              ? (_socialTabIndex == 0
                  ? 'Mensajes'
                  : _socialTabIndex == 1
                      ? 'Contactos'
                      : 'Mi Perfil')
              : 'Explorar & IA',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _mainNavIndex == 0 ? _buildSocialBody() : const MapExploreScreen(),
      floatingActionButton: (_mainNavIndex == 0 && _socialTabIndex == 0)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/newmessage');
              },
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              child: const Icon(Icons.chat_rounded),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mainNavIndex,
        onDestinationSelected: (index) {
          setState(() {
            _mainNavIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Social',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Explorar',
          ),
        ],
      ),
    );
  }

  Widget _buildSocialBody() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSubTabButton('Chats', 0, Icons.chat_bubble_outline),
              _buildSubTabButton('Contactos', 1, Icons.people_outline),
              _buildSubTabButton('Perfil', 2, Icons.person_outline),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _socialTabIndex == 0
              ? _buildConversationsList()
              : _socialTabIndex == 1
                  ? _buildContactsList()
                  : const ProfileScreen(),
        ),
      ],
    );
  }

  Widget _buildSubTabButton(String label, int index, IconData icon) {
    final isSelected = _socialTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _socialTabIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      return const Center(child: Text('No hay sesión iniciada'));
    }

    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    final Map<String, List<Mensaje>> groupedByContact = {};
    for (final m in _allUserMessages) {
      final otherId =
          (m.remitenteId == currentUser.uid) ? m.destinatarioId : m.remitenteId;
      groupedByContact.putIfAbsent(otherId, () => []).add(m);
    }

    if (groupedByContact.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No tienes conversaciones activas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicia un chat desde el botón inferior o la pestaña Contactos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final conversationsList = groupedByContact.entries.toList();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: conversationsList.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
      itemBuilder: (context, index) {
        final entry = conversationsList[index];
        final otherUserId = entry.key;
        final conversationMsgs = entry.value;

        final lastMsg = conversationMsgs.first;
        final contactProfile = _profilesCache[otherUserId] ??
            Perfil(
              uId: otherUserId,
              nombre: 'Usuario',
              email: '',
            );

        final bool hasUnread =
            !lastMsg.leido && lastMsg.destinatarioId == currentUser.uid;

        final horaFormateada =
            '${lastMsg.fecha.hour.toString().padLeft(2, '0')}:${lastMsg.fecha.minute.toString().padLeft(2, '0')}';

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: _buildAvatar(contactProfile.fotoUrl, radius: 26),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  contactProfile.nombre.isNotEmpty
                      ? contactProfile.nombre
                      : contactProfile.email,
                  style: TextStyle(
                    fontWeight:
                        hasUnread ? FontWeight.bold : FontWeight.w600,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                horaFormateada,
                style: TextStyle(
                  fontSize: 12,
                  color: hasUnread ? Colors.deepPurple : Colors.grey,
                  fontWeight:
                      hasUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  lastMsg.texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                    fontWeight:
                        hasUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (hasUnread)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  contacto: contactProfile,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContactsList() {
    if (_allContacts.isEmpty) {
      return const Center(
        child: Text(
          'No hay otros usuarios registrados.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: _allContacts.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
      itemBuilder: (context, index) {
        final contact = _allContacts[index];

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: _buildAvatar(contact.fotoUrl, radius: 26),
          title: Text(
            contact.nombre.isNotEmpty ? contact.nombre : contact.email,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            contact.email,
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                color: Colors.deepPurple),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    contacto: contact,
                  ),
                ),
              );
            },
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  contacto: contact,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _receivedSub?.cancel();
    _sentSub?.cancel();
    super.dispose();
  }
}
