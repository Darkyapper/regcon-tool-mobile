import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'shared_prefs.dart';
import 'login.dart'; // Importa la pantalla de login

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _userId;
  int? _workgroupId;
  int? _roleId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Método para cargar los datos del usuario
  Future<void> _loadUserData() async {
    final userId = await SharedPrefs.getUserId();
    final workgroupId = await SharedPrefs.getWorkgroupId();
    final roleId = await SharedPrefs.getRoleId();

    setState(() {
      _userId = userId;
      _workgroupId = workgroupId;
      _roleId = roleId;
      _isLoading = false;
    });
  }

  // Método para cerrar sesión
  Future<void> _logout() async {
    await SharedPrefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => LoginScreen()), // Usa LoginScreen aquí
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bienvenido, Usuario ID: $_userId'),
                  Text('Workgroup ID: $_workgroupId'),
                  Text('Role ID: $_roleId'),
                  SizedBox(height: 20),
                  Expanded(
                    child: _buildEventList(), // Aquí se mostrarán los eventos
                  ),
                ],
              ),
            ),
    );
  }

  // Método para construir la lista de eventos (por ahora vacía)
  Widget _buildEventList() {
    // Aquí puedes hacer la petición a tu API para obtener los eventos
    // y mostrarlos en un ListView, GridView, etc.
    return Center(
      child: Text('Aquí se mostrarán los eventos'),
    );
  }
}
