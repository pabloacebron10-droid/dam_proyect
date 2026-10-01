import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dam_proyect/models/mensaje.dart';
import 'package:dam_proyect/services/auth_service.dart';
import 'package:dam_proyect/services/firestore_service.dart';
import 'package:dam_proyect/screens/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<List<Mensaje>>? _messageSubscription;

  final Set<String> _knownMessageIds = {};

  List<Mensaje> _mensajes = [];

  @override
  void initState() {
    super.initState();

    _listenForNewMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mis chats',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.black,
                ),
              ),

              if (_mensajes.any((mensaje) => !mensaje.leido))
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          IconButton(
            onPressed: () async {
              await _authService.logout();

              if (!mounted) return;

              Navigator.pushReplacementNamed(
                context,
                '/login',
              );
            },
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.black,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: _buildBody(),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/newmessage',
          );
        },
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(
          Icons.chat_rounded,
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.chat_bubble_rounded,
            ),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.people_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.people_rounded,
            ),
            label: 'Contactos',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline_rounded,
            ),
            selectedIcon: Icon(
              Icons.person_rounded,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 1) {
      return const Center(
        child: Text(
          'Contactos',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (_selectedIndex == 2) {
      return const Center(
        child: Text(
          'Mi perfil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return _buildChats();
  }

  Widget _buildChats() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            15,
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar conversaciones...',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        Expanded(
          child: _buildMessageList(),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    if (_mensajes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              'No tienes mensajes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cuando recibas uno aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _mensajes.length,
      itemBuilder: (context, index) {
        final mensaje = _mensajes[index];

        final bool mensajeNoLeido = !mensaje.leido;

        return ListTile(
          leading: const CircleAvatar(
            child: Icon(
              Icons.person,
            ),
          ),
          title: Text(
            mensaje.texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: mensajeNoLeido
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            mensajeNoLeido
                ? 'Mensaje nuevo'
                : 'Mensaje leído',
          ),
          trailing: mensajeNoLeido
              ? Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          )
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  mensaje: mensaje,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Stream<List<Mensaje>> _getReceivedMessages() {
    final user = _authService.getCurrentUser();

    if (user == null) {
      return const Stream.empty();
    }

    return _firestoreService.getReceivedMessages(
      user.uid,
    );
  }

  void _listenForNewMessages() {
    _messageSubscription = _getReceivedMessages().listen(
          (mensajes) {
        if (_knownMessageIds.isEmpty) {
          for (final mensaje in mensajes) {
            _knownMessageIds.add(
              mensaje.id,
            );
          }

          if (mounted) {
            setState(() {
              _mensajes = mensajes;
            });
          }

          return;
        }

        for (final mensaje in mensajes) {
          if (!_knownMessageIds.contains(mensaje.id)) {
            _knownMessageIds.add(
              mensaje.id,
            );

            if (!mounted) return;

            setState(() {
              _mensajes = mensajes;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Nuevo mensaje: ${mensaje.texto}',
                ),
                action: SnackBarAction(
                  label: 'VER',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          mensaje: mensaje,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );

            return;
          }
        }

        if (mounted) {
          setState(() {
            _mensajes = mensajes;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }
}