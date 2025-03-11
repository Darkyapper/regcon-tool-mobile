import 'package:flutter/material.dart';
import 'login.dart';
import 'shared_prefs.dart';
import 'dart:convert'; // Para manejar JSON
import 'package:http/http.dart' as http; // Para hacer solicitudes HTTP
import 'createEvent.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0; // Índice para la barra de navegación inferior
  Map<String, dynamic>?
      _latestEvent; // Último evento creado por el grupo de trabajo
  bool _isLoading = true; // Para controlar la carga del último evento

  @override
  void initState() {
    super.initState();
    _loadLatestEvent(); // Cargar el último evento al iniciar
  }

  // Método para cargar el último evento creado por el grupo de trabajo
  Future<void> _loadLatestEvent() async {
    final groupId = await SharedPrefs.getWorkgroupId();

    if (groupId == null) {
      setState(() {
        _isLoading = false;
        _latestEvent = null;
      });
      return;
    }

    final url = Uri.parse(
        'https://recgonback-8awa0rdv.b4a.run/all-events?limit=1&latest=true&workgroup_id=$groupId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse['data'] is List &&
            decodedResponse['data'].isNotEmpty) {
          setState(() {
            _latestEvent = decodedResponse['data']
                [0]; // Tomar el primer evento de la lista
          });
        } else {
          setState(() {
            _latestEvent = null; // No hay eventos recientes
          });
        }
      } else {
        setState(() {
          _latestEvent = null;
        });
        print('Error al cargar el evento: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en la solicitud HTTP: $e');
      setState(() {
        _latestEvent = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método para manejar el cambio de índice en la barra de navegación
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            Color(0xFF2F27CE), // Color naranja para la barra superior
        title: Row(
          children: [
            Image.asset(
              'assets/regcon-tool-icon-white.png', // Logo de la app
              height: 40,
              width: 40,
            ),
            SizedBox(width: 10),
            Text(
              'RegCon Tool',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF6F6F6)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(), // Contenido principal de la pantalla
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF7C79DC),
        unselectedItemColor: Color(0xFFAAA9B2),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Mis Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Crear Evento',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // Método para construir el contenido principal según la sección seleccionada
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: // Inicio
        return _buildLatestEvent();
      case 1: // Mis Eventos
        return Center(child: Text('Mis Eventos'));
      case 2: // Crear Evento
        return CreateEventScreen();
      case 3: // Perfil
        return Center(child: Text('Perfil'));
      default:
        return Center(child: Text('Selecciona una opción'));
    }
  }

  // Método para construir la vista del último evento creado
  Widget _buildLatestEvent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_latestEvent == null) {
      return Center(child: Text('No hay eventos creados recientemente.'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  _latestEvent!['event_image'], // Imagen del evento
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _latestEvent!['event_name'], // Título del evento
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Fecha: ${_latestEvent!['event_date']}', // Fecha del evento
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ubicación: ${_latestEvent!['location']}', // Ubicación del evento
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _latestEvent![
                            'event_description'], // Descripción del evento
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20), // Espacio entre la tarjeta y el botón
          ElevatedButton(
            onPressed: () {
              // Acción que se ejecuta cuando se presiona el botón
              print('Botón presionado!');
              // Aquí puedes agregar la lógica que desees, como navegar a otra pantalla
            },
            child: Text('Ver todos los eventos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFdddbff), // Color naranja
              foregroundColor: Color(0xFF101010),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
