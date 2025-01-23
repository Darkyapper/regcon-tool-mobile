import 'dart:convert';
import 'package:http/http.dart' as http;
import 'shared_prefs.dart';

class AuthService {
  // URL de tu API
  static const String _baseUrl = 'https://recgonback-8awa0rdv.b4a.run';

  // Método para hacer login
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Respuesta de la API: ${response.body}'); // Log para depuración

      if (response.statusCode == 200) {
        // Decodificar la respuesta
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Verificar que los datos necesarios estén presentes
        if (responseData['token'] == null ||
            responseData['user_id'] == null ||
            responseData['workgroup_id'] == null ||
            responseData['role_id'] == null) {
          throw Exception('Datos incompletos en la respuesta de la API');
        }

        // Guardar el token y otros datos en SharedPreferences
        await SharedPrefs.saveToken(responseData['token']);
        await SharedPrefs.saveUserId(responseData['user_id']);
        await SharedPrefs.saveWorkgroupId(responseData['workgroup_id']);
        await SharedPrefs.saveRoleId(responseData['role_id']);

        return true;
      } else {
        // Mostrar error si el login falla
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Error en el login');
      }
    } catch (e) {
      print('Error en AuthService.login: $e'); // Log para depuración
      throw Exception('Error: $e');
    }
  }

  // Método para validar el token
  static Future<bool> validateToken() async {
    try {
      final token = await SharedPrefs.getToken();
      return token != null; // Devuelve true si hay un token guardado
    } catch (e) {
      print('Error en AuthService.validateToken: $e'); // Log para depuración
      return false;
    }
  }
}
