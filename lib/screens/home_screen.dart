import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: _buildBody(),

      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.chat_rounded),
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
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Contactos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
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
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar conversaciones...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        const Expanded(
          child: Center(
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
                  'No tienes conversaciones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Empieza una conversación para verla aquí.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}