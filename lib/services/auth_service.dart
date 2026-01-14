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
          'username': email, // Django usa 'username' aunque sea email
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
          'telefono': telefono ?? '',
          // El backend detecta automáticamente el rol por el email
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

  // Solicitar código de recuperación
  static Future<Map<String, dynamic>> solicitarCodigoRecuperacion(
      String email) async {
    try {
      final response = await ApiService.post(
        '/actas/api/auth/solicitar-codigo/',
        {
          'email': email,
        },
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Código enviado al correo',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al enviar código',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Verificar código de recuperación
  static Future<Map<String, dynamic>> verificarCodigo({
    required String email,
    required String code,
  }) async {
    try {
      final response = await ApiService.post(
        '/actas/api/auth/verificar-codigo/',
        {
          'email': email,
          'code': code,
        },
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Código verificado',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Código inválido o expirado',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Resetear contraseña
  static Future<Map<String, dynamic>> resetearPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.post(
        '/actas/api/auth/resetear-password/',
        {
          'email': email,
          'code': code,
          'new_password': newPassword,
        },
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Contraseña actualizada correctamente',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al actualizar contraseña',
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

  // Verificar email con código de 6 dígitos
  static Future<Map<String, dynamic>> verificarEmail({
    required String email,
    required String codigo,
  }) async {
    try {
      final response = await ApiService.post(
        '/actas/api/auth/verificar-email/',
        {
          'email': email,
          'codigo': codigo,
        },
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        // Retornar todo lo que el backend envía
        return {
          'success': true,
          'message': data['message'] ?? 'Email verificado correctamente',
          'token': data['token'], // Puede ser null si el backend no lo envía
          'user': data['user'],   // Puede ser null si el backend no lo envía
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Código incorrecto o expirado',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // Reenviar código de verificación de email
  static Future<Map<String, dynamic>> reenviarCodigoVerificacion(
      String email) async {
    try {
      final response = await ApiService.post(
        '/actas/api/auth/reenviar-codigo/',
        {
          'email': email,
        },
      );

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Código reenviado al correo',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al reenviar código',
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
