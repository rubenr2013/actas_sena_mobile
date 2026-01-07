import 'dart:convert';
import 'api_service.dart';

class CompromisosService {
  /// Crear un nuevo compromiso
  static Future<Map<String, dynamic>> crearCompromiso({
    required int actaId,
    required String descripcion,
    required int responsableId,
    required String fechaLimite,
    String? observaciones,
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final body = {
        'acta_id': actaId,
        'descripcion': descripcion,
        'responsable_id': responsableId,
        'fecha_limite': fechaLimite,
        'observaciones': observaciones ?? '',
      };

      final response = await ApiService.post(
        'actas/api/compromisos/crear/',
        body,
        token: token,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['data'];
      } else {
        throw Exception(data['error'] ?? 'Error al crear compromiso');
      }
    } catch (e) {
      throw Exception('Error al crear compromiso: $e');
    }
  }

  /// Obtener mis compromisos asignados
  static Future<List<Map<String, dynamic>>> obtenerMisCompromisos() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final response = await ApiService.get(
        '/actas/api/compromisos/mis-compromisos/',
        token: token,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada');
      } else {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Error al cargar compromisos');
      }
    } catch (e) {
      throw Exception('Error al cargar compromisos: $e');
    }
  }

  /// Actualizar un compromiso (estado, porcentaje, reporte)
  static Future<Map<String, dynamic>> actualizarCompromiso({
    required int compromisoId,
    String? estado,
    int? porcentajeAvance,
    String? reporteCumplimiento,
  }) async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final body = <String, dynamic>{};
      if (estado != null) body['estado'] = estado;
      if (porcentajeAvance != null)
        body['porcentaje_avance'] = porcentajeAvance;
      if (reporteCumplimiento != null)
        body['reporte_cumplimiento'] = reporteCumplimiento;

      final response = await ApiService.put(
        '/actas/api/compromisos/$compromisoId/actualizar/',
        body,
        token: token,
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        throw Exception(data['error'] ?? 'Error al actualizar compromiso');
      }
    } catch (e) {
      throw Exception('Error al actualizar compromiso: $e');
    }
  }
}
