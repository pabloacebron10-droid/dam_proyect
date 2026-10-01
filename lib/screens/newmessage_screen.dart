import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dam_proyect/models/mensaje.dart';
import 'package:dam_proyect/services/firestore_service.dart';


class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {

  final TextEditingController _destinatarioController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();


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
                onPressed: () async {
                  final email = _destinatarioController.text.trim();
                  final texto = _mensajeController.text.trim();

                  if (email.isEmpty || texto.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Completa el destinatario y el mensaje',
                        ),
                      ),
                    );
                    return;
                  }

                  try {
                    final perfil =
                    await _firestoreService.getProfileByEmail(email);

                    if (perfil == null) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No existe ningún usuario con ese correo',
                          ),
                        ),
                      );
                      return;
                    }

                    final usuarioActual = FirebaseAuth.instance.currentUser;

                    if (usuarioActual == null) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No hay ninguna sesión iniciada',
                          ),
                        ),
                      );
                      return;
                    }

                    final mensaje = Mensaje(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      remitenteId: usuarioActual.uid,
                      destinatarioId: perfil.uId,
                      texto: texto,
                      fecha: DateTime.now(),
                      leido: false,
                    );

                    await _firestoreService.saveMessage(mensaje);

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Mensaje enviado correctamente',
                        ),
                      ),
                    );

                    Navigator.pop(context);
                  } on Exception catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst(
                            'Exception: ',
                            '',
                          ),
                        ),
                      ),
                    );
                  }
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