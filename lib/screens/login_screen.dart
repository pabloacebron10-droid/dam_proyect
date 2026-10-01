import 'package:flutter/material.dart';
import 'package:dam_proyect/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  bool _passwordVisible = false;
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // CUERPO DE LA PANTALLA

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 40,
          ),

          // CONTENIDO DEL LOGIN

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // 1. DECORACIÓN SUPERIOR
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 55,
                  color: Colors.deepPurple,
                ),
              ),

              const SizedBox(height: 35),

              // 2. TÍTULO

              const Text(
                '¡Bienvenido!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // 3. SUBTÍTULO

              Text(
                'Inicia sesión para continuar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 40),


              // 4. TEXTO "CORREO ELECTRÓNICO

              const Text(
                'Correo electrónico',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // 5. CAMPO DE CORREO

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Introduce tu correo',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 22),

              // 6. TEXTO "CONTRASEÑA"

              const Text(
                'Contraseña',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // 7. CAMPO DE CONTRASEÑA

              TextField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  hintText: 'Introduce tu contraseña',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                  ),
                  suffixIcon: IconButton(
                      onPressed: (){
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    icon: const Icon(
                      Icons.visibility,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 12),

              // 8. CONTRASEÑA OLVIDADA

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Más adelante añadiremos
                    // la recuperación de contraseña.
                  },
                  child: const Text(
                    '¿Has olvidado tu contraseña?',
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 9. BOTÓN INICIAR SESIÓN

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {

                    try {
                      await _authService.login(_emailController.text, _passwordController.text,);

                      if (!mounted) return;

                      Navigator.pushReplacementNamed(context, '/homescreen',);

                    } on Exception catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceFirst('Exception: ', ''),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 10. REGISTRO

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Text(
                    '¿No tienes una cuenta?',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/register',
                      );
                    },
                    child: const Text(
                      'Regístrate',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
