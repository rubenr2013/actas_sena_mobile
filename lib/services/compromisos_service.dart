import 'dart:convert';
import 'api_service.dart';

class CompromisosService {
  /// Crear un nuevo compromiso
  static Future<Map<String, dynamic>> crearCompromiso({
    required int actaId,
    required String descripcion,
    required int responsableId,
    required String fechaLimite, // Formato: YYYY-MM-DD
    String? observaciones,
  }) async {
    try {
      // Obtener token
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      // Preparar datos
      final body = {
        'acta_id': actaId,  // ← IMPORTANTE: incluir acta_id en el body
        'descripcion': descripcion,
        'responsable_id': responsableId,
        'fecha_limite': fechaLimite,
        'observaciones': observaciones ?? '',
      };

      // Hacer petición a la URL CORRECTA
      final response = await ApiService.post(
        'actas/api/compromisos/crear/',  // ← URL CORRECTA
        body,
        token: token,
      );

      // Parsear respuesta
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
}
