import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'shared_prefs.dart';
import 'uploadImage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    if (!mounted) return; // Verifica si el widget sigue en el árbol

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
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Crear Evento'),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          color: Color(0xFF101010),
          fontSize: 26,
        ),
        iconTheme: IconThemeData(color: Color(0xFF3A31D8)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3A31D8)))
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Información básica'),
                        const SizedBox(height: 16),
                        _buildTextField(
                          label: 'Nombre del Evento',
                          hint: 'Ej. Concierto de Rock',
                          icon: Icons.event,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Por favor ingresa un nombre'
                              : null,
                          onSaved: (value) => _name = value!,
                        ),
                        const SizedBox(height: 20),
                        _buildDatePicker(),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Ubicación',
                          hint: 'Ej. Centro de Convenciones',
                          icon: Icons.location_on,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Por favor ingresa una ubicación'
                              : null,
                          onSaved: (value) => _location = value!,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: 'Descripción',
                          hint: 'Describe tu evento...',
                          icon: Icons.description,
                          maxLines: 3,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Por favor ingresa una descripción'
                              : null,
                          onSaved: (value) => _description = value!,
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Detalles adicionales'),
                        const SizedBox(height: 16),
                        _buildCategoryDropdown(),
                        const SizedBox(height: 20),
                        _buildOnlineSwitch(),
                        const SizedBox(height: 32),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3A31D8),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Color(0xFF3A31D8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF3A31D8), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      maxLines: maxLines,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: _eventDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFF3A31D8),
                  onPrimary: Colors.white,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Color(0xFF3A31D8),
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (selectedDate != null) {
          setState(() {
            _eventDate = selectedDate;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Color(0xFF3A31D8)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _eventDate == null
                    ? 'Selecciona una fecha'
                    : DateFormat('dd/MM/yyyy').format(_eventDate!),
                style: TextStyle(
                  fontSize: 16,
                  color: _eventDate == null ? Colors.grey : Colors.black,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonFormField<int>(
        decoration: InputDecoration(
          labelText: 'Categoría',
          prefixIcon: Icon(Icons.category, color: Color(0xFF3A31D8)),
          border: InputBorder.none,
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.grey),
        isExpanded: true,
        items: _categories
            .map((category) => DropdownMenuItem<int>(
                  value: category['id'],
                  child: Text(category['name']),
                ))
            .toList(),
        onChanged: (value) => setState(() => _eventCategory = value),
        validator: (value) =>
            value == null ? 'Por favor selecciona una categoría' : null,
      ),
    );
  }

  Widget _buildOnlineSwitch() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(Icons.computer, color: Color(0xFF3A31D8)),
            SizedBox(width: 12),
            Text(
              '¿El evento es online?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        value: _isOnline,
        onChanged: (value) => setState(() => _isOnline = value),
        activeColor: Color(0xFF3A31D8),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF3A31D8),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          'Crear Evento',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
