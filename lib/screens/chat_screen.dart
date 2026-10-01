import 'package:flutter/material.dart';
import 'package:dam_proyect/models/mensaje.dart';
import 'package:dam_proyect/services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final Mensaje mensaje;

  const ChatScreen({
    super.key,
    required this.mensaje,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();

    _markAsRead();
  }

  Future<void> _markAsRead() async {
    if (widget.mensaje.leido) {
      return;
    }

    await _firestoreService.markMessageAsRead(
      widget.mensaje.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversación'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.mensaje.texto,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}