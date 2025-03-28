import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'createCategories.dart';
import 'package:http_parser/http_parser.dart';
import 'package:dotted_border/dotted_border.dart';

class ImageUploadScreen extends StatefulWidget {
  final int eventId;
  const ImageUploadScreen({super.key, required this.eventId});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen>
    with SingleTickerProviderStateMixin {
  File? _image;
  bool _isLoading = false;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _animation;
  final Color primaryColor = Color(0xFF3A31D8); // Updated to deep blue/indigo

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _isLoading = true;
        });

        // Simulate image processing delay
        await Future.delayed(Duration(milliseconds: 500));

        setState(() {
          _isLoading = false;
        });

        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showErrorSnackBar('Error al seleccionar la imagen');
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      _showErrorSnackBar('Por favor selecciona una imagen primero');
      return;
    }

    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
            'https://recgonback-8awa0rdv.b4a.run/events/${widget.eventId}/update-image'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _image!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final response = await request.send().timeout(Duration(seconds: 30));
      final responseData = await response.stream.bytesToString();
      debugPrint('Respuesta del servidor: $responseData');

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        throw Exception(
            'Error al actualizar la imagen del evento: Código de estado ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating event image: $e');
      _showErrorSnackBar('Error: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('¡Éxito!'),
            ],
          ),
          content:
              Text('La imagen del evento ha sido actualizada correctamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TicketCategoryScreen(eventId: widget.eventId),
                  ),
                );
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
          'Imagen del Evento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderText(),
                SizedBox(height: 30),
                Expanded(
                  child: _buildImagePreviewArea(),
                ),
                SizedBox(height: 30),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Añade una imagen atractiva',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'La imagen será la portada principal de tu evento y ayudará a atraer más asistentes.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreviewArea() {
    return _isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
                SizedBox(height: 16),
                Text(
                  'Procesando imagen...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        : GestureDetector(
            onTap: _pickImage,
            child: _image == null
                ? _buildEmptyImageArea()
                : _buildSelectedImagePreview(),
          );
  }

  Widget _buildEmptyImageArea() {
    return Center(
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: Radius.circular(16),
        color: primaryColor.withOpacity(0.6),
        strokeWidth: 2,
        dashPattern: [8, 4],
        child: Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 80,
                color: primaryColor.withOpacity(0.7),
              ),
              SizedBox(height: 16),
              Text(
                'Toca para seleccionar una imagen',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Recomendamos imágenes de alta calidad\nen formato horizontal',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedImagePreview() {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Image.file(
                _image!,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Text(
                  'Toca para cambiar la imagen',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return _isUploading
        ? Center(
            child: Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
                SizedBox(height: 16),
                Text(
                  'Subiendo imagen...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              if (_image != null)
                ElevatedButton.icon(
                  onPressed: _uploadImage,
                  icon: Icon(Icons.cloud_upload),
                  label: Text('Subir y Continuar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(double.infinity, 50),
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (_image == null)
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.photo_library),
                  label: Text('Seleccionar Imagen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(double.infinity, 50),
                    textStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TicketCategoryScreen(eventId: widget.eventId),
                    ),
                  );
                },
                child: Text(
                  'Omitir este paso',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          );
  }
}
