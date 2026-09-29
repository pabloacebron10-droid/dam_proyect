import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(

  // ========================================
  // CUERPO DE LA PANTALLA
  // ========================================

      body: SafeArea(
      child: SingleChildScrollView(

  // Espacio alrededor de todo el contenido
      padding: const EdgeInsets.symmetric(
      horizontal: 28,
      vertical: 40,
      ),

  // ========================================
  // CONTENIDO DE LA PÁGINA
  // ========================================

      child: Column(
      children: [


      ],
    ),
  ),
  ),
  );
  }
  }