import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

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
  final Color primaryColor = const Color(0xFF3A31D8);

  @override
  void initState() {
    super.initState();
    if (_categories.isEmpty) {
      _addCategory();
    }
  }

  void _addCategory() {
    if (_categories.length < 3) {
      setState(() {
        _categories.add({
          'name': '',
          'description': '',
          'price': '',
          'tickets_quantity': '100' // Valor por defecto
        });
      });
    } else {
      Fluttertoast.showToast(
        msg: "Máximo 3 categorías permitidas",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _removeCategory(int index) {
    if (_categories.length > 1) {
      setState(() {
        _categories.removeAt(index);
      });
    } else {
      Fluttertoast.showToast(
        msg: "Debes tener al menos una categoría",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<int?> _getWorkgroupId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('workgroup_id');
  }

  Future<bool> _createTicketCategory(
      Map<String, dynamic> category, int workgroupId) async {
    try {
      final response = await http.post(
        Uri.parse('https://recgonback-8awa0rdv.b4a.run/ticket-categories'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': category['name'],
          'price': double.parse(category['price']),
          'description': category['description'],
          'workgroup_id': workgroupId,
          'tickets_quantity': int.parse(category['tickets_quantity']),
          'event_id': widget.eventId
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error al crear categoría');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      return false;
    }
  }

  void _submitCategories() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    int? workgroupId = await _getWorkgroupId();
    if (workgroupId == null) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
        msg: "Error: No se encontró workgroup_id",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    bool allSuccess = true;

    for (var category in _categories) {
      bool success = await _createTicketCategory(category, workgroupId);
      if (!success) {
        allSuccess = false;
        break;
      }
    }

    setState(() => _isLoading = false);

    if (allSuccess) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('¡Categorías creadas!'),
            ],
          ),
          content: const Text(
              'Las categorías de boletos han sido creadas exitosamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(true); // Retorna éxito
              },
              child: Text('Continuar', style: TextStyle(color: primaryColor)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categorías de Boletos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderText(),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            ..._buildCategoryForms(),
                            const SizedBox(height: 24),
                            _buildAddCategoryButton(),
                            const SizedBox(height: 32),
                            _buildSubmitButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Creando categorías...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Define tus categorías de boletos',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Crea hasta 3 categorías diferentes de boletos para tu evento (ej. VIP, General, Estudiante).',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCategoryForms() {
    return List.generate(_categories.length, (index) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categoría ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                  if (_categories.length > 1)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                      onPressed: () => _removeCategory(index),
                      tooltip: 'Eliminar categoría',
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTextField(
                    label: 'Nombre de la categoría',
                    hint: 'Ej. VIP, General, Estudiante',
                    icon: Icons.label_outline,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Por favor ingresa un nombre'
                        : null,
                    onSaved: (value) => _categories[index]['name'] = value!,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Descripción',
                    hint: 'Ej. Acceso a todas las áreas, asiento preferencial',
                    icon: Icons.description_outlined,
                    maxLines: 2,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Por favor ingresa una descripción'
                        : null,
                    onSaved: (value) =>
                        _categories[index]['description'] = value!,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Precio',
                    hint: 'Ej. 100.00',
                    icon: Icons.attach_money,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa un precio';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Por favor ingresa un número válido';
                      }
                      return null;
                    },
                    onSaved: (value) => _categories[index]['price'] = value!,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Cantidad de tickets',
                    hint: 'Ej. 100',
                    icon: Icons.confirmation_number,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa una cantidad';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Por favor ingresa un número entero';
                      }
                      return null;
                    },
                    onSaved: (value) =>
                        _categories[index]['tickets_quantity'] = value!,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryColor),
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
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildAddCategoryButton() {
    return _categories.length < 3
        ? ElevatedButton.icon(
            onPressed: _addCategory,
            icon: const Icon(Icons.add),
            label: const Text('Agregar otra categoría'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Has alcanzado el límite máximo de 3 categorías',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _submitCategories(); // Llamar a la función de creación de categorías

          // Navegar al Home después de crear las categorías
          Navigator.pushReplacementNamed(context,
              '/home'); // Suponiendo que tengas la ruta '/home' configurada
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Guardar y Continuar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
