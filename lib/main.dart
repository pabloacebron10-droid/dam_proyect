import 'package:flutter/material.dart';
import 'package:dam_proyect/screens/home_screen.dart';
import 'package:dam_proyect/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAM Proyecto',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
      routes: {
        '/login' : (context) => const LoginScreen(),
      }
    );
  }
}