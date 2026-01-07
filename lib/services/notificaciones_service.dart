import 'dart:convert';
import '../models/notificacion.dart';
import 'api_service.dart';

class NotificacionesService {
  /// Obtener notificaciones del usuario
  static Future<Map<String, dynamic>> obtenerNotificaciones({
    bool? leida,
    String? tipo,
    int limit = 50,
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      // Construir query parameters
      String endpoint = '/notifications/api/';
      List<String> params = [];

      if (leida != null) {
        params.add('leida=${leida ? "true" : "false"}');
      }
      if (tipo != null && tipo.isNotEmpty) {
        params.add('tipo=$tipo');
      }
      params.add('limit=$limit');

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      final response = await ApiService.get(endpoint, token: token);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final notificaciones = (data['data']['notificaciones'] as List)
            .map((json) => Notificacion.fromJson(json))
            .toList();

        return {
          'notificaciones': notificaciones,
          'total_no_leidas': data['data']['total_no_leidas'],
        };
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada');
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Error al cargar notificaciones');
      }
    } catch (e) {
      throw Exception('Error al cargar notificaciones: $e');
    }
  }

  /// Contar notificaciones no leídas
  static Future<int> contarNoLeidas() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final response = await ApiService.get(
        '/notifications/api/count/',
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['count'];
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  /// Marcar una notificación como leída
  static Future<void> marcarComoLeida(int notificacionId) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final response = await ApiService.post(
        '/notifications/api/$notificacionId/marcar-leida/',
        {},
        token: token,
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Error al marcar como leída');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Marcar todas las notificaciones como leídas
  static Future<int> marcarTodasComoLeidas() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final response = await ApiService.post(
        '/notifications/api/marcar-todas-leidas/',
        {},
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'];
      } else {
        throw Exception('Error al marcar todas como leídas');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Eliminar una notificación
  static Future<void> eliminarNotificacion(int notificacionId) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final response = await ApiService.delete(
        '/notifications/api/$notificacionId/eliminar/',
        token: token,
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Error al eliminar notificación');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
