import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'shared_prefs.dart';

class AddEventsScreen extends StatefulWidget {
  const AddEventsScreen({super.key});

  @override
  _AddEventsScreenState createState() => _AddEventsScreenState();
}

class _AddEventsScreenState extends State<AddEventsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _workgroupId; // Se obtiene de SharedPrefs

  @override
  void initState() {
    super.initState();
    _loadWorkgroupId();
  }

  Future<void> _loadWorkgroupId() async {
    final workgroupId = await SharedPrefs.getWorkgroupId();
    setState(() {
      _workgroupId = workgroupId?.toString();
    });
  }

  Future<void> _addEvent() async {
    if (_formKey.currentState!.validate()) {
      // Prepara los datos del evento
      final event = {
        'name': _nameController.text,
        'event_date': _dateController.text,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'category_id': 10, // Valor fijo según el script proporcionado
        'workgroup_id': int.tryParse(_workgroupId ?? ''),
        'image':
            "https://i.ytimg.com/vi/m9WK8iTxQjs/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLD-a6ObmmAreyot6VtaUGhTpjn64A", // Valor fijo
      };

      print('Datos enviados: $event'); // Depuración: Imprime los datos enviados

      try {
        // Realiza la solicitud POST
        final response = await http.post(
          Uri.parse('https://recgonback-8awa0rdv.b4a.run/events'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(event),
        );

        print(
            'Respuesta completa del servidor: ${response.body}'); // Depuración: Respuesta del servidor

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Evento registrado exitosamente')),
          );
          Navigator.pop(context);
        } else {
          print(
              'Error del servidor: ${response.body}'); // Depuración: Errores en respuesta
          throw Exception('valor devuelto: ${response.body}');
        }
      } catch (e) {
        print(
            'Se agregó el evento: $e'); // Depuración: Muestra el error completo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Se agregó el evento correctamente $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Evento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _workgroupId == null
            ? Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            InputDecoration(labelText: 'Nombre del evento'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa un nombre';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                            labelText: 'Fecha del evento (YYYY-MM-DD)'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa una fecha';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _locationController,
                        decoration:
                            InputDecoration(labelText: 'Ubicación del evento'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa una ubicación';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                            labelText: 'Descripción del evento'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa una descripción';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _addEvent,
                        child: Text('Registrar Evento'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
