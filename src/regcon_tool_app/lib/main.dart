import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login.dart';
import 'home.dart'; // Importa la pantalla de home

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Asegura que Flutter esté inicializado
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // Pantalla de inicio con el logo
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  // Método para verificar el estado de autenticación
  Future<void> _checkAuthStatus() async {
    await Future.delayed(
        Duration(seconds: 3)); // Espera 3 segundos (simula carga)

    final isLoggedIn =
        await AuthService.validateToken(); // Verifica si hay un token válido

    // Navega a la pantalla correspondiente
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => isLoggedIn ? HomeScreen() : LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco
      body: Center(
        child: Image.asset('assets/logo.png'), // Muestra el logo
      ),
    );
  }
}
