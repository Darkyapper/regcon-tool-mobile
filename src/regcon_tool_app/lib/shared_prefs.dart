import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static const String _tokenKey = 'token';
  static const String _userIdKey = 'user_id';
  static const String _workgroupIdKey = 'workgroup_id';
  static const String _roleIdKey = 'role_id';

  // Guardar el token
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Error en SharedPrefs.saveToken: $e'); // Log para depuración
    }
  }

  // Obtener el token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error en SharedPrefs.getToken: $e'); // Log para depuración
      return null;
    }
  }

  // Guardar el ID del usuario
  static Future<void> saveUserId(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userIdKey, userId);
    } catch (e) {
      print('Error en SharedPrefs.saveUserId: $e'); // Log para depuración
    }
  }

  // Obtener el ID del usuario
  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_userIdKey);
    } catch (e) {
      print('Error en SharedPrefs.getUserId: $e'); // Log para depuración
      return null;
    }
  }

  // Guardar el workgroup_id
  static Future<void> saveWorkgroupId(int workgroupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_workgroupIdKey, workgroupId);
    } catch (e) {
      print('Error en SharedPrefs.saveWorkgroupId: $e'); // Log para depuración
    }
  }

  // Obtener el workgroup_id
  static Future<int?> getWorkgroupId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_workgroupIdKey);
    } catch (e) {
      print('Error en SharedPrefs.getWorkgroupId: $e'); // Log para depuración
      return null;
    }
  }

  // Guardar el role_id
  static Future<void> saveRoleId(int roleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_roleIdKey, roleId);
    } catch (e) {
      print('Error en SharedPrefs.saveRoleId: $e'); // Log para depuración
    }
  }

  // Obtener el role_id
  static Future<int?> getRoleId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_roleIdKey);
    } catch (e) {
      print('Error en SharedPrefs.getRoleId: $e'); // Log para depuración
      return null;
    }
  }

  // Eliminar todos los datos (para logout)
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error en SharedPrefs.clear: $e'); // Log para depuración
    }
  }
}
