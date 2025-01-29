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
  final List<TextEditingController> _ticketQuantityControllers = [];
  final bool _isLoading = false;

  Future<void> _createTicketCategory(
      String name, double price, String description) async {
    final workgroupId = await SharedPrefs.getWorkgroupId();
    if (workgroupId == null) return;

    final url =
        Uri.parse('https://recgonback-8awa0rdv.b4a.run/ticket-categories');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'price': price,
        'description': description,
        'workgroup_id': workgroupId,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      setState(() {
        _ticketCategories.add({
          'name': name,
          'price': price,
          'description': description,
          'id': responseData['data']['id'],
        });
        _ticketQuantityControllers.add(TextEditingController());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear la categoría de boletos')),
      );
    }
  }

  Future<void> _createTickets() async {
    if (_ticketCategories.isEmpty) return;

    final workgroupId = await SharedPrefs.getWorkgroupId();
    if (workgroupId == null) return;

    for (var category in _ticketCategories) {
      final categoryId = category['id'];
      final quantity = int.tryParse(
              _ticketQuantityControllers[_ticketCategories.indexOf(category)]
                  .text) ??
          0;

      if (quantity > 0) {
        for (int i = 0; i < quantity; i++) {
          final ticketCode = _generateRandomCode();
          await _createTicket(
              ticketCode, category['name'], categoryId, workgroupId);
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
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'code': code,
        'name': name,
        'category_id': categoryId, // Esto es un entero
        'status': 'Sin Usar',
        'workgroup_id': workgroupId, // Esto también es un entero
      }),
    );

    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear boletos')),
      );
    }
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Nombre de la Categoría'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Por favor ingresa un nombre'
                          : null,
                      onSaved: (value) {
                        if (value != null) {
                          _createTicketCategory(value, 10.0, 'Descripción');
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ..._ticketCategories.map((category) {
                      final controller = _ticketQuantityControllers[
                          _ticketCategories.indexOf(category)];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Text(category['name']),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                decoration: InputDecoration(
                                    labelText:
                                        'Cantidad de ${category['name']}'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _createTickets();
                        }
                      },
                      child: const Text('Crear Boletos'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
