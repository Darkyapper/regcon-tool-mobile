import 'package:flutter/material.dart';
import 'login.dart';
import 'shared_prefs.dart';
import 'dart:convert'; // Para manejar JSON
import 'package:http/http.dart' as http; // Para hacer solicitudes HTTP

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Índice para la barra de navegación inferior
  final List<dynamic> _events = []; // Lista de eventos
  int _offset = 0; // Offset para la paginación
  bool _isLoading = false; // Para controlar la carga de más eventos
  final ScrollController _scrollController =
      ScrollController(); // Controlador de scroll

  @override
  void initState() {
    super.initState();
    _loadEvents(); // Cargar eventos al iniciar
    _scrollController.addListener(_scrollListener); // Escuchar el scroll
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Liberar el controlador de scroll
    super.dispose();
  }

  // Método para cargar eventos desde la API
  Future<void> _loadEvents() async {
    if (_isLoading) return; // Evitar múltiples solicitudes

    setState(() {
      _isLoading = true;
    });

    final url =
        Uri.parse('https://recgonback-8awa0rdv.b4a.run/events?offset=$_offset');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body); // Decodificar JSON
      final List<dynamic> data =
          decodedResponse['data']; // Obtener la lista de eventos
      setState(() {
        _events.addAll(data); // Agregar los eventos a la lista
        _offset += 10; // Incrementar el offset para la próxima página
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Error al cargar los eventos');
    }
  }

  // Método para manejar el scroll y cargar más eventos
  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadEvents(); // Cargar más eventos cuando el usuario llegue al final
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
            Color(0xFFEB6D1E), // Color naranja para la barra superior
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png', // Logo de la app
              height: 40,
              width: 40,
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar eventos...',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.3),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(20), // Bordes redondeados
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(20), // Bordes redondeados
                    borderSide: BorderSide(color: Colors.transparent),
                  ),
                ),
              ),
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
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Mis boletos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  // Método para construir el contenido principal según la sección seleccionada
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: // Inicio
        return _buildEventList();
      case 1: // Mis boletos
        return Center(child: Text('Mis boletos'));
      case 2: // Favoritos
        return Center(child: Text('Favoritos'));
      case 3: // Ajustes
        return Center(child: Text('Ajustes de cuenta'));
      default:
        return Center(child: Text('Selecciona una opción'));
    }
  }

  // Método para construir la lista de eventos
  Widget _buildEventList() {
    return ListView.builder(
      controller: _scrollController, // Asignar el controlador de scroll
      padding: EdgeInsets.all(16),
      itemCount: _events.length +
          (_isLoading ? 1 : 0), // +1 para el indicador de carga
      itemBuilder: (context, index) {
        if (index == _events.length) {
          return Center(
            child: CircularProgressIndicator(), // Indicador de carga al final
          );
        }

        final event = _events[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                event['image'], // Imagen del evento
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['name'], // Título del evento
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Fecha: ${event['event_date']}', // Fecha del evento
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ubicación: ${event['location']}', // Ubicación del evento
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      event['description'], // Descripción del evento
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
