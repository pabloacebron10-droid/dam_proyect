import 'package:flutter/material.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final TextEditingController _destinatarioController =
  TextEditingController();

  final TextEditingController _mensajeController =
  TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo mensaje'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _destinatarioController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Destinatario',
                hintText: 'Correo electrónico',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _mensajeController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Mensaje',
                hintText: 'Escribe tu mensaje...',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.message_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Más adelante guardaremos el mensaje en Firestore.
                },
                icon: const Icon(Icons.send),
                label: const Text(
                  'Enviar mensaje',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _destinatarioController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }
}