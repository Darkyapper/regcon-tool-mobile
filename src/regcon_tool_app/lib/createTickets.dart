import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'shared_prefs.dart';
import 'home.dart';

class CreateTicketsScreen extends StatefulWidget {
  final int eventId;

  const CreateTicketsScreen({super.key, required this.eventId});

  @override
  _CreateTicketsScreenState createState() => _CreateTicketsScreenState();
}

class _CreateTicketsScreenState extends State<CreateTicketsScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Map<String, dynamic>> _ticketCategories = [];
  final List<TextEditingController> _controllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAssignedCategories();
  }

  Future<void> _fetchAssignedCategories() async {
    final url = Uri.parse(
        'https://recgonback-8awa0rdv.b4a.run/ticket-events/${widget.eventId}');
    final response =
        await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print("Respuesta de la API (categorías asignadas): $responseData");

      if (responseData['data'] is List) {
        _ticketCategories.clear();
        _controllers.clear();

        for (var category in responseData['data']) {
          final categoryId = category['ticketcategory_id'];

          if (categoryId == null) {
            print(
                "Advertencia: Se encontró una categoría sin 'ticketcategory_id'");
            continue;
          }

          final categoryName = await _fetchCategoryName(categoryId);

          _ticketCategories.add({
            'category_id': categoryId,
            'category_name': categoryName ?? 'Categoría sin nombre',
          });

          _controllers.add(TextEditingController());
        }

        print("Categorías asignadas: $_ticketCategories");
        setState(() {});
      } else {
        print("Error: 'data' no es una lista en la respuesta de la API");
      }
    } else {
      print("Error al obtener categorías asignadas: ${response.statusCode}");
    }
  }

  Future<String?> _fetchCategoryName(int categoryId) async {
    final url = Uri.parse(
        'https://recgonback-8awa0rdv.b4a.run/ticket-categories/$categoryId');
    final response =
        await http.get(url, headers: {'Content-Type': 'application/json'});

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['data']['name'];
    } else {
      print(
          "Error al obtener el nombre de la categoría: ${response.statusCode}");
      return null;
    }
  }

  Future<void> _handleCreateTickets() async {
    if (!_formKey.currentState!.validate()) {
      print("El formulario no es válido");
      return;
    }

    setState(() => _isLoading = true);

    final workgroupId = await SharedPrefs.getWorkgroupId();
    if (workgroupId == null) {
      print("Error: workgroupId es null");
      setState(() => _isLoading = false);
      return;
    }

    print("Creando boletos...");

    for (int i = 0; i < _ticketCategories.length; i++) {
      final category = _ticketCategories[i];
      final categoryId = category['category_id'];
      final categoryName = category['category_name'] ?? 'Categoría sin nombre';
      final quantity = int.tryParse(_controllers[i].text) ?? 0;

      if (quantity > 0) {
        print("Creando $quantity boletos para la categoría $categoryName");
        for (int j = 0; j < quantity; j++) {
          final ticketCode = _generateRandomCode();
          final success =
              await _createTicket(ticketCode, categoryId, workgroupId);
          if (!success) {
            print("Error al crear un boleto. Deteniendo proceso.");
            setState(() => _isLoading = false);
            return;
          }
        }
      }
    }

    setState(() => _isLoading = false);
    _navigateToAdminHome();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<bool> _createTicket(
      String code, int categoryId, int workgroupId) async {
    final url = Uri.parse('https://recgonback-8awa0rdv.b4a.run/tickets');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'code': code,
        'category_id': categoryId,
        'workgroup_id': workgroupId,
        'status': 'Sin Usar',
      }),
    );

    if (response.statusCode == 200) {
      print("Boleto creado exitosamente: ${response.body}");
      return true;
    } else {
      print("Error al crear el boleto: ${response.statusCode}");
      return false;
    }
  }

  void _navigateToAdminHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => AdminHomeScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Boletos'),
        backgroundColor: const Color(0xFFEB6D1E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_ticketCategories.isEmpty)
                      const Center(
                        child:
                            Text('No hay categorías asignadas a este evento.'),
                      ),
                    ..._ticketCategories.map((category) {
                      int index = _ticketCategories.indexOf(category);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Categoría: ${category['category_name']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              TextFormField(
                                controller: _controllers[index],
                                decoration: const InputDecoration(
                                  labelText: 'Cantidad de Boletos',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Campo requerido'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _handleCreateTickets,
                      child: const Text('Crear Boletos'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
