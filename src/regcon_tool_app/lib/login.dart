import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final success = await AuthService.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login exitoso')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error en el login')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        print('Error durante el login: $e'); // Log para depuración
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo de la aplicación
                  Image.asset(
                    'assets/regcon-logo.png', // Ruta de la imagen
                    height: 60, // Altura del logo
                    width: 120, // Ancho del logo
                  ),
                  SizedBox(height: 8), // Espacio entre el logo y el texto
                  Text(
                    '¡Bienvenido de nuevo!',
                    style: TextStyle(
                      fontFamily: 'Poppins', // Usar la fuente Poppins
                      fontSize: 24,
                      fontWeight: FontWeight.bold, // Poppins-Bold
                      color: Color(0xFFEB6D1E),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(
                      fontFamily: 'Poppins', // Usar la fuente Poppins
                      fontSize: 16,
                      fontWeight: FontWeight.normal, // Poppins-Regular
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 32), // Espacio antes del formulario
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins', // Usar la fuente Poppins
                        fontWeight: FontWeight.normal, // Poppins-Regular
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFEB6D1E)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu email';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(value)) {
                        return 'Por favor ingresa un email válido';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins', // Usar la fuente Poppins
                        fontWeight: FontWeight.normal, // Poppins-Regular
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFEB6D1E)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32), // Espacio antes del botón
                  _isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFEB6D1E)),
                        )
                      : ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFEB6D1E),
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontFamily: 'Poppins', // Usar la fuente Poppins
                              fontSize: 16,
                              fontWeight: FontWeight.bold, // Poppins-Bold
                              color: Colors.white,
                            ),
                          ),
                        ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Aquí puedes añadir la lógica para recuperar la contraseña
                    },
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        fontFamily: 'Poppins', // Usar la fuente Poppins
                        color: Color(0xFFEB6D1E),
                        fontWeight: FontWeight.bold, // Poppins-Bold
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Aquí puedes añadir la lógica para crear una cuenta
                    },
                    child: Text(
                      '¿No tienes una cuenta? ¡Crea una!',
                      style: TextStyle(
                        fontFamily: 'Poppins', // Usar la fuente Poppins
                        color: Color(0xFFEB6D1E),
                        fontWeight: FontWeight.bold, // Poppins-Bold
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
