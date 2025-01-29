import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'createTickets.dart';

class TicketCategoryScreen extends StatefulWidget {
  final int eventId;

  const TicketCategoryScreen({super.key, required this.eventId});

  @override
  _TicketCategoryScreenState createState() => _TicketCategoryScreenState();
}

class _TicketCategoryScreenState extends State<TicketCategoryScreen> {
  final List<Map<String, dynamic>> _categories = [];
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _addCategory() {
    if (_categories.length < 3) {
      setState(() {
        _categories.add({'name': '', 'description': '', 'price': ''});
      });
    }
  }

  Future<int?> _getWorkgroupId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('workgroup_id');
  }

  Future<int?> _createCategory(
      Map<String, dynamic> category, int workgroupId) async {
    final response = await http.post(
      Uri.parse('https://recgonback-8awa0rdv.b4a.run/ticket-categories'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': category['name'],
        'price': category['price'],
        'description': category['description'],
        'workgroup_id': workgroupId
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['id'];
    } else {
      return null;
    }
  }

  Future<bool> _associateCategoryWithEvent(int categoryId) async {
    final response = await http.post(
      Uri.parse('https://recgonback-8awa0rdv.b4a.run/ticket-events'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'event_id': widget.eventId,
        'ticketcategory_id': categoryId,
      }),
    );

    return response.statusCode == 200;
  }

  void _submitCategories() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    int? workgroupId = await _getWorkgroupId();
    if (workgroupId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: No se encontró workgroup_id')),
      );
      return;
    }

    List<int> createdCategoryIds = [];

    for (var category in _categories) {
      int? categoryId = await _createCategory(category, workgroupId);
      if (categoryId != null) {
        bool success = await _associateCategoryWithEvent(categoryId);
        if (success) {
          createdCategoryIds.add(categoryId);
        }
      }
    }

    setState(() => _isLoading = false);

    if (createdCategoryIds.length == _categories.length) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateTicketsScreen(eventId: widget.eventId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear algunas categorías')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Categorías de Boletos'),
        backgroundColor: const Color(0xFFEB6D1E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: _categories.map((category) {
                  return Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Por favor ingresa un nombre'
                            : null,
                        onSaved: (value) => category['name'] = value!,
                      ),
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Descripción'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Por favor ingresa una descripción'
                            : null,
                        onSaved: (value) => category['description'] = value!,
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Precio'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Por favor ingresa un precio'
                            : null,
                        onSaved: (value) => category['price'] = value!,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addCategory,
              child: const Text('Agregar Categoría'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitCategories,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : const Text('Crear Categorías'),
            ),
          ],
        ),
      ),
    );
  }
}
