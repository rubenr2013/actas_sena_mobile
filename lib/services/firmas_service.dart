import 'dart:convert';
import '../models/firma_pendiente.dart';
import 'api_service.dart';

class FirmasService {
  static Future<List<FirmaPendiente>> getActasPendientesFirma() async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await ApiService.get(
        '/actas/api/firmas/pendientes/',
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((json) => FirmaPendiente.fromJson(json))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada');
      } else {
        throw Exception('Error al cargar actas pendientes');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Map<String, dynamic>> firmarActa({
    required int firmaId,
    required String firmaImagenBase64,
  }) async {
    try {
      final token = await ApiService.getToken();

      if (token == null) {
        throw Exception('No autenticado');
      }

      final response = await ApiService.post(
        '/actas/api/firmas/firmar/',
        {
          'firma_id': firmaId,
          'firma_imagen': firmaImagenBase64,
        },
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'acta_finalizada': data['acta_finalizada'] ?? false,
          'firmas_completadas': data['firmas_completadas'],
        };
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Error al firmar acta');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}
