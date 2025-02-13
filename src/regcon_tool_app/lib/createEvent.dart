import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'shared_prefs.dart';
import 'uploadImage.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  DateTime? _eventDate;
  String _location = '';
  String _description = '';
  int? _eventCategory;
  bool _isOnline = false;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final url =
        Uri.parse('https://recgonback-8awa0rdv.b4a.run/event-categories');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(response.body);
      setState(() {
        _categories = List<Map<String, dynamic>>.from(decodedResponse['data']);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar categorías')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() {
      _isLoading = true;
    });

    final workgroupId = await SharedPrefs.getWorkgroupId();
    if (workgroupId == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Workgroup ID no encontrado.')),
      );
      return;
    }

    final url = Uri.parse('https://recgonback-8awa0rdv.b4a.run/events');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': _name,
        'event_date': _eventDate?.toIso8601String(),
        'location': _location,
        'description': _description,
        'workgroup_id': workgroupId,
        'image': 'https://via.placeholder.com/150',
        'event_category': _eventCategory,
        'is_online': _isOnline,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      if (responseData['message'] == 'Success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evento creado con éxito')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ImageUploadScreen(eventId: responseData['data']['id']),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${responseData['message']}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear el evento')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Evento'),
        backgroundColor: const Color(0xFFEB6D1E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration:
                            InputDecoration(labelText: 'Nombre del Evento'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Por favor ingresa un nombre'
                            : null,
                        onSaved: (value) => _name = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: TextEditingController(
                          text: _eventDate == null
                              ? 'Selecciona una fecha'
                              : '${_eventDate!.toLocal()}'.split(' ')[0],
                        ),
                        readOnly: true,
                        decoration:
                            InputDecoration(labelText: 'Fecha del Evento'),
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selectedDate != null) {
                            setState(() {
                              _eventDate = selectedDate;
                            });
                          }
                        },
                        validator: (value) => _eventDate == null
                            ? 'Por favor selecciona una fecha'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Ubicación'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Por favor ingresa una ubicación'
                            : null,
                        onSaved: (value) => _location = value!,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(labelText: 'Descripción'),
                        maxLines: 3,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Por favor ingresa una descripción'
                            : null,
                        onSaved: (value) => _description = value!,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        decoration: InputDecoration(labelText: 'Categoría'),
                        items: _categories
                            .map((category) => DropdownMenuItem<int>(
                                  value: category['id'],
                                  child: Text(category['name']),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _eventCategory = value),
                        validator: (value) => value == null
                            ? 'Por favor selecciona una categoría'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('¿El evento es online?'),
                        value: _isOnline,
                        onChanged: (value) => setState(() => _isOnline = value),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Crear Evento'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
