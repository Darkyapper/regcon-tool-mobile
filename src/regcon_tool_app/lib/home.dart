import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'shared_prefs.dart';
import 'login.dart';
import 'showEvents.dart';
import 'addEvents.dart';

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
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  // Método para manejar el registro de eventos
  void _registerEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEventsScreen()),
    );
  }

  // Método para mostrar los eventos
  void _showEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ShowEventsScreen()),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _registerEvent,
                        child: Text('Registrar eventos'),
                      ),
                      ElevatedButton(
                        onPressed: _showEvents,
                        child: Text('Mostrar eventos'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: _buildEventList(),
                  ),
                ],
              ),
            ),
    );
  }

  // Método para construir la lista de eventos (por ahora vacía)
  Widget _buildEventList() {
    return Center(
      child: Text('Aquí se mostrarán los eventos'),
    );
  }
}
