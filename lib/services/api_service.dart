import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ApiService {
  static const String baseUrl = AppConstants.baseUrl;

  // Headers básicos
  static Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // GET
  static Future<http.Response> get(String endpoint, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http
          .get(
            url,
            headers: _getHeaders(token: token),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('La petición tardó demasiado tiempo');
            },
          );
      return response;
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Verifica tu conexión a internet.');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // POST
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http
          .post(
            url,
            headers: _getHeaders(token: token),
            body: json.encode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('La petición tardó demasiado tiempo');
            },
          );
      return response;
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Verifica tu conexión a internet.');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // PUT
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http
          .put(
            url,
            headers: _getHeaders(token: token),
            body: json.encode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('La petición tardó demasiado tiempo');
            },
          );
      return response;
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Verifica tu conexión a internet.');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // DELETE
  static Future<http.Response> delete(String endpoint, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http
          .delete(
            url,
            headers: _getHeaders(token: token),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('La petición tardó demasiado tiempo');
            },
          );
      return response;
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado. Verifica tu conexión a internet.');
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Guardar token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  // Obtener token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // Eliminar token (logout)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
  }

  // Guardar datos de usuario
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, json.encode(userData));

    // Guardar el rol por separado para fácil acceso
    if (userData['rol'] != null) {
      await prefs.setString('user_rol', userData['rol'] as String);
    }
  }

  // Obtener datos de usuario
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(AppConstants.userKey);
    if (userString != null) {
      return json.decode(userString) as Map<String, dynamic>;
    }
    return null;
  }

  // Obtener rol del usuario
  static Future<String?> getUserRol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_rol');
  }

  // Verificar si el usuario es instructor o admin
  static Future<bool> canCreateActas() async {
    final rol = await getUserRol();
    return rol == 'instructor' ||
        rol == 'admin' ||
        rol == 'coordinador' ||
        rol == 'director';
  }

  // Verificar si el usuario es admin
  static Future<bool> isAdmin() async {
    final userData = await getUserData();
    if (userData == null) return false;
    return userData['is_staff'] == true || userData['is_superuser'] == true;
  }

  // Limpiar datos (logout completo)
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
