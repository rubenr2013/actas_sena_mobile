import 'dart:convert';
import '../models/usuario.dart';
import 'api_service.dart';
import '../utils/constants.dart';

class AuthService {
  // Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await ApiService.post(
        AppConstants.loginEndpoint,
        {
          'username': email,  // Django usa 'username' aunque sea email
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Guardar token
        if (data['token'] != null) {
          await ApiService.saveToken(data['token'] as String);
        }
        
        // Guardar datos de usuario
        if (data['user'] != null) {
          await ApiService.saveUserData(data['user'] as Map<String, dynamic>);
        }
        
        return {
          'success': true,
          'token': data['token'],
          'user': Usuario.fromJson(data['user'] as Map<String, dynamic>),
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'Credenciales incorrectas',
        };
      } else {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': data['error'] ?? 'Error al iniciar sesión',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Registro de nuevo usuario
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String rol,
    String? telefono,
  }) async {
    try {
      final response = await ApiService.post(
        '/actas/api/auth/register/',
        {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'rol': rol,
          'telefono': telefono ?? '',
        },
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Cuenta creada correctamente',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al crear cuenta',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Logout
  static Future<void> logout() async {
    await ApiService.clearAllData();
  }

  // Verificar si está autenticado
  static Future<bool> isAuthenticated() async {
    final token = await ApiService.getToken();
    return token != null && token.isNotEmpty;
  }

  // Obtener usuario actual
  static Future<Usuario?> getCurrentUser() async {
    final userData = await ApiService.getUserData();
    if (userData != null) {
      return Usuario.fromJson(userData);
    }
    return null;
  }

  static Future<Map<String, dynamic>> cambiarPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await ApiService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'error': 'No autenticado',
        };
      }

      final response = await ApiService.post(
        '/actas/api/cambiar-password/',
        {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        token: token,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al cambiar contraseña',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }
}