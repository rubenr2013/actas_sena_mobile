import 'dart:convert';
import '../models/dashboard.dart';
import 'api_service.dart';

class DashboardService {
  static Future<DashboardData> getDashboard() async {
    const endpoint = '/actas/api/dashboard/';

    try {
      final token = await ApiService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Sesión expirada. Por favor inicia sesión');
      }

      final response = await ApiService.get(
        endpoint,
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Validar estructura de respuesta
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Respuesta del servidor indica error');
        }

        if (data['data'] == null) {
          throw Exception('Respuesta del servidor sin datos');
        }

        return DashboardData.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada. Por favor inicia sesión');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para acceder');
      } else if (response.statusCode == 404) {
        throw Exception('Servicio no encontrado. Verifica la URL del servidor');
      } else if (response.statusCode == 500) {
        throw Exception('Error del servidor. Intenta más tarde');
      } else {
        throw Exception('Error al cargar dashboard (${response.statusCode})');
      }
    } on FormatException {
      throw Exception('Respuesta del servidor en formato inválido');
    } catch (e) {
      // Identificar errores de conexión
      final errorStr = e.toString();
      if (errorStr.contains('SocketException') ||
          errorStr.contains('Failed host lookup')) {
        throw Exception('Sin conexión a internet o servidor no disponible');
      } else if (errorStr.contains('HandshakeException')) {
        throw Exception('Error de conexión segura (SSL/TLS)');
      } else if (errorStr.contains('TimeoutException') ||
          errorStr.contains('Timeout')) {
        throw Exception('Tiempo de espera agotado. El servidor no responde');
      }

      rethrow;
    }
  }
}
