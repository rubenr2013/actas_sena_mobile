import 'dart:convert';
import '../models/dashboard.dart';
import 'api_service.dart';

class DashboardService {
  static Future<DashboardData> getDashboard() async {
    const endpoint = '/actas/api/dashboard/';
    // ignore: avoid_print
    print('📊 Dashboard Request: $endpoint');

    try {
      final token = await ApiService.getToken();

      if (token == null || token.isEmpty) {
        // ignore: avoid_print
        print('❌ Token no encontrado');
        throw Exception('Sesión expirada. Por favor inicia sesión');
      }

      // ignore: avoid_print
      print('✅ Token presente: ${token.substring(0, token.length > 10 ? 10 : token.length)}...');

      final response = await ApiService.get(
        endpoint,
        token: token,
      );

      // ignore: avoid_print
      print('📡 Status Code: ${response.statusCode}');

      // Log preview del body (primeros 500 caracteres)
      final bodyPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      // ignore: avoid_print
      print('📄 Response Body (preview): $bodyPreview');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Validar estructura de respuesta
        if (data['success'] != true) {
          // ignore: avoid_print
          print('❌ Respuesta del servidor indica error: ${data['error'] ?? 'Sin mensaje'}');
          throw Exception(data['error'] ?? 'Respuesta del servidor indica error');
        }

        if (data['data'] == null) {
          // ignore: avoid_print
          print('❌ Respuesta sin campo "data"');
          throw Exception('Respuesta del servidor sin datos');
        }

        // ignore: avoid_print
        print('✅ Dashboard cargado exitosamente');
        return DashboardData.fromJson(data['data']);
      } else if (response.statusCode == 401) {
        // ignore: avoid_print
        print('❌ Error 401: Token inválido o expirado');
        throw Exception('Sesión expirada. Por favor inicia sesión');
      } else if (response.statusCode == 403) {
        // ignore: avoid_print
        print('❌ Error 403: Sin permisos');
        throw Exception('No tienes permisos para acceder');
      } else if (response.statusCode == 404) {
        // ignore: avoid_print
        print('❌ Error 404: Endpoint no encontrado');
        throw Exception('Servicio no encontrado. Verifica la URL del servidor');
      } else if (response.statusCode == 500) {
        // ignore: avoid_print
        print('❌ Error 500: Error interno del servidor');
        throw Exception('Error del servidor. Intenta más tarde');
      } else {
        // ignore: avoid_print
        print('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Error al cargar dashboard (${response.statusCode})');
      }
    } on FormatException catch (e) {
      // ignore: avoid_print
      print('❌ Error parseando JSON: $e');
      throw Exception('Respuesta del servidor en formato inválido');
    } catch (e) {
      // ignore: avoid_print
      print('❌ Excepción en getDashboard: $e');

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
