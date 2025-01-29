import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'shared_prefs.dart';

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

      if (responseData['data'] is List) {
        _ticketCategories.clear();
        _controllers.clear();

        for (var category in responseData['data']) {
          final categoryId = category['category_id'];

          if (categoryId == null) {
            print("Advertencia: Se encontró una categoría sin 'category_id'");
            continue;
          }

          final categoryName = await _fetchCategoryName(categoryId);

          _ticketCategories.add({
            'category_id': categoryId,
            'category_name': categoryName ?? 'Categoría sin nombre',
          });

          _controllers.add(TextEditingController());
        }

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

  Future<void> _createTickets() async {
    final workgroupId = await SharedPrefs.getWorkgroupId();
    if (workgroupId == null) return;

    for (int i = 0; i < _ticketCategories.length; i++) {
      final category = _ticketCategories[i];
      final categoryId = category['category_id'];
      final categoryName = category['category_name'] ?? 'Categoría sin nombre';
      final quantity = int.tryParse(_controllers[i].text) ?? 0;

      if (quantity > 0) {
        for (int j = 0; j < quantity; j++) {
          final ticketCode = _generateRandomCode();
          await _createTicket(
              ticketCode, categoryName, categoryId, workgroupId);
        }
      }
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<void> _createTicket(
      String code, String name, int categoryId, int workgroupId) async {
    final url = Uri.parse('https://recgonback-8awa0rdv.b4a.run/tickets');
    await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'code': code,
        'name': name,
        'category_id': categoryId,
        'workgroup_id': workgroupId,
        'status': 'Sin Usar',
      }),
    );
  }

  Future<void> _handleCreateTickets() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    _formKey.currentState!.save();

    await _createTickets();

    setState(() => _isLoading = false);
    _showSuccessModal();
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Éxito'),
        content: const Text('Boletos creados exitosamente.'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.popUntil(context, ModalRoute.withName('/home')),
            child: const Text('Aceptar'),
          ),
        ],
      ),
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
