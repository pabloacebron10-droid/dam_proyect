import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dam_proyect/models/mensaje.dart';
import 'package:dam_proyect/models/perfil.dart';
import 'package:dam_proyect/services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final Perfil contacto;

  const ChatScreen({
    super.key,
    required this.contacto,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<List<Mensaje>>? _receivedSub;
  StreamSubscription<List<Mensaje>>? _sentSub;

  List<Mensaje> _allMessages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startListeningMessages();
  }

  void _startListeningMessages() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final currentUserId = currentUser.uid;
    final otherUserId = widget.contacto.uId;

    List<Mensaje> received = [];
    List<Mensaje> sent = [];

    void updateCombinedList() {
      final Map<String, Mensaje> uniqueMessages = {};

      for (final msg in received) {
        if (msg.remitenteId == otherUserId && msg.destinatarioId == currentUserId) {
          uniqueMessages[msg.id] = msg;
          if (!msg.leido) {
            _firestoreService.markMessageAsRead(msg.id);
          }
        }
      }

      for (final msg in sent) {
        if (msg.remitenteId == currentUserId && msg.destinatarioId == otherUserId) {
          uniqueMessages[msg.id] = msg;
        }
      }

      final combined = uniqueMessages.values.toList();
      combined.sort((a, b) => a.fecha.compareTo(b.fecha));

      if (mounted) {
        setState(() {
          _allMessages = combined;
          _isLoading = false;
        });

        _scrollToBottom();
      }
    }

    _receivedSub = _firestoreService.getReceivedMessages(currentUserId).listen((list) {
      received = list;
      updateCombinedList();
    });

    _sentSub = _firestoreService.getSentMessages(currentUserId).listen((list) {
      sent = list;
      updateCombinedList();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _messageController.clear();

    final nuevoMensaje = Mensaje(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      remitenteId: currentUser.uid,
      destinatarioId: widget.contacto.uId,
      texto: text,
      fecha: DateTime.now(),
      leido: false,
    );

    try {
      await _firestoreService.saveMessage(nuevoMensaje);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar mensaje: $e'),
          ),
        );
      }
    }
  }

  Widget _buildAvatarWidget() {
    final url = widget.contacto.fotoUrl;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image/')) {
        try {
          final base64String = url.split(',').last;
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: 40,
            height: 40,
          );
        } catch (_) {}
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          width: 40,
          height: 40,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
        );
      }
    }
    return const Icon(Icons.person, color: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.deepPurpleAccent,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: _buildAvatarWidget(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.contacto.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.contacto.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _allMessages.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay mensajes en esta conversación.\n¡Escribe el primero!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        itemCount: _allMessages.length,
                        itemBuilder: (context, index) {
                          final mensaje = _allMessages[index];
                          final isMe = mensaje.remitenteId == currentUser?.uid;

                          final horaFormateada =
                              '${mensaje.fecha.hour.toString().padLeft(2, '0')}:${mensaje.fecha.minute.toString().padLeft(2, '0')}';

                          return Align(
                            alignment:
                                isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.deepPurple
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 18),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    mensaje.texto,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isMe ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    horaFormateada,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white70 : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
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

  @override
  void dispose() {
    _receivedSub?.cancel();
    _sentSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
